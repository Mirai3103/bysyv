import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/feed_page.dart';
import '../../domain/models/spotlight_article.dart';
import '../../domain/models/trend_tag.dart';
import '../services/pixiv_api_service.dart';
import 'pixiv_domain_mappers.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(apiService: ref.watch(pixivApiServiceProvider));
});

class DiscoveryRepository {
  DiscoveryRepository({required PixivApiService apiService})
    : _apiService = apiService;

  final PixivApiService _apiService;

  Future<List<TrendTag>> trendingIllustTags() async {
    final tags = await _apiService.getTrendingIllustTags();
    return tags.map(mapTrendTag).toList();
  }

  Future<List<TrendTag>> trendingNovelTags() async {
    final tags = await _apiService.getTrendingNovelTags();
    return tags.map(mapTrendTag).toList();
  }

  Future<FeedPage<SpotlightArticle>> spotlightArticles({
    String category = 'all',
  }) async {
    final page = await _apiService.getSpotlightArticles(category: category);
    return mapPage(page, mapSpotlightArticle);
  }
}
