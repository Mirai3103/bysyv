import 'package:bysiv/data/repositories/artwork_repository.dart';
import 'package:bysiv/data/repositories/auth_session_store.dart';
import 'package:bysiv/data/repositories/discover_repository.dart';
import 'package:bysiv/data/repositories/search_recent_store.dart';
import 'package:bysiv/data/repositories/search_repository.dart';
import 'package:bysiv/data/repositories/user_repository.dart';
import 'package:bysiv/data/services/pixiv_api_service.dart';
import 'package:bysiv/data/services/pixiv_auth_service.dart';
import 'package:bysiv/domain/models/artwork.dart';
import 'package:bysiv/domain/models/artwork_detail.dart';
import 'package:bysiv/domain/models/auth_session.dart';
import 'package:bysiv/domain/models/feed_page.dart';
import 'package:bysiv/domain/models/novel.dart';
import 'package:bysiv/domain/models/pixiv_comment.dart';
import 'package:bysiv/domain/models/pixiv_creator.dart';
import 'package:bysiv/domain/models/pixiv_tag.dart';
import 'package:bysiv/domain/models/search_user_result.dart';
import 'package:bysiv/domain/models/trend_tag.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ---------------------------------------------------------------------------
// Shared test session
// ---------------------------------------------------------------------------

const kTestSession = AuthSession(
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  userId: '123',
  userName: 'Tester',
  account: 'tester',
);

// ---------------------------------------------------------------------------
// In-memory auth session store
// ---------------------------------------------------------------------------

class FakeAuthSessionStore extends AuthSessionStore {
  FakeAuthSessionStore([this._session])
    : super(storage: const FlutterSecureStorage());

  AuthSession? _session;

  @override
  Future<AuthSession?> load() async => _session;

  @override
  Future<void> save(AuthSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}

// ---------------------------------------------------------------------------
// In-memory search recent store
// ---------------------------------------------------------------------------

class FakeSearchRecentStore extends SearchRecentStore {
  FakeSearchRecentStore([List<String> initial = const []])
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
  Future<void> clear() async => words = [];
}

// ---------------------------------------------------------------------------
// Fake discover repository
// ---------------------------------------------------------------------------

class FakeDiscoverRepository extends DiscoverRepository {
  FakeDiscoverRepository() : super(apiService: PixivApiService(dio: Dio()));

  @override
  Future<List<Artwork>> recommendedArtwork() async => Artwork.samples;

  @override
  Future<List<Artwork>> rankingArtwork() async => Artwork.samples;

  @override
  Future<List<Artwork>> originalArtwork() async => Artwork.samples;

  @override
  Future<List<Artwork>> followingArtwork() async => Artwork.samples;
}

// ---------------------------------------------------------------------------
// Fake artwork repository
// ---------------------------------------------------------------------------

class FakeArtworkRepository extends ArtworkRepository {
  FakeArtworkRepository() : super(apiService: PixivApiService(dio: Dio()));

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
      tags: const [PixivTag(name: 'original'), PixivTag(name: 'fantasy')],
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
  }) async => true;

  @override
  Future<bool> deleteBookmark(String illustId) async => false;
}

// ---------------------------------------------------------------------------
// Fake search repository
// ---------------------------------------------------------------------------

class FakeSearchRepository extends SearchRepository {
  FakeSearchRepository() : super(apiService: PixivApiService(dio: Dio()));

  @override
  Future<List<TrendTag>> trendingIllustTags() async => [
    TrendTag(tag: '初音ミク', artwork: Artwork.samples.first),
    TrendTag(tag: 'オリジナル', artwork: Artwork.samples[1]),
    TrendTag(tag: 'landscape', artwork: Artwork.samples[2]),
  ];

  @override
  Future<List<PixivTag>> autocompleteTags(String word) async => [
    PixivTag(name: word),
    PixivTag(name: '$word original', translatedName: 'Original'),
  ];

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
  }) async => const FeedPage(
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

  @override
  Future<FeedPage<Novel>> novels({
    required String word,
    String sort = 'date_desc',
    String searchTarget = 'partial_match_for_tags',
    String? startDate,
    String? endDate,
    int? bookmarkNum,
  }) async => const FeedPage(
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

  @override
  Future<FeedPage<SearchUserResult>> userResults(String word) async =>
      const FeedPage(
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

// ---------------------------------------------------------------------------
// Fake user repository
// ---------------------------------------------------------------------------

class FakeUserRepository extends UserRepository {
  FakeUserRepository() : super(apiService: PixivApiService(dio: Dio()));

  @override
  Future<bool> follow({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
  }) async => true;

  @override
  Future<bool> unfollow(String userId) async => false;
}

// ---------------------------------------------------------------------------
// Fake auth service (used in unit tests)
// ---------------------------------------------------------------------------

class FakeAuthService extends PixivAuthService {
  FakeAuthService({AuthSession? refreshed})
    : nextSession = refreshed ?? _unitSession,
      super(dio: Dio());

  AuthSession nextSession;
  bool throwOnRefresh = false;

  @override
  PixivAuthRequest createWebAuthRequest(PixivWebAuthMode mode) {
    final path = mode == PixivWebAuthMode.login
        ? '/web/v1/login'
        : '/web/v1/provisional-accounts/create';
    return PixivAuthRequest(
      url: Uri.parse('https://app-api.pixiv.net$path'),
      codeVerifier: 'verifier',
    );
  }

  @override
  Future<AuthSession> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
  }) async => nextSession;

  @override
  Future<AuthSession> refreshToken(String refreshToken) async {
    if (throwOnRefresh) throw PixivAuthException('refresh failed');
    return nextSession;
  }
}

const _unitSession = AuthSession(
  accessToken: 'access',
  refreshToken: 'refresh',
  userId: 'user-1',
  userName: 'Mika',
  account: 'mika',
);
