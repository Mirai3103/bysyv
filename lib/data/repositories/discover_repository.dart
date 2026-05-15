import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/artwork.dart';
import '../models/pixiv_recommend_response.dart';
import '../services/pixiv_api_service.dart';

final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  return DiscoverRepository(apiService: ref.watch(pixivApiServiceProvider));
});

class DiscoverRepository {
  DiscoverRepository({required PixivApiService apiService})
    : _apiService = apiService;

  final PixivApiService _apiService;

  PixivApiService get apiService => _apiService;

  Future<List<Artwork>> recommendedArtwork() async {
    final response = await _apiService.getRecommendedIllusts();
    return response.illusts.map(_mapIllust).toList();
  }

  Future<List<Artwork>> rankingArtwork() async {
    final response = await _apiService.getIllustRanking(
      mode: PixivApiService.rankingModeDay,
    );
    return response.items.map(_mapIllust).toList();
  }

  Future<List<Artwork>> originalArtwork() async {
    final response = await _apiService.getIllustRanking(
      mode: PixivApiService.rankingModeWeekOriginal,
    );
    return response.items.map(_mapIllust).toList();
  }

  Future<List<Artwork>> followingArtwork() async {
    final response = await _apiService.getFollowIllusts();
    return response.items.map(_mapIllust).toList();
  }

  Artwork _mapIllust(PixivIllust illust) {
    return Artwork(
      id: illust.id,
      title: illust.title,
      artist: illust.artistName,
      bookmarks: illust.totalBookmarks,
      imageUrl: illust.imageUrl,
      pageCount: illust.pageCount,
      isBookmarked: illust.isBookmarked,
      xRestrict: illust.xRestrict,
      gradient: const [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
      isSpotlight: false,
    );
  }
}
