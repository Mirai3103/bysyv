import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/network/dio_provider.dart';

final pixivApiServiceProvider = Provider<PixivApiService>((ref) {
  return PixivApiService(dio: ref.watch(dioProvider));
});

class PixivApiService {
  PixivApiService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Dio get client => _dio;
}
