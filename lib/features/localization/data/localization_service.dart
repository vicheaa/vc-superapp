import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/utils/logger.dart';
import '../../../data/local/local_storage.dart';
import '../../../data/local/secure_storage.dart';
import 'localization_api_service.dart';

class LocalizationService {
  final LocalizationApiService _apiService;
  final LocalStorageUtils _localStorage;
  final SecureStorageService _secureStorage;
  final Map<String, Map<String, dynamic>> _cachedTranslations = {};
  Map<String, dynamic> translations = {};
  bool _isInitialized = false;
  bool _hasAttemptedDownload = false;
  static LocalizationService? instance;
  static const _supportedLanguages = ['en', 'km'];

  LocalizationService({
    required LocalizationApiService apiService,
    required LocalStorageUtils localStorage,
    required SecureStorageService secureStorage,
  })  : _apiService = apiService,
        _localStorage = localStorage,
        _secureStorage = secureStorage {
    instance = this;
  }

  /// Initializes the service by pre-saving asset translations and loading the current language.
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.info('LocalizationService already initialized, skipping.', tag: 'LocalizationService');
      return;
    }
    AppLogger.info('Initializing LocalizationService...', tag: 'LocalizationService');

    // Pre-save asset translations to local storage
    await _preSaveAssetTranslations();
    await loadCurrentLanguageTranslations();
    _isInitialized = true;
    AppLogger.info('LocalizationService initialized successfully.', tag: 'LocalizationService');
  }

  /// Copies asset translations to local storage if they don't exist.
  Future<void> _preSaveAssetTranslations() async {
    for (final lang in _supportedLanguages) {
      try {
        final filePath = 'lang/$lang';
        final assetJson = await rootBundle.loadString('assets/lang/$lang.json');
        final assetData = _parseJsonString(assetJson);
        final assetVersion = assetData['version']?.toString();

        final exists = await _localFileExists(filePath);
        if (!exists) {
          AppLogger.info('Local file $filePath.json does not exist, copying', tag: 'LocalizationService');
          await _saveTranslationsToFile(lang, assetData);
        } else {
          final localData = await _safeReadJsonFile(filePath);
          final localVersion = localData['version']?.toString();

          if (_isVersionNewer(assetVersion, localVersion)) {
            AppLogger.info(
              'Asset version ($assetVersion) is newer than local version ($localVersion), updating from assets',
              tag: 'LocalizationService',
            );
            await _saveTranslationsToFile(lang, assetData);
          } else {
            AppLogger.info('Local file $filePath.json is up to date (V$localVersion)', tag: 'LocalizationService');
          }
        }
      } catch (e) {
        AppLogger.error(
          'Failed to pre-save $lang translations from assets',
          tag: 'LocalizationService',
          error: e,
        );
      }
    }
  }

  /// Compares two version strings (e.g., "0.0.1" and "0.8").
  /// Returns true if [newVersion] is strictly newer than [oldVersion].
  bool _isVersionNewer(String? newVersion, String? oldVersion) {
    if (newVersion == null) return false;
    if (oldVersion == null) return true;

    try {
      final List<int> newParts = newVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final List<int> oldParts = oldVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final int maxLength = newParts.length > oldParts.length ? newParts.length : oldParts.length;

      for (int i = 0; i < maxLength; i++) {
        final int newVal = i < newParts.length ? newParts[i] : 0;
        final int oldVal = i < oldParts.length ? oldParts[i] : 0;

        if (newVal > oldVal) return true;
        if (newVal < oldVal) return false;
      }
    } catch (e) {
      // In case of parsing error, only update if they are not identical
      return newVersion != oldVersion;
    }

    return false;
  }

  /// Checks if a local file exists.
  Future<bool> _localFileExists(String path) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$path.json');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Loads translations for the current language.
  Future<void> loadCurrentLanguageTranslations() async {
    final currentLang = _localStorage.getStringKey(StorageKeys.lang) ?? 'en';
    AppLogger.info('Loading translations for current language: $currentLang', tag: 'LocalizationService');
    await setLanguage(currentLang);
  }

  /// Sets the language and loads corresponding translations.
  Future<void> setLanguage(String lang) async {
    AppLogger.info('Setting language to: $lang', tag: 'LocalizationService');
    try {
      if (!_supportedLanguages.contains(lang)) {
        AppLogger.warning(
          'Unsupported language: $lang, falling back to en',
          tag: 'LocalizationService',
        );
        lang = 'en';
      }

      // Check cache first
      if (_cachedTranslations.containsKey(lang)) {
        translations = _cachedTranslations[lang]!;
        await _localStorage.setKeyString(StorageKeys.lang, lang);
        AppLogger.info('Loaded $lang translations from cache', tag: 'LocalizationService');
        return;
      }

      // Try local storage
      try {
        final data = await _safeReadJsonFile('lang/$lang');
        translations = _ensureStringMap(data);
        _cachedTranslations[lang] = translations;
        await _localStorage.setKeyString(StorageKeys.lang, lang);
        AppLogger.info('Loaded $lang translations from local storage', tag: 'LocalizationService');
      } catch (e) {
        AppLogger.error(
          'Failed to load $lang from local storage, using assets',
          tag: 'LocalizationService',
          error: e,
        );
        translations = await _loadAssetTranslations(lang);
        _cachedTranslations[lang] = translations;
        await _localStorage.setKeyString(StorageKeys.lang, lang);
        await _saveTranslationsToFile(lang, translations);
        AppLogger.info('Set $lang translations from assets', tag: 'LocalizationService');
      }
    } catch (e) {
      AppLogger.error('Failed to set language $lang', tag: 'LocalizationService', error: e);
      // Fallback to English assets
      translations = await _loadAssetTranslations('en');
      _cachedTranslations['en'] = translations;
      await _localStorage.setKeyString(StorageKeys.lang, 'en');
      AppLogger.info('Fell back to English translations', tag: 'LocalizationService');
    }
  }

  /// Loads translations from assets.
  Future<Map<String, dynamic>> _loadAssetTranslations(String lang) async {
    try {
      final assetJson = await rootBundle.loadString('assets/lang/$lang.json');
      final data = _parseJsonString(assetJson);
      AppLogger.info('Loaded $lang translations from assets', tag: 'LocalizationService');
      return _ensureStringMap(data);
    } catch (e) {
      AppLogger.error(
        'Failed to load $lang asset translations',
        tag: 'LocalizationService',
        error: e,
      );
      return {};
    }
  }

  /// Downloads translations from the server, merges with local data, and overrides local files.
  Future<void> downloadAndMergeTranslations({
    List<String> languages = const ['en', 'km'],
  }) async {
    if (_hasAttemptedDownload) {
      AppLogger.info('Download already in progress, skipping', tag: 'LocalizationService');
      return;
    }

    AppLogger.info('Starting translation download for languages: $languages', tag: 'LocalizationService');
    try {
      _hasAttemptedDownload = true;
      final token = await _secureStorage.getToken();
      if (token == null) {
        AppLogger.info('No token available, skipping download', tag: 'LocalizationService');
        return;
      }

      final localLangVersion = _localStorage.getStringKey(StorageKeys.langVersion) ?? '0.0.0';
      AppLogger.info('Local language version: $localLangVersion', tag: 'LocalizationService');
      bool hasDownloaded = false;
      String? serverVersion;

      for (final String lang in languages) {
        if (!_supportedLanguages.contains(lang)) {
          AppLogger.warning('Skipping unsupported language: $lang', tag: 'LocalizationService');
          continue;
        }

        AppLogger.info('Downloading translations for $lang', tag: 'LocalizationService');
        final result = await _apiService.downloadTranslations(
          lang: lang,
          currentVersion: localLangVersion,
        );

        await result.when(
          success: (serverData) async {
            AppLogger.info('Successfully received $lang translations from server', tag: 'LocalizationService');
            AppLogger.debug('Server data for $lang: $serverData', tag: 'LocalizationService');
            
            serverVersion = serverData['version']?.toString();
            if (serverVersion == null) {
              AppLogger.warning('No version found in server data for $lang. Skipping update.', tag: 'LocalizationService');
              return;
            }

            AppLogger.info('Processing $lang update (New Version: $serverVersion)', tag: 'LocalizationService');
            Map<String, dynamic> localData;
            try {
              localData = await _safeReadJsonFile('lang/$lang');
            } catch (e) {
              localData = {};
              AppLogger.info('No valid local translations found for $lang, using server data', tag: 'LocalizationService');
            }

            final merged = _deepMerge(localData, serverData);
            await _saveTranslationsToFile(lang, merged);
            _cachedTranslations[lang] = merged;
            
            // Update in-memory translations if the current language is being processed
            final currentLang = _localStorage.getStringKey(StorageKeys.lang) ?? 'en';
            if (lang == currentLang) {
              translations = merged;
              AppLogger.info('Updated in-memory translations for current language: $lang', tag: 'LocalizationService');
            }
            hasDownloaded = true;
          },
          failure: (message, statusCode) {
            AppLogger.error('Failed to download translations for $lang: $message', tag: 'LocalizationService');
          },
        );
      }

      if (hasDownloaded && serverVersion != null) {
        await _localStorage.setKeyString(StorageKeys.langVersion, serverVersion!);
        AppLogger.info('Updated language version to $serverVersion', tag: 'LocalizationService');
      }
    } catch (e) {
      AppLogger.error('Unexpected error during translation download', tag: 'LocalizationService', error: e);
    } finally {
      _hasAttemptedDownload = false;
      AppLogger.info('Download attempt completed', tag: 'LocalizationService');
    }
  }

  /// Safely saves translations to a file.
  Future<void> _saveTranslationsToFile(String lang, Map<String, dynamic> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = 'lang/$lang';
      final file = File('${directory.path}/$path.json');
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsString(jsonEncode(data));
      AppLogger.info('Saved translations for $lang to local storage', tag: 'LocalizationService');
    } catch (e) {
      AppLogger.error('Failed to save translations for $lang', tag: 'LocalizationService', error: e);
      rethrow;
    }
  }

  /// Safely reads a JSON file.
  Future<Map<String, dynamic>> _safeReadJsonFile(String path) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$path.json');
      if (!await file.exists()) {
        throw FileSystemException('File not found: $path');
      }
      final contents = await file.readAsString();
      final decoded = jsonDecode(contents);
      return _ensureStringMap(decoded);
    } catch (e) {
      AppLogger.error('Error reading $path', tag: 'LocalizationService', error: e);
      rethrow;
    }
  }

  /// Parses a JSON string.
  Map<String, dynamic> _parseJsonString(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      return _ensureStringMap(decoded);
    } catch (e) {
      AppLogger.error('Error parsing JSON string', tag: 'LocalizationService', error: e);
      rethrow;
    }
  }

  /// Ensures a map has String keys.
  Map<String, dynamic> _ensureStringMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw FormatException('Expected a Map but got ${data.runtimeType}');
  }

  /// Deep merges two maps, prioritizing server data.
  Map<String, dynamic> _deepMerge(Map<String, dynamic> localData, Map<String, dynamic> serverData) {
    final merged = Map<String, dynamic>.from(localData);
    serverData.forEach((key, value) {
      if (value is Map<String, dynamic> && merged.containsKey(key) && merged[key] is Map<String, dynamic>) {
        merged[key] = _deepMerge(merged[key] as Map<String, dynamic>, value);
      } else {
        merged[key] = value;
      }
    });
    return merged;
  }

  /// Translates a key to its corresponding value.
  String translate(String key) {
    final keys = key.split('.');
    dynamic value = translations;

    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return key;
      }
    }

    return value is String ? value : key;
  }
}
