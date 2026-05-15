import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/auth_session.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authSessionStoreProvider = Provider<AuthSessionStore>((ref) {
  return AuthSessionStore(storage: ref.watch(secureStorageProvider));
});

class AuthSessionStore {
  AuthSessionStore({required FlutterSecureStorage storage})
    : _storage = storage;

  static const _sessionKey = 'pixiv_auth_session';

  final FlutterSecureStorage _storage;

  Future<AuthSession?> load() async {
    try {
      final raw = await _storage.read(key: _sessionKey);
      if (raw == null || raw.isEmpty) return null;

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final session = AuthSession.fromJson(json);
      if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
        return null;
      }
      return session;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AuthSession session) async {
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    await _storage.delete(key: _sessionKey);
  }
}
