import 'package:bysiv/data/models/pixiv_common_models.dart' as api;
import 'package:bysiv/data/models/pixiv_recommend_response.dart';
import 'package:bysiv/data/repositories/artwork_repository.dart';
import 'package:bysiv/data/repositories/discover_repository.dart';
import 'package:bysiv/data/repositories/novel_repository.dart';
import 'package:bysiv/data/repositories/search_repository.dart';
import 'package:bysiv/data/repositories/user_repository.dart';
import 'package:bysiv/data/services/pixiv_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('repositories', () {
    test(
      'map API service responses across discovery, artwork, novels, search, and users',
      () async {
        final apiService = _RepositoryApiService();

        final discover = DiscoverRepository(apiService: apiService);
        expect((await discover.recommendedArtwork()).single.id, 'illust-1');
        expect((await discover.rankingArtwork()).single.title, 'Blue hour');
        expect((await discover.originalArtwork()).single.artist, 'Mika');
        expect((await discover.followingArtwork()).single.bookmarks, 300);
        expect(discover.apiService, same(apiService));

        final artwork = ArtworkRepository(apiService: apiService);
        expect((await artwork.recommendedIllusts()).nextUrl, 'next');
        expect((await artwork.recommendedManga()).items.single.id, 'illust-1');
        expect(
          (await artwork.ranking(mode: 'day')).items.single.title,
          'Blue hour',
        );
        expect((await artwork.walkthrough()).single.artist, 'Mika');
        expect((await artwork.detail('illust-1'))!.id, 'illust-1');
        expect((await artwork.detailFull('illust-1'))!.comments, hasLength(1));
        expect((await artwork.related('illust-1')).items, hasLength(1));
        expect(
          (await artwork.ugoiraMetadata('illust-1'))!.frames,
          hasLength(1),
        );
        expect(await artwork.addBookmark(illustId: 'illust-1'), isTrue);
        expect(await artwork.deleteBookmark('illust-1'), isFalse);
        expect(
          (await artwork.bookmarkDetail('illust-1'))!.tags.single.name,
          'favorite',
        );
        expect((await artwork.followFeed()).items, hasLength(1));
        expect((await artwork.comments('illust-1')).items.single.body, 'Hello');
        expect((await artwork.commentReplies('comment-1')).items, hasLength(1));
        expect(
          (await artwork.addComment(illustId: 'illust-1', comment: 'Nice'))!.id,
          'comment-1',
        );

        final novels = NovelRepository(apiService: apiService);
        expect((await novels.recommended()).items.single.title, 'Novel');
        expect((await novels.ranking(mode: 'day')).items, hasLength(1));
        expect((await novels.detail('novel-1'))!.id, 'novel-1');
        expect((await novels.text('novel-1'))!.text, 'text');
        expect((await novels.followFeed()).items, hasLength(1));
        await novels.addBookmark(novelId: 'novel-1');
        await novels.deleteBookmark('novel-1');
        expect((await novels.comments('novel-1')).items.single.body, 'Hello');
        expect((await novels.commentReplies('comment-1')).items, hasLength(1));
        expect(
          (await novels.addComment(novelId: 'novel-1', comment: 'Nice'))!.id,
          'comment-1',
        );

        final search = SearchRepository(apiService: apiService);
        expect(
          (await search.illusts(word: 'miku')).items.single.id,
          'illust-1',
        );
        expect((await search.novels(word: 'miku')).items.single.id, 'novel-1');
        expect((await search.users('miku')).items.single.name, 'Mika');
        expect(
          (await search.userResults('miku')).items.single.previewArtworks,
          hasLength(1),
        );
        expect((await search.nextIllusts('next')).items, hasLength(1));
        expect((await search.nextNovels('next')).items, hasLength(1));
        expect((await search.nextUsers('next')).items, hasLength(1));
        expect(
          (await search.autocompleteTags('miku')).single.name,
          'original',
        );
        expect((await search.trendingIllustTags()).single.tag, 'miku');
        expect(
          (await search.popularIllustPreview(word: 'miku')).items,
          hasLength(1),
        );

        final user = UserRepository(apiService: apiService);
        expect((await user.detail('user-1'))!.profile['webpage'], 'site');
        expect((await user.recommended()).items.single.account, 'mika');
        expect((await user.illusts(userId: 'user-1')).items, hasLength(1));
        expect((await user.novels('user-1')).items, hasLength(1));
        expect(
          (await user.illustBookmarks(userId: 'user-1')).items,
          hasLength(1),
        );
        expect(
          (await user.novelBookmarks(userId: 'user-1')).items,
          hasLength(1),
        );
        expect(
          (await user.illustBookmarkTags(userId: 'user-1')).items.single.count,
          4,
        );
        expect(
          (await user.following(userId: 'user-1')).items.single.name,
          'Mika',
        );
        expect(
          (await user.followers(userId: 'user-1')).items.single.name,
          'Mika',
        );
        expect(await user.follow(userId: 'user-1'), isTrue);
        expect(await user.unfollow('user-1'), isFalse);
        expect(await user.showAi(), isFalse);
        await user.setShowAi(true);
        expect(await user.restrictedMode(), isTrue);
        await user.setRestrictedMode(false);
      },
    );

    test('surfaces nullable detail results', () async {
      final artwork = ArtworkRepository(apiService: _NullDetailApiService());
      final novel = NovelRepository(apiService: _NullDetailApiService());
      final user = UserRepository(apiService: _NullDetailApiService());

      expect(await artwork.detail('missing'), isNull);
      expect(await artwork.detailFull('missing'), isNull);
      expect(await artwork.bookmarkDetail('missing'), isNull);
      expect(
        await artwork.addComment(illustId: 'missing', comment: 'x'),
        isNull,
      );
      expect(await novel.detail('missing'), isNull);
      expect(await novel.addComment(novelId: 'missing', comment: 'x'), isNull);
      expect(await user.detail('missing'), isNull);
    });
  });
}

// ---------------------------------------------------------------------------
// Shared JSON fixtures
// ---------------------------------------------------------------------------

Map<String, dynamic> _illustJson() => {
  'id': 'illust-1',
  'title': 'Blue hour',
  'type': 'illust',
  'user': _userJson(),
  'total_view': 1200,
  'total_bookmarks': 300,
  'image_urls': {'large': 'large.jpg'},
  'tags': [_tagJson()],
  'caption': '<p>Line<br>&amp; title</p>',
  'create_date': '2026-05-16T00:00:00+09:00',
  'page_count': 2,
  'width': 800,
  'height': 1200,
  'restrict': 0,
  'x_restrict': 1,
  'sanity_level': 4,
  'is_bookmarked': true,
  'visible': true,
  'is_muted': false,
  'illust_ai_type': 2,
  'total_comments': 3,
  'meta_single_page': {'original_image_url': 'single.jpg'},
  'meta_pages': [
    {'image_urls': {'original': 'page-original.jpg'}},
  ],
};

Map<String, dynamic> _novelJson() => {
  'id': 'novel-1',
  'title': 'Novel',
  'user': _userJson(),
  'image_urls': {'large': 'novel.jpg'},
  'tags': [{'tag': 'novel-tag'}],
  'caption': 'Caption',
  'create_date': '2026-05-16T00:00:00+09:00',
  'page_count': 10,
  'text_length': 12000,
  'total_bookmarks': 55,
  'total_view': 999,
  'total_comments': 2,
  'restrict': 0,
  'x_restrict': 0,
  'is_original': true,
  'is_bookmarked': true,
  'visible': true,
  'is_muted': false,
  'is_mypixiv_only': false,
  'is_x_restricted': false,
  'novel_ai_type': 1,
  'series': {'id': 'series-1', 'title': 'Series'},
};

Map<String, dynamic> _userJson() => {
  'id': 'user-1',
  'name': 'Mika',
  'account': 'mika',
  'profile_image_urls': {'medium': 'avatar.jpg'},
  'is_followed': true,
};

Map<String, dynamic> _tagJson() => {
  'name': 'original',
  'translated_name': 'Original',
  'added_by_uploaded_user': true,
};

Map<String, dynamic> _commentJson() => {
  'id': 'comment-1',
  'comment': 'Hello',
  'user': _userJson(),
  'date': '2026-05-16T00:00:00+09:00',
  'has_replies': true,
};

Map<String, dynamic> _bookmarkDetailJson() => {
  'is_bookmarked': true,
  'restrict': 'private',
  'tags': [{'name': 'favorite', 'count': 4, 'is_registered': true}],
};

Map<String, dynamic> _bookmarkTagJson() => {
  'name': 'favorite',
  'count': 4,
  'is_registered': true,
};

Map<String, dynamic> _userPreviewJson() => {
  'user': _userJson(),
  'illusts': [_illustJson()],
};

Map<String, dynamic> _userDetailJson() => {
  'user': _userJson(),
  'profile': {'webpage': 'site'},
  'profile_publicity': {'gender': 'public'},
  'workspace': {'chair': 'good'},
};

Map<String, dynamic> _ugoiraJson() => {
  'zip_urls': {'medium': 'ugoira.zip'},
  'frames': [{'file': '000001.jpg', 'delay': 80}],
};

Map<String, dynamic> _trendTagJson() => {
  'tag': 'miku',
  'translated_name': 'Miku',
  'illust': _illustJson(),
};

// ---------------------------------------------------------------------------
// Computed getters for typed API objects
// ---------------------------------------------------------------------------

api.PixivIllust get _apiIllust => api.PixivIllust.fromJson(_illustJson());
api.PixivNovel get _apiNovel => api.PixivNovel.fromJson(_novelJson());
api.PixivComment get _apiComment => api.PixivComment.fromJson(_commentJson());

api.PixivPage<api.PixivIllust> get _apiIllustPage =>
    api.PixivPage(items: [_apiIllust], nextUrl: 'next');
api.PixivPage<api.PixivNovel> get _apiNovelPage =>
    api.PixivPage(items: [_apiNovel], nextUrl: 'next');
api.PixivPage<api.PixivComment> get _apiCommentPage =>
    api.PixivPage(items: [_apiComment], nextUrl: 'next');
api.PixivPage<api.PixivUserPreview> get _apiUserPreviewPage =>
    api.PixivPage(
      items: [api.PixivUserPreview.fromJson(_userPreviewJson())],
      nextUrl: 'next',
    );

// ---------------------------------------------------------------------------
// Stub API service that returns canned data
// ---------------------------------------------------------------------------

class _RepositoryApiService extends PixivApiService {
  _RepositoryApiService() : super(dio: Dio());

  @override
  Future<PixivRecommendResponse> getRecommendedIllusts() async =>
      PixivRecommendResponse(illusts: [_apiIllust], nextUrl: 'next');

  @override
  Future<api.PixivPage<api.PixivIllust>> getRecommendedManga() async =>
      _apiIllustPage;

  @override
  Future<api.PixivPage<api.PixivIllust>> getIllustRanking({
    required String mode,
    String? date,
  }) async => _apiIllustPage;

  @override
  Future<List<api.PixivIllust>> getWalkthroughIllusts() async => [_apiIllust];

  @override
  Future<api.PixivIllust?> getIllustDetail(String illustId) async => _apiIllust;

  @override
  Future<api.PixivPage<api.PixivIllust>> getRelatedIllusts(
    String illustId,
  ) async => _apiIllustPage;

  @override
  Future<api.PixivUgoiraMetadata?> getUgoiraMetadata(String illustId) async =>
      api.PixivUgoiraMetadata.fromJson(_ugoiraJson());

  @override
  Future<bool> addIllustBookmark({
    required String illustId,
    String restrict = PixivApiService.publicRestrict,
    List<String> tags = const [],
  }) async => true;

  @override
  Future<bool> deleteIllustBookmark(String illustId) async => false;

  @override
  Future<api.PixivBookmarkDetail?> getIllustBookmarkDetail(
    String illustId,
  ) async => api.PixivBookmarkDetail.fromJson(_bookmarkDetailJson());

  @override
  Future<api.PixivPage<api.PixivIllust>> getFollowIllusts({
    String restrict = PixivApiService.publicRestrict,
  }) async => _apiIllustPage;

  @override
  Future<api.PixivPage<api.PixivComment>> getIllustComments(
    String illustId,
  ) async => _apiCommentPage;

  @override
  Future<api.PixivPage<api.PixivComment>> getIllustCommentReplies(
    String commentId,
  ) async => _apiCommentPage;

  @override
  Future<api.PixivComment?> addIllustComment({
    required String illustId,
    required String comment,
    String? parentCommentId,
  }) async => _apiComment;

  @override
  Future<api.PixivPage<api.PixivNovel>> getRecommendedNovels() async =>
      _apiNovelPage;

  @override
  Future<api.PixivPage<api.PixivNovel>> getNovelRanking({
    required String mode,
    String? date,
  }) async => _apiNovelPage;

  @override
  Future<api.PixivNovel?> getNovelDetail(String novelId) async => _apiNovel;

  @override
  Future<api.PixivNovelText?> getNovelText(String novelId) async =>
      const api.PixivNovelText(novelId: 'novel-1', text: 'text');

  @override
  Future<api.PixivPage<api.PixivNovel>> getFollowNovels({
    String restrict = PixivApiService.publicRestrict,
  }) async => _apiNovelPage;

  @override
  Future<void> addNovelBookmark({
    required String novelId,
    String restrict = PixivApiService.publicRestrict,
  }) async {}

  @override
  Future<void> deleteNovelBookmark(String novelId) async {}

  @override
  Future<api.PixivPage<api.PixivComment>> getNovelComments(
    String novelId,
  ) async => _apiCommentPage;

  @override
  Future<api.PixivPage<api.PixivComment>> getNovelCommentReplies(
    String commentId,
  ) async => _apiCommentPage;

  @override
  Future<api.PixivComment?> addNovelComment({
    required String novelId,
    required String comment,
    String? parentCommentId,
  }) async => _apiComment;

  @override
  Future<api.PixivUserDetail?> getUserDetail(String userId) async =>
      api.PixivUserDetail.fromJson(_userDetailJson());

  @override
  Future<api.PixivPage<api.PixivUserPreview>> getRecommendedUsers() async =>
      _apiUserPreviewPage;

  @override
  Future<api.PixivPage<api.PixivIllust>> getUserIllusts({
    required String userId,
    String type = 'illust',
    int? offset,
  }) async => _apiIllustPage;

  @override
  Future<api.PixivPage<api.PixivNovel>> getUserNovels(String userId) async =>
      _apiNovelPage;

  @override
  Future<api.PixivPage<api.PixivIllust>> getUserIllustBookmarks({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
    String? tag,
    int? offset,
  }) async => _apiIllustPage;

  @override
  Future<api.PixivPage<api.PixivNovel>> getUserNovelBookmarks({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
  }) async => _apiNovelPage;

  @override
  Future<api.PixivPage<api.PixivBookmarkTag>> getUserIllustBookmarkTags({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
  }) async => api.PixivPage(
    items: [api.PixivBookmarkTag.fromJson(_bookmarkTagJson())],
    nextUrl: 'next',
  );

  @override
  Future<api.PixivPage<api.PixivUserPreview>> getUserFollowing({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
  }) async => _apiUserPreviewPage;

  @override
  Future<api.PixivPage<api.PixivUserPreview>> getUserFollowers({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
  }) async => _apiUserPreviewPage;

  @override
  Future<bool> addUserFollow({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
  }) async => true;

  @override
  Future<bool> deleteUserFollow(String userId) async => false;

  @override
  Future<bool> getShowAiSetting() async => false;

  @override
  Future<void> editShowAiSetting(bool showAi) async {}

  @override
  Future<bool> getRestrictedModeSetting() async => true;

  @override
  Future<void> editRestrictedModeSetting(bool enabled) async {}

  @override
  Future<api.PixivPage<api.PixivIllust>> searchIllusts({
    required String word,
    String sort = 'date_desc',
    String searchTarget = 'partial_match_for_tags',
    String? startDate,
    String? endDate,
    int? bookmarkNumMin,
    int? bookmarkNumMax,
    int searchAiType = 0,
  }) async => _apiIllustPage;

  @override
  Future<api.PixivPage<api.PixivNovel>> searchNovels({
    required String word,
    String sort = 'date_desc',
    String searchTarget = 'partial_match_for_tags',
    String? startDate,
    String? endDate,
    int? bookmarkNum,
  }) async => _apiNovelPage;

  @override
  Future<api.PixivPage<api.PixivUserPreview>> searchUsers(String word) async =>
      _apiUserPreviewPage;

  @override
  Future<api.PixivPage<api.PixivIllust>> getNextIllustPage(
    String nextUrl,
  ) async => _apiIllustPage;

  @override
  Future<api.PixivPage<api.PixivNovel>> getNextNovelPage(
    String nextUrl,
  ) async => _apiNovelPage;

  @override
  Future<api.PixivPage<api.PixivUserPreview>> getNextUserPreviewPage(
    String nextUrl,
  ) async => _apiUserPreviewPage;

  @override
  Future<List<api.PixivTag>> autocompleteTags(String word) async =>
      [api.PixivTag.fromJson(_tagJson())];

  @override
  Future<List<api.PixivTrendTag>> getTrendingIllustTags() async =>
      [api.PixivTrendTag.fromJson(_trendTagJson())];

  @override
  Future<api.PixivPage<api.PixivIllust>> getPopularIllustPreview({
    required String word,
    String searchTarget = 'partial_match_for_tags',
  }) async => _apiIllustPage;
}

class _NullDetailApiService extends _RepositoryApiService {
  @override
  Future<api.PixivIllust?> getIllustDetail(String illustId) async => null;

  @override
  Future<api.PixivBookmarkDetail?> getIllustBookmarkDetail(
    String illustId,
  ) async => null;

  @override
  Future<api.PixivComment?> addIllustComment({
    required String illustId,
    required String comment,
    String? parentCommentId,
  }) async => null;

  @override
  Future<api.PixivNovel?> getNovelDetail(String novelId) async => null;

  @override
  Future<api.PixivComment?> addNovelComment({
    required String novelId,
    required String comment,
    String? parentCommentId,
  }) async => null;

  @override
  Future<api.PixivUserDetail?> getUserDetail(String userId) async => null;
}
