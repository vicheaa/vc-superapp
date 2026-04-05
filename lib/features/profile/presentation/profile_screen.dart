import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oml_central/features/localization/presentation/localization_provider.dart';
import 'package:oml_central/core/theme/app_colors.dart';
import 'package:oml_central/core/theme/app_text_styles.dart';
import 'package:oml_central/core/widgets/button.dart';
import 'package:oml_central/core/widgets/dialog.dart';
import 'package:oml_central/features/auth/presentation/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value?.user;
    ref.watch(localizationProvider);
    final l10n = ref.read(localizationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        surfaceTintColor: AppColors.primary500,
        backgroundColor: AppColors.primary500,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, user),
            const SizedBox(height: 24),
            _buildSettingsList(context, ref, l10n),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppButton(
                text: 'Logout',
                onPressed: () => _handleLogout(context, ref),
                backgroundColor: AppColors.red500,
                icon: Icons.logout,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary500,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 40, top: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neutral10.withValues(alpha: 0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.neutral10.withValues(alpha: 0.1),
              backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
              child: user?.avatarUrl == null
                  ? Text(
                      user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'User Name',
            style: AppTextStyles.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'user@example.com',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral100.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, WidgetRef ref, LocalizationNotifier l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      width: MediaQuery.of(context).size.width - 32, 
      decoration: BoxDecoration(
        color: AppColors.neutral10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.person_outline,
            title: 'Account Information',
            onTap: () {},
            l10n: l10n,
          ),
          _buildSettingItem(
            icon: Icons.security_outlined,
            title: 'Security & Password',
            onTap: () {},
            l10n: l10n,
          ),
          _buildSettingItem(
            icon: Icons.notifications_none_outlined,
            title: 'Notification Preferences',
            onTap: () {},
            l10n: l10n,
          ),
          _buildSettingItem(
            icon: Icons.language,
            title: 'App Language',
            onTap: () {
              context.push('/localization');
            },
            l10n: l10n,
          ),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
            l10n: l10n,
          ),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
            l10n: l10n,
          ),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'setting.about_app',
            onTap: () {},
            l10n: l10n,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required LocalizationNotifier l10n,
  }) {
    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary50.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary500, size: 22),
        ),
        // title: Text(
        //   title,
        //   style: AppTextStyles.bodyMedium,
        // ),
        title: Text(
          l10n.translate(title),
          style: AppTextStyles.bodyMedium,
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.neutral400,
          size: 20,
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showAppDialog(
      context: context,
      barrierBlur: 1.0, 
      builder: (context) => AppAlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: AppColors.red500, size: 24),
        iconBgColor: AppColors.red500.withValues(alpha: 0.2),
        content: const Text('Are you sure you want to log out?', textAlign: TextAlign.center,),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w400),),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.red500, fontWeight: FontWeight.w400)),
          ),
        ],
      ),
    );
  }
}
