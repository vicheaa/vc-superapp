import 'package:get_it/get_it.dart';

import '../../data/local/hive_storage.dart';
import '../../data/local/secure_storage.dart';
import '../../data/network/dio_client.dart';
import '../../features/auth/data/auth_api_service.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/miniapps/data/miniapp_api_service.dart';
import '../../features/miniapps/data/miniapp_repository_impl.dart';
import '../../features/miniapps/domain/miniapp_repository.dart';

import '../../features/profile/data/profile_api_service.dart';
import '../../features/profile/data/profile_repository_impl.dart';
import '../../features/profile/domain/profile_repository.dart';
// [GENERATED_IMPORTS_INJECTION]

final GetIt getIt = GetIt.instance;

/// Registers all dependencies in the service locator.
///
/// Call this before `runApp()`.
Future<void> configureDependencies() async {
  // ── Local Storage ──
  final hiveStorage = HiveStorageService();
  await hiveStorage.init();
  getIt.registerSingleton<HiveStorageService>(hiveStorage);

  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );

  // ── Network ──
  getIt.registerLazySingleton<DioClient>(
    () => DioClient(
      secureStorage: getIt<SecureStorageService>(),
      cacheStorage: getIt<HiveStorageService>(),
      onLogout: () {
        if (getIt.isRegistered<AuthRepository>()) {
          getIt<AuthRepository>().markUnauthenticated();
        }
      },
    ),
  );

  // ── Feature: Auth ──
  getIt.registerLazySingleton<AuthApiService>(
    () => AuthApiService(dio: getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      secureStorage: getIt<SecureStorageService>(),
      apiService: getIt<AuthApiService>(),
    ),
  );


  // ── Feature: Mini Apps ──
  getIt.registerLazySingleton<MiniAppApiService>(
    () => MiniAppApiService(dio: getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton<MiniAppRepository>(
    () => MiniAppRepositoryImpl(
      apiService: getIt<MiniAppApiService>(),
      dio: getIt<DioClient>().dio,
    ),
  );

    // ── Feature: Profile ──
  getIt.registerLazySingleton<ProfileApiService>(
    () => ProfileApiService(dio: getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(apiService: getIt<ProfileApiService>()),
  );

  // [GENERATED_DEPENDENCIES_INJECTION]
}
