enum Flavor { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
  });

  final Flavor flavor;
  final String appName;
  final String apiBaseUrl;

  static const apiTimeout = Duration(seconds: 20);

  static AppConfig? _instance;
  static AppConfig get instance {
    assert(
      _instance != null,
      'AppConfig not initialized. Call AppConfig.init() first.',
    );
    return _instance!;
  }

  static void init(AppConfig config) => _instance = config;

  bool get isDev => flavor == Flavor.dev;
  bool get isStaging => flavor == Flavor.staging;
  bool get isProd => flavor == Flavor.prod;
}
