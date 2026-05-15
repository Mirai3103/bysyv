import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../ui/core/widgets/app_tab_shell.dart';
import '../data/services/pixiv_auth_service.dart';
import '../ui/features/auth/view_models/auth_controller.dart';
import '../ui/features/auth/views/auth_screen.dart';
import '../ui/features/auth/views/pixiv_auth_web_view_screen.dart';
import '../ui/features/home/views/home_screen.dart';
import '../ui/features/placeholders/views/placeholder_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoute.auth.path,
    refreshListenable: auth,
    redirect: (context, state) {
      if (!auth.isInitialized) return null;

      final path = state.uri.path;
      final isAuthRoute = path == AppRoute.auth.path || path == '/auth/web';

      if (auth.isAuthenticated && (path == '/' || isAuthRoute)) {
        return AppRoute.home.path;
      }

      if (!auth.isAuthenticated && !isAuthRoute) {
        return AppRoute.auth.path;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoute.auth.path),
      GoRoute(
        path: AppRoute.auth.path,
        name: AppRoute.auth.name,
        pageBuilder: (context, state) {
          return const NoTransitionPage(child: AuthScreen());
        },
      ),
      GoRoute(
        path: '/auth/web',
        name: 'authWeb',
        pageBuilder: (context, state) {
          final mode = state.extra is PixivWebAuthMode
              ? state.extra! as PixivWebAuthMode
              : PixivWebAuthMode.login;
          return NoTransitionPage(child: PixivAuthWebViewScreen(mode: mode));
        },
      ),
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
  auth('/auth', 'Auth'),
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
