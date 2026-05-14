import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalJsonDatabase {
  LocalJsonDatabase({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  Future<List<Map<String, dynamic>>> readTable(String key) async {
    final raw = await _preferences.getString(key);
    return _decodeList(raw);
  }

  Future<void> writeTable(String key, List<Map<String, dynamic>> rows) async {
    await _preferences.setString(key, jsonEncode(rows));
  }

  Future<Map<String, dynamic>?> readDocument(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (mapKey, value) => MapEntry(mapKey.toString(), value),
        );
      }
    } on FormatException {
      return null;
    }

    return null;
  }

  Future<void> writeDocument(String key, Map<String, dynamic> document) async {
    await _preferences.setString(key, jsonEncode(document));
  }

  Future<void> remove(String key) {
    return _preferences.remove(key);
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <Map<String, dynamic>>[];
      }

      return decoded
          .whereType<Object?>()
          .map(
            (item) => switch (item) {
              final Map<String, dynamic> map => map,
              final Map map => map.map(
                (mapKey, value) => MapEntry(mapKey.toString(), value),
              ),
              _ => <String, dynamic>{},
            },
          )
          .toList(growable: false);
    } on FormatException {
      return const <Map<String, dynamic>>[];
    }
  }
}
