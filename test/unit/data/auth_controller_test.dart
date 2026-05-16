import 'package:bysiv/data/services/pixiv_auth_service.dart';
import 'package:bysiv/ui/features/auth/view_models/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dio_helpers.dart';
import '../../helpers/fakes.dart';

void main() {
  group('AuthController', () {
    test('loads, authenticates, reports failures, and logs out', () async {
      final store = MemorySessionStore(null);
      final service = FakeAuthService();
      final controller = AuthController(
        authService: service,
        sessionStore: store,
      );

      await controller.loadSession();
      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.isInitialized, isTrue);
      expect(controller.isBusy, isFalse);

      final request = controller.startWebLogin(PixivWebAuthMode.login);
      expect(request.url.path, '/web/v1/login');

      await controller.exchangeAuthorizationCode(
        code: 'code',
        codeVerifier: 'verifier',
      );
      expect(controller.status, AuthStatus.authenticated);
      expect(controller.isAuthenticated, isTrue);
      expect((await store.load())!.accessToken, 'access');

      service.nextSession = sessionWith(accessToken: '');
      await controller.loginWithRefreshToken('bad-refresh');
      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.errorMessage, contains('usable token'));

      service.throwOnRefresh = true;
      await controller.loginWithRefreshToken('bad-refresh');
      expect(controller.errorMessage, contains('refresh failed'));

      await controller.logout();
      expect(controller.session, isNull);
      expect(await store.load(), isNull);
      controller.dispose();
    });
  });
}
