import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vc_super_app/core/config/env_config.dart';
import 'package:vc_super_app/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vc_super_app/app.dart';

void main() {
  setUpAll(() async {
    // Set mock local storage for Hive/SecureStorage in tests
    SharedPreferences.setMockInitialValues({});
    EnvConfig.initDev();
    await configureDependencies();
  });

  testWidgets('App should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    // Verify the app renders
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
