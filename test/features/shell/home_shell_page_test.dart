import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/storage/token_storage.dart';
import 'package:furpa_merkez_terminal/features/auth/data/auth_repository.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/routing/shell_module_registry.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/view_models/app_session_controller.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/views/home_shell_page.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  testWidgets('terminal back navigates menu history before leaving the shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = _buildSession();
    final sessionController = AppSessionController(
      authRepository: _FakeAuthRepository(session),
    );
    await sessionController.signIn(usernameOrEmail: 'demo', password: '1234');

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShellPage(
          sessionController: sessionController,
          moduleRegistry: _FakeShellModuleRegistry(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Birinci Menu').first);
    await tester.pump();
    expect(find.text('Content: Birinci Menu'), findsOneWidget);

    await tester.tap(find.byTooltip('Menuyu genislet'));
    await tester.pump();

    await tester.tap(find.text('Ikinci Menu').first);
    await tester.pump();
    expect(find.text('Content: Ikinci Menu'), findsOneWidget);

    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));

    // ignore: avoid_dynamic_calls
    expect(await widgetsAppState.didPopRoute(), isTrue);
    await tester.pump();
    expect(find.text('Content: Birinci Menu'), findsOneWidget);

    // ignore: avoid_dynamic_calls
    expect(await widgetsAppState.didPopRoute(), isTrue);
    await tester.pump();
    expect(find.text('Tum Menuler'), findsOneWidget);
    expect(find.text('Content: Birinci Menu'), findsNothing);
  });

  testWidgets('shows home while warehouse verification guards offline sync', (
    tester,
  ) async {
    final session = _buildSession();
    final warehouseContextCompleter = Completer<WarehouseContext>();
    final repository = _FakeAuthRepository(
      session,
      warehouseContextCompleter: warehouseContextCompleter,
    );
    final sessionController = AppSessionController(authRepository: repository);
    final registry = _FakeShellModuleRegistry();
    await sessionController.signIn(usernameOrEmail: 'demo', password: '1234');

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShellPage(
          sessionController: sessionController,
          moduleRegistry: registry,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Tum Menuler'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(registry.syncCallCount, 0);

    warehouseContextCompleter.complete(_verifiedWarehouseContext());
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(registry.syncCallCount, 1);
  });

  testWidgets(
    'later warehouse verification failure blocks menu and shows warning',
    (tester) async {
      final session = _buildSession();
      final repository = _FakeAuthRepository(session);
      final sessionController = AppSessionController(
        authRepository: repository,
      );
      final registry = _FakeShellModuleRegistry();
      await sessionController.signIn(usernameOrEmail: 'demo', password: '1234');

      await tester.pumpWidget(
        MaterialApp(
          home: HomeShellPage(
            sessionController: sessionController,
            moduleRegistry: registry,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(registry.syncCallCount, 1);

      repository.warehouseContextError = const ApiException(
        statusCode: 0,
        title: 'Baglanti Hatasi',
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.textContaining('Depo bilgisi dogrulanamadi'), findsOneWidget);

      await tester.tap(find.text('Birinci Menu').first);
      await tester.pumpAndSettle();

      expect(find.text('Content: Birinci Menu'), findsNothing);
      expect(registry.syncCallCount, 1);
    },
  );
}

class _FakeShellModuleRegistry implements ShellModuleRegistry {
  final _NoopOfflineSyncService _offlineSyncService = _NoopOfflineSyncService();

  int get syncCallCount => _offlineSyncService.syncCallCount;

  @override
  OfflineSyncService get offlineSyncService => _offlineSyncService;

  @override
  Widget buildPage({
    required MenuEntry selectedMenu,
    required CurrentUser user,
    required String accessToken,
  }) {
    return Center(child: Text('Content: ${selectedMenu.displayMenuName}'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopOfflineSyncService implements OfflineSyncService {
  int syncCallCount = 0;

  @override
  Future<void> syncPending({
    required String accessToken,
    required String userId,
    required String warehouseNo,
  }) async {
    syncCallCount += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this._session, {this.warehouseContextCompleter})
    : super(
        apiClient: ApiClient(
          baseUrl: 'http://localhost:5228',
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ),
        tokenStorage: TokenStorage(),
      );

  final AuthSession _session;
  final Completer<WarehouseContext>? warehouseContextCompleter;
  ApiException? warehouseContextError;

  @override
  Future<AuthSession> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    return _session;
  }

  @override
  Future<WarehouseContext> fetchWarehouseContext({String? accessToken}) {
    if (warehouseContextError case final error?) {
      return Future<WarehouseContext>.error(error);
    }
    return warehouseContextCompleter?.future ??
        Future<WarehouseContext>.value(_verifiedWarehouseContext());
  }
}

AuthSession _buildSession() {
  const action = PermissionAction(
    code: 'page',
    name: 'Ekran',
    permissionCode: 'test-modulu.birinci-menu.page',
  );
  const module = PermissionModule(
    code: 'test-modulu',
    name: 'TestModulu',
    menus: <PermissionMenu>[
      PermissionMenu(
        code: 'birinci-menu',
        name: 'BirinciMenu',
        actions: <PermissionAction>[action],
      ),
      PermissionMenu(
        code: 'ikinci-menu',
        name: 'IkinciMenu',
        actions: <PermissionAction>[action],
      ),
    ],
  );

  return AuthSession(
    accessToken: 'token',
    refreshToken: 'refresh',
    expiresAtUtc: DateTime.utc(2026, 5, 22, 12),
    user: const CurrentUser(
      id: 'user-1',
      username: 'demo',
      email: 'demo@example.com',
      firstName: 'Demo',
      lastName: 'User',
      warehouseNo: '110',
      warehouseName: 'KESTEL 1',
      isActive: true,
      roles: <String>['Operator'],
      permissions: <String>[
        'test-modulu.birinci-menu.page',
        'test-modulu.ikinci-menu.page',
      ],
      modules: <PermissionModule>[module],
    ),
  );
}

WarehouseContext _verifiedWarehouseContext() {
  return const WarehouseContext(
    userId: 'user-1',
    username: 'demo',
    tokenWarehouseNo: '110',
    tokenWarehouseName: 'KESTEL 1',
    currentWarehouseNo: '110',
    currentWarehouseName: 'KESTEL 1',
    isTerminalUser: true,
    requiresRelogin: false,
    reason: '',
  );
}
