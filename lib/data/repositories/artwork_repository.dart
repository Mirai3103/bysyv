import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/artwork.dart';
import '../../domain/models/bookmark_detail.dart';
import '../../domain/models/feed_page.dart';
import '../../domain/models/pixiv_comment.dart';
import '../models/pixiv_common_models.dart' hide PixivComment;
import '../services/pixiv_api_service.dart';
import 'pixiv_domain_mappers.dart';

final artworkRepositoryProvider = Provider<ArtworkRepository>((ref) {
  return ArtworkRepository(apiService: ref.watch(pixivApiServiceProvider));
});

class ArtworkRepository {
  ArtworkRepository({required PixivApiService apiService})
    : _apiService = apiService;

  final PixivApiService _apiService;

  Future<FeedPage<Artwork>> recommendedIllusts() async {
    final response = await _apiService.getRecommendedIllusts();
    return FeedPage(
      items: response.illusts.map(mapIllust).toList(),
      nextUrl: response.nextUrl,
    );
  }

  Future<FeedPage<Artwork>> recommendedManga() async {
    return mapPage(await _apiService.getRecommendedManga(), mapIllust);
  }

  Future<FeedPage<Artwork>> ranking({
    required String mode,
    String? date,
  }) async {
    return mapPage(
      await _apiService.getIllustRanking(mode: mode, date: date),
      mapIllust,
    );
  }

  Future<List<Artwork>> walkthrough() async {
    final illusts = await _apiService.getWalkthroughIllusts();
    return illusts.map(mapIllust).toList();
  }

  Future<Artwork?> detail(String illustId) async {
    final illust = await _apiService.getIllustDetail(illustId);
    return illust == null ? null : mapIllust(illust);
  }

  Future<FeedPage<Artwork>> related(String illustId) async {
    return mapPage(await _apiService.getRelatedIllusts(illustId), mapIllust);
  }

  Future<PixivUgoiraMetadata?> ugoiraMetadata(String illustId) {
    return _apiService.getUgoiraMetadata(illustId);
  }

  Future<bool> addBookmark({
    required String illustId,
    String restrict = PixivApiService.publicRestrict,
    List<String> tags = const [],
  }) {
    return _apiService.addIllustBookmark(
      illustId: illustId,
      restrict: restrict,
      tags: tags,
    );
  }

  Future<bool> deleteBookmark(String illustId) {
    return _apiService.deleteIllustBookmark(illustId);
  }

  Future<BookmarkDetail?> bookmarkDetail(String illustId) async {
    final detail = await _apiService.getIllustBookmarkDetail(illustId);
    return detail == null ? null : mapBookmarkDetail(detail);
  }

  Future<FeedPage<Artwork>> followFeed({
    String restrict = PixivApiService.publicRestrict,
  }) async {
    return mapPage(
      await _apiService.getFollowIllusts(restrict: restrict),
      mapIllust,
    );
  }

  Future<FeedPage<PixivComment>> comments(String illustId) async {
    return mapPage(await _apiService.getIllustComments(illustId), mapComment);
  }

  Future<FeedPage<PixivComment>> commentReplies(String commentId) async {
    return mapPage(
      await _apiService.getIllustCommentReplies(commentId),
      mapComment,
    );
  }

  Future<PixivComment?> addComment({
    required String illustId,
    required String comment,
    String? parentCommentId,
  }) async {
    final created = await _apiService.addIllustComment(
      illustId: illustId,
      comment: comment,
      parentCommentId: parentCommentId,
    );
    return created == null ? null : mapComment(created);
  }
}
