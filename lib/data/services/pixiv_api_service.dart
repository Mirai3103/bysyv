import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/network/dio_provider.dart';
import '../models/pixiv_common_models.dart';
import '../repositories/auth_session_store.dart';
import '../models/pixiv_recommend_response.dart';
import 'pixiv_api_interceptor.dart';
import 'pixiv_auth_service.dart';

final pixivApiServiceProvider = Provider<PixivApiService>((ref) {
  final dio = ref.watch(dioProvider);
  dio.interceptors.add(
    PixivApiInterceptor(
      dio: dio,
      sessionStore: ref.watch(authSessionStoreProvider),
      authService: ref.watch(pixivAuthServiceProvider),
    ),
  );

  return PixivApiService(dio: dio);
});

class PixivApiService {
  PixivApiService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const filterIos = 'for_ios';
  static const filterAndroid = 'for_android';
  static const publicRestrict = 'public';
  static const privateRestrict = 'private';
  static const allRestrict = 'all';

  Future<PixivRecommendResponse> getRecommendedIllusts() async {
    final page = await _getIllustPage(
      '/v1/illust/recommended',
      queryParameters: const {
        'filter': filterIos,
        'include_ranking_label': 'true',
      },
    );

    return PixivRecommendResponse(illusts: page.items, nextUrl: page.nextUrl);
  }

  Future<PixivPage<PixivIllust>> getRecommendedManga() {
    return _getIllustPage(
      '/v1/manga/recommended',
      queryParameters: const {
        'filter': filterIos,
        'include_ranking_label': 'true',
      },
    );
  }

  Future<PixivPage<PixivIllust>> getIllustRanking({
    required String mode,
    String? date,
  }) {
    return _getIllustPage(
      '/v1/illust/ranking',
      queryParameters: _withoutNulls({
        'filter': filterAndroid,
        'mode': mode,
        'date': date,
      }),
    );
  }

  Future<List<PixivIllust>> getWalkthroughIllusts() async {
    final page = await _getIllustPage('/v1/walkthrough/illusts');
    return page.items;
  }

  Future<PixivIllust?> getIllustDetail(String illustId) async {
    final data = await _getJson(
      '/v1/illust/detail',
      queryParameters: {'filter': filterAndroid, 'illust_id': illustId},
    );
    final illust = data['illust'];
    return illust is JsonMap ? PixivIllust.fromJson(illust) : null;
  }

  Future<PixivPage<PixivIllust>> getRelatedIllusts(String illustId) {
    return _getIllustPage(
      '/v2/illust/related',
      queryParameters: {'filter': filterAndroid, 'illust_id': illustId},
    );
  }

  Future<PixivUgoiraMetadata?> getUgoiraMetadata(String illustId) async {
    final data = await _getJson(
      '/v1/ugoira/metadata',
      queryParameters: {'illust_id': illustId},
    );
    final metadata = data['ugoira_metadata'];
    return metadata is JsonMap ? PixivUgoiraMetadata.fromJson(metadata) : null;
  }

  Future<bool> addIllustBookmark({
    required String illustId,
    String restrict = publicRestrict,
    List<String> tags = const [],
  }) async {
    final data = await _postForm('/v2/illust/bookmark/add', {
      'illust_id': illustId,
      'restrict': restrict,
      if (tags.isNotEmpty) 'tags[]': tags.join(' '),
    });
    return data['is_bookmarked'] as bool? ?? true;
  }

  Future<bool> deleteIllustBookmark(String illustId) async {
    final data = await _postForm('/v1/illust/bookmark/delete', {
      'illust_id': illustId,
    });
    return data['is_bookmarked'] as bool? ?? false;
  }

  Future<bool> deleteIllustBookmarkByGet(String illustId) async {
    final data = await _getJson(
      '/v1/illust/bookmark/delete',
      queryParameters: {'illust_id': illustId},
    );
    return data['is_bookmarked'] as bool? ?? false;
  }

  Future<PixivBookmarkDetail?> getIllustBookmarkDetail(String illustId) async {
    final data = await _getJson(
      '/v2/illust/bookmark/detail',
      queryParameters: {'illust_id': illustId},
    );
    final detail = data['bookmark_detail'];
    return detail is JsonMap ? PixivBookmarkDetail.fromJson(detail) : null;
  }

  Future<PixivPage<PixivIllust>> getFollowIllusts({
    String restrict = publicRestrict,
  }) {
    return _getIllustPage(
      '/v2/illust/follow',
      queryParameters: {'restrict': restrict},
    );
  }

  Future<JsonMap> getIllustSeries(String seriesId) {
    return _getJson(
      '/v1/illust/series',
      queryParameters: {'illust_series_id': seriesId, 'filter': filterIos},
    );
  }

  Future<List<PixivSeries>> getIllustSeriesForIllust(String illustId) async {
    final data = await _getJson(
      '/v1/illust-series/illust',
      queryParameters: {'illust_id': illustId},
    );
    final series = data['illust_series'];
    return series is List
        ? series.whereType<JsonMap>().map(PixivSeries.fromJson).toList()
        : const [];
  }

  Future<PixivPage<PixivSeries>> getMangaWatchlist() async {
    final data = await _getJson('/v1/watchlist/manga');
    return PixivPage(
      items: _parseSeriesList(data['series'] ?? data['illust_series']),
      nextUrl: data['next_url'] as String?,
    );
  }

  Future<void> addMangaWatchlist(String seriesId) {
    return _postForm('/v1/watchlist/manga/add', {'series_id': seriesId});
  }

  Future<void> deleteMangaWatchlist(String seriesId) {
    return _postForm('/v1/watchlist/manga/delete', {'series_id': seriesId});
  }

  Future<PixivPage<PixivComment>> getIllustComments(String illustId) {
    return _getCommentPage(
      '/v3/illust/comments',
      queryParameters: {'illust_id': illustId},
    );
  }

  Future<PixivPage<PixivComment>> getIllustCommentReplies(String commentId) {
    return _getCommentPage(
      '/v2/illust/comment/replies',
      queryParameters: {'comment_id': commentId},
    );
  }

  Future<PixivComment?> addIllustComment({
    required String illustId,
    required String comment,
    String? parentCommentId,
  }) async {
    final data = await _postForm(
      '/v1/illust/comment/add',
      _withoutNulls({
        'illust_id': illustId,
        'comment': comment,
        'parent_comment_id': parentCommentId,
      }),
    );
    final item = data['comment'];
    return item is JsonMap ? PixivComment.fromJson(item) : null;
  }

  Future<PixivPage<PixivNovel>> getRecommendedNovels() {
    return _getNovelPage(
      '/v1/novel/recommended',
      queryParameters: const {
        'include_privacy_policy': 'true',
        'filter': filterAndroid,
        'include_ranking_novels': 'true',
      },
    );
  }

  Future<PixivPage<PixivNovel>> getNovelRanking({
    required String mode,
    String? date,
  }) {
    return _getNovelPage(
      '/v1/novel/ranking',
      queryParameters: _withoutNulls({
        'filter': filterAndroid,
        'mode': mode,
        'date': date,
      }),
    );
  }

  Future<PixivNovel?> getNovelDetail(String novelId) async {
    final data = await _getJson(
      '/v2/novel/detail',
      queryParameters: {'novel_id': novelId},
    );
    final novel = data['novel'];
    return novel is JsonMap ? PixivNovel.fromJson(novel) : null;
  }

  Future<PixivNovelText?> getNovelText(String novelId) async {
    final data = await _getJson(
      '/v1/novel/text',
      queryParameters: {'novel_id': novelId},
    );
    final text = data['novel_text'];
    return text is JsonMap ? PixivNovelText.fromJson(text) : null;
  }

  Future<Response<dynamic>> getNovelWebView(String novelId) {
    return _dio.get<dynamic>(
      '/webview/v2/novel',
      queryParameters: {'id': novelId},
    );
  }

  Future<PixivPage<PixivNovel>> getFollowNovels({
    String restrict = publicRestrict,
  }) {
    return _getNovelPage(
      '/v1/novel/follow',
      queryParameters: {'restrict': restrict},
    );
  }

  Future<JsonMap> getNovelSeries(String seriesId) {
    return _getJson(
      '/v2/novel/series',
      queryParameters: {'series_id': seriesId},
    );
  }

  Future<PixivPage<PixivSeries>> getNovelWatchlist() async {
    final data = await _getJson('/v1/watchlist/novel');
    return PixivPage(
      items: _parseSeriesList(data['series'] ?? data['novel_series']),
      nextUrl: data['next_url'] as String?,
    );
  }

  Future<void> addNovelWatchlist(String seriesId) {
    return _postForm('/v1/watchlist/novel/add', {'series_id': seriesId});
  }

  Future<void> deleteNovelWatchlist(String seriesId) {
    return _postForm('/v1/watchlist/novel/delete', {'series_id': seriesId});
  }

  Future<void> addNovelBookmark({
    required String novelId,
    String restrict = publicRestrict,
  }) {
    return _postForm('/v2/novel/bookmark/add', {
      'novel_id': novelId,
      'restrict': restrict,
    });
  }

  Future<void> deleteNovelBookmark(String novelId) {
    return _postForm('/v1/novel/bookmark/delete', {'novel_id': novelId});
  }

  Future<PixivPage<PixivComment>> getNovelComments(String novelId) {
    return _getCommentPage(
      '/v3/novel/comments',
      queryParameters: {'novel_id': novelId},
    );
  }

  Future<PixivPage<PixivComment>> getNovelCommentReplies(String commentId) {
    return _getCommentPage(
      '/v2/novel/comment/replies',
      queryParameters: {'comment_id': commentId},
    );
  }

  Future<PixivComment?> addNovelComment({
    required String novelId,
    required String comment,
    String? parentCommentId,
  }) async {
    final data = await _postForm(
      '/v1/novel/comment/add',
      _withoutNulls({
        'novel_id': novelId,
        'comment': comment,
        'parent_comment_id': parentCommentId,
      }),
    );
    final item = data['comment'];
    return item is JsonMap ? PixivComment.fromJson(item) : null;
  }

  Future<PixivUserDetail?> getUserDetail(String userId) async {
    final data = await _getJson(
      '/v1/user/detail',
      queryParameters: {'filter': filterAndroid, 'user_id': userId},
    );
    return PixivUserDetail.fromJson(data);
  }

  Future<PixivPage<PixivUserPreview>> getRecommendedUsers() {
    return _getUserPreviewPage(
      '/v1/user/recommended',
      queryParameters: const {'filter': filterAndroid},
    );
  }

  Future<PixivPage<PixivIllust>> getUserIllusts({
    required String userId,
    String type = 'illust',
    int? offset,
  }) {
    return _getIllustPage(
      '/v1/user/illusts',
      queryParameters: _withoutNulls({
        'filter': filterAndroid,
        'user_id': userId,
        'type': type,
        'offset': offset,
      }),
    );
  }

  Future<PixivPage<PixivNovel>> getUserNovels(String userId) {
    return _getNovelPage(
      '/v1/user/novels',
      queryParameters: {'filter': filterAndroid, 'user_id': userId},
    );
  }

  Future<PixivPage<PixivIllust>> getUserIllustBookmarks({
    required String userId,
    String restrict = publicRestrict,
    String? tag,
    int? offset,
  }) {
    return _getIllustPage(
      '/v1/user/bookmarks/illust',
      queryParameters: _withoutNulls({
        'user_id': userId,
        'restrict': restrict,
        'tag': tag,
        'offset': offset,
      }),
    );
  }

  Future<PixivPage<PixivNovel>> getUserNovelBookmarks({
    required String userId,
    String restrict = publicRestrict,
  }) {
    return _getNovelPage(
      '/v1/user/bookmarks/novel',
      queryParameters: {'user_id': userId, 'restrict': restrict},
    );
  }

  Future<PixivPage<PixivBookmarkTag>> getUserIllustBookmarkTags({
    required String userId,
    String restrict = publicRestrict,
  }) async {
    final data = await _getJson(
      '/v1/user/bookmark-tags/illust',
      queryParameters: {'user_id': userId, 'restrict': restrict},
    );
    final tags = data['bookmark_tags'];
    return PixivPage(
      items: tags is List
          ? tags.whereType<JsonMap>().map(PixivBookmarkTag.fromJson).toList()
          : const [],
      nextUrl: data['next_url'] as String?,
    );
  }

  Future<PixivPage<PixivUserPreview>> getUserFollowing({
    required String userId,
    String restrict = publicRestrict,
  }) {
    return _getUserPreviewPage(
      '/v1/user/following',
      queryParameters: {
        'filter': filterAndroid,
        'user_id': userId,
        'restrict': restrict,
      },
    );
  }

  Future<PixivPage<PixivUserPreview>> getUserFollowers({
    required String userId,
    String restrict = publicRestrict,
  }) {
    return _getUserPreviewPage(
      '/v1/user/follower',
      queryParameters: {
        'filter': filterAndroid,
        'user_id': userId,
        'restrict': restrict,
      },
    );
  }

  Future<PixivFollowDetail?> getUserFollowDetail(String userId) async {
    final data = await _getJson(
      '/v1/user/follow/detail',
      queryParameters: {'user_id': userId},
    );
    final detail = data['follow_detail'];
    return detail is JsonMap ? PixivFollowDetail.fromJson(detail) : null;
  }

  Future<bool> addUserFollow({
    required String userId,
    String restrict = publicRestrict,
  }) async {
    final data = await _postForm('/v1/user/follow/add', {
      'user_id': userId,
      'restrict': restrict,
    });
    return data['is_followed'] as bool? ?? true;
  }

  Future<bool> deleteUserFollow(String userId) async {
    final data = await _postForm('/v1/user/follow/delete', {'user_id': userId});
    return data['is_followed'] as bool? ?? false;
  }

  Future<bool> getShowAiSetting() async {
    final data = await _getJson('/v1/user/ai-show-settings');
    return data['show_ai'] as bool? ?? true;
  }

  Future<void> editShowAiSetting(bool showAi) {
    return _postForm('/v1/user/ai-show-settings/edit', {'show_ai': showAi});
  }

  Future<bool> getRestrictedModeSetting() async {
    final data = await _getJson('/v1/user/restricted-mode-settings');
    return data['is_restricted_mode_enabled'] as bool? ?? false;
  }

  Future<void> editRestrictedModeSetting(bool enabled) {
    return _postForm('/v1/user/restricted-mode-settings', {
      'is_restricted_mode_enabled': enabled,
    });
  }

  Future<PixivPage<PixivIllust>> searchIllusts({
    required String word,
    String sort = 'date_desc',
    String searchTarget = 'partial_match_for_tags',
    String? startDate,
    String? endDate,
    int? bookmarkNumMin,
    int? bookmarkNumMax,
    int searchAiType = 0,
  }) {
    return _getIllustPage(
      '/v1/search/illust',
      queryParameters: _withoutNulls({
        'word': word,
        'filter': filterAndroid,
        'merge_plain_keyword_results': 'true',
        'sort': sort,
        'search_target': searchTarget,
        'start_date': startDate,
        'end_date': endDate,
        'bookmark_num_min': bookmarkNumMin,
        'bookmark_num_max': bookmarkNumMax,
        'search_ai_type': searchAiType,
      }),
    );
  }

  Future<PixivPage<PixivNovel>> searchNovels({
    required String word,
    String sort = 'date_desc',
    String searchTarget = 'partial_match_for_tags',
    String? startDate,
    String? endDate,
    int? bookmarkNum,
  }) {
    return _getNovelPage(
      '/v1/search/novel',
      queryParameters: _withoutNulls({
        'word': word,
        'filter': filterAndroid,
        'merge_plain_keyword_results': 'true',
        'sort': sort,
        'search_target': searchTarget,
        'start_date': startDate,
        'end_date': endDate,
        'bookmark_num': bookmarkNum,
      }),
    );
  }

  Future<PixivPage<PixivUserPreview>> searchUsers(String word) {
    return _getUserPreviewPage(
      '/v1/search/user',
      queryParameters: {'word': word, 'filter': filterAndroid},
    );
  }

  Future<List<PixivTag>> autocompleteTags(String word) async {
    final data = await _getJson(
      '/v2/search/autocomplete',
      queryParameters: {'word': word, 'merge_plain_keyword_results': 'true'},
    );
    final tags = data['tags'];
    return tags is List
        ? tags.whereType<JsonMap>().map(PixivTag.fromJson).toList()
        : const [];
  }

  Future<PixivPage<PixivIllust>> getPopularIllustPreview({
    required String word,
    String searchTarget = 'partial_match_for_tags',
  }) {
    return _getIllustPage(
      '/v1/search/popular-preview/illust',
      queryParameters: {
        'filter': filterAndroid,
        'include_translated_tag_results': 'true',
        'merge_plain_keyword_results': 'true',
        'word': word,
        'search_target': searchTarget,
      },
    );
  }

  Future<List<PixivTrendTag>> getTrendingIllustTags() async {
    final data = await _getJson(
      '/v1/trending-tags/illust',
      queryParameters: const {'filter': filterAndroid},
    );
    final tags = data['trend_tags'];
    return tags is List
        ? tags.whereType<JsonMap>().map(PixivTrendTag.fromJson).toList()
        : const [];
  }

  Future<List<PixivTrendTag>> getTrendingNovelTags() async {
    final data = await _getJson(
      '/v1/trending-tags/novel',
      queryParameters: const {'filter': filterAndroid},
    );
    final tags = data['trend_tags'];
    return tags is List
        ? tags.whereType<JsonMap>().map(PixivTrendTag.fromJson).toList()
        : const [];
  }

  Future<PixivPage<PixivSpotlightArticle>> getSpotlightArticles({
    String category = 'all',
  }) async {
    final data = await _getJson(
      '/v1/spotlight/articles',
      queryParameters: {'filter': filterAndroid, 'category': category},
    );
    final articles = data['spotlight_articles'];
    return PixivPage(
      items: articles is List
          ? articles
                .whereType<JsonMap>()
                .map(PixivSpotlightArticle.fromJson)
                .toList()
          : const [],
      nextUrl: data['next_url'] as String?,
    );
  }

  Future<JsonMap> getNext(String nextUrl) {
    return _getJson(nextUrl);
  }

  Future<PixivPage<PixivIllust>> getNextIllustPage(String nextUrl) {
    return _getIllustPage(nextUrl);
  }

  Future<PixivPage<PixivNovel>> getNextNovelPage(String nextUrl) {
    return _getNovelPage(nextUrl);
  }

  Future<PixivPage<PixivUserPreview>> getNextUserPreviewPage(String nextUrl) {
    return _getUserPreviewPage(nextUrl);
  }

  Future<PixivPage<PixivIllust>> _getIllustPage(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _getJson(path, queryParameters: queryParameters);
    final illusts = data['illusts'];
    return PixivPage(
      items: illusts is List
          ? illusts.whereType<JsonMap>().map(PixivIllust.fromJson).toList()
          : const [],
      nextUrl: data['next_url'] as String?,
    );
  }

  Future<PixivPage<PixivNovel>> _getNovelPage(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _getJson(path, queryParameters: queryParameters);
    final novels = data['novels'];
    return PixivPage(
      items: novels is List
          ? novels.whereType<JsonMap>().map(PixivNovel.fromJson).toList()
          : const [],
      nextUrl: data['next_url'] as String?,
    );
  }

  Future<PixivPage<PixivUserPreview>> _getUserPreviewPage(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _getJson(path, queryParameters: queryParameters);
    final previews = data['user_previews'];
    return PixivPage(
      items: previews is List
          ? previews
                .whereType<JsonMap>()
                .map(PixivUserPreview.fromJson)
                .toList()
          : const [],
      nextUrl: data['next_url'] as String?,
    );
  }

  Future<PixivPage<PixivComment>> _getCommentPage(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _getJson(path, queryParameters: queryParameters);
    final comments = data['comments'];
    return PixivPage(
      items: comments is List
          ? comments.whereType<JsonMap>().map(PixivComment.fromJson).toList()
          : const [],
      nextUrl: data['next_url'] as String?,
    );
  }

  Future<JsonMap> _getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<JsonMap>(
      path,
      queryParameters: queryParameters,
    );
    return response.data ?? const {};
  }

  Future<JsonMap> _postForm(String path, Map<String, dynamic> data) async {
    final response = await _dio.post<JsonMap>(
      path,
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return response.data ?? const {};
  }

  List<PixivSeries> _parseSeriesList(Object? value) {
    return value is List
        ? value.whereType<JsonMap>().map(PixivSeries.fromJson).toList()
        : const [];
  }

  Map<String, dynamic> _withoutNulls(Map<String, dynamic> input) {
    return Map.fromEntries(input.entries.where((entry) => entry.value != null));
  }
}
