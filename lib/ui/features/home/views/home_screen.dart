import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/artwork_card.dart';
import '../../../core/widgets/glass_panel.dart';
import '../view_models/home_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _activeFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider).build();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHomeHeaderDelegate(),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _SearchPill().animate().fadeIn(delay: 80.ms),
                ),
              ),
              SliverToBoxAdapter(
                child: _FilterRow(
                  filters: state.filters,
                  activeIndex: _activeFilterIndex,
                  onChanged: (index) {
                    setState(() {
                      _activeFilterIndex = index;
                    });
                  },
                ).animate().fadeIn(delay: 140.ms),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final artwork = state.artwork[index];
                    return ArtworkCard(
                      artwork: artwork,
                      compact: index.isOdd,
                    ).animate().fadeIn(delay: (180 + index * 45).ms);
                  }, childCount: state.artwork.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

class _StickyHomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  static const _maxHeaderExtent = 88.0;
  static const _minHeaderExtent = 64.0;

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

    return _Header(progress: t);
  }

  @override
  bool shouldRebuild(covariant _StickyHomeHeaderDelegate oldDelegate) => false;
}

class _Header extends StatelessWidget {
  const _Header({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final backgroundOpacity = lerpDouble(0, 0.86, progress)!;
    final blur = lerpDouble(0, 28, progress)!;
    final titleSize = lerpDouble(32, 22, progress)!;
    final avatarRadius = lerpDouble(20, 17, progress)!;
    final topPadding = lerpDouble(18, 8, progress)!;
    final bottomPadding = lerpDouble(8, 7, progress)!;

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
                      ClipRect(
                        child: Align(
                          heightFactor: lerpDouble(1, 0, progress)!,
                          alignment: Alignment.topLeft,
                          child: Transform.translate(
                            offset: Offset(0, -8 * progress),
                            child: Opacity(
                              opacity: 1 - progress,
                              child: Text(
                                'TODAY',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      letterSpacing: 0.8,
                                      color: AppColors.inkSub,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: lerpDouble(6, 0, progress)!),
                      Text(
                        'Discover',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontSize: titleSize),
                      ),
                    ],
                  ),
                ),
                GlassPanel(
                  radius: 999,
                  padding: EdgeInsets.all(lerpDouble(5, 4, progress)!),
                  strong: true,
                  child: CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      size: lerpDouble(20, 17, progress)!,
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

class _SearchPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      strong: true,
      child: Row(
        children: const [
          Icon(Icons.search_rounded, color: AppColors.inkSub, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search artists, tags...',
              style: TextStyle(
                color: AppColors.inkDim,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(7),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
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

  final List<String> filters;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  static const _gap = 8.0;
  static const _horizontalPadding = 20.0;
  static const _verticalPadding = 14.0;
  static const _pillHeight = 36.0;
  static const _pillHorizontalPadding = 16.0;

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );
    final widths = [
      for (final filter in filters)
        _measureText(context, filter, textStyle) + _pillHorizontalPadding * 2,
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
                    color: AppColors.ink,
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
                          label: filters[index],
                          width: widths[index],
                          active: activeIndex == index,
                          onTap: () => onChanged(index),
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
