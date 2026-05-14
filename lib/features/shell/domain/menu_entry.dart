import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';

class MenuEntry {
  const MenuEntry({
    required this.moduleCode,
    required this.moduleName,
    required this.menuCode,
    required this.menuName,
    required this.actions,
  });

  final String moduleCode;
  final String moduleName;
  final String menuCode;
  final String menuName;
  final List<PermissionAction> actions;

  String get id => '$moduleCode::$menuCode';
  String get displayModuleName =>
      prettifyIdentifier(moduleName, fallback: moduleCode);
  String get displayMenuName =>
      prettifyIdentifier(menuName, fallback: menuCode);

  factory MenuEntry.fromPermissionMenu(
    PermissionModule module,
    PermissionMenu menu,
  ) {
    return MenuEntry(
      moduleCode: module.code,
      moduleName: module.name,
      menuCode: menu.code,
      menuName: menu.name,
      actions: menu.actions,
    );
  }
}

List<MenuEntry> flattenMenus(List<PermissionModule> modules) {
  return modules
      .expand(
        (module) => module.menus.map(
          (menu) => MenuEntry.fromPermissionMenu(module, menu),
        ),
      )
      .toList(growable: false);
}

String prettifyIdentifier(String raw, {required String fallback}) {
  final candidate = raw.trim().isEmpty ? fallback : raw.trim();
  final withSpaces = candidate
      .replaceAll('-', ' ')
      .replaceAll('_', ' ')
      .replaceAllMapped(
        RegExp(r'(?<=[a-z])([A-Z])'),
        (match) => ' ${match.group(0)}',
      );

  return withSpaces
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .join(' ');
}
