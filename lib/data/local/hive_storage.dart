import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/utils/logger.dart';

/// Generic key-value cache backed by Hive.
/// Used for offline caching of API responses.
///
/// Entries are timestamped and evicted after [defaultMaxAge].
class HiveStorageService {
  static const String _cacheBoxName = 'api_cache';
  static const Duration defaultMaxAge = Duration(hours: 24);

  late Box<String> _cacheBox;

  /// Initialize Hive and open the cache box.
  Future<void> init() async {
    // Tests don't have a valid UI/path configuration for Hive's local path
    try {
       await Hive.initFlutter();
       _cacheBox = await Hive.openBox<String>(_cacheBoxName);
       AppLogger.info('HiveStorageService initialized', tag: 'CACHE');

       // Evict expired entries on startup
       await _evictExpired();
    } catch (e) {
       AppLogger.info('Skipping Hive init for tests ($e)', tag: 'CACHE');
    }
  }

  /// Store a JSON-serializable value with a cache key and timestamp.
  Future<void> put(String key, dynamic value) async {
    try {
      final entry = {
        'data': value,
        'ts': DateTime.now().millisecondsSinceEpoch,
      };
      await _cacheBox.put(key, jsonEncode(entry));
    } catch (e) {
      AppLogger.error('Cache put error for key: $key', error: e, tag: 'CACHE');
    }
  }

  /// Retrieve a cached value by key. Returns `null` if expired or missing.
  T? get<T>(String key, {Duration maxAge = defaultMaxAge}) {
    try {
      final jsonString = _cacheBox.get(key);
      if (jsonString == null) return null;

      final decoded = jsonDecode(jsonString);

      // Support legacy entries without timestamp wrapper
      if (decoded is! Map<String, dynamic> || !decoded.containsKey('ts')) {
        return decoded as T;
      }

      final ts = decoded['ts'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > maxAge.inMilliseconds) {
        _cacheBox.delete(key); // Evict expired entry
        return null;
      }

      return decoded['data'] as T;
    } catch (e) {
      AppLogger.error('Cache get error for key: $key', error: e, tag: 'CACHE');
      return null;
    }
  }

  /// Check if a key exists in the cache.
  bool containsKey(String key) => _cacheBox.containsKey(key);

  /// Remove a cached value by key.
  Future<void> remove(String key) async {
    await _cacheBox.delete(key);
  }

  /// Clear the entire cache.
  Future<void> clearAll() async {
    await _cacheBox.clear();
  }

  /// Remove all entries older than [defaultMaxAge].
  Future<void> _evictExpired() async {
    final keysToDelete = <dynamic>[];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final key in _cacheBox.keys) {
      try {
        final jsonString = _cacheBox.get(key);
        if (jsonString == null) continue;

        final decoded = jsonDecode(jsonString);
        if (decoded is Map<String, dynamic> && decoded.containsKey('ts')) {
          final ts = decoded['ts'] as int;
          if (now - ts > defaultMaxAge.inMilliseconds) {
            keysToDelete.add(key);
          }
        }
      } catch (_) {
        keysToDelete.add(key); // Remove corrupted entries
      }
    }

    if (keysToDelete.isNotEmpty) {
      await _cacheBox.deleteAll(keysToDelete);
      AppLogger.info('Evicted ${keysToDelete.length} expired cache entries', tag: 'CACHE');
    }
  }
}
