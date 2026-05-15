import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/feed_page.dart';
import '../../domain/models/novel.dart';
import '../../domain/models/pixiv_comment.dart';
import '../models/pixiv_common_models.dart' hide PixivComment;
import '../services/pixiv_api_service.dart';
import 'pixiv_domain_mappers.dart';

final novelRepositoryProvider = Provider<NovelRepository>((ref) {
  return NovelRepository(apiService: ref.watch(pixivApiServiceProvider));
});

class NovelRepository {
  NovelRepository({required PixivApiService apiService})
    : _apiService = apiService;

  final PixivApiService _apiService;

  Future<FeedPage<Novel>> recommended() async {
    return mapPage(await _apiService.getRecommendedNovels(), mapNovel);
  }

  Future<FeedPage<Novel>> ranking({required String mode, String? date}) async {
    return mapPage(
      await _apiService.getNovelRanking(mode: mode, date: date),
      mapNovel,
    );
  }

  Future<Novel?> detail(String novelId) async {
    final novel = await _apiService.getNovelDetail(novelId);
    return novel == null ? null : mapNovel(novel);
  }

  Future<PixivNovelText?> text(String novelId) {
    return _apiService.getNovelText(novelId);
  }

  Future<FeedPage<Novel>> followFeed({
    String restrict = PixivApiService.publicRestrict,
  }) async {
    return mapPage(
      await _apiService.getFollowNovels(restrict: restrict),
      mapNovel,
    );
  }

  Future<void> addBookmark({
    required String novelId,
    String restrict = PixivApiService.publicRestrict,
  }) {
    return _apiService.addNovelBookmark(novelId: novelId, restrict: restrict);
  }

  Future<void> deleteBookmark(String novelId) {
    return _apiService.deleteNovelBookmark(novelId);
  }

  Future<FeedPage<PixivComment>> comments(String novelId) async {
    return mapPage(await _apiService.getNovelComments(novelId), mapComment);
  }

  Future<FeedPage<PixivComment>> commentReplies(String commentId) async {
    return mapPage(
      await _apiService.getNovelCommentReplies(commentId),
      mapComment,
    );
  }

  Future<PixivComment?> addComment({
    required String novelId,
    required String comment,
    String? parentCommentId,
  }) async {
    final created = await _apiService.addNovelComment(
      novelId: novelId,
      comment: comment,
      parentCommentId: parentCommentId,
    );
    return created == null ? null : mapComment(created);
  }
}
