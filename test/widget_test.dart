import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';
import 'package:furpa_merkez_terminal/features/modules/presentation/views/module_placeholder_page.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/widgets/home_dashboard.dart';

void main() {
  testWidgets('renders production placeholder for unmapped menu', (
    WidgetTester tester,
  ) async {
    const module = PermissionModule(
      code: 'siparis-islemleri',
      name: 'SiparisIslemleri',
      menus: <PermissionMenu>[
        PermissionMenu(
          code: 'verilen-depo-siparisleri',
          name: 'VerilenDepoSiparisleri',
          actions: <PermissionAction>[
            PermissionAction(
              code: 'list',
              name: 'Listele',
              permissionCode: 'siparis-islemleri.verilen-depo-siparisleri.list',
            ),
            PermissionAction(
              code: 'detail',
              name: 'Detay',
              permissionCode:
                  'siparis-islemleri.verilen-depo-siparisleri.detail',
            ),
          ],
        ),
      ],
    );
    final menuEntry = MenuEntry.fromPermissionMenu(module, module.menus.first);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 640,
            child: ModulePlaceholderPage(menuEntry: menuEntry),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Verilen Depo Siparisleri'), findsOneWidget);
    expect(
      find.text('Bu ekran terminal uygulamasinda henuz hazir degil.'),
      findsOneWidget,
    );
    expect(find.text('Ekran Durumu'), findsOneWidget);
    expect(find.text('Listele'), findsOneWidget);
    expect(find.textContaining('/api/'), findsNothing);
  });

  testWidgets('home dashboard fits common terminal widths', (
    WidgetTester tester,
  ) async {
    const action = PermissionAction(
      code: 'list',
      name: 'Listele',
      permissionCode: 'stok-islemleri.sayim-sonuclari.list',
    );
    const module = PermissionModule(
      code: 'stok-islemleri',
      name: 'StokIslemleri',
      menus: <PermissionMenu>[
        PermissionMenu(
          code: 'sayim-sonuclari',
          name: 'SayimSonuclari',
          actions: <PermissionAction>[action],
        ),
      ],
    );
    const user = CurrentUser(
      id: '1',
      username: 'terminal',
      email: 'terminal@example.test',
      firstName: 'Terminal',
      lastName: 'Kullanici',
      warehouseNo: '50',
      warehouseName: 'MERKEZ DEPO',
      isActive: true,
      roles: <String>[],
      permissions: <String>[],
      modules: <PermissionModule>[module],
    );
    final menus = <MenuEntry>[
      MenuEntry.fromPermissionMenu(module, module.menus.first),
    ];

    for (final width in <double>[320, 360]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: 640,
              child: HomeDashboard(
                user: user,
                menus: menus,
                onSelectMenu: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Hizli Erisim'), findsOneWidget);
      expect(
        find.text(
          'Islem yapmak icin menuden bir ekran secin veya hizli erisim kartlarini kullanin.',
        ),
        findsOneWidget,
      );
    }
  });
}
