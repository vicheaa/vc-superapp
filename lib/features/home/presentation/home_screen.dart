import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'widgets/home_header.dart';
import 'widgets/miniapp_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch authenticated user
    final authState = ref.watch(authProvider);
    final user = authState.value?.user;

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Column(
          children: [
            HomeHeader(user: user),
            const Expanded(
              child: MiniAppGrid(),
            ),
          ],
        ),
      ),
    );
  }
}