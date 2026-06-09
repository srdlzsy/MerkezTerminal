abstract class LocalDatabase {
  Future<List<Map<String, dynamic>>> readTable(String key);

  Future<void> writeTable(String key, List<Map<String, dynamic>> rows);

  Future<Map<String, dynamic>?> readDocument(String key);

  Future<void> writeDocument(String key, Map<String, dynamic> document);

  Future<void> remove(String key);
}
