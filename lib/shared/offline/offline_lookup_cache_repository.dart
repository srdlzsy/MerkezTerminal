import 'dart:math' as math;

import 'package:furpa_merkez_terminal/core/storage/local_database.dart';
import 'package:furpa_merkez_terminal/core/storage/local_sqlite_database.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';

class OfflineLookupCacheRepository {
  OfflineLookupCacheRepository({LocalDatabase? database})
    : _database = database ?? LocalSqliteDatabase();

  final LocalDatabase _database;

  static const String _customerTable = 'offline_lookup_cache.customers.v1';

  Future<void> cacheCustomers({
    required String userId,
    required String warehouseNo,
    required List<CustomerLookupItem> items,
  }) async {
    final rows = await _database.readTable(_customerTable);
    final now = DateTime.now().toUtc().toIso8601String();
    final updated = _mergeRows(
      existing: rows,
      incoming: items
          .map((item) {
            return <String, dynamic>{
              'userId': userId,
              'warehouseNo': warehouseNo,
              'customerCode': item.customerCode,
              'customerName': item.customerName,
              'customerTitle': item.customerTitle,
              'customerDisplayName': item.customerDisplayName,
              'taxNumber': item.taxNumber,
              'representativeCode': item.representativeCode,
              'representativeName': item.representativeName,
              'invoiceAddressNo': item.invoiceAddressNo,
              'shippingAddressNo': item.shippingAddressNo,
              'isLocked': item.isLocked,
              'isClosed': item.isClosed,
              'cachedAt': now,
            };
          })
          .toList(growable: false),
      keyOf: (row) =>
          '${row['userId']}|${row['warehouseNo']}|${row['customerCode']}',
      maxCount: 250,
    );
    await _database.writeTable(_customerTable, updated);
  }

  Future<List<CustomerLookupItem>> searchCustomers({
    required String userId,
    required String warehouseNo,
    required String query,
  }) async {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return const <CustomerLookupItem>[];
    }

    final rows = await _database.readTable(_customerTable);
    final filtered =
        rows
            .where(
              (row) =>
                  row['userId']?.toString() == userId &&
                  row['warehouseNo']?.toString() == warehouseNo &&
                  _customerSearchKey(row).contains(normalizedQuery),
            )
            .toList(growable: false)
          ..sort(_compareCachedRows);

    return filtered.take(20).map(_customerFromRow).toList(growable: false);
  }

  List<Map<String, dynamic>> _mergeRows({
    required List<Map<String, dynamic>> existing,
    required List<Map<String, dynamic>> incoming,
    required String Function(Map<String, dynamic> row) keyOf,
    required int maxCount,
  }) {
    final map = <String, Map<String, dynamic>>{
      for (final row in existing) keyOf(row): row,
    };

    for (final row in incoming) {
      map[keyOf(row)] = row;
    }

    final rows = map.values.toList(growable: false)..sort(_compareCachedRows);

    return rows.take(math.max(1, maxCount)).toList(growable: false);
  }

  int _compareCachedRows(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final leftAt = DateTime.tryParse(left['cachedAt']?.toString() ?? '');
    final rightAt = DateTime.tryParse(right['cachedAt']?.toString() ?? '');
    if (leftAt == null && rightAt == null) {
      return 0;
    }
    if (leftAt == null) {
      return 1;
    }
    if (rightAt == null) {
      return -1;
    }
    return rightAt.compareTo(leftAt);
  }

  String _customerSearchKey(Map<String, dynamic> row) {
    return _normalize(
      '${row['customerCode']} ${row['customerDisplayName']} '
      '${row['customerName']} ${row['customerTitle']} ${row['taxNumber']} '
      '${row['representativeName']}',
    );
  }

  CustomerLookupItem _customerFromRow(Map<String, dynamic> row) {
    return CustomerLookupItem(
      customerCode: row['customerCode']?.toString() ?? '',
      customerName: row['customerName']?.toString() ?? '',
      customerTitle: row['customerTitle']?.toString() ?? '',
      customerDisplayName: row['customerDisplayName']?.toString() ?? '',
      taxNumber: row['taxNumber']?.toString() ?? '',
      representativeCode: row['representativeCode']?.toString() ?? '',
      representativeName: row['representativeName']?.toString() ?? '',
      invoiceAddressNo: _readInt(row['invoiceAddressNo']),
      shippingAddressNo: _readInt(row['shippingAddressNo']),
      isLocked: _readBool(row['isLocked']),
      isClosed: _readBool(row['isClosed']),
    );
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  bool _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final raw = value?.toString().trim().toLowerCase();
    return raw == 'true' || raw == '1';
  }

  int _readInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
