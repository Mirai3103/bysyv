import 'package:bysiv/app/app.dart';
import 'package:bysiv/core/theme/app_theme.dart';
import 'package:bysiv/data/repositories/discover_repository.dart';
import 'package:bysiv/data/repositories/artwork_repository.dart';
import 'package:bysiv/data/services/pixiv_api_service.dart';
import 'package:bysiv/domain/models/artwork.dart';
import 'package:bysiv/domain/models/artwork_detail.dart';
import 'package:bysiv/data/repositories/auth_session_store.dart';
import 'package:bysiv/data/repositories/user_repository.dart';
import 'package:bysiv/domain/models/auth_session.dart';
import 'package:bysiv/domain/models/pixiv_comment.dart';
import 'package:bysiv/domain/models/pixiv_creator.dart';
import 'package:bysiv/domain/models/pixiv_tag.dart';
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

  testWidgets('opens artwork detail from a home artwork card', (tester) async {
    await _pumpApp(tester, session: _session);
    await tester.pumpAndSettle();

    await _openFirstArtworkDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('bookmark button updates artwork detail state', (tester) async {
    await _pumpApp(tester, session: _session);
    await tester.pumpAndSettle();

    await _openFirstArtworkDetail(tester);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Save'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsOneWidget);
  });
}

Future<void> _openFirstArtworkDetail(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('artwork-card-spotlight')));
}

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoverRepositoryProvider.overrideWithValue(_FakeDiscoverRepository()),
        artworkRepositoryProvider.overrideWithValue(_FakeArtworkRepository()),
        userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
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
        artworkRepositoryProvider.overrideWithValue(_FakeArtworkRepository()),
        userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
      ],
      child: const BysivApp(),
    ),
  );
}

class _FakeDiscoverRepository extends DiscoverRepository {
  _FakeDiscoverRepository() : super(apiService: PixivApiService(dio: Dio()));

  @override
  Future<List<Artwork>> recommendedArtwork() async => Artwork.samples;

  @override
  Future<List<Artwork>> rankingArtwork() async => Artwork.samples;

  @override
  Future<List<Artwork>> originalArtwork() async => Artwork.samples;

  @override
  Future<List<Artwork>> followingArtwork() async => Artwork.samples;
}

class _FakeArtworkRepository extends ArtworkRepository {
  _FakeArtworkRepository() : super(apiService: PixivApiService(dio: Dio()));

  @override
  Future<ArtworkDetail?> detailFull(String illustId) async {
    final artwork = Artwork.samples.firstWhere(
      (item) => item.id == illustId,
      orElse: () => Artwork.samples.first,
    );
    return ArtworkDetail(
      artwork: artwork,
      creator: const PixivCreator(
        id: 'artist-1',
        name: 'mika',
        account: 'mika',
        avatarUrl: '',
      ),
      tags: const [
        PixivTag(name: 'original'),
        PixivTag(name: 'fantasy'),
      ],
      pages: const [
        ArtworkImagePage(
          imageUrl: 'https://example.com/page-1.jpg',
          width: 393,
          height: 520,
        ),
        ArtworkImagePage(
          imageUrl: 'https://example.com/page-2.jpg',
          width: 393,
          height: 680,
        ),
      ],
      related: Artwork.samples.skip(1).toList(),
      comments: const [
        PixivComment(
          id: 'comment-1',
          body: 'Beautiful colors',
          user: PixivCreator(id: 'user-1', name: 'Aki', account: 'aki'),
          date: '2026-05-15T00:00:00+09:00',
        ),
      ],
      caption: 'Commission work.',
      createDate: '2026-05-15T00:00:00+09:00',
      totalView: 128400,
      totalBookmarks: artwork.bookmarks,
      totalComments: 1,
    );
  }

  @override
  Future<bool> addBookmark({
    required String illustId,
    String restrict = PixivApiService.publicRestrict,
    List<String> tags = const [],
  }) async {
    return true;
  }

  @override
  Future<bool> deleteBookmark(String illustId) async {
    return false;
  }
}

class _FakeUserRepository extends UserRepository {
  _FakeUserRepository() : super(apiService: PixivApiService(dio: Dio()));

  @override
  Future<bool> follow({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
  }) async {
    return true;
  }

  @override
  Future<bool> unfollow(String userId) async {
    return false;
  }
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
