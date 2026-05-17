import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/artwork.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/artwork_card.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../auth/view_models/auth_controller.dart';
import '../view_models/home_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(homeViewModelProvider);
    final state = viewModel.state;
    final avatarUrl = ref.watch(authControllerProvider).session?.avatarUrl;

    return Scaffold(
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHomeHeaderDelegate(avatarUrl: avatarUrl),
              ),
              SliverToBoxAdapter(
                child: _FilterRow(
                  filters: state.filters,
                  activeIndex: state.activeFilterIndex,
                  onChanged: viewModel.selectFilter,
                ).animate().fadeIn(delay: 80.ms),
              ),
              if (state.isLoading)
                const _ArtworkSkeletonGrid()
              else if (state.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _FeedMessage(
                    title: 'Recommend failed',
                    message: state.errorMessage!,
                    actionLabel: 'Retry',
                    onAction: viewModel.refresh,
                  ),
                )
              else if (state.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _FeedMessage(
                    title: 'No recommendations',
                    message: 'Pull to refresh and try again.',
                    actionLabel: 'Refresh',
                    onAction: viewModel.refresh,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final artwork = state.artwork[index];
                      return GestureDetector(
                        key: ValueKey('artwork-card-${artwork.id}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.push('/artworks/${artwork.id}'),
                        child: ArtworkCard(
                          artwork: artwork,
                          compact: index.isOdd,
                        ),
                      ).animate().fadeIn(delay: (180 + index * 45).ms);
                    }, childCount: state.artwork.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.72,
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

class _ArtworkSkeletonGrid extends StatelessWidget {
  const _ArtworkSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.sliver(
      enabled: true,
      child: SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
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

class _StickyHomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StickyHomeHeaderDelegate({required this.avatarUrl});

  static const _maxHeaderExtent = 88.0;
  static const _minHeaderExtent = 64.0;

  final String? avatarUrl;

  @override
  double get maxExtent => _maxHeaderExtent;

  @override
  double get minExtent => _minHeaderExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return _Header(progress: t, avatarUrl: avatarUrl);
  }

  @override
  bool shouldRebuild(covariant _StickyHomeHeaderDelegate oldDelegate) {
    return oldDelegate.avatarUrl != avatarUrl;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.progress, required this.avatarUrl});

  final double progress;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final backgroundOpacity = lerpDouble(0, 0.86, progress)!;
    final blur = lerpDouble(0, 28, progress)!;
    final titleSize = lerpDouble(32, 22, progress)!;
    final avatarRadius = lerpDouble(20, 17, progress)!;
    final topPadding = lerpDouble(4, 0, progress)!;
    final bottomPadding = lerpDouble(6, 5, progress)!;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bg.withValues(alpha: backgroundOpacity),
            border: Border(
              bottom: BorderSide(
                color: AppColors.ink.withValues(alpha: progress * 0.06),
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding, 20, bottomPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontSize: titleSize),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => context.go('/profile'),
                    child: GlassPanel(
                      radius: 999,
                      padding: EdgeInsets.all(lerpDouble(5, 4, progress)!),
                      strong: true,
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: AppColors.primarySoft,
                        backgroundImage: avatarUrl == null || avatarUrl!.isEmpty
                            ? null
                            : CachedNetworkImageProvider(
                                avatarUrl!,
                                headers: ArtworkCard.imageHeaders,
                              ),
                        child: avatarUrl == null || avatarUrl!.isEmpty
                            ? Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                                size: lerpDouble(20, 17, progress)!,
                              )
                            : null,
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

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filters,
    required this.activeIndex,
    required this.onChanged,
  });

  final List<HomeFilter> filters;
  final int activeIndex;
  final ValueChanged<HomeFilter> onChanged;

  static const _gap = 8.0;
  static const _horizontalPadding = 20.0;
  static const _verticalPadding = 14.0;
  static const _pillHeight = 36.0;
  static const _pillHorizontalPadding = 16.0;

  @override
  Widget build(BuildContext context) {
    final labels = filters.map((filter) => filter.label).toList();
    final textStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );
    final widths = [
      for (final label in labels)
        _measureText(context, label, textStyle) + _pillHorizontalPadding * 2,
    ];
    final activeLeft =
        _horizontalPadding +
        widths
            .take(activeIndex)
            .fold<double>(0, (offset, width) => offset + width + _gap);
    final rowWidth =
        _horizontalPadding * 2 +
        widths.fold<double>(0, (total, width) => total + width) +
        _gap * (filters.length - 1);

    return SizedBox(
      height: 58,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: SizedBox(
          width: rowWidth,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: 520.ms,
                curve: Curves.easeOutBack,
                left: activeLeft,
                top: _verticalPadding,
                width: widths[activeIndex],
                height: _pillHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2914141E),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _horizontalPadding,
                    _verticalPadding,
                    _horizontalPadding,
                    8,
                  ),
                  child: Row(
                    children: [
                      for (var index = 0; index < filters.length; index++) ...[
                        _FilterPill(
                          label: labels[index],
                          width: widths[index],
                          active: activeIndex == index,
                          onTap: () => onChanged(filters[index]),
                        ),
                        if (index != filters.length - 1)
                          const SizedBox(width: _gap),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _measureText(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();

    return painter.width;
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.width,
    required this.active,
    required this.onTap,
  });

  final String label;
  final double width;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: 240.ms,
          curve: Curves.easeOutCubic,
          width: width,
          height: _FilterRow._pillHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.transparent : AppColors.glass,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? Colors.transparent : AppColors.glassBorder,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: 240.ms,
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: active ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
