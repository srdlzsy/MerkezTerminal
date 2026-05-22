import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/routing/shell_module_registry.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/view_models/app_session_controller.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/widgets/home_dashboard.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/widgets/module_navigation_panel.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<MenuEntry> _menuBackStack = <MenuEntry>[];
  MenuEntry? _selectedMenu;
  bool _isSidebarExpanded = false;
  Timer? _offlineSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedMenu = null;
    _offlineSyncTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => unawaited(_triggerOfflineSync()),
    );
    unawaited(_triggerOfflineSync());
  }

  @override
  void didUpdateWidget(HomeShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final user = widget.sessionController.currentUser;
    final availableMenus = _flattenVisibleMenus(
      _visibleModules(user?.modules ?? const <PermissionModule>[]),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.sessionController;
    final user = session.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final visibleModules = _visibleModules(user.modules);
    final availableMenus = _flattenVisibleMenus(visibleModules);
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
        _openMenu(menu);
        if (!isWide) {
          Navigator.of(context).pop();
        }
      },
      onSignOut: () => session.signOut(),
    );

    final content = _selectedMenu == null
        ? HomeDashboard(
            user: user,
            menus: availableMenus,
            onSelectMenu: _openMenu,
          )
        : _buildContent(
            selectedMenu: _selectedMenu!,
            session: session,
            user: user,
          );

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
                        isSidebarExpanded: _isSidebarExpanded,
                        onHomeTap: _goHome,
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

  void _openMenu(MenuEntry menu) {
    if (_selectedMenu?.id == menu.id) {
      return;
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

  List<PermissionModule> _visibleModules(List<PermissionModule> modules) {
    return modules
        .map(
          (module) => PermissionModule(
            code: module.code,
            name: module.name,
            menus: module.menus
                .where((item) => item.actions.isNotEmpty)
                .toList(growable: false),
          ),
        )
        .where((item) => item.menus.isNotEmpty)
        .toList(growable: false);
  }

  List<MenuEntry> _flattenVisibleMenus(List<PermissionModule> modules) {
    return modules
        .expand(
          (module) => module.menus.map(
            (menu) => MenuEntry.fromPermissionMenu(module, menu),
          ),
        )
        .toList(growable: false);
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
    final user = widget.sessionController.currentUser;
    final accessToken = widget.sessionController.accessToken;

    if (user == null || accessToken == null || accessToken.trim().isEmpty) {
      return;
    }

    await widget.moduleRegistry.offlineSyncService.syncPending(
      accessToken: accessToken,
      userId: user.id,
      warehouseNo: user.warehouseNo,
    );
  }

  Future<void> _handleAppResume() async {
    await widget.sessionController.refreshSessionOnResume();
    await _triggerOfflineSync();
  }
}

class _WideTopBar extends StatelessWidget {
  const _WideTopBar({
    required this.userName,
    required this.warehouseName,
    required this.isSidebarExpanded,
    required this.onHomeTap,
    required this.onToggleMenu,
    required this.onSignOut,
  });

  final String userName;
  final String warehouseName;
  final bool isSidebarExpanded;
  final VoidCallback onHomeTap;
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
