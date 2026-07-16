abstract class LocalDatabase {
  Future<List<Map<String, dynamic>>> readTable(String key);

  Future<void> writeTable(String key, List<Map<String, dynamic>> rows);

  Future<Map<String, dynamic>?> readDocument(String key);

  Future<void> writeDocument(String key, Map<String, dynamic> document);

  Future<void> remove(String key);
}

class LocalIndexedRow {
  const LocalIndexedRow({
    required this.rowKey,
    required this.document,
    this.partitionKey,
    this.lookupKey,
    this.searchKey,
  });

  final String rowKey;
  final String? partitionKey;
  final String? lookupKey;
  final String? searchKey;
  final Map<String, dynamic> document;
}

abstract class IndexedLocalDatabase implements LocalDatabase {
  Future<List<Map<String, dynamic>>> searchIndexedTable(
    String key, {
    String? partitionKey,
    String? normalizedQuery,
    int limit = 50,
  });

  Future<Map<String, dynamic>?> findIndexedTableRow(
    String key, {
    String? partitionKey,
    required String lookupKey,
  });

  Future<int> countIndexedRows(String key, {String? partitionKey});

  Future<void> upsertIndexedRows(String key, List<LocalIndexedRow> rows);

  Future<void> replaceIndexedRows(
    String key, {
    required List<LocalIndexedRow> rows,
    String? partitionKey,
  });

  Future<void> deleteIndexedRows(String key, List<String> rowKeys);
}
