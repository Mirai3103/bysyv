import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

void main() {
  AppConfig.init(
    const AppConfig(
      flavor: Flavor.staging,
      appName: 'Bysiv Staging',
      apiBaseUrl: 'https://app-api.pixiv.net',
    ),
  );
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BysivApp()));
}
