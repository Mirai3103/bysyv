import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/artwork.dart';
import '../../../../domain/models/novel.dart';
import '../../../../domain/models/pixiv_tag.dart';
import '../../../../domain/models/search_user_result.dart';
import '../../../../domain/models/trend_tag.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_bottom_sheet_overlay.dart';
import '../../../core/widgets/artwork_card.dart';
import '../../../core/widgets/glass_panel.dart';
import '../view_models/search_view_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  var _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    _focusNode = FocusNode()
      ..addListener(() {
        if (!mounted) return;
        setState(() => _focused = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.extentAfter < 700) {
      ref.read(searchViewModelProvider).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(searchViewModelProvider);
    final state = viewModel.state;

    if (_controller.text != state.query) {
      _controller.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: state.mode == SearchMode.results
                ? [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child:
                            _SearchHeader(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  focused: _focused,
                                  onChanged: viewModel.queryChanged,
                                  onSubmitted: viewModel.submitSearch,
                                  onBack: viewModel.backToIdle,
                                  onClear: () {
                                    _controller.clear();
                                    viewModel.clearQuery();
                                  },
                                )
                                .animate()
                                .fadeIn(duration: 260.ms)
                                .slideY(
                                  begin: 0.08,
                                  end: 0,
                                  duration: 420.ms,
                                  curve: Curves.easeOutCubic,
                                ),
                      ),
                    ),
                    _ResultHeaderSliver(
                      state: state,
                      onTabSelected: viewModel.setActiveTab,
                      onSortSelected: viewModel.setSort,
                      onFilterTap: () => _showFilterSheet(state.filters),
                    ),
                    ..._buildResultSlivers(state, viewModel),
                  ]
                : [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child:
                            _SearchHeader(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  focused: _focused,
                                  onChanged: viewModel.queryChanged,
                                  onSubmitted: viewModel.submitSearch,
                                  onBack: () {
                                    _focusNode.unfocus();
                                    HapticFeedback.selectionClick();
                                  },
                                  onClear: () {
                                    _controller.clear();
                                    viewModel.clearQuery();
                                  },
                                )
                                .animate()
                                .fadeIn(duration: 260.ms)
                                .slideY(
                                  begin: 0.08,
                                  end: 0,
                                  duration: 420.ms,
                                  curve: Curves.easeOutCubic,
                                ),
                      ),
                    ),
                    if (state.hasQuery)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: _AutocompletePanel(
                            tags: state.autocompleteTags,
                            isLoading: state.isAutocompleteLoading,
                            onSelect: viewModel.selectAutocomplete,
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _SectionTitle(
                          title: 'Recent',
                          actionLabel: state.recentWords.isEmpty
                              ? null
                              : 'Clear all',
                          onAction: viewModel.clearRecent,
                        ).animate().fadeIn(delay: 80.ms),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _RecentBadges(
                          words: state.recentWords,
                          onSelect: viewModel.selectRecent,
                          onRemove: viewModel.removeRecent,
                        ).animate().fadeIn(delay: 130.ms),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: const _SectionTitle(
                          title: 'Trending tags',
                        ).animate().fadeIn(delay: 160.ms),
                      ),
                    ),
                    if (state.isTrendingLoading)
                      const _TrendingSkeletonGrid()
                    else if (state.hasError)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
                        sliver: SliverToBoxAdapter(
                          child: _SearchMessage(
                            title: 'Could not load tags',
                            message: state.errorMessage!,
                            onRetry: viewModel.retryTrending,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 128),
                        sliver: _TrendingTagGrid(
                          tags: state.trendingTags,
                          onSelect: viewModel.selectTrendingTag,
                        ),
                      ),
                  ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResultSlivers(
    SearchState state,
    SearchViewModel viewModel,
  ) {
    if (state.isResultsLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ];
    }

    if (state.hasResultsError && state.activeCount == 0) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 128),
          sliver: SliverToBoxAdapter(
            child: _SearchMessage(
              title: 'Could not load results',
              message: state.resultsErrorMessage!,
              onRetry: viewModel.retryResults,
            ),
          ),
        ),
      ];
    }

    final slivers = <Widget>[];
    switch (state.activeTab) {
      case SearchResultTab.artwork:
        if (state.artworkResults.isEmpty) {
          slivers.add(const _EmptyResultsSliver(label: 'No artworks found'));
        } else {
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final artwork = state.artworkResults[index];
                  return _ArtworkResultTile(artwork: artwork);
                }, childCount: state.artworkResults.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
              ),
            ),
          );
        }
      case SearchResultTab.novel:
        if (state.novelResults.isEmpty) {
          slivers.add(const _EmptyResultsSliver(label: 'No novels found'));
        } else {
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              sliver: SliverList.separated(
                itemBuilder: (context, index) {
                  return _NovelResultRow(novel: state.novelResults[index]);
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemCount: state.novelResults.length,
              ),
            ),
          );
        }
      case SearchResultTab.user:
        if (state.userResults.isEmpty) {
          slivers.add(const _EmptyResultsSliver(label: 'No users found'));
        } else {
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              sliver: SliverList.separated(
                itemBuilder: (context, index) {
                  return _UserResultRow(result: state.userResults[index]);
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemCount: state.userResults.length,
              ),
            ),
          );
        }
    }

    if (state.isLoadingMore) {
      slivers.add(
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 128),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      );
    } else {
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 128)));
    }
    return slivers;
  }

  Future<void> _showFilterSheet(SearchFilters filters) async {
    final updated = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(initial: filters),
    );
    if (updated != null) {
      await ref.read(searchViewModelProvider).applyFilters(updated);
    }
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.onChanged,
    required this.onSubmitted,
    required this.onBack,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onBack;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: AppColors.glassStrong,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: focused ? AppColors.primary : AppColors.glassBorder,
                width: focused ? 1.5 : 1,
              ),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x0D14141E),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
                if (focused)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    blurRadius: 0,
                    spreadRadius: 3,
                  ),
              ],
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search tags, titles, users...',
                hintStyle: const TextStyle(
                  color: AppColors.inkSub,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: focused ? AppColors.primary : AppColors.inkSub,
                  size: 18,
                ),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          tooltip: 'Clear search',
                          onPressed: onClear,
                          icon: const Icon(Icons.close, size: 16),
                          color: AppColors.primary,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primarySoft,
                            minimumSize: const Size(28, 28),
                            fixedSize: const Size(28, 28),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconGlassButton extends StatelessWidget {
  const _IconGlassButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.glassStrong,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(64, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}

class _RecentBadges extends StatelessWidget {
  const _RecentBadges({
    required this.words,
    required this.onSelect,
    required this.onRemove,
  });

  final List<String> words;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'No recent searches',
          style: TextStyle(
            color: AppColors.inkSub,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final word in words)
          _RecentBadge(
            key: ValueKey('recent-$word'),
            word: word,
            onSelect: () => onSelect(word),
            onRemove: () => onRemove(word),
          ),
      ],
    );
  }
}

class _RecentBadge extends StatefulWidget {
  const _RecentBadge({
    super.key,
    required this.word,
    required this.onSelect,
    required this.onRemove,
  });

  final String word;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  @override
  State<_RecentBadge> createState() => _RecentBadgeState();
}

class _RecentBadgeState extends State<_RecentBadge> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: AppColors.glassStrong,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onSelect,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 7, 7, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.word,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onRemove,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.inkSubSub,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: Icon(
                        Icons.close,
                        size: 10,
                        color: AppColors.inkDim,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AutocompletePanel extends StatelessWidget {
  const _AutocompletePanel({
    required this.tags,
    required this.isLoading,
    required this.onSelect,
  });

  final List<PixivTag> tags;
  final bool isLoading;
  final ValueChanged<PixivTag> onSelect;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && tags.isEmpty) return const SizedBox.shrink();

    return GlassPanel(
          strong: true,
          radius: 22,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                for (final tag in tags)
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.search,
                      color: AppColors.inkSub,
                      size: 17,
                    ),
                    title: Text(
                      tag.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle:
                        tag.translatedName == null ||
                            tag.translatedName!.isEmpty
                        ? null
                        : Text(
                            tag.translatedName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    onTap: () => onSelect(tag),
                  ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 180.ms)
        .slideY(
          begin: -0.04,
          end: 0,
          duration: 240.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _TrendingSkeletonGrid extends StatelessWidget {
  const _TrendingSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.sliver(
      enabled: true,
      child: SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 128),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate((context, index) {
            return const _TagPlaceholderCard(label: 'Loading');
          }, childCount: 9),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
        ),
      ),
    );
  }
}

class _TrendingTagGrid extends StatelessWidget {
  const _TrendingTagGrid({required this.tags, required this.onSelect});

  final List<TrendTag> tags;
  final ValueChanged<TrendTag> onSelect;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No trending tags',
            style: TextStyle(color: AppColors.inkSub),
          ),
        ),
      );
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate((context, index) {
        final tag = tags[index];
        return _TrendingTagCard(tag: tag, onTap: () => onSelect(tag))
            .animate()
            .fadeIn(delay: (80 + index * 35).ms)
            .slideY(
              begin: 0.08,
              end: 0,
              duration: 360.ms,
              curve: Curves.easeOutCubic,
            );
      }, childCount: tags.length),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
    );
  }
}

class _TrendingTagCard extends StatefulWidget {
  const _TrendingTagCard({required this.tag, required this.onTap});

  final TrendTag tag;
  final VoidCallback onTap;

  @override
  State<_TrendingTagCard> createState() => _TrendingTagCardState();
}

class _TrendingTagCardState extends State<_TrendingTagCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final artwork = widget.tag.artwork;
    final imageUrl = artwork?.imageUrl;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl == null || imageUrl.isEmpty)
                _TagPlaceholderCard(label: widget.tag.tag)
              else
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  httpHeaders: ArtworkCard.imageHeaders,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      _TagPlaceholderCard(label: widget.tag.tag),
                  errorWidget: (context, url, error) =>
                      _TagPlaceholderCard(label: widget.tag.tag),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x99000000)],
                  ),
                ),
              ),
              Positioned(
                left: 9,
                right: 9,
                bottom: 9,
                child: Text(
                  widget.tag.tag,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagPlaceholderCard extends StatelessWidget {
  const _TagPlaceholderCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultHeaderSliver extends StatelessWidget {
  const _ResultHeaderSliver({
    required this.state,
    required this.onTabSelected,
    required this.onSortSelected,
    required this.onFilterTap,
  });

  final SearchState state;
  final ValueChanged<SearchResultTab> onTabSelected;
  final ValueChanged<String> onSortSelected;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (state.activeTab) {
      SearchResultTab.artwork => 'artworks',
      SearchResultTab.novel => 'novels',
      SearchResultTab.user => 'users',
    };

    return SliverPersistentHeader(
      pinned: true,
      delegate: _ResultHeaderDelegate(
        child: ColoredBox(
          color: AppColors.bg.withValues(alpha: 0.92),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${state.activeCount} $label loaded',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (state.activeTab != SearchResultTab.user) ...[
                      _SortMenu(value: state.sort, onSelected: onSortSelected),
                      const SizedBox(width: 8),
                      _IconGlassButton(
                        tooltip: 'Filter',
                        icon: state.filters.hasActiveFilters
                            ? Icons.tune
                            : Icons.filter_list,
                        onTap: onFilterTap,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _ResultTabPill(
                      label: 'Artwork',
                      selected: state.activeTab == SearchResultTab.artwork,
                      onTap: () => onTabSelected(SearchResultTab.artwork),
                    ),
                    const SizedBox(width: 8),
                    _ResultTabPill(
                      label: 'Novel',
                      selected: state.activeTab == SearchResultTab.novel,
                      onTap: () => onTabSelected(SearchResultTab.novel),
                    ),
                    const SizedBox(width: 8),
                    _ResultTabPill(
                      label: 'Users',
                      selected: state.activeTab == SearchResultTab.user,
                      onTap: () => onTabSelected(SearchResultTab.user),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ResultHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 112;

  @override
  double get maxExtent => 112;

  @override
  Widget build(context, shrinkOffset, overlapsContent) => child;

  @override
  bool shouldRebuild(_ResultHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _ResultTabPill extends StatelessWidget {
  const _ResultTabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : AppColors.glassStrong,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 38,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.value, required this.onSelected});

  final String value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Sort',
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'date_desc', child: Text('Newest')),
        PopupMenuItem(value: 'date_asc', child: Text('Oldest')),
        PopupMenuItem(value: 'popular_desc', child: Text('Popular')),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.glassStrong,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Icon(Icons.swap_vert, size: 18),
      ),
    );
  }
}

class _ArtworkResultTile extends StatelessWidget {
  const _ArtworkResultTile({required this.artwork});

  final Artwork artwork;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glassStrong,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('search-artwork-${artwork.id}'),
        onTap: () => context.push('/artworks/${artwork.id}'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (artwork.imageUrl == null || artwork.imageUrl!.isEmpty)
              _TagPlaceholderCard(label: artwork.title)
            else
              CachedNetworkImage(
                imageUrl: artwork.imageUrl!,
                httpHeaders: ArtworkCard.imageHeaders,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    _TagPlaceholderCard(label: artwork.title),
              ),
            if (artwork.pageCount > 1 || artwork.aiType > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Wrap(
                  spacing: 4,
                  children: [
                    if (artwork.aiType > 0) const _Badge(label: 'AI'),
                    if (artwork.pageCount > 1)
                      _Badge(label: '${artwork.pageCount}p'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NovelResultRow extends StatelessWidget {
  const _NovelResultRow({required this.novel});

  final Novel novel;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey('search-novel-${novel.id}'),
      child: _ResultRowPanel(
        onTap: () => context.push('/novels/${novel.id}'),
        child: Row(
          children: [
            _Thumb(url: novel.imageUrl, label: novel.title, size: 72),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    novel.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    novel.author.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.inkSub),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_compactCount(novel.bookmarks)} bookmarks · ${novel.pageCount} pages · ${_compactCount(novel.textLength)} chars',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.inkDim,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserResultRow extends StatelessWidget {
  const _UserResultRow({required this.result});

  final SearchUserResult result;

  @override
  Widget build(BuildContext context) {
    final creator = result.creator;

    return KeyedSubtree(
      key: ValueKey('search-user-${creator.id}'),
      child: _ResultRowPanel(
        onTap: () => context.push('/users/${creator.id}'),
        child: Row(
          children: [
            _Avatar(url: creator.avatarUrl, label: creator.name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    creator.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '@${creator.account}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.inkSub),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            for (final artwork in result.previewArtworks.take(3)) ...[
              _Thumb(url: artwork.imageUrl, label: artwork.title, size: 46),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultRowPanel extends StatelessWidget {
  const _ResultRowPanel({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glassStrong,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: child),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.label, required this.size});

  final String? url;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: size,
        child: url == null || url!.isEmpty
            ? _TagPlaceholderCard(label: label)
            : CachedNetworkImage(
                imageUrl: url!,
                httpHeaders: ArtworkCard.imageHeaders,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    _TagPlaceholderCard(label: label),
              ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.label});

  final String? url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox.square(
        dimension: 54,
        child: url == null || url!.isEmpty
            ? ColoredBox(
                color: AppColors.primarySoft,
                child: Center(
                  child: Text(
                    label.isEmpty ? '?' : label.characters.first,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: url!,
                httpHeaders: ArtworkCard.imageHeaders,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    const ColoredBox(color: AppColors.primarySoft),
              ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _EmptyResultsSliver extends StatelessWidget {
  const _EmptyResultsSliver({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.inkSub,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final SearchFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SearchFilters _filters = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetOverlay(
      title: 'Filter results',
      subtitle:
          'Refine artwork and novel searches with Pixiv-supported fields.',
      onBack: () => Navigator.of(context).pop(),
      children: [
        _FilterDropdown(
          label: 'Match',
          value: _filters.searchTarget,
          items: const {
            'partial_match_for_tags': 'Partial tag',
            'exact_match_for_tags': 'Exact tag',
            'title_and_caption': 'Title and caption',
          },
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(searchTarget: value);
            });
          },
        ),
        const SizedBox(height: 14),
        _FilterDropdown(
          label: 'Artwork type',
          value: _filters.contentType,
          items: const {
            'all': 'All',
            'illust': 'Illustration',
            'manga': 'Manga',
            'ugoira': 'Ugoira',
          },
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(contentType: value);
            });
          },
        ),
        const SizedBox(height: 14),
        _FilterDropdown(
          label: 'Bookmarks',
          value: (_filters.bookmarkMinimum ?? 0).toString(),
          items: const {
            '0': 'Any',
            '100': '100+',
            '500': '500+',
            '1000': '1,000+',
            '5000': '5,000+',
          },
          onChanged: (value) {
            final parsed = int.parse(value);
            setState(() {
              _filters = _filters.copyWith(
                bookmarkMinimum: parsed == 0 ? null : parsed,
              );
            });
          },
        ),
        const SizedBox(height: 14),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('AI results only'),
          value: _filters.aiOnly,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(aiOnly: value);
            });
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop(const SearchFilters());
                },
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_filters),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final entry in items.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

String _compactCount(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toString();
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      strong: true,
      radius: 24,
      child: Column(
        children: [
          const Icon(Icons.trending_up, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkSub),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
