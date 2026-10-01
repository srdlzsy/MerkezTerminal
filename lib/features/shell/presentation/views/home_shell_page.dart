import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/routing/shell_module_registry.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/view_models/app_session_controller.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/widgets/home_dashboard.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/widgets/module_navigation_panel.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_record_status.dart';
import 'package:furpa_merkez_terminal/shared/widgets/furpa_brand.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({
    super.key,
    required this.sessionController,
    required this.moduleRegistry,
  });

  final AppSessionController sessionController;
  final ShellModuleRegistry moduleRegistry;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage>
    with WidgetsBindingObserver {
  static const Duration _sessionContextRefreshInterval = Duration(minutes: 1);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<MenuEntry> _menuBackStack = <MenuEntry>[];
  MenuEntry? _selectedMenu;
  bool _isSidebarExpanded = false;
  _OfflineQueueSummary _offlineQueueSummary =
      const _OfflineQueueSummary.empty();
  Timer? _offlineSyncTimer;
  Timer? _sessionContextRefreshTimer;
  bool _isWarehouseContextChecking = true;
  bool _isWarehouseContextVerified = false;
  bool _isWarehouseContextUnavailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedMenu = null;
    _offlineSyncTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => unawaited(_triggerOfflineSync()),
    );
    _sessionContextRefreshTimer = Timer.periodic(
      _sessionContextRefreshInterval,
      (_) => unawaited(_refreshWarehouseContext()),
    );
    unawaited(_initializeWarehouseContext());
  }

  @override
  void didUpdateWidget(HomeShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final user = widget.sessionController.currentUser;
    final availableMenus = user == null
        ? const <MenuEntry>[]
        : flattenVisibleMenus(
            user.modules,
            userPermissionCodes: user.permissions,
          );
    _syncMenuStateWithAvailableMenus(availableMenus);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_handleAppResume());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offlineSyncTimer?.cancel();
    _sessionContextRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.sessionController;
    final user = session.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final visibleModules = _visibleModules(user);
    final availableMenus = flattenMenus(visibleModules);
    final isWide = MediaQuery.sizeOf(context).width >= 1080;

    _syncMenuStateWithAvailableMenus(availableMenus);

    final navigationPanel = ModuleNavigationPanel(
      user: user,
      modules: visibleModules,
      selectedMenu: _selectedMenu,
      isExpanded: !isWide || _isSidebarExpanded,
      onToggleExpanded: isWide
          ? () {
              setState(() {
                _isSidebarExpanded = !_isSidebarExpanded;
              });
            }
          : null,
      onHomeTap: _goHome,
      onSelectMenu: (menu) {
        unawaited(_openMenu(menu));
        if (!isWide) {
          Navigator.of(context).pop();
        }
      },
      onSignOut: () => session.signOut(),
    );

    final pageContent = _selectedMenu == null
        ? HomeDashboard(
            user: user,
            menus: availableMenus,
            offlineQueueCount: _offlineQueueSummary.total,
            offlineFailedCount: _offlineQueueSummary.failed,
            onSelectMenu: (menu) => unawaited(_openMenu(menu)),
          )
        : _buildContent(
            selectedMenu: _selectedMenu!,
            session: session,
            user: user,
          );
    final content = _buildWarehouseContextGuard(pageContent);

    if (isWide) {
      return _buildBackAwareScaffold(
        Scaffold(
          key: _scaffoldKey,
          body: SafeArea(
            child: Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: _isSidebarExpanded ? 332 : 92,
                  child: navigationPanel,
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      _WideTopBar(
                        userName: user.fullName,
                        warehouseName: user.warehouseName,
                        offlineQueueSummary: _offlineQueueSummary,
                        isSidebarExpanded: _isSidebarExpanded,
                        onHomeTap: _goHome,
                        onSyncOffline: () => unawaited(_triggerOfflineSync()),
                        onToggleMenu: () {
                          setState(() {
                            _isSidebarExpanded = !_isSidebarExpanded;
                          });
                        },
                        onSignOut: () => session.signOut(),
                      ),
                      Expanded(child: content),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildBackAwareScaffold(
      Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _goHome,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: FurpaBrandLockup(scale: 0.64),
            ),
          ),
          actions: <Widget>[
            if (_offlineQueueSummary.total > 0)
              _OfflineQueueIconButton(
                summary: _offlineQueueSummary,
                onPressed: () => unawaited(_triggerOfflineSync()),
              ),
            IconButton(
              onPressed: _goHome,
              tooltip: 'Anasayfa',
              icon: const Icon(Icons.home_rounded),
            ),
            IconButton(
              onPressed: () => session.signOut(),
              tooltip: 'Cikis yap',
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        drawer: Drawer(child: navigationPanel),
        body: SafeArea(top: false, bottom: true, child: content),
      ),
    );
  }

  void _goHome() {
    setState(() {
      _selectedMenu = null;
      _menuBackStack.clear();
    });
  }

  Future<void> _openMenu(MenuEntry menu) async {
    if (_selectedMenu?.id == menu.id) {
      return;
    }

    if (!_isWarehouseContextVerified) {
      final result = await _refreshWarehouseContext(showProgress: true);
      if (!mounted ||
          result == WarehouseContextGuardResult.signedOut ||
          result == WarehouseContextGuardResult.notAuthenticated) {
        return;
      }
    }

    setState(() {
      final previousMenu = _selectedMenu;
      if (previousMenu != null) {
        _menuBackStack.add(previousMenu);
      }
      _selectedMenu = menu;
    });
  }

  Widget _buildBackAwareScaffold(Widget scaffold) {
    return PopScope<Object?>(
      canPop: !_hasShellBackTarget,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        _handleShellBack();
      },
      child: scaffold,
    );
  }

  bool get _hasShellBackTarget =>
      _selectedMenu != null || _menuBackStack.isNotEmpty;

  void _handleShellBack() {
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState?.isDrawerOpen ?? false) {
      scaffoldState?.closeDrawer();
      return;
    }

    if (_menuBackStack.isNotEmpty) {
      setState(() {
        _selectedMenu = _menuBackStack.removeLast();
      });
      return;
    }

    if (_selectedMenu != null) {
      _goHome();
    }
  }

  void _syncMenuStateWithAvailableMenus(List<MenuEntry> availableMenus) {
    final availableMenuIds = availableMenus.map((item) => item.id).toSet();

    _menuBackStack.removeWhere((menu) => !availableMenuIds.contains(menu.id));

    final selectedMenu = _selectedMenu;
    if (selectedMenu != null && !availableMenuIds.contains(selectedMenu.id)) {
      _selectedMenu = null;
      _menuBackStack.clear();
    }
  }

  List<PermissionModule> _visibleModules(CurrentUser user) {
    return visiblePermissionModules(
      user.modules,
      userPermissionCodes: user.permissions,
    );
  }

  Widget _buildContent({
    required MenuEntry selectedMenu,
    required AppSessionController session,
    required CurrentUser user,
  }) {
    return widget.moduleRegistry.buildPage(
      selectedMenu: selectedMenu,
      user: user,
      accessToken: session.accessToken ?? '',
    );
  }

  Future<void> _triggerOfflineSync() async {
    if (!_isWarehouseContextVerified) {
      final result = await widget.sessionController
          .refreshWarehouseContextGuard();
      if (result != WarehouseContextGuardResult.verified) {
        await _refreshOfflineQueueSummary();
        return;
      }
      if (mounted) {
        setState(() {
          _isWarehouseContextVerified = true;
          _isWarehouseContextUnavailable = false;
        });
      }
    }

    final user = widget.sessionController.currentUser;
    final accessToken = widget.sessionController.accessToken;

    if (user == null) {
      await _refreshOfflineQueueSummary();
      return;
    }

    if (accessToken == null || accessToken.trim().isEmpty) {
      await _refreshOfflineQueueSummary();
      return;
    }

    await widget.moduleRegistry.offlineSyncService.syncPending(
      accessToken: accessToken,
      userId: user.id,
      warehouseNo: user.warehouseNo,
    );
    await _refreshOfflineQueueSummary();
  }

  Future<void> _handleAppResume() async {
    final result = await _refreshWarehouseContext();
    if (result == WarehouseContextGuardResult.verified) {
      await _triggerOfflineSync();
    }
  }

  Future<void> _initializeWarehouseContext() async {
    final result = await _refreshWarehouseContext(showProgress: true);
    if (result == WarehouseContextGuardResult.verified) {
      await _triggerOfflineSync();
    } else {
      await _refreshOfflineQueueSummary();
    }
  }

  Future<WarehouseContextGuardResult> _refreshWarehouseContext({
    bool showProgress = false,
  }) async {
    if (showProgress && mounted) {
      setState(() => _isWarehouseContextChecking = true);
    }

    final result = await widget.sessionController
        .refreshWarehouseContextGuard();
    if (!mounted) {
      return result;
    }

    setState(() {
      _isWarehouseContextChecking = false;
      if (result == WarehouseContextGuardResult.verified) {
        _isWarehouseContextVerified = true;
        _isWarehouseContextUnavailable = false;
      } else if (result == WarehouseContextGuardResult.unavailable &&
          !_isWarehouseContextVerified) {
        _isWarehouseContextUnavailable = true;
      }
    });
    return result;
  }

  Widget _buildWarehouseContextGuard(Widget child) {
    if (_isWarehouseContextChecking && !_isWarehouseContextVerified) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Depo bilgisi dogrulaniyor...'),
          ],
        ),
      );
    }

    if (!_isWarehouseContextUnavailable || _isWarehouseContextVerified) {
      return child;
    }

    return Column(
      children: <Widget>[
        Material(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: <Widget>[
                const Icon(Icons.wifi_off_rounded, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Depo bilgisi dogrulanamadi. Otomatik senkronizasyon '
                    'bekletiliyor; online kayittan once tekrar deneyin.',
                    maxLines: 2,
                  ),
                ),
                TextButton(
                  onPressed: () => unawaited(_initializeWarehouseContext()),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Future<void> _refreshOfflineQueueSummary() async {
    final user = widget.sessionController.currentUser;
    if (user == null) {
      if (mounted && _offlineQueueSummary.total > 0) {
        setState(() {
          _offlineQueueSummary = const _OfflineQueueSummary.empty();
        });
      }
      return;
    }

    try {
      final inventoryDrafts = await widget
          .moduleRegistry
          .offlineInventoryCountsRepository
          .fetchDrafts(userId: user.id, warehouseNo: user.warehouseNo);
      final companyAcceptanceDrafts = await widget
          .moduleRegistry
          .offlineCompanyAcceptancesRepository
          .fetchDrafts(userId: user.id, warehouseNo: user.warehouseNo);
      final summary = _OfflineQueueSummary.fromStatuses(<OfflineRecordStatus>[
        ...inventoryDrafts.map((item) => item.status),
        ...companyAcceptanceDrafts.map((item) => item.status),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _offlineQueueSummary = summary;
      });
    } catch (_) {
      // Minimal fake registries in widget tests do not expose offline stores.
    }
  }
}

class _WideTopBar extends StatelessWidget {
  const _WideTopBar({
    required this.userName,
    required this.warehouseName,
    required this.offlineQueueSummary,
    required this.isSidebarExpanded,
    required this.onHomeTap,
    required this.onSyncOffline,
    required this.onToggleMenu,
    required this.onSignOut,
  });

  final String userName;
  final String warehouseName;
  final _OfflineQueueSummary offlineQueueSummary;
  final bool isSidebarExpanded;
  final VoidCallback onHomeTap;
  final VoidCallback onSyncOffline;
  final VoidCallback onToggleMenu;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onToggleMenu,
            tooltip: isSidebarExpanded ? 'Menuyu daralt' : 'Menuyu genislet',
            icon: Icon(
              isSidebarExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onHomeTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: FurpaBrandLockup(scale: 0.68),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$userName | $warehouseName',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF22356A),
                  ),
                ),
              ],
            ),
          ),
          if (offlineQueueSummary.total > 0) ...<Widget>[
            OutlinedButton.icon(
              onPressed: onSyncOffline,
              icon: Icon(
                offlineQueueSummary.failed > 0
                    ? Icons.error_outline_rounded
                    : Icons.cloud_upload_outlined,
              ),
              label: Text(
                offlineQueueSummary.failed > 0
                    ? 'Offline ${offlineQueueSummary.total} / Hata ${offlineQueueSummary.failed}'
                    : 'Offline ${offlineQueueSummary.total}',
              ),
            ),
            const SizedBox(width: 10),
          ],
          OutlinedButton.icon(
            onPressed: onHomeTap,
            icon: const Icon(Icons.home_rounded),
            label: const Text('Anasayfa'),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cikis'),
          ),
        ],
      ),
    );
  }
}

class _OfflineQueueIconButton extends StatelessWidget {
  const _OfflineQueueIconButton({
    required this.summary,
    required this.onPressed,
  });

  final _OfflineQueueSummary summary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: summary.failed > 0
          ? '${summary.total} offline kayit, ${summary.failed} hata. Tekrar dene'
          : '${summary.total} offline kayit senkron bekliyor',
      icon: Badge(
        label: Text(summary.total > 99 ? '99+' : '${summary.total}'),
        child: Icon(
          summary.failed > 0
              ? Icons.error_outline_rounded
              : Icons.cloud_upload_outlined,
        ),
      ),
    );
  }
}

class _OfflineQueueSummary {
  const _OfflineQueueSummary({required this.total, required this.failed});

  const _OfflineQueueSummary.empty() : total = 0, failed = 0;

  final int total;
  final int failed;

  factory _OfflineQueueSummary.fromStatuses(
    Iterable<OfflineRecordStatus> statuses,
  ) {
    var total = 0;
    var failed = 0;
    for (final status in statuses) {
      total += 1;
      if (status == OfflineRecordStatus.failed) {
        failed += 1;
      }
    }

    return _OfflineQueueSummary(total: total, failed: failed);
  }
}
