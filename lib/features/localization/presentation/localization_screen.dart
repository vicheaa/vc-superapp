import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oml_central/core/theme/app_colors.dart';
import 'package:oml_central/core/theme/app_text_styles.dart';
import 'package:oml_central/core/widgets/button.dart';
import 'package:oml_central/core/widgets/custom_progress_indicator.dart';

import 'localization_provider.dart';

class LocalizationScreen extends ConsumerStatefulWidget {
  const LocalizationScreen({super.key});

  @override
  ConsumerState<LocalizationScreen> createState() => _LocalizationScreenState();
}

class _LocalizationScreenState extends ConsumerState<LocalizationScreen> {
  String? _selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localizationProvider);
    final notifier = ref.read(localizationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(
          notifier.translate('localization.title'),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.neutral950,
      ),
      body: state.when(
        data: (data) {
          // Initialize local state if not set
          _selectedLanguage ??= data.currentLanguage;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LanguageCard(
                        title: notifier.translate('localization.en'),
                        isSelected: _selectedLanguage == 'en',
                        onTap: () => setState(() => _selectedLanguage = 'en'),
                        icon: '🇺🇸',
                      ),
                      const SizedBox(height: 16),
                      _LanguageCard(
                        title: notifier.translate('localization.km'),
                        isSelected: _selectedLanguage == 'km',
                        onTap: () => setState(() => _selectedLanguage = 'km'),
                        icon: '🇰🇭',
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: AppButton(
                  text: notifier.translate('localization.confirm'),
                  onPressed: data.isLoadingTranslations ||
                          _selectedLanguage == null ||
                          _selectedLanguage == data.currentLanguage
                      ? null
                      : () async {
                          await notifier.changeLanguage(_selectedLanguage!);
                        },
                  isLoading: data.isLoadingTranslations,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: AppCircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final String icon;

  const _LanguageCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary400 : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.transparent,
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.neutral50,
                    shape: BoxShape.circle,
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary600 : AppColors.neutral800,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary400,
                    size: 24,
                  )
                else
                  Icon(
                    Icons.circle_outlined,
                    color: AppColors.neutral300,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
