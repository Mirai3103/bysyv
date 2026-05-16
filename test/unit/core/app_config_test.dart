import 'package:bysiv/core/config/app_config.dart';
import 'package:bysiv/core/network/dio_provider.dart';
import 'package:bysiv/core/theme/app_colors.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('AppConfig', () {
    test('initializes flavor flags and Dio defaults', () {
      AppConfig.init(
        const AppConfig(
          flavor: Flavor.dev,
          appName: 'bysiv test',
          apiBaseUrl: 'https://app-api.pixiv.net',
        ),
      );

      expect(AppConfig.instance.isDev, isTrue);
      expect(AppConfig.instance.isStaging, isFalse);
      expect(AppConfig.instance.isProd, isFalse);
      expect(AppConfig.apiTimeout, const Duration(seconds: 20));
      expect(AppColors.primary.toARGB32(), 0xFF4C5FEF);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final dio = container.read(dioProvider);

      expect(dio.options.baseUrl, 'https://app-api.pixiv.net');
      expect(dio.options.connectTimeout, AppConfig.apiTimeout);
      expect(dio.options.headers[Headers.acceptHeader], 'application/json');
    });
  });
}
