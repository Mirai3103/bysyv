import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../ui/core/widgets/app_tab_shell.dart';
import '../ui/features/home/views/home_screen.dart';
import '../ui/features/placeholders/views/placeholder_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.home.path,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoute.home.path),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppTabShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.home.path,
                name: AppRoute.home.name,
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: HomeScreen());
                },
              ),
            ],
          ),
          for (final route in AppRoute.placeholderRoutes)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: route.path,
                  name: route.name,
                  pageBuilder: (context, state) {
                    return NoTransitionPage(
                      child: PlaceholderScreen(title: route.label),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    ],
  );
});

enum AppRoute {
  home('/home', 'Home'),
  search('/search', 'Search'),
  news('/news', 'News'),
  notifications('/notifications', 'Notification'),
  profile('/profile', 'Profile');

  const AppRoute(this.path, this.label);

  final String path;
  final String label;

  static List<AppRoute> get tabRoutes => [
    home,
    search,
    news,
    notifications,
    profile,
  ];

  static List<AppRoute> get placeholderRoutes => [
    search,
    news,
    notifications,
    profile,
  ];
}
