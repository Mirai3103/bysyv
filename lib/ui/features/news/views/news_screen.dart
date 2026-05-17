import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/artwork.dart';
import '../../../../domain/models/novel.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/artwork_card.dart';
import '../../../core/widgets/glass_panel.dart';
import '../view_models/news_view_model.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(newsViewModelProvider);
    final state = viewModel.state;

    return Scaffold(
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _NewsHeader()),
              SliverToBoxAdapter(
                child: _TopTabs(
                  active: state.feedTab,
                  onChanged: viewModel.selectFeedTab,
                ).animate().fadeIn(delay: 80.ms),
              ),
              SliverToBoxAdapter(
                child: _ContentSwitch(
                  active: state.contentType,
                  onChanged: viewModel.selectContentType,
                ).animate().fadeIn(delay: 120.ms),
              ),
              if (state.isLoading)
                const _NewsSkeleton()
              else if (state.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _FeedMessage(
                    title: 'News failed',
                    message: state.errorMessage!,
                    actionLabel: 'Retry',
                    onAction: viewModel.refresh,
                  ),
                )
              else if (state.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _FeedMessage(
                    title: 'No items',
                    message: 'Pull to refresh and try again.',
                    actionLabel: 'Refresh',
                    onAction: viewModel.refresh,
                  ),
                )
              else if (state.contentType == NewsContentType.artworks)
                _ArtworkGrid(artworks: state.artworks)
              else
                _NovelList(novels: state.novels),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsHeader extends StatelessWidget {
  const _NewsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 68, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              'News',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 30,
                letterSpacing: -0.8,
              ),
            ),
          ),
          GlassPanel(
            radius: 999,
            padding: const EdgeInsets.all(8),
            strong: true,
            child: const Icon(
              Icons.article_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTabs extends StatelessWidget {
  const _TopTabs({required this.active, required this.onChanged});

  final NewsFeedTab active;
  final ValueChanged<NewsFeedTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          for (final tab in NewsFeedTab.values) ...[
            _TopTab(
              label: tab.label,
              active: active == tab,
              onTap: () => onChanged(tab),
            ),
            if (tab != NewsFeedTab.values.last) const SizedBox(width: 22),
          ],
        ],
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  const _TopTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.ink : AppColors.inkSub,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: 240.ms,
                width: active ? 34 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentSwitch extends StatelessWidget {
  const _ContentSwitch({required this.active, required this.onChanged});

  final NewsContentType active;
  final ValueChanged<NewsContentType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SwitchPill(
            label: 'Artworks',
            active: active == NewsContentType.artworks,
            onTap: () => onChanged(NewsContentType.artworks),
          ),
          const SizedBox(width: 8),
          _SwitchPill(
            label: 'Novels',
            active: active == NewsContentType.novels,
            onTap: () => onChanged(NewsContentType.novels),
          ),
        ],
      ),
    );
  }
}

class _SwitchPill extends StatelessWidget {
  const _SwitchPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: 220.ms,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.inkDim,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ArtworkGrid extends StatelessWidget {
  const _ArtworkGrid({required this.artworks});

  final List<Artwork> artworks;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 128),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          final artwork = artworks[index];
          return ArtworkCard(
            artwork: artwork,
            compact: index.isOdd,
            onTap: () => context.push('/artworks/${artwork.id}'),
          ).animate().fadeIn(delay: (80 + index * 35).ms);
        }, childCount: artworks.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
      ),
    );
  }
}

class _NovelList extends StatelessWidget {
  const _NovelList({required this.novels});

  final List<Novel> novels;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 128),
      sliver: SliverList.separated(
        itemBuilder: (context, index) {
          final novel = novels[index];
          return _NovelCard(
            novel: novel,
          ).animate().fadeIn(delay: (80 + index * 35).ms);
        },
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemCount: novels.length,
      ),
    );
  }
}

class _NovelCard extends StatelessWidget {
  const _NovelCard({required this.novel});

  final Novel novel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/novels/${novel.id}'),
        child: GlassPanel(
          radius: 20,
          padding: const EdgeInsets.all(12),
          strong: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 58,
                  height: 76,
                  child: _NetworkImage(url: novel.imageUrl),
                ),
              ),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@${novel.author.account}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (novel.caption.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        novel.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkSub,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _TinyMeta(
                          icon: Icons.menu_book,
                          label: _formatCount(novel.textLength),
                        ),
                        const SizedBox(width: 10),
                        _TinyMeta(
                          icon: Icons.visibility_outlined,
                          label: _formatCount(novel.totalView),
                        ),
                        const SizedBox(width: 10),
                        _TinyMeta(
                          icon: Icons.bookmark_border,
                          label: _formatCount(novel.bookmarks),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int value) {
    if (value >= 10000) return '${(value / 10000).toStringAsFixed(1)}万';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toString();
  }
}

class _TinyMeta extends StatelessWidget {
  const _TinyMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.inkSub),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.inkSub,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return const _GradientFallback();

    return CachedNetworkImage(
      imageUrl: url!,
      httpHeaders: ArtworkCard.imageHeaders,
      fit: BoxFit.cover,
      placeholder: (context, url) => const _GradientFallback(),
      errorWidget: (context, url, error) => const _GradientFallback(),
    );
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
        ),
      ),
    );
  }
}

class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.sliver(
      enabled: true,
      child: SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 128),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate((context, index) {
            final artwork = Artwork.samples[index % Artwork.samples.length];
            return ArtworkCard(artwork: artwork, compact: index.isOdd);
          }, childCount: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
        ),
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inkSub),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
