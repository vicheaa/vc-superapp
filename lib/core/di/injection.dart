import 'package:get_it/get_it.dart';

import '../../data/local/hive_storage.dart';
import '../../data/local/secure_storage.dart';
import '../../data/network/dio_client.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/home/data/home_api_service.dart';
import '../../features/home/data/home_repository_impl.dart';
import '../../features/home/domain/home_repository.dart';
import '../../features/miniapps/data/miniapp_repository_impl.dart';
import '../../features/miniapps/domain/miniapp_repository.dart';

import '../../features/movie/data/movie_api_service.dart';
import '../../features/movie/data/movie_repository_impl.dart';
import '../../features/movie/domain/movie_repository.dart';
import '../../features/movie/data/movie_api_service.dart';
import '../../features/movie/data/movie_repository_impl.dart';
import '../../features/movie/domain/movie_repository.dart';
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
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      secureStorage: getIt<SecureStorageService>(),
      tokenDio: getIt<DioClient>().dio, // using standard dio for now since we mock it
    ),
  );

  // ── Feature: Home ──
  getIt.registerLazySingleton<HomeApiService>(
    () => HomeApiService(dio: getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(apiService: getIt<HomeApiService>()),
  );

  // ── Feature: Mini Apps ──
  getIt.registerLazySingleton<MiniAppRepository>(
    () => MiniAppRepositoryImpl(dio: getIt<DioClient>().dio),
  );

    // ── Feature: Movie ──
  getIt.registerLazySingleton<MovieApiService>(
    () => MovieApiService(dio: getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton<MovieRepository>(
    () => MovieRepositoryImpl(apiService: getIt<MovieApiService>()),
  );

    // ── Feature: Movie ──
  getIt.registerLazySingleton<MovieApiService>(
    () => MovieApiService(dio: getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton<MovieRepository>(
    () => MovieRepositoryImpl(apiService: getIt<MovieApiService>()),
  );

  // [GENERATED_DEPENDENCIES_INJECTION]
}
