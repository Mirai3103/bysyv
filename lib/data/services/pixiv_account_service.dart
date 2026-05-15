import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/pixiv_account_models.dart';
import '../repositories/auth_session_store.dart';

final pixivAccountServiceProvider = Provider<PixivAccountService>((ref) {
  return PixivAccountService(sessionStore: ref.watch(authSessionStoreProvider));
});

class PixivAccountException implements Exception {
  PixivAccountException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PixivAccountService {
  PixivAccountService({required AuthSessionStore sessionStore, Dio? dio})
    : _sessionStore = sessionStore,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
            ),
          );

  static const _baseUrl = 'https://accounts.pixiv.net';
  static const _guestToken = 'l-f9qZ0ZyqSwRyZs8-MymbtWBbSxmCu1pmbOlyisou8';
  static const _hashSalt =
      '28c1fdd170a5204386cb1313c7077b34f83e4aaf4aa829ce78c231e05b0bae2c';

  final AuthSessionStore _sessionStore;
  final Dio _dio;

  Future<PixivProvisionalAccount> createProvisionalAccount({
    required String userName,
  }) async {
    final response = await _post(
      '/api/provisional-accounts/create',
      data: {
        'user_name': userName,
        'ref': 'pixiv_android_app_provisional_account',
      },
      authorization: 'Bearer $_guestToken',
    );

    return PixivProvisionalAccount.fromJson(response.body);
  }

  Future<PixivAccountResponse> editAccount({
    required String currentPassword,
    String? newMailAddress,
    String? newUserAccount,
    String? newPassword,
  }) async {
    final session = await _sessionStore.load();
    if (session == null || session.accessToken.isEmpty) {
      throw PixivAccountException('Missing Pixiv session.');
    }

    return _post(
      '/api/account/edit',
      data: _withoutNulls({
        'current_password': currentPassword,
        'new_mail_address': newMailAddress,
        'new_user_account': newUserAccount,
        'new_password': newPassword,
      }),
      authorization: 'Bearer ${session.accessToken}',
    );
  }

  Future<PixivAccountResponse> _post(
    String path, {
    required Map<String, dynamic> data,
    required String authorization,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {..._clientHeaders(), 'Authorization': authorization},
      ),
    );

    final body = response.data;
    if (body == null) {
      throw PixivAccountException('Pixiv returned an empty account response.');
    }
    return PixivAccountResponse.fromJson(body);
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
      'Host': 'accounts.pixiv.net',
      'X-Client-Time': time,
      'X-Client-Hash': hash,
      'User-Agent': 'PixivAndroidApp/5.0.166 (Android 10.0; Pixel 5)',
      'App-OS': 'Android',
      'App-OS-Version': 'Android 10.0',
      'App-Version': '5.0.166',
      'Accept-Language': 'zh-CN',
    };
  }

  Map<String, dynamic> _withoutNulls(Map<String, dynamic> input) {
    return Map.fromEntries(input.entries.where((entry) => entry.value != null));
  }
}
