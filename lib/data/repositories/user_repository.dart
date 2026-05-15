import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/artwork.dart';
import '../../domain/models/bookmark_detail.dart';
import '../../domain/models/feed_page.dart';
import '../../domain/models/novel.dart';
import '../../domain/models/pixiv_creator.dart';
import '../services/pixiv_api_service.dart';
import 'pixiv_domain_mappers.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(apiService: ref.watch(pixivApiServiceProvider));
});

class UserRepository {
  UserRepository({required PixivApiService apiService})
    : _apiService = apiService;

  final PixivApiService _apiService;

  Future<PixivCreator?> detail(String userId) async {
    final detail = await _apiService.getUserDetail(userId);
    return detail == null ? null : mapCreatorDetail(detail);
  }

  Future<FeedPage<PixivCreator>> recommended() async {
    final page = await _apiService.getRecommendedUsers();
    return FeedPage(
      items: page.items.map((preview) => mapCreator(preview.user)).toList(),
      nextUrl: page.nextUrl,
    );
  }

  Future<FeedPage<Artwork>> illusts({
    required String userId,
    String type = 'illust',
    int? offset,
  }) async {
    return mapPage(
      await _apiService.getUserIllusts(
        userId: userId,
        type: type,
        offset: offset,
      ),
      mapIllust,
    );
  }

  Future<FeedPage<Novel>> novels(String userId) async {
    return mapPage(await _apiService.getUserNovels(userId), mapNovel);
  }

  Future<FeedPage<Artwork>> illustBookmarks({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
    String? tag,
    int? offset,
  }) async {
    return mapPage(
      await _apiService.getUserIllustBookmarks(
        userId: userId,
        restrict: restrict,
        tag: tag,
        offset: offset,
      ),
      mapIllust,
    );
  }

  Future<FeedPage<Novel>> novelBookmarks({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
  }) async {
    return mapPage(
      await _apiService.getUserNovelBookmarks(
        userId: userId,
        restrict: restrict,
      ),
      mapNovel,
    );
  }

  Future<FeedPage<BookmarkTag>> illustBookmarkTags({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
  }) async {
    return mapPage(
      await _apiService.getUserIllustBookmarkTags(
        userId: userId,
        restrict: restrict,
      ),
      mapBookmarkTag,
    );
  }

  Future<FeedPage<PixivCreator>> following({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
  }) async {
    final page = await _apiService.getUserFollowing(
      userId: userId,
      restrict: restrict,
    );
    return FeedPage(
      items: page.items.map((preview) => mapCreator(preview.user)).toList(),
      nextUrl: page.nextUrl,
    );
  }

  Future<FeedPage<PixivCreator>> followers({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
  }) async {
    final page = await _apiService.getUserFollowers(
      userId: userId,
      restrict: restrict,
    );
    return FeedPage(
      items: page.items.map((preview) => mapCreator(preview.user)).toList(),
      nextUrl: page.nextUrl,
    );
  }

  Future<bool> follow({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
  }) {
    return _apiService.addUserFollow(userId: userId, restrict: restrict);
  }

  Future<bool> unfollow(String userId) {
    return _apiService.deleteUserFollow(userId);
  }

  Future<bool> showAi() {
    return _apiService.getShowAiSetting();
  }

  Future<void> setShowAi(bool showAi) {
    return _apiService.editShowAiSetting(showAi);
  }

  Future<bool> restrictedMode() {
    return _apiService.getRestrictedModeSetting();
  }

  Future<void> setRestrictedMode(bool enabled) {
    return _apiService.editRestrictedModeSetting(enabled);
  }
}
