import 'package:bysiv/app/app.dart';
import 'package:bysiv/core/theme/app_theme.dart';
import 'package:bysiv/data/repositories/artwork_repository.dart';
import 'package:bysiv/data/repositories/auth_session_store.dart';
import 'package:bysiv/data/repositories/discover_repository.dart';
import 'package:bysiv/data/repositories/discovery_repository.dart';
import 'package:bysiv/data/repositories/novel_repository.dart';
import 'package:bysiv/data/repositories/search_recent_store.dart';
import 'package:bysiv/data/repositories/search_repository.dart';
import 'package:bysiv/data/repositories/user_repository.dart';
import 'package:bysiv/domain/models/auth_session.dart';
import 'package:bysiv/ui/features/home/views/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fakes.dart';

/// Pumps the full [BysivApp] router with all repositories overridden.
/// Pass [session] to simulate a logged-in user; omit it for the auth screen.
Future<void> pumpApp(
  WidgetTester tester, {
  AuthSession? session,
  SearchRecentStore? searchRecentStore,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionStoreProvider.overrideWithValue(
          FakeAuthSessionStore(session),
        ),
        discoverRepositoryProvider.overrideWithValue(FakeDiscoverRepository()),
        discoveryRepositoryProvider.overrideWithValue(FakeDiscoveryRepository()),
        artworkRepositoryProvider.overrideWithValue(FakeArtworkRepository()),
        novelRepositoryProvider.overrideWithValue(FakeNovelRepository()),
        userRepositoryProvider.overrideWithValue(FakeUserRepository()),
        searchRepositoryProvider.overrideWithValue(FakeSearchRepository()),
        searchRecentStoreProvider.overrideWithValue(
          searchRecentStore ?? FakeSearchRecentStore(),
        ),
      ],
      child: const BysivApp(),
    ),
  );
}

/// Pumps [HomeScreen] directly, bypassing the router.
Future<void> pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoverRepositoryProvider.overrideWithValue(FakeDiscoverRepository()),
        discoveryRepositoryProvider.overrideWithValue(FakeDiscoveryRepository()),
        artworkRepositoryProvider.overrideWithValue(FakeArtworkRepository()),
        novelRepositoryProvider.overrideWithValue(FakeNovelRepository()),
        userRepositoryProvider.overrideWithValue(FakeUserRepository()),
        searchRepositoryProvider.overrideWithValue(FakeSearchRepository()),
        searchRecentStoreProvider.overrideWithValue(FakeSearchRecentStore()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Scrolls down and taps the first artwork card with key `artwork-card-spotlight`.
Future<void> openFirstArtworkDetail(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('artwork-card-spotlight')));
}
