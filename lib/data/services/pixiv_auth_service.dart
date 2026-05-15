import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/auth_session.dart';

final pixivAuthServiceProvider = Provider<PixivAuthService>((ref) {
  return PixivAuthService();
});

enum PixivWebAuthMode { login, register }

class PixivAuthRequest {
  const PixivAuthRequest({required this.url, required this.codeVerifier});

  final Uri url;
  final String codeVerifier;
}

class PixivAuthException implements Exception {
  PixivAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PixivAuthService {
  PixivAuthService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _oauthBaseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
            ),
          );

  static const _oauthBaseUrl = 'https://oauth.secure.pixiv.net';
  static const _webBaseUrl = 'https://app-api.pixiv.net';
  static const _clientId = 'MOBrBDS8blbauoSck0ZfDbtuzpyT';
  static const _clientSecret = 'lsACyCD94FhDUtGTXi3QzcFE2uU1hqtDaKeqrdwj';
  static const _redirectUri =
      'https://app-api.pixiv.net/web/v1/users/auth/pixiv/callback';
  static const _hashSalt =
      '28c1fdd170a5204386cb1313c7077b34f83e4aaf4aa829ce78c231e05b0bae2c';
  static const _verifierChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  final Dio _dio;
  final _random = Random.secure();

  PixivAuthRequest createWebAuthRequest(PixivWebAuthMode mode) {
    final verifier = _createCodeVerifier();
    final challenge = _createCodeChallenge(verifier);
    final path = switch (mode) {
      PixivWebAuthMode.login => '/web/v1/login',
      PixivWebAuthMode.register => '/web/v1/provisional-accounts/create',
    };

    return PixivAuthRequest(
      codeVerifier: verifier,
      url: Uri.parse('$_webBaseUrl$path').replace(
        queryParameters: {
          'code_challenge': challenge,
          'code_challenge_method': 'S256',
          'client': 'pixiv-android',
        },
      ),
    );
  }

  Future<AuthSession> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
  }) async {
    return _postToken({
      'grant_type': 'authorization_code',
      'client_id': _clientId,
      'client_secret': _clientSecret,
      'code': code,
      'code_verifier': codeVerifier,
      'redirect_uri': _redirectUri,
      'include_policy': 'true',
    });
  }

  Future<AuthSession> loginWithPassword({
    required String username,
    required String password,
    String deviceToken = 'pixiv',
  }) async {
    return _postToken({
      'grant_type': 'password',
      'client_id': _clientId,
      'client_secret': _clientSecret,
      'username': username,
      'password': password,
      'Device_token': deviceToken,
      'get_secure_url': 'true',
      'include_policy': 'true',
    });
  }

  Future<AuthSession> refreshToken(String refreshToken) async {
    return _postToken({
      'grant_type': 'refresh_token',
      'client_id': _clientId,
      'client_secret': _clientSecret,
      'refresh_token': refreshToken,
      'include_policy': 'true',
    });
  }

  Future<AuthSession> _postToken(Map<String, String> data) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/token',
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: _clientHeaders('oauth.secure.pixiv.net'),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw PixivAuthException('Pixiv returned an empty auth response.');
      }
      return AuthSession.fromPixivResponse(body);
    } on DioException catch (error) {
      throw PixivAuthException(_oauthErrorMessage(error));
    }
  }

  String _oauthErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'] as Map<String, dynamic>?;
      final system = errors?['system'] as Map<String, dynamic>?;
      final message = system?['message'] as String?;
      if (message != null && message.isNotEmpty) return message;

      final oauthError = data['error'] as Map<String, dynamic>?;
      final oauthMessage = oauthError?['message'] as String?;
      if (oauthMessage != null && oauthMessage.isNotEmpty) {
        return oauthMessage;
      }
    }
    return error.message ?? 'Pixiv authentication failed.';
  }

  String _createCodeVerifier() {
    return List.generate(
      128,
      (_) => _verifierChars[_random.nextInt(_verifierChars.length)],
    ).join();
  }

  String _createCodeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  Map<String, String> _clientHeaders(String host) {
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
      'Host': host,
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
