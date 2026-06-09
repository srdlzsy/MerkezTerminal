import 'package:furpa_merkez_terminal/core/storage/local_database.dart';

class MemoryLocalDatabase implements LocalDatabase {
  final Map<String, List<Map<String, dynamic>>> _tables =
      <String, List<Map<String, dynamic>>>{};
  final Map<String, Map<String, dynamic>> _documents =
      <String, Map<String, dynamic>>{};

  @override
  Future<List<Map<String, dynamic>>> readTable(String key) async {
    final rows = _tables[key] ?? const <Map<String, dynamic>>[];
    return rows.map(_copyMap).toList(growable: false);
  }

  @override
  Future<void> writeTable(String key, List<Map<String, dynamic>> rows) async {
    _tables[key] = rows.map(_copyMap).toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> readDocument(String key) async {
    final document = _documents[key];
    return document == null ? null : _copyMap(document);
  }

  @override
  Future<void> writeDocument(String key, Map<String, dynamic> document) async {
    _documents[key] = _copyMap(document);
  }

  @override
  Future<void> remove(String key) async {
    _tables.remove(key);
    _documents.remove(key);
  }

  Map<String, dynamic> _copyMap(Map<String, dynamic> value) {
    return Map<String, dynamic>.from(value);
  }
}
