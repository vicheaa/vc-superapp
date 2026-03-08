import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../../core/utils/logger.dart';
import '../../local/hive_storage.dart';

/// Caches successful GET responses and serves them when offline.
///
/// Strategy:
/// - On successful GET response: cache the response body keyed by full URL + query.
/// - On request error (no internet): serve from cache if available.
class CacheInterceptor extends Interceptor {
  CacheInterceptor({
    required HiveStorageService cacheStorage,
    Connectivity? connectivity,
  })  : _cacheStorage = cacheStorage,
        _connectivity = connectivity ?? Connectivity();

  final HiveStorageService _cacheStorage;
  final Connectivity _connectivity;

  /// Generate a unique cache key from the request URL and query params.
  String _createCacheKey(RequestOptions options) {
    final uri = options.uri;
    return uri.toString();
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only cache GET requests
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    // Check connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);

    if (isOffline) {
      final cacheKey = _createCacheKey(options);
      final cachedData = _cacheStorage.get<dynamic>(cacheKey);

      if (cachedData != null) {
        AppLogger.info(
          'Serving from cache: ${options.path}',
          tag: 'CACHE',
        );
        return handler.resolve(
          Response(
            requestOptions: options,
            data: cachedData,
            statusCode: 200,
            statusMessage: 'OK (from cache)',
          ),
        );
      }

      AppLogger.warning(
        'Offline with no cached data for: ${options.path}',
        tag: 'CACHE',
      );
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // Cache successful GET responses
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final cacheKey = _createCacheKey(response.requestOptions);
      await _cacheStorage.put(cacheKey, response.data);
    }

    handler.next(response);
  }
}
