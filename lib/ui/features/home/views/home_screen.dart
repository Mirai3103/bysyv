import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/artwork_card.dart';
import '../../../core/widgets/glass_panel.dart';
import '../view_models/home_view_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider).build();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: _Header().animate().fadeIn().slideY(
                        begin: 0.08,
                        duration: 420.ms,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
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
              const Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _BottomNavigation(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TODAY',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 0.8,
                  color: AppColors.inkSub,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Discover',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ],
          ),
        ),
        GlassPanel(
          radius: 999,
          padding: const EdgeInsets.all(5),
          strong: true,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
      ],
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
  const _FilterRow({required this.filters});

  final List<String> filters;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final active = index == 0;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: active ? AppColors.ink : AppColors.bgPure,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active ? AppColors.ink : AppColors.primaryBorder,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D14141E),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Text(
                filters[index],
                style: TextStyle(
                  color: active ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: filters.length,
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (AppRoute.home, Icons.home_rounded),
      (AppRoute.search, Icons.search_rounded),
      (AppRoute.create, Icons.add_rounded),
      (AppRoute.bookmarks, Icons.favorite_rounded),
      (AppRoute.profile, Icons.person_rounded),
    ];

    return GlassPanel(
      radius: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      strong: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final tab in tabs)
            _NavButton(
              route: tab.$1,
              icon: tab.$2,
              active: tab.$1 == AppRoute.home,
            ),
        ],
      ),
    ).animate().slideY(begin: 0.4, duration: 520.ms).fadeIn();
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.route,
    required this.icon,
    required this.active,
  });

  final AppRoute route;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: route.label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x4D4C5FEF),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(active ? 13 : 12),
          child: Icon(
            icon,
            color: active ? Colors.white : AppColors.inkSub,
            size: active ? 23 : 22,
          ),
        ),
      ),
    );
  }
}
