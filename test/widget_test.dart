import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';
import 'package:furpa_merkez_terminal/features/modules/presentation/views/module_placeholder_page.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';

void main() {
  testWidgets('renders blueprint details for given warehouse orders menu', (
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
      MaterialApp(home: ModulePlaceholderPage(menuEntry: menuEntry)),
    );

    expect(find.text('Verilen Depo Siparisleri'), findsOneWidget);
    expect(
      find.textContaining('/api/siparis-islemleri/verilen-depo-siparisleri'),
      findsWidgets,
    );
    expect(find.text('Listele'), findsOneWidget);
    expect(find.text('Detay'), findsWidgets);
  });
}
