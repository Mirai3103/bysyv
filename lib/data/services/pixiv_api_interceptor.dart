import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../repositories/auth_session_store.dart';
import 'pixiv_auth_service.dart';

class PixivApiInterceptor extends Interceptor {
  PixivApiInterceptor({
    required Dio dio,
    required AuthSessionStore sessionStore,
    required PixivAuthService authService,
  }) : _dio = dio,
       _sessionStore = sessionStore,
       _authService = authService;

  static const _hashSalt =
      '28c1fdd170a5204386cb1313c7077b34f83e4aaf4aa829ce78c231e05b0bae2c';
  static const _host = 'app-api.pixiv.net';
  static const _retryKey = 'pixiv_retry_after_refresh';

  final Dio _dio;
  final AuthSessionStore _sessionStore;
  final PixivAuthService _authService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers.addAll(_clientHeaders());

    if (_requiresAuthorization(options.path)) {
      final session = await _sessionStore.load();
      if (session == null || session.accessToken.isEmpty) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            error: 'Missing Pixiv session.',
          ),
        );
        return;
      }
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (!_canRefresh(err) || request.extra[_retryKey] == true) {
      handler.next(err);
      return;
    }

    final session = await _sessionStore.load();
    final refreshToken = session?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      handler.next(err);
      return;
    }

    try {
      final refreshed = await _authService.refreshToken(refreshToken);
      await _sessionStore.save(refreshed);

      final retryOptions = request.copyWith(
        headers: {
          ...request.headers,
          'Authorization': 'Bearer ${refreshed.accessToken}',
        },
        extra: {...request.extra, _retryKey: true},
      );
      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _requiresAuthorization(String path) {
    return !path.contains('v1/walkthrough/illusts');
  }

  bool _canRefresh(DioException err) {
    if (err.response?.statusCode != 400) return false;

    final data = err.response?.data;
    if (data is! Map<String, dynamic>) return false;

    final error = data['error'];
    if (error is! Map<String, dynamic>) return false;

    final message = error['message'];
    return message is String && message.contains('OAuth');
  }

  Map<String, String> _clientHeaders() {
    final now = DateTime.now().toUtc();
    final time =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}T'
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}+00:00';
    final hash = md5.convert(utf8.encode(time + _hashSalt)).toString();

    return {
      'Host': _host,
      'X-Client-Time': time,
      'X-Client-Hash': hash,
      'User-Agent': 'PixivAndroidApp/5.0.166 (Android 10.0; Pixel 5)',
      'App-OS': 'Android',
      'App-OS-Version': 'Android 10.0',
      'App-Version': '5.0.166',
      'Accept-Language': 'zh-CN',
    };
  }
}
