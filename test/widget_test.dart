import 'package:bysiv/app/app.dart';
import 'package:bysiv/core/theme/app_theme.dart';
import 'package:bysiv/data/repositories/discover_repository.dart';
import 'package:bysiv/data/repositories/artwork_repository.dart';
import 'package:bysiv/data/repositories/search_recent_store.dart';
import 'package:bysiv/data/repositories/search_repository.dart';
import 'package:bysiv/data/services/pixiv_api_service.dart';
import 'package:bysiv/domain/models/artwork.dart';
import 'package:bysiv/domain/models/artwork_detail.dart';
import 'package:bysiv/data/repositories/auth_session_store.dart';
import 'package:bysiv/data/repositories/user_repository.dart';
import 'package:bysiv/domain/models/auth_session.dart';
import 'package:bysiv/domain/models/feed_page.dart';
import 'package:bysiv/domain/models/novel.dart';
import 'package:bysiv/domain/models/pixiv_comment.dart';
import 'package:bysiv/domain/models/pixiv_creator.dart';
import 'package:bysiv/domain/models/pixiv_tag.dart';
import 'package:bysiv/domain/models/search_user_result.dart';
import 'package:bysiv/domain/models/trend_tag.dart';
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
    expect(find.text('Search artists, tags...'), findsNothing);
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

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Search tags, titles, users...'), findsOneWidget);
    expect(find.text('Trending tags'), findsOneWidget);

    for (final tab in ['News', 'Notification', 'Profile']) {
      await tester.tap(find.byTooltip(tab));
      await tester.pumpAndSettle();

      expect(find.text(tab), findsOneWidget);
    }

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Discover'), findsOneWidget);
  });

  testWidgets('search tab loads trending tags and autocomplete', (
    tester,
  ) async {
    await _pumpApp(tester, session: _session);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('初音ミク'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'miku');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('miku'), findsWidgets);
    expect(find.text('miku original'), findsOneWidget);
  });

  testWidgets('search tab stores five recent words locally', (tester) async {
    final recentStore = _MemorySearchRecentStore();

    await _pumpApp(tester, session: _session, searchRecentStore: recentStore);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    for (final word in [
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'three',
    ]) {
      await tester.enterText(find.byType(TextField), word);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 40));
    }

    expect(recentStore.words, ['three', 'six', 'five', 'four', 'two']);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('three'), findsWidgets);
    expect(find.text('one'), findsNothing);

    await tester.tap(find.text('Clear all'));
    await tester.pump();

    expect(recentStore.words, isEmpty);
    expect(find.text('No recent searches'), findsOneWidget);
  });

  testWidgets('search submit shows result tabs', (tester) async {
    await _pumpApp(tester, session: _session);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'miku');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Artwork'), findsOneWidget);
    expect(find.text('Novel'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('1 artworks loaded'), findsOneWidget);
  });

  testWidgets('search artwork result opens artwork detail', (tester) async {
    await _pumpApp(tester, session: _session);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'miku');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('search-artwork-search-1')));
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('search novel and user results open placeholders', (
    tester,
  ) async {
    await _pumpApp(tester, session: _session);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'miku');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Novel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('search-novel-novel-1')));
    await tester.pumpAndSettle();

    expect(find.text('Novel detail novel-1'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Users'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('search-user-user-1')));
    await tester.pumpAndSettle();

    expect(find.text('User profile user-1'), findsOneWidget);
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
        searchRepositoryProvider.overrideWithValue(_FakeSearchRepository()),
        searchRecentStoreProvider.overrideWithValue(_MemorySearchRecentStore()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpApp(
  WidgetTester tester, {
  AuthSession? session,
  SearchRecentStore? searchRecentStore,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionStoreProvider.overrideWithValue(
          _MemoryAuthSessionStore(session),
        ),
        discoverRepositoryProvider.overrideWithValue(_FakeDiscoverRepository()),
        artworkRepositoryProvider.overrideWithValue(_FakeArtworkRepository()),
        userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
        searchRepositoryProvider.overrideWithValue(_FakeSearchRepository()),
        searchRecentStoreProvider.overrideWithValue(
          searchRecentStore ?? _MemorySearchRecentStore(),
        ),
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

class _FakeSearchRepository extends SearchRepository {
  _FakeSearchRepository() : super(apiService: PixivApiService(dio: Dio()));

  @override
  Future<List<TrendTag>> trendingIllustTags() async {
    return [
      TrendTag(tag: '初音ミク', artwork: Artwork.samples.first),
      TrendTag(tag: 'オリジナル', artwork: Artwork.samples[1]),
      TrendTag(tag: 'landscape', artwork: Artwork.samples[2]),
    ];
  }

  @override
  Future<List<PixivTag>> autocompleteTags(String word) async {
    return [
      PixivTag(name: word),
      PixivTag(name: '$word original', translatedName: 'Original'),
    ];
  }

  @override
  Future<FeedPage<Artwork>> illusts({
    required String word,
    String sort = 'date_desc',
    String searchTarget = 'partial_match_for_tags',
    String? startDate,
    String? endDate,
    int? bookmarkNumMin,
    int? bookmarkNumMax,
    int searchAiType = 0,
  }) async {
    return const FeedPage(
      items: [
        Artwork(
          id: 'search-1',
          title: 'Search Artwork',
          artist: 'mika',
          bookmarks: 1200,
          gradient: [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
          pageCount: 2,
        ),
      ],
    );
  }

  @override
  Future<FeedPage<Novel>> novels({
    required String word,
    String sort = 'date_desc',
    String searchTarget = 'partial_match_for_tags',
    String? startDate,
    String? endDate,
    int? bookmarkNum,
  }) async {
    return const FeedPage(
      items: [
        Novel(
          id: 'novel-1',
          title: 'Search Novel',
          author: PixivCreator(id: 'author-1', name: 'Aki', account: 'aki'),
          bookmarks: 450,
          pageCount: 12,
          textLength: 24000,
        ),
      ],
    );
  }

  @override
  Future<FeedPage<SearchUserResult>> userResults(String word) async {
    return const FeedPage(
      items: [
        SearchUserResult(
          creator: PixivCreator(
            id: 'user-1',
            name: 'Search User',
            account: 'search_user',
          ),
          previewArtworks: [
            Artwork(
              id: 'preview-1',
              title: 'Preview',
              artist: 'Search User',
              bookmarks: 8,
              gradient: [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
            ),
          ],
        ),
      ],
    );
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

class _MemorySearchRecentStore extends SearchRecentStore {
  _MemorySearchRecentStore([List<String> initial = const []])
    : words = [...initial];

  List<String> words;

  @override
  Future<List<String>> load() async => [...words];

  @override
  Future<List<String>> saveWord(String word) async {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return load();
    words = [
      trimmed,
      for (final item in words)
        if (item != trimmed) item,
    ].take(SearchRecentStore.recentLimit).toList();
    return load();
  }

  @override
  Future<List<String>> remove(String word) async {
    words = words.where((item) => item != word).toList();
    return load();
  }

  @override
  Future<void> clear() async {
    words = [];
  }
}
