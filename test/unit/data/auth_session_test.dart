import 'package:bysiv/domain/models/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSession', () {
    test('parses persisted JSON and serializes it back', () {
      final session = AuthSession.fromJson({
        'access_token': 'access',
        'refresh_token': 'refresh',
        'user_id': '42',
        'user_name': 'Mika',
        'account': 'mika',
        'avatar_url': 'avatar.jpg',
        'mail_address': 'mika@example.com',
        'is_premium': true,
        'x_restrict': 1,
        'is_mail_authorized': true,
      });

      expect(session.accessToken, 'access');
      expect(session.refreshToken, 'refresh');
      expect(session.userId, '42');
      expect(session.isPremium, isTrue);
      expect(session.toJson(), containsPair('account', 'mika'));
    });

    test('parses Pixiv auth response and falls back safely on empty input', () {
      final session = AuthSession.fromPixivResponse({
        'response': {
          'access_token': 'access',
          'refresh_token': 'refresh',
          'user': {
            'id': 123,
            'name': 'Aki',
            'account': 'aki',
            'profile_image_urls': {
              'px_50x50': 'small.jpg',
              'medium': 'medium.jpg',
            },
          },
        },
      });

      expect(session.userId, '123');
      expect(session.avatarUrl, 'small.jpg');
      expect(AuthSession.fromJson(const {}).accessToken, isEmpty);
    });
  });
}
