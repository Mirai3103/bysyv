import 'package:dio/dio.dart';
import 'package:bysiv/data/services/pixiv_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dio_helpers.dart';

void main() {
  group('PixivAuthService', () {
    test('builds web auth requests and posts OAuth grant bodies', () async {
      final seen = <RequestOptions>[];
      final service = PixivAuthService(
        dio: dioWithResponses(seen, [
          authResponseJson('code-access'),
          authResponseJson('password-access'),
          authResponseJson('refresh-access'),
        ]),
      );

      final login = service.createWebAuthRequest(PixivWebAuthMode.login);
      expect(login.url.path, '/web/v1/login');
      expect(login.url.queryParameters['code_challenge_method'], 'S256');
      expect(login.codeVerifier, hasLength(128));

      final register = service.createWebAuthRequest(PixivWebAuthMode.register);
      expect(register.url.path, '/web/v1/provisional-accounts/create');

      expect(
        (await service.exchangeAuthorizationCode(
          code: 'code',
          codeVerifier: 'verifier',
        )).accessToken,
        'code-access',
      );
      expect(
        (await service.loginWithPassword(
          username: 'user',
          password: 'pass',
        )).accessToken,
        'password-access',
      );
      expect(
        (await service.refreshToken('refresh')).accessToken,
        'refresh-access',
      );

      expect(seen[0].data['grant_type'], 'authorization_code');
      expect(seen[1].data['Device_token'], 'pixiv');
      expect(seen[2].data['refresh_token'], 'refresh');
      expect(seen[0].headers['Host'], 'oauth.secure.pixiv.net');
    });

    test(
      'throws readable auth errors for empty and failed token responses',
      () async {
        final emptyService = PixivAuthService(
          dio: dioWithNullableResponses([null]),
        );
        expect(
          () => emptyService.refreshToken('refresh'),
          throwsA(
            isA<PixivAuthException>().having(
              (e) => e.toString(),
              'message',
              contains('empty'),
            ),
          ),
        );

        final errorService = PixivAuthService(
          dio: dioWithDioError({
            'errors': {
              'system': {'message': 'System says no'},
            },
          }),
        );
        expect(
          () => errorService.refreshToken('refresh'),
          throwsA(
            isA<PixivAuthException>().having(
              (e) => e.toString(),
              'message',
              'System says no',
            ),
          ),
        );

        final oauthErrorService = PixivAuthService(
          dio: dioWithDioError({
            'error': {'message': 'OAuth says no'},
          }),
        );
        expect(
          () => oauthErrorService.refreshToken('refresh'),
          throwsA(
            isA<PixivAuthException>().having(
              (e) => e.toString(),
              'message',
              'OAuth says no',
            ),
          ),
        );
      },
    );
  });
}
