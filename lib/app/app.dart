import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/app/dependencies.dart';
import 'package:furpa_merkez_terminal/app/theme/app_theme.dart';
import 'package:furpa_merkez_terminal/core/config/app_config.dart';
import 'package:furpa_merkez_terminal/core/update/app_update_service.dart';
import 'package:furpa_merkez_terminal/features/auth/presentation/views/login_page.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/view_models/app_session_controller.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/views/home_shell_page.dart';

class FurpaMerkezApp extends StatefulWidget {
  const FurpaMerkezApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<FurpaMerkezApp> createState() => _FurpaMerkezAppState();
}

class _FurpaMerkezAppState extends State<FurpaMerkezApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _updateCheckStarted = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForUpdate());
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.dependencies.sessionController,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          scaffoldMessengerKey: _scaffoldMessengerKey,
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: switch (widget.dependencies.sessionController.status) {
            AppSessionStatus.booting => const _BootPlaceholderPage(),
            AppSessionStatus.unauthenticated => LoginPage(
              sessionController: widget.dependencies.sessionController,
            ),
            AppSessionStatus.authenticated => HomeShellPage(
              sessionController: widget.dependencies.sessionController,
              moduleRegistry: widget.dependencies.moduleRegistry,
            ),
          },
        );
      },
    );
  }

  Future<void> _checkForUpdate() async {
    if (_updateCheckStarted) {
      return;
    }

    _updateCheckStarted = true;

    try {
      final updateInfo = await widget.dependencies.updateService
          .checkForUpdate();
      if (!mounted || updateInfo == null) {
        return;
      }

      final dialogContext = _navigatorKey.currentContext;
      if (dialogContext == null || !dialogContext.mounted) {
        return;
      }

      final shouldDownload = await showDialog<bool>(
        context: dialogContext,
        builder: (context) {
          return AlertDialog(
            title: const Text('Yeni surum var'),
            content: Text(
              'Mevcut surum: ${updateInfo.currentVersion}\n'
              'Yeni surum: ${updateInfo.version}\n\n'
              'Guncellemeyi indirelim mi?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Daha sonra'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Indir'),
              ),
            ],
          );
        },
      );

      if (!mounted || shouldDownload != true) {
        return;
      }

      await _downloadAndInstall(updateInfo);
    } on AppUpdateException catch (error) {
      debugPrint('Guncelleme kontrolu atlandi: ${error.message}');
    } on Object catch (error) {
      debugPrint('Guncelleme kontrolu atlandi: $error');
    }
  }

  Future<void> _downloadAndInstall(AppUpdateInfo updateInfo) async {
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) {
      return;
    }

    var progressDialogVisible = true;
    final progressDialog =
        showDialog<void>(
          context: dialogContext,
          barrierDismissible: false,
          builder: (context) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text('Guncelleme indiriliyor'),
                content: Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${updateInfo.version} surumu indiriliyor...',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ).whenComplete(() {
          progressDialogVisible = false;
        });
    unawaited(progressDialog);

    try {
      final installerOpened = await widget.dependencies.updateService
          .downloadAndInstall(updateInfo);
      if (!mounted) {
        return;
      }

      _closeProgressDialog(isVisible: progressDialogVisible);

      if (!installerOpened) {
        _showMessage(
          'Kurulum izni sayfasi acildi. Izin verilince kurulum ekrani '
          'otomatik acilacak.',
        );
      }
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      _closeProgressDialog(isVisible: progressDialogVisible);
      _showMessage(error.message ?? 'Guncelleme indirilemedi.');
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      _closeProgressDialog(isVisible: progressDialogVisible);
      _showMessage('Guncelleme indirilemedi: $error');
    }
  }

  void _closeProgressDialog({required bool isVisible}) {
    if (!isVisible) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null || !navigator.canPop()) {
      return;
    }

    navigator.pop();
  }

  void _showMessage(String message) {
    _scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BootPlaceholderPage extends StatelessWidget {
  const _BootPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Color(0xFFF6F8FC));
  }
}
