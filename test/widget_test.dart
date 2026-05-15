import 'package:bysiv/app/app.dart';
import 'package:bysiv/core/theme/app_theme.dart';
import 'package:bysiv/data/repositories/discover_repository.dart';
import 'package:bysiv/data/services/pixiv_api_service.dart';
import 'package:bysiv/domain/models/artwork.dart';
import 'package:bysiv/data/repositories/auth_session_store.dart';
import 'package:bysiv/domain/models/auth_session.dart';
import 'package:bysiv/ui/features/home/views/home_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('renders auth welcome as the entry screen', (tester) async {
    await _pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('pixiv'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Login with token'), findsOneWidget);
  });

  testWidgets('opens the Pixiv login webview route', (tester) async {
    await _pumpApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Pixiv Login'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Pixiv Login'), findsNothing);
    expect(find.text('pixiv'), findsOneWidget);
  });

  testWidgets('opens register webview and token auth sheet', (tester) async {
    await _pumpApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.text('Pixiv Register'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Login with token'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login with token'));
    await tester.pumpAndSettle();

    expect(find.text('Refresh token'), findsOneWidget);
    expect(find.text('Authenticate'), findsOneWidget);
  });

  testWidgets('stored session starts on home', (tester) async {
    await _pumpApp(tester, session: _session);
    await tester.pumpAndSettle();

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('pixiv'), findsNothing);
  });

  testWidgets('renders the initialized discover shell', (tester) async {
    await _pumpHome(tester);

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Search artists, tags...'), findsOneWidget);
    expect(find.text('Recommend'), findsOneWidget);
    expect(find.text('Ranking'), findsOneWidget);
  });

  testWidgets('updates the active home filter pill', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.text('Original'));
    await tester.pumpAndSettle();

    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
  });

  testWidgets('switches between shell tabs', (tester) async {
    await _pumpApp(tester, session: _session);
    await tester.pumpAndSettle();

    for (final tab in ['Search', 'News', 'Notification', 'Profile']) {
      await tester.tap(find.byTooltip(tab));
      await tester.pumpAndSettle();

      expect(find.text(tab), findsOneWidget);
    }

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Discover'), findsOneWidget);
  });
}

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoverRepositoryProvider.overrideWithValue(_FakeDiscoverRepository()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpApp(WidgetTester tester, {AuthSession? session}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionStoreProvider.overrideWithValue(
          _MemoryAuthSessionStore(session),
        ),
        discoverRepositoryProvider.overrideWithValue(_FakeDiscoverRepository()),
      ],
      child: const BysivApp(),
    ),
  );
}

class _FakeDiscoverRepository extends DiscoverRepository {
  _FakeDiscoverRepository() : super(apiService: PixivApiService(dio: Dio()));

  @override
  Future<List<Artwork>> recommendedArtwork() async => Artwork.samples;
}

const _session = AuthSession(
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  userId: '123',
  userName: 'Tester',
  account: 'tester',
);

class _MemoryAuthSessionStore extends AuthSessionStore {
  _MemoryAuthSessionStore(this._session)
    : super(storage: const FlutterSecureStorage());

  AuthSession? _session;

  @override
  Future<AuthSession?> load() async => _session;

  @override
  Future<void> save(AuthSession session) async {
    _session = session;
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}
