import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/artwork.dart';
import '../../domain/models/feed_page.dart';
import '../../domain/models/novel.dart';
import '../../domain/models/pixiv_creator.dart';
import '../../domain/models/pixiv_tag.dart';
import '../../domain/models/search_user_result.dart';
import '../../domain/models/trend_tag.dart';
import '../services/pixiv_api_service.dart';
import 'pixiv_domain_mappers.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(apiService: ref.watch(pixivApiServiceProvider));
});

class SearchRepository {
  SearchRepository({required PixivApiService apiService})
    : _apiService = apiService;

  final PixivApiService _apiService;

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
    return mapPage(
      await _apiService.searchIllusts(
        word: word,
        sort: sort,
        searchTarget: searchTarget,
        startDate: startDate,
        endDate: endDate,
        bookmarkNumMin: bookmarkNumMin,
        bookmarkNumMax: bookmarkNumMax,
        searchAiType: searchAiType,
      ),
      mapIllust,
    );
  }

  Future<FeedPage<Novel>> novels({
    required String word,
    String sort = 'date_desc',
    String searchTarget = 'partial_match_for_tags',
    String? startDate,
    String? endDate,
    int? bookmarkNum,
  }) async {
    return mapPage(
      await _apiService.searchNovels(
        word: word,
        sort: sort,
        searchTarget: searchTarget,
        startDate: startDate,
        endDate: endDate,
        bookmarkNum: bookmarkNum,
      ),
      mapNovel,
    );
  }

  Future<FeedPage<PixivCreator>> users(String word) async {
    final page = await _apiService.searchUsers(word);
    return FeedPage(
      items: page.items.map((preview) => mapCreator(preview.user)).toList(),
      nextUrl: page.nextUrl,
    );
  }

  Future<FeedPage<SearchUserResult>> userResults(String word) async {
    final page = await _apiService.searchUsers(word);
    return FeedPage(
      items: page.items
          .map(
            (preview) => SearchUserResult(
              creator: mapCreator(preview.user),
              previewArtworks: preview.illusts.map(mapIllust).toList(),
            ),
          )
          .toList(),
      nextUrl: page.nextUrl,
    );
  }

  Future<FeedPage<Artwork>> nextIllusts(String nextUrl) async {
    return mapPage(await _apiService.getNextIllustPage(nextUrl), mapIllust);
  }

  Future<FeedPage<Novel>> nextNovels(String nextUrl) async {
    return mapPage(await _apiService.getNextNovelPage(nextUrl), mapNovel);
  }

  Future<FeedPage<SearchUserResult>> nextUsers(String nextUrl) async {
    final page = await _apiService.getNextUserPreviewPage(nextUrl);
    return FeedPage(
      items: page.items
          .map(
            (preview) => SearchUserResult(
              creator: mapCreator(preview.user),
              previewArtworks: preview.illusts.map(mapIllust).toList(),
            ),
          )
          .toList(),
      nextUrl: page.nextUrl,
    );
  }

  Future<List<PixivTag>> autocompleteTags(String word) async {
    final tags = await _apiService.autocompleteTags(word);
    return tags.map(mapTag).toList();
  }

  Future<List<TrendTag>> trendingIllustTags() async {
    final tags = await _apiService.getTrendingIllustTags();
    return tags.map(mapTrendTag).toList();
  }

  Future<FeedPage<Artwork>> popularIllustPreview({
    required String word,
    String searchTarget = 'partial_match_for_tags',
  }) async {
    return mapPage(
      await _apiService.getPopularIllustPreview(
        word: word,
        searchTarget: searchTarget,
      ),
      mapIllust,
    );
  }
}
