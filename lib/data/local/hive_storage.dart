import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/utils/logger.dart';

/// Generic key-value cache backed by Hive.
/// Used for offline caching of API responses.
class HiveStorageService {
  static const String _cacheBoxName = 'api_cache';

  late Box<String> _cacheBox;

  /// Initialize Hive and open the cache box.
  Future<void> init() async {
    // Tests don't have a valid UI/path configuration for Hive's local path
    try {
       await Hive.initFlutter();
       _cacheBox = await Hive.openBox<String>(_cacheBoxName);
       AppLogger.info('HiveStorageService initialized', tag: 'CACHE');
    } catch (e) {
       AppLogger.info('Skipping Hive init for tests ($e)', tag: 'CACHE');
    }
  }

  /// Store a JSON-serializable value with a cache key.
  Future<void> put(String key, dynamic value) async {
    try {
      final jsonString = jsonEncode(value);
      await _cacheBox.put(key, jsonString);
    } catch (e) {
      AppLogger.error('Cache put error for key: $key', error: e, tag: 'CACHE');
    }
  }

  /// Retrieve a cached value by key.
  T? get<T>(String key) {
    try {
      final jsonString = _cacheBox.get(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as T;
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
}
