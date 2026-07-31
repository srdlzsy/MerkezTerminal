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

List<PermissionModule> visiblePermissionModules(
  List<PermissionModule> modules, {
  Iterable<String> userPermissionCodes = const <String>[],
}) {
  final normalizedUserPermissionCodes = userPermissionCodes
      .map(_normalizePermissionCode)
      .where((item) => item.isNotEmpty)
      .toSet();

  return modules
      .map(
        (module) => PermissionModule(
          code: module.code,
          name: module.name,
          menus: module.menus
              .where(
                (menu) => hasMenuRoutePermission(
                  module: module,
                  menu: menu,
                  normalizedUserPermissionCodes: normalizedUserPermissionCodes,
                ),
              )
              .toList(growable: false),
        ),
      )
      .where((module) => module.menus.isNotEmpty)
      .toList(growable: false);
}

List<MenuEntry> flattenVisibleMenus(
  List<PermissionModule> modules, {
  Iterable<String> userPermissionCodes = const <String>[],
}) {
  return flattenMenus(
    visiblePermissionModules(modules, userPermissionCodes: userPermissionCodes),
  );
}

bool hasMenuRoutePermission({
  required PermissionModule module,
  required PermissionMenu menu,
  Set<String> normalizedUserPermissionCodes = const <String>{},
}) {
  if (menu.actions.any(_isMenuRouteAction)) {
    return true;
  }

  final normalizedRoutePermissions = <String>{
    _normalizePermissionCode('${module.code}.${menu.code}.page'),
    _normalizePermissionCode('${module.code}.${menu.code}.manage'),
  };

  return normalizedRoutePermissions.any(normalizedUserPermissionCodes.contains);
}

bool _isMenuRouteAction(PermissionAction action) {
  final normalizedActionCode = action.code.trim().toLowerCase();
  if (normalizedActionCode == 'page' || normalizedActionCode == 'manage') {
    return true;
  }

  final normalizedPermissionCode = _normalizePermissionCode(
    action.permissionCode,
  );

  return normalizedPermissionCode.endsWith('.page') ||
      normalizedPermissionCode.endsWith('.manage');
}

String _normalizePermissionCode(String value) {
  return value.trim().toLowerCase();
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
