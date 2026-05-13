import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/artwork.dart';
import '../services/pixiv_api_service.dart';

final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  return DiscoverRepository(apiService: ref.watch(pixivApiServiceProvider));
});

class DiscoverRepository {
  DiscoverRepository({required PixivApiService apiService})
    : _apiService = apiService;

  final PixivApiService _apiService;

  PixivApiService get apiService => _apiService;

  List<Artwork> featuredArtwork() {
    return Artwork.samples;
  }
}
