import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/network/dio_provider.dart';
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

  Future<PixivRecommendResponse> getRecommendedIllusts() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/illust/recommended',
      queryParameters: const {
        'filter': 'for_ios',
        'include_ranking_label': 'true',
      },
    );

    final data = response.data;
    if (data == null) {
      return const PixivRecommendResponse(illusts: []);
    }

    return PixivRecommendResponse.fromJson(data);
  }
}
