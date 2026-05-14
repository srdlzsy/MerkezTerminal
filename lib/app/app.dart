import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/app/dependencies.dart';
import 'package:furpa_merkez_terminal/app/theme/app_theme.dart';
import 'package:furpa_merkez_terminal/core/config/app_config.dart';
import 'package:furpa_merkez_terminal/features/auth/presentation/views/login_page.dart';
import 'package:furpa_merkez_terminal/features/auth/presentation/views/splash_page.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/view_models/app_session_controller.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/views/home_shell_page.dart';

class FurpaMerkezApp extends StatelessWidget {
  const FurpaMerkezApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dependencies.sessionController,
      builder: (context, child) {
        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: switch (dependencies.sessionController.status) {
            AppSessionStatus.booting => const SplashPage(),
            AppSessionStatus.unauthenticated => LoginPage(
              sessionController: dependencies.sessionController,
            ),
            AppSessionStatus.authenticated => HomeShellPage(
              sessionController: dependencies.sessionController,
              moduleRegistry: dependencies.moduleRegistry,
            ),
          },
        );
      },
    );
  }
}
