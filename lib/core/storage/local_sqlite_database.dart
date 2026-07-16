import 'dart:convert';

import 'package:furpa_merkez_terminal/core/storage/local_database.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class LocalSqliteDatabase implements IndexedLocalDatabase {
  LocalSqliteDatabase({
    Future<String> Function()? databasesPathProvider,
    Future<Database> Function(String databasePath)? openDatabaseProvider,
    SharedPreferencesAsync? legacyPreferences,
  }) : _databasesPathProvider = databasesPathProvider ?? getDatabasesPath,
       _openDatabaseProvider =
           openDatabaseProvider ??
           ((databasePath) => openDatabase(
             databasePath,
             version: _databaseVersion,
             onCreate: (database, _) => _createSchema(database),
             onUpgrade: (database, _, _) => _createSchema(database),
           )),
       _legacyPreferences = legacyPreferences ?? SharedPreferencesAsync();

  static const String _databaseName = 'furpa_terminal_local.db';
  static const int _databaseVersion = 1;
  static const String _rowsTable = 'local_rows';
  static const String _documentsTable = 'local_documents';
  static const String _migrationMarkerKey =
      'local_sqlite_database.legacy_shared_preferences_migration.v1';
  static const Set<String> _legacyTableKeys = <String>{
    'offline_inventory_count_drafts_v1',
    'offline_company_acceptance_drafts_v1',
    'offline_lookup_cache.customers.v1',
    'mobile_product_catalog.items.v1',
  };
  static const String _legacyCatalogMetadataPrefix =
      'mobile_product_catalog.metadata.v1.';

  final Future<String> Function() _databasesPathProvider;
  final Future<Database> Function(String databasePath) _openDatabaseProvider;
  final SharedPreferencesAsync _legacyPreferences;
  Future<Database>? _databaseFuture;

  Future<Database> get _database {
    return _databaseFuture ??= _openAndPrepareDatabase();
  }

  @override
  Future<List<Map<String, dynamic>>> readTable(String key) async {
    final database = await _database;
    final rows = await database.query(
      _rowsTable,
      columns: const <String>['row_json'],
      where: 'table_key = ?',
      whereArgs: <Object?>[key],
      orderBy: 'row_id ASC',
    );

    return rows
        .map((row) => _decodeDocument(row['row_json']?.toString()))
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  @override
  Future<void> writeTable(String key, List<Map<String, dynamic>> rows) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await _replaceTableRows(transaction, key, rows);
    });
  }

  @override
  Future<List<Map<String, dynamic>>> searchIndexedTable(
    String key, {
    String? partitionKey,
    String? normalizedQuery,
    int limit = 50,
  }) async {
    final database = await _database;
    final whereParts = <String>['table_key = ?', 'row_key IS NOT NULL'];
    final whereArgs = <Object?>[key];
    final normalizedPartitionKey = partitionKey?.trim() ?? '';
    final query = normalizedQuery?.trim() ?? '';

    if (normalizedPartitionKey.isNotEmpty) {
      whereParts.add('partition_key = ?');
      whereArgs.add(normalizedPartitionKey);
    }

    if (query.isNotEmpty) {
      whereParts.add("search_key LIKE ? ESCAPE '\\'");
      whereArgs.add('%${_escapeLike(query)}%');
    }

    final rows = await database.query(
      _rowsTable,
      columns: const <String>['row_json'],
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'row_id ASC',
      limit: limit <= 0 ? 50 : limit,
    );

    return rows
        .map((row) => _decodeDocument(row['row_json']?.toString()))
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> findIndexedTableRow(
    String key, {
    String? partitionKey,
    required String lookupKey,
  }) async {
    final normalizedLookupKey = lookupKey.trim();
    if (normalizedLookupKey.isEmpty) {
      return null;
    }

    final database = await _database;
    final whereParts = <String>[
      'table_key = ?',
      'lookup_key = ?',
      'row_key IS NOT NULL',
    ];
    final whereArgs = <Object?>[key, normalizedLookupKey];
    final normalizedPartitionKey = partitionKey?.trim() ?? '';

    if (normalizedPartitionKey.isNotEmpty) {
      whereParts.add('partition_key = ?');
      whereArgs.add(normalizedPartitionKey);
    }

    final rows = await database.query(
      _rowsTable,
      columns: const <String>['row_json'],
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _decodeDocument(rows.first['row_json']?.toString());
  }

  @override
  Future<int> countIndexedRows(String key, {String? partitionKey}) async {
    final database = await _database;
    final whereParts = <String>['table_key = ?', 'row_key IS NOT NULL'];
    final whereArgs = <Object?>[key];
    final normalizedPartitionKey = partitionKey?.trim() ?? '';

    if (normalizedPartitionKey.isNotEmpty) {
      whereParts.add('partition_key = ?');
      whereArgs.add(normalizedPartitionKey);
    }

    final result = await database.rawQuery(
      'SELECT COUNT(*) AS row_count FROM $_rowsTable '
      'WHERE ${whereParts.join(' AND ')}',
      whereArgs,
    );

    return (result.first['row_count'] as int?) ?? 0;
  }

  @override
  Future<void> upsertIndexedRows(String key, List<LocalIndexedRow> rows) async {
    if (rows.isEmpty) {
      return;
    }

    final database = await _database;
    await database.transaction((transaction) async {
      await _upsertIndexedRows(transaction, key, rows);
    });
  }

  @override
  Future<void> replaceIndexedRows(
    String key, {
    required List<LocalIndexedRow> rows,
    String? partitionKey,
  }) async {
    final database = await _database;
    await database.transaction((transaction) async {
      final normalizedPartitionKey = partitionKey?.trim() ?? '';
      if (normalizedPartitionKey.isEmpty) {
        await transaction.delete(
          _rowsTable,
          where: 'table_key = ? AND row_key IS NOT NULL',
          whereArgs: <Object?>[key],
        );
      } else {
        await transaction.delete(
          _rowsTable,
          where: 'table_key = ? AND partition_key = ? AND row_key IS NOT NULL',
          whereArgs: <Object?>[key, normalizedPartitionKey],
        );
      }
      await _upsertIndexedRows(transaction, key, rows);
    });
  }

  @override
  Future<void> deleteIndexedRows(String key, List<String> rowKeys) async {
    final normalizedRowKeys = rowKeys
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    if (normalizedRowKeys.isEmpty) {
      return;
    }

    final database = await _database;
    await database.transaction((transaction) async {
      for (final rowKey in normalizedRowKeys) {
        await transaction.delete(
          _rowsTable,
          where: 'table_key = ? AND row_key = ?',
          whereArgs: <Object?>[key, rowKey],
        );
      }
    });
  }

  @override
  Future<Map<String, dynamic>?> readDocument(String key) async {
    final database = await _database;
    final rows = await database.query(
      _documentsTable,
      columns: const <String>['document_json'],
      where: 'document_key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _decodeDocument(rows.first['document_json']?.toString());
  }

  @override
  Future<void> writeDocument(String key, Map<String, dynamic> document) async {
    final database = await _database;
    await database.insert(_documentsTable, <String, Object?>{
      'document_key': key,
      'document_json': jsonEncode(document),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> remove(String key) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.delete(
        _rowsTable,
        where: 'table_key = ?',
        whereArgs: <Object?>[key],
      );
      await transaction.delete(
        _documentsTable,
        where: 'document_key = ?',
        whereArgs: <Object?>[key],
      );
    });
  }

  Future<Database> _openAndPrepareDatabase() async {
    final databasesPath = await _databasesPathProvider();
    final databasePath = path.join(databasesPath, _databaseName);
    final database = await _openDatabaseProvider(databasePath);
    await _createSchema(database);
    await _migrateLegacySharedPreferences(database);
    return database;
  }

  static Future<void> _createSchema(Database database) async {
    await database.execute('''
CREATE TABLE IF NOT EXISTS $_rowsTable (
  table_key TEXT NOT NULL,
  row_id INTEGER NOT NULL,
  row_key TEXT,
  partition_key TEXT,
  lookup_key TEXT,
  search_key TEXT,
  row_json TEXT NOT NULL,
  PRIMARY KEY (table_key, row_id)
)
''');
    await _ensureColumn(database, _rowsTable, 'row_key', 'TEXT');
    await _ensureColumn(database, _rowsTable, 'partition_key', 'TEXT');
    await _ensureColumn(database, _rowsTable, 'lookup_key', 'TEXT');
    await _ensureColumn(database, _rowsTable, 'search_key', 'TEXT');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_${_rowsTable}_table_key '
      'ON $_rowsTable (table_key)',
    );
    await database.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_${_rowsTable}_row_key '
      'ON $_rowsTable (table_key, row_key) WHERE row_key IS NOT NULL',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_${_rowsTable}_partition_search '
      'ON $_rowsTable (table_key, partition_key, search_key)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_${_rowsTable}_lookup '
      'ON $_rowsTable (table_key, partition_key, lookup_key)',
    );
    await database.execute('''
CREATE TABLE IF NOT EXISTS $_documentsTable (
  document_key TEXT PRIMARY KEY,
  document_json TEXT NOT NULL
)
''');
  }

  static Future<void> _ensureColumn(
    Database database,
    String tableName,
    String columnName,
    String columnType,
  ) async {
    try {
      await database.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnName $columnType',
      );
    } on DatabaseException catch (error) {
      if (!error.toString().toLowerCase().contains('duplicate column')) {
        rethrow;
      }
    }
  }

  Future<void> _migrateLegacySharedPreferences(Database database) async {
    final existingMarker = await database.query(
      _documentsTable,
      columns: const <String>['document_key'],
      where: 'document_key = ?',
      whereArgs: const <Object?>[_migrationMarkerKey],
      limit: 1,
    );
    if (existingMarker.isNotEmpty) {
      return;
    }

    try {
      final keys = await _legacyPreferences.getKeys();
      await database.transaction((transaction) async {
        for (final key in keys) {
          if (_legacyTableKeys.contains(key)) {
            final raw = await _legacyPreferences.getString(key);
            final rows = _decodeList(raw);
            if (rows.isEmpty) {
              continue;
            }
            await _replaceTableRows(transaction, key, rows);
            continue;
          }

          if (key.startsWith(_legacyCatalogMetadataPrefix)) {
            final raw = await _legacyPreferences.getString(key);
            final document = _decodeDocument(raw);
            if (document == null) {
              continue;
            }
            await transaction.insert(_documentsTable, <String, Object?>{
              'document_key': key,
              'document_json': jsonEncode(document),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        await transaction.insert(_documentsTable, <String, Object?>{
          'document_key': _migrationMarkerKey,
          'document_json': jsonEncode(<String, dynamic>{
            'completedAt': DateTime.now().toUtc().toIso8601String(),
          }),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
    } catch (_) {
      await database.insert(_documentsTable, <String, Object?>{
        'document_key': _migrationMarkerKey,
        'document_json': jsonEncode(<String, dynamic>{
          'completedAt': DateTime.now().toUtc().toIso8601String(),
          'legacyPreferencesAvailable': false,
        }),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _replaceTableRows(
    DatabaseExecutor executor,
    String key,
    List<Map<String, dynamic>> rows,
  ) async {
    await executor.delete(
      _rowsTable,
      where: 'table_key = ?',
      whereArgs: <Object?>[key],
    );

    final batch = executor.batch();
    for (var index = 0; index < rows.length; index += 1) {
      batch.insert(_rowsTable, <String, Object?>{
        'table_key': key,
        'row_id': index,
        'row_json': jsonEncode(rows[index]),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _upsertIndexedRows(
    DatabaseExecutor executor,
    String key,
    List<LocalIndexedRow> rows,
  ) async {
    final batch = executor.batch();
    for (final row in rows) {
      final rowKey = row.rowKey.trim();
      if (rowKey.isEmpty) {
        continue;
      }

      batch.insert(_rowsTable, <String, Object?>{
        'table_key': key,
        'row_id': _stableRowId(rowKey),
        'row_key': rowKey,
        'partition_key': _nullableTrimmed(row.partitionKey),
        'lookup_key': _nullableTrimmed(row.lookupKey),
        'search_key': _nullableTrimmed(row.searchKey),
        'row_json': jsonEncode(row.document),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Map<String, dynamic>? _decodeDocument(String? raw) {
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

  static List<Map<String, dynamic>> _decodeList(String? raw) {
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

  static int _stableRowId(String value) {
    const int mask = 0x7fffffffffffffff;
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & mask;
    }
    return hash;
  }

  static String? _nullableTrimmed(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _escapeLike(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }
}
