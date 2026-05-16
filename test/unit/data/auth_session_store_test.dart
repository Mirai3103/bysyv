import 'package:bysiv/data/repositories/auth_session_store.dart';
import 'package:bysiv/domain/models/auth_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSessionStore', () {
    test('returns null when storage is empty', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final store = AuthSessionStore(storage: const FlutterSecureStorage());
      expect(await store.load(), isNull);
    });

    test('returns null when stored value is empty string', () async {
      FlutterSecureStorage.setMockInitialValues({'pixiv_auth_session': ''});
      final store = AuthSessionStore(storage: const FlutterSecureStorage());
      expect(await store.load(), isNull);
    });

    test('returns null when stored session has empty tokens', () async {
      FlutterSecureStorage.setMockInitialValues({
        'pixiv_auth_session':
            '{"access_token":"","refresh_token":"","user_id":"1","user_name":"x","account":"x"}',
      });
      final store = AuthSessionStore(storage: const FlutterSecureStorage());
      expect(await store.load(), isNull);
    });

    test('returns null when stored JSON is malformed', () async {
      FlutterSecureStorage.setMockInitialValues({
        'pixiv_auth_session': 'not-json',
      });
      final store = AuthSessionStore(storage: const FlutterSecureStorage());
      expect(await store.load(), isNull);
    });

    test('saves and loads a valid session', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final store = AuthSessionStore(storage: const FlutterSecureStorage());

      const session = AuthSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        userId: '42',
        userName: 'Mika',
        account: 'mika',
      );

      await store.save(session);
      final loaded = await store.load();

      expect(loaded, isNotNull);
      expect(loaded!.accessToken, 'access');
      expect(loaded.userId, '42');
    });

    test('clear removes the stored session', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final store = AuthSessionStore(storage: const FlutterSecureStorage());

      const session = AuthSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        userId: '1',
        userName: 'x',
        account: 'x',
      );

      await store.save(session);
      expect(await store.load(), isNotNull);

      await store.clear();
      expect(await store.load(), isNull);
    });
  });
}
