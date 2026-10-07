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
import 'package:furpa_merkez_terminal/shared/widgets/furpa_brand.dart';

class FurpaMerkezApp extends StatefulWidget {
  const FurpaMerkezApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<FurpaMerkezApp> createState() => _FurpaMerkezAppState();
}

class _FurpaMerkezAppState extends State<FurpaMerkezApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _automaticUpdateCheckStarted = false;
  bool _isCheckingUpdate = false;
  bool _isDownloadingUpdate = false;
  bool _isAwaitingInstallation = false;
  InstalledAppVersion? _installedVersion;
  AppUpdateInfo? _availableUpdate;
  AppUpdateDownloadProgress? _updateProgress;
  String? _updateStatusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeUpdateState());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_verifyInstalledVersionAfterResume());
    }
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
              installedVersionLabel: _installedVersion?.label ?? 'Okunuyor...',
              availableVersionLabel: _availableUpdate?.versionLabel,
              isCheckingUpdate: _isCheckingUpdate,
              isDownloadingUpdate: _isDownloadingUpdate,
              updateProgress: _updateProgress?.fraction,
              updateStatusMessage: _updateStatusMessage,
              onCheckForUpdate: () => unawaited(_checkForUpdate(manual: true)),
              onInstallUpdate: _availableUpdate == null
                  ? null
                  : () => unawaited(_downloadAndInstall(_availableUpdate!)),
            ),
          },
        );
      },
    );
  }

  Future<void> _initializeUpdateState() async {
    await _refreshInstalledVersion();
    await _checkForUpdate();
  }

  Future<void> _checkForUpdate({bool manual = false}) async {
    if (_isCheckingUpdate || _isDownloadingUpdate) {
      if (manual) {
        _showMessage('Guncelleme islemi zaten devam ediyor.');
      }
      return;
    }

    if (!manual && _automaticUpdateCheckStarted) {
      return;
    }

    if (!manual) {
      _automaticUpdateCheckStarted = true;
    }

    setState(() {
      _isCheckingUpdate = true;
      _updateStatusMessage = 'Guncelleme kontrol ediliyor...';
    });

    try {
      final updateInfo = await widget.dependencies.updateService
          .checkForUpdate();
      if (!mounted) {
        return;
      }

      await _refreshInstalledVersion();
      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingUpdate = false;
        _availableUpdate = updateInfo;
        _updateStatusMessage = updateInfo == null
            ? 'Uygulama guncel.'
            : '${updateInfo.versionLabel} surumu hazir.';
      });

      if (updateInfo == null) {
        if (manual) {
          _showMessage('Uygulama guncel: ${_installedVersion?.label ?? '-'}');
        }
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
              'Mevcut surum: ${updateInfo.currentVersionLabel}\n'
              'Yeni surum: ${updateInfo.versionLabel}\n\n'
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
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
          _updateStatusMessage = 'Guncelleme kontrol edilemedi.';
        });
      }
      if (manual) {
        _showMessage(error.message);
      }
      debugPrint('Guncelleme kontrolu atlandi: ${error.message}');
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
          _updateStatusMessage = 'Guncelleme kontrol edilemedi.';
        });
      }
      if (manual) {
        _showMessage('Guncelleme kontrol edilemedi: $error');
      }
      debugPrint('Guncelleme kontrolu atlandi: $error');
    }
  }

  Future<void> _downloadAndInstall(AppUpdateInfo updateInfo) async {
    if (_isDownloadingUpdate) {
      return;
    }

    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) {
      return;
    }

    var progressDialogVisible = true;
    var downloadProgress = const AppUpdateDownloadProgress(
      bytesRead: 0,
      totalBytes: 0,
    );
    StateSetter? updateProgressDialog;
    setState(() {
      _isDownloadingUpdate = true;
      _updateProgress = downloadProgress;
      _updateStatusMessage = '${updateInfo.versionLabel} indiriliyor...';
    });
    final progressDialog =
        showDialog<void>(
          context: dialogContext,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                updateProgressDialog = setDialogState;

                return PopScope(
                  canPop: false,
                  child: AlertDialog(
                    title: const Text('Guncelleme indiriliyor'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text('${updateInfo.version} surumu indiriliyor...'),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: downloadProgress.fraction,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _formatUpdateProgress(downloadProgress),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ).whenComplete(() {
          progressDialogVisible = false;
          updateProgressDialog = null;
        });
    unawaited(progressDialog);

    try {
      final installerOpened = await widget.dependencies.updateService
          .downloadAndInstall(
            updateInfo,
            onProgress: (progress) {
              downloadProgress = progress;
              if (mounted) {
                setState(() {
                  _updateProgress = progress;
                  _updateStatusMessage = progress.fraction == null
                      ? 'Guncelleme indiriliyor...'
                      : 'Guncelleme %${(progress.fraction! * 100).round()} indirildi.';
                });
              }
              final updateDialog = updateProgressDialog;
              if (progressDialogVisible && updateDialog != null) {
                updateDialog(() {});
              }
            },
          );
      if (!mounted) {
        return;
      }

      _closeProgressDialog(isVisible: progressDialogVisible);

      setState(() {
        _isDownloadingUpdate = false;
        _isAwaitingInstallation = true;
        _updateProgress = null;
        _updateStatusMessage = installerOpened
            ? 'Kurulum ekrani acildi. Kur secenegine basin.'
            : 'Kurulum iznini verin; kurulum ekrani acilacak.';
      });

      if (!installerOpened) {
        _showMessage(
          'Kurulum izni sayfasi acildi. Izin verilince kurulum ekrani '
          'otomatik acilacak.',
        );
      } else {
        _showMessage(
          'APK dogrulandi. Kurulum ekraninda Kur secenegine basin; '
          'kurulumu iptal ederseniz guncelleme yeniden gosterilir.',
        );
      }
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      _closeProgressDialog(isVisible: progressDialogVisible);
      setState(() {
        _isDownloadingUpdate = false;
        _updateProgress = null;
        _updateStatusMessage = error.message ?? 'Guncelleme indirilemedi.';
      });
      _showMessage(error.message ?? 'Guncelleme indirilemedi.');
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      _closeProgressDialog(isVisible: progressDialogVisible);
      setState(() {
        _isDownloadingUpdate = false;
        _updateProgress = null;
        _updateStatusMessage = 'Guncelleme indirilemedi.';
      });
      _showMessage('Guncelleme indirilemedi: $error');
    }
  }

  Future<void> _refreshInstalledVersion() async {
    final installed = await widget.dependencies.updateService
        .getInstalledVersion();
    if (!mounted || installed == null) {
      return;
    }

    setState(() => _installedVersion = installed);
  }

  Future<void> _verifyInstalledVersionAfterResume() async {
    final expectedUpdate = _availableUpdate;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    await _refreshInstalledVersion();
    if (!mounted || expectedUpdate == null || !_isAwaitingInstallation) {
      return;
    }

    final installed = _installedVersion;
    final installedBuild = installed?.buildNumber;
    final expectedBuild = expectedUpdate.buildNumber;
    final installationCompleted =
        expectedBuild != null && installedBuild != null
        ? installedBuild >= expectedBuild
        : installed?.version.trim() == expectedUpdate.version.trim();

    setState(() {
      _isAwaitingInstallation = false;
      if (installationCompleted) {
        _availableUpdate = null;
        _updateStatusMessage = 'Guncelleme tamamlandi.';
      } else {
        _updateStatusMessage =
            'Kurulum tamamlanmadi. Guncelle ile yeniden deneyin.';
      }
    });

    _showMessage(
      installationCompleted
          ? 'Guncelleme tamamlandi: ${installed?.label ?? expectedUpdate.versionLabel}'
          : 'Kurulum tamamlanmadi. Home ekranindan yeniden deneyebilirsiniz.',
    );
  }

  String _formatUpdateProgress(AppUpdateDownloadProgress progress) {
    final downloaded = _formatBytes(progress.bytesRead);
    if (!progress.hasTotal) {
      return '$downloaded indirildi';
    }

    final percent = (progress.fraction! * 100).clamp(0, 100).toStringAsFixed(0);
    return '$percent% - $downloaded / ${_formatBytes(progress.totalBytes)}';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 MB';
    }

    const bytesInKb = 1024;
    const bytesInMb = bytesInKb * 1024;
    if (bytes >= bytesInMb) {
      final value = bytes / bytesInMb;
      return '${value.toStringAsFixed(value >= 10 ? 1 : 2)} MB';
    }

    final value = bytes / bytesInKb;
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} KB';
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
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FurpaStartupLockup(),
                SizedBox(height: 26),
                SizedBox(
                  width: 112,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                    color: FurpaBrandColors.navy,
                    backgroundColor: Color(0xFFDDE2EE),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Oturum hazirlaniyor...',
                  style: TextStyle(
                    color: FurpaBrandColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
