import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment { dev, staging, production }

class EnvConfig {
  static late Environment _environment;
  static late String _baseUrl;
  static late String _appName;
  static late String _imgUrl;

  static Environment get environment => _environment;
  static String get baseUrl => _baseUrl;
  static String get appName => _appName;
  static String get imgUrl => _imgUrl;

  static bool get isDev => _environment == Environment.dev;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;

  static Future<void> init({
    required Environment environment,
    required String baseUrl,
    required String appName,
    String? imgUrl,
  }) async {
    _environment = environment;
    _baseUrl = baseUrl;
    _appName = appName;
    _imgUrl = imgUrl ?? '';
  }

  /// Convenience factory for dev flavor
  static Future<void> initDev() async {
    await dotenv.load(fileName: ".env.dev");
    await init(
      environment: Environment.dev,
      baseUrl: dotenv.env['DEV_BASE_URL']!,
      appName: 'VC SuperApp Dev',
      imgUrl: dotenv.env['DEV_IMG_URL'],
    );
  }

  /// Convenience factory for staging flavor
  static Future<void> initStaging() => init(
        environment: Environment.staging,
        baseUrl: 'https://jsonplaceholder.typicode.com',
        appName: 'VC SuperApp Staging',
      );

  /// Convenience factory for production flavor
  static Future<void> initProduction() => init(
        environment: Environment.production,
        baseUrl: 'https://jsonplaceholder.typicode.com',
        appName: 'VC SuperApp',
      );
}
