import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';

void main() {
  test('visiblePermissionModules keeps only page or manage route menus', () {
    const module = PermissionModule(
      code: 'ortak-islemler',
      name: 'OrtakIslemler',
      menus: <PermissionMenu>[
        PermissionMenu(
          code: 'sikayet-oneri',
          name: 'SikayetOneri',
          actions: <PermissionAction>[
            PermissionAction(
              code: 'list',
              name: 'Listele',
              permissionCode: 'ortak-islemler.sikayet-oneri.list',
            ),
          ],
        ),
        PermissionMenu(
          code: 'duyurular',
          name: 'Duyurular',
          actions: <PermissionAction>[
            PermissionAction(
              code: 'page',
              name: 'Ekran',
              permissionCode: 'ortak-islemler.duyurular.page',
            ),
            PermissionAction(
              code: 'list',
              name: 'Listele',
              permissionCode: 'ortak-islemler.duyurular.list',
            ),
          ],
        ),
        PermissionMenu(
          code: 'product-case-profiles',
          name: 'ProductCaseProfiles',
          actions: <PermissionAction>[
            PermissionAction(
              code: 'manage',
              name: 'Yonet',
              permissionCode: 'green-grocer.product-case-profiles.manage',
            ),
          ],
        ),
      ],
    );

    final modules = visiblePermissionModules(const <PermissionModule>[module]);

    expect(modules, hasLength(1));
    expect(
      modules.single.menus.map((menu) => menu.code),
      containsAllInOrder(<String>['duyurular', 'product-case-profiles']),
    );
    expect(
      modules.single.menus.map((menu) => menu.code),
      isNot(contains('sikayet-oneri')),
    );
  });

  test('visiblePermissionModules can use flat page permission fallback', () {
    const module = PermissionModule(
      code: 'kasa-islemleri',
      name: 'KasaIslemleri',
      menus: <PermissionMenu>[
        PermissionMenu(
          code: 'manav-kunye-etiket-yazdirma',
          name: 'ManavKunyeEtiketYazdirma',
          actions: <PermissionAction>[
            PermissionAction(
              code: 'list',
              name: 'Listele',
              permissionCode: 'kasa-islemleri.manav-kunye-etiket-yazdirma.list',
            ),
          ],
        ),
      ],
    );

    final modules = visiblePermissionModules(
      const <PermissionModule>[module],
      userPermissionCodes: const <String>[
        'kasa-islemleri.manav-kunye-etiket-yazdirma.page',
      ],
    );

    expect(modules.single.menus.single.code, 'manav-kunye-etiket-yazdirma');
  });
}
