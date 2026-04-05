import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/di/injection.dart';
import '../../../data/local/local_storage.dart';
import '../../../core/utils/logger.dart';
import '../data/localization_service.dart';

class LocalizationState {
  final String currentLanguage;
  final Map<String, dynamic> translations;
  final bool isLoadingTranslations;

  const LocalizationState({
    required this.currentLanguage,
    required this.translations,
    this.isLoadingTranslations = false,
  });

  LocalizationState copyWith({
    String? currentLanguage,
    Map<String, dynamic>? translations,
    bool? isLoadingTranslations,
  }) {
    return LocalizationState(
      currentLanguage: currentLanguage ?? this.currentLanguage,
      translations: translations ?? this.translations,
      isLoadingTranslations: isLoadingTranslations ?? this.isLoadingTranslations,
    );
  }
}

// Provide LocalizationService with initialization
final localizationServiceProvider = FutureProvider<LocalizationService>((ref) async {
  final service = getIt<LocalizationService>();
  await service.initialize();
  return service;
});

final localizationProvider = AsyncNotifierProvider<LocalizationNotifier, LocalizationState>(LocalizationNotifier.new);

class LocalizationNotifier extends AsyncNotifier<LocalizationState> {
  late final LocalizationService _localizationService;
  late final LocalStorageUtils _localStorage;

  @override
  Future<LocalizationState> build() async {
    _localizationService = await ref.watch(localizationServiceProvider.future);
    _localStorage = getIt<LocalStorageUtils>();
    
    final currentLanguage = _localStorage.getStringKey(StorageKeys.lang) ?? 'en';
    
    return LocalizationState(
      currentLanguage: currentLanguage,
      translations: _localizationService.translations,
      isLoadingTranslations: false,
    );
  }

  Future<void> _loadTranslations(String language) async {
    state = AsyncData(
      state.asData?.value.copyWith(
            currentLanguage: language,
            isLoadingTranslations: true,
          ) ??
          LocalizationState(
            currentLanguage: language,
            translations: _localizationService.translations,
            isLoadingTranslations: true,
          ),
    );

    try {
      await _localStorage.setKeyString(StorageKeys.lang, language);
      await _localizationService.setLanguage(language);
      
      state = AsyncData(
        state.asData!.value.copyWith(
          currentLanguage: language,
          translations: _localizationService.translations,
          isLoadingTranslations: false,
        ),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> changeLanguage(String lang) async {
    // 1. Switch locally first for instant UI response
    await _loadTranslations(lang);
    
    // 2. Trigger background download for the newly selected language
    try {
      await _localizationService.downloadAndMergeTranslations(languages: [lang]);
      // 3. Reload translations into memory to reflect any merged server data
      await _loadTranslations(lang);
    } catch (e) {
      // We don't set the error state here as the user has already switched locales locally
      AppLogger.error('Background language sync failed for $lang', tag: 'Localization', error: e);
    }
  }

  Future<void> updateTranslations() async {
    try {
      await _localizationService.downloadAndMergeTranslations();
      final currentLanguage = state.asData?.value.currentLanguage ?? 'en';
      await _loadTranslations(currentLanguage);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Translates a key, returning the key if translations are not ready.
  String translate(String key) {
    if (state.isLoading || !state.hasValue || state.hasError) {
      return key;
    }
    return _localizationService.translate(key);
  }
}
