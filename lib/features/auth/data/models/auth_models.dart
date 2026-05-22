import 'package:furpa_merkez_terminal/core/network/api_client.dart';

const Set<String> _hiddenModuleCodes = <String>{
  'entegrasyon-islemleri',
  'entegrasyonislemleri',
  'fatura-islemleri',
  'faturaislemleri',
  'operations',
};

const Set<String> _hiddenMenuRouteKeys = <String>{};

class LoginRequest {
  const LoginRequest({required this.usernameOrEmail, required this.password});

  final String usernameOrEmail;
  final String password;

  JsonMap toJson() {
    return <String, dynamic>{
      'usernameOrEmail': usernameOrEmail,
      'password': password,
    };
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.user,
    this.expiresAtUtc,
    this.refreshToken,
  });

  final String accessToken;
  final CurrentUser user;
  final DateTime? expiresAtUtc;
  final String? refreshToken;

  JsonMap toJson() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'expiresAtUtc': expiresAtUtc?.toIso8601String(),
      'refreshToken': refreshToken,
      'user': user.toJson(),
    };
  }

  factory AuthSession.fromJson(JsonMap json) {
    return AuthSession(
      accessToken: json['accessToken']?.toString() ?? '',
      expiresAtUtc: _readNullableDate(json['expiresAtUtc']),
      refreshToken: _readNullableString(json['refreshToken']),
      user: CurrentUser.fromJson(
        json['user'] as JsonMap? ?? <String, dynamic>{},
      ),
    );
  }
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.expiresAtUtc,
    required this.user,
    this.refreshToken,
  });

  final String accessToken;
  final DateTime expiresAtUtc;
  final CurrentUser user;
  final String? refreshToken;

  factory LoginResponse.fromJson(JsonMap json) {
    return LoginResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      expiresAtUtc: DateTime.parse(
        json['expiresAtUtc']?.toString() ?? DateTime.now().toUtc().toString(),
      ),
      refreshToken: _readNullableString(json['refreshToken']),
      user: CurrentUser.fromJson(
        json['user'] as JsonMap? ?? <String, dynamic>{},
      ),
    );
  }
}

class RefreshTokenResponse {
  const RefreshTokenResponse({
    required this.accessToken,
    this.expiresAtUtc,
    this.refreshToken,
  });

  final String accessToken;
  final DateTime? expiresAtUtc;
  final String? refreshToken;

  factory RefreshTokenResponse.fromJson(JsonMap json) {
    return RefreshTokenResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      expiresAtUtc: _readNullableDate(json['expiresAtUtc']),
      refreshToken: _readNullableString(json['refreshToken']),
    );
  }
}

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.warehouseNo,
    required this.warehouseName,
    required this.isActive,
    required this.roles,
    required this.permissions,
    required this.modules,
  });

  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String warehouseNo;
  final String warehouseName;
  final bool isActive;
  final List<String> roles;
  final List<String> permissions;
  final List<PermissionModule> modules;

  factory CurrentUser.fromJson(JsonMap json) {
    return CurrentUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      warehouseNo: json['warehouseNo']?.toString() ?? '',
      warehouseName: json['warehouseName']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? false,
      roles: (json['roles'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      permissions: (json['permissions'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      modules: (json['modules'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => PermissionModule.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .where(
            (item) =>
                !_hiddenModuleCodes.contains(_normalizeModuleKey(item.code)) &&
                !_hiddenModuleCodes.contains(_normalizeModuleKey(item.name)),
          )
          .toList(growable: false),
    );
  }

  String get fullName {
    final parts = <String>[
      firstName.trim(),
      lastName.trim(),
    ].where((item) => item.isNotEmpty).toList(growable: false);

    if (parts.isEmpty) {
      return username;
    }

    return parts.join(' ');
  }

  bool hasPermission(String permissionCode) {
    return permissions.contains(permissionCode);
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'warehouseNo': warehouseNo,
      'warehouseName': warehouseName,
      'isActive': isActive,
      'roles': roles,
      'permissions': permissions,
      'modules': modules.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

String _normalizeModuleKey(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String _normalizeMenuKey(String moduleCode, String menuCode) {
  return '${_normalizeModuleKey(moduleCode)}.${_normalizeModuleKey(menuCode)}';
}

class PermissionModule {
  const PermissionModule({
    required this.code,
    required this.name,
    required this.menus,
  });

  final String code;
  final String name;
  final List<PermissionMenu> menus;

  factory PermissionModule.fromJson(JsonMap json) {
    final moduleCode = json['code']?.toString() ?? '';
    final moduleName = json['name']?.toString() ?? '';

    return PermissionModule(
      code: moduleCode,
      name: moduleName,
      menus: (json['menus'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => PermissionMenu.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .where(
            (item) => !_hiddenMenuRouteKeys.contains(
              _normalizeMenuKey(moduleCode, item.code),
            ),
          )
          .toList(growable: false),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'code': code,
      'name': name,
      'menus': menus.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class PermissionMenu {
  const PermissionMenu({
    required this.code,
    required this.name,
    required this.actions,
  });

  final String code;
  final String name;
  final List<PermissionAction> actions;

  factory PermissionMenu.fromJson(JsonMap json) {
    return PermissionMenu(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      actions: (json['actions'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => PermissionAction.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'code': code,
      'name': name,
      'actions': actions.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class PermissionAction {
  const PermissionAction({
    required this.code,
    required this.name,
    required this.permissionCode,
    this.description,
  });

  final String code;
  final String name;
  final String permissionCode;
  final String? description;

  factory PermissionAction.fromJson(JsonMap json) {
    return PermissionAction(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      permissionCode: json['permissionCode']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'code': code,
      'name': name,
      'permissionCode': permissionCode,
      'description': description,
    };
  }
}

DateTime? _readNullableDate(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }

  return DateTime.tryParse(raw);
}

String? _readNullableString(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }

  return raw;
}
