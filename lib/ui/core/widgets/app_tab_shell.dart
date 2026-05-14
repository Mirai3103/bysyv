import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import 'glass_panel.dart';

class AppTabShell extends StatelessWidget {
  const AppTabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 4,
            right: 4,
            bottom: 4,
            child: _AnimatedBottomNavigation(
              currentIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBottomNavigation extends StatelessWidget {
  const _AnimatedBottomNavigation({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _indicatorWidth = 58.0;
  static const _indicatorHeight = 44.0;
  static const _navHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      strong: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / _tabs.length;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: currentIndex.toDouble()),
            duration: 360.ms,
            curve: Curves.easeOutCubic,
            builder: (context, indicatorPosition, child) {
              return SizedBox(
                height: _navHeight,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: 360.ms,
                      curve: Curves.easeOutCubic,
                      left:
                          tabWidth * currentIndex +
                          (tabWidth - _indicatorWidth) / 2,
                      top: (_navHeight - _indicatorHeight) / 2,
                      width: _indicatorWidth,
                      height: _indicatorHeight,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var index = 0; index < _tabs.length; index++)
                          SizedBox(
                            width: tabWidth,
                            height: _navHeight,
                            child: _NavButton(
                              tab: _tabs[index],
                              index: index,
                              indicatorPosition: indicatorPosition,
                              onTap: onDestinationSelected,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    ).animate().slideY(begin: 0.4, duration: 520.ms).fadeIn();
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.tab,
    required this.index,
    required this.indicatorPosition,
    required this.onTap,
  });

  final _TabDestination tab;
  final int index;
  final double indicatorPosition;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final progress = (1 - (indicatorPosition - index).abs()).clamp(0.0, 1.0);
    final color = Color.lerp(AppColors.inkSub, Colors.white, progress)!;
    final scale = 1 + progress * 0.1;

    return Semantics(
      button: true,
      selected: progress > 0.98,
      label: tab.route.label,
      child: Tooltip(
        message: tab.route.label,
        child: InkResponse(
          onTap: () => onTap(index),
          radius: 28,
          customBorder: const CircleBorder(),
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Icon(tab.icon, color: color, size: 23),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabDestination {
  const _TabDestination({required this.route, required this.icon});

  final AppRoute route;
  final IconData icon;
}

const _tabs = [
  _TabDestination(route: AppRoute.home, icon: LucideIcons.house),
  _TabDestination(route: AppRoute.search, icon: LucideIcons.search),
  _TabDestination(route: AppRoute.news, icon: LucideIcons.newspaper),
  _TabDestination(route: AppRoute.notifications, icon: LucideIcons.bell),
  _TabDestination(route: AppRoute.profile, icon: LucideIcons.circleUser),
];
