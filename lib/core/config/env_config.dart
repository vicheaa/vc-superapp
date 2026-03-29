enum Environment { dev, staging, production }

class EnvConfig {
  static late Environment _environment;
  static late String _baseUrl;
  static late String _appName;

  static Environment get environment => _environment;
  static String get baseUrl => _baseUrl;
  static String get appName => _appName;

  static bool get isDev => _environment == Environment.dev;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;

  static void init({
    required Environment environment,
    required String baseUrl,
    required String appName,
  }) {
    _environment = environment;
    _baseUrl = baseUrl;
    _appName = appName;
  }

  /// Convenience factory for dev flavor
  static void initDev() => init(
        environment: Environment.dev,
        baseUrl: 'https://jsonplaceholder.typicode.com',
        appName: 'VC SuperApp Dev',
      );

  /// Convenience factory for staging flavor
  static void initStaging() => init(
        environment: Environment.staging,
        baseUrl: 'https://jsonplaceholder.typicode.com',
        appName: 'VC SuperApp Staging',
      );

  /// Convenience factory for production flavor
  static void initProduction() => init(
        environment: Environment.production,
        baseUrl: 'https://jsonplaceholder.typicode.com',
        appName: 'VC SuperApp',
      );
}
