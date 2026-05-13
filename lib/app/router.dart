import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../ui/features/home/views/home_screen.dart';
import '../ui/features/placeholders/views/placeholder_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.home.path,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoute.home.path),
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.name,
        pageBuilder: (context, state) {
          return const NoTransitionPage(child: HomeScreen());
        },
      ),
      for (final route in AppRoute.placeholderRoutes)
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
  );
});

enum AppRoute {
  home('/home', 'Home'),
  search('/search', 'Search'),
  create('/create', 'Create'),
  bookmarks('/bookmarks', 'Bookmarks'),
  profile('/profile', 'Profile'),
  auth('/auth', 'Sign in');

  const AppRoute(this.path, this.label);

  final String path;
  final String label;

  static List<AppRoute> get placeholderRoutes => [
    search,
    create,
    bookmarks,
    profile,
    auth,
  ];
}
