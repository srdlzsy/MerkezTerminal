import 'dart:math' as math;

import 'package:furpa_merkez_terminal/core/storage/local_json_database.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';

class OfflineLookupCacheRepository {
  OfflineLookupCacheRepository({LocalJsonDatabase? database})
    : _database = database ?? LocalJsonDatabase();

  final LocalJsonDatabase _database;

  static const String _customerTable = 'offline_lookup_cache.customers.v1';
  static const String _acceptanceProductTable =
      'offline_lookup_cache.acceptance_products.v1';
  static const String _inventoryProductTable =
      'offline_lookup_cache.inventory_products.v1';

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

  Future<void> cacheAcceptanceProducts({
    required String userId,
    required String warehouseNo,
    required String? customerCode,
    required List<SearchProductLookupItem> items,
  }) async {
    final rows = await _database.readTable(_acceptanceProductTable);
    final now = DateTime.now().toUtc().toIso8601String();
    final normalizedCustomerCode = customerCode?.trim() ?? '';
    final updated = _mergeRows(
      existing: rows,
      incoming: items
          .map((item) {
            return <String, dynamic>{
              'userId': userId,
              'warehouseNo': warehouseNo,
              'customerCode': normalizedCustomerCode,
              'barcode': item.barcode,
              'stockCode': item.stockCode,
              'stockName': item.stockName,
              'price': item.price,
              'priceTypeCode': item.priceTypeCode,
              'unitName': item.unitName,
              'unitMultiplier': item.unitMultiplier,
              'secondaryUnitName': item.secondaryUnitName,
              'secondaryUnitMultiplier': item.secondaryUnitMultiplier,
              'salesBlockCode': item.salesBlockCode,
              'orderBlockCode': item.orderBlockCode,
              'goodsAcceptanceBlockCode': item.goodsAcceptanceBlockCode,
              'isSalesBlocked': item.isSalesBlocked,
              'isOrderBlocked': item.isOrderBlocked,
              'isGoodsAcceptanceBlocked': item.isGoodsAcceptanceBlocked,
              'productManagerCode': item.productManagerCode,
              'cachedAt': now,
            };
          })
          .toList(growable: false),
      keyOf: (row) {
        return '${row['userId']}|${row['warehouseNo']}|${row['customerCode']}|'
            '${row['stockCode']}|${row['barcode']}';
      },
      maxCount: 600,
    );
    await _database.writeTable(_acceptanceProductTable, updated);
  }

  Future<List<SearchProductLookupItem>> searchAcceptanceProducts({
    required String userId,
    required String warehouseNo,
    required String query,
    String? customerCode,
  }) async {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return const <SearchProductLookupItem>[];
    }

    final normalizedCustomerCode = customerCode?.trim() ?? '';
    final rows = await _database.readTable(_acceptanceProductTable);
    final filtered =
        rows
            .where(
              (row) =>
                  row['userId']?.toString() == userId &&
                  row['warehouseNo']?.toString() == warehouseNo &&
                  _matchesCustomerCode(
                    cachedCustomerCode: row['customerCode']?.toString() ?? '',
                    requestedCustomerCode: normalizedCustomerCode,
                  ) &&
                  _productSearchKey(row).contains(normalizedQuery),
            )
            .toList(growable: false)
          ..sort((left, right) {
            final customerPriority =
                _customerPriority(
                  cachedCustomerCode: left['customerCode']?.toString() ?? '',
                  requestedCustomerCode: normalizedCustomerCode,
                ).compareTo(
                  _customerPriority(
                    cachedCustomerCode: right['customerCode']?.toString() ?? '',
                    requestedCustomerCode: normalizedCustomerCode,
                  ),
                );
            if (customerPriority != 0) {
              return customerPriority;
            }
            return _compareCachedRows(left, right);
          });

    return filtered
        .take(20)
        .map(_acceptanceProductFromRow)
        .toList(growable: false);
  }

  Future<void> cacheInventoryProducts({
    required String userId,
    required String warehouseNo,
    required List<InventoryCountProductLookupItem> items,
  }) async {
    final rows = await _database.readTable(_inventoryProductTable);
    final now = DateTime.now().toUtc().toIso8601String();
    final updated = _mergeRows(
      existing: rows,
      incoming: items
          .map((item) {
            return <String, dynamic>{
              'userId': userId,
              'warehouseNo': warehouseNo,
              'barcode': item.barcode,
              'stockCode': item.stockCode,
              'stockName': item.stockName,
              'unitName': item.unitName,
              'price': item.price,
              'isGoodsAcceptanceBlocked': item.isGoodsAcceptanceBlocked,
              'cachedAt': now,
            };
          })
          .toList(growable: false),
      keyOf: (row) =>
          '${row['userId']}|${row['warehouseNo']}|${row['stockCode']}|'
          '${row['barcode']}',
      maxCount: 600,
    );
    await _database.writeTable(_inventoryProductTable, updated);
  }

  Future<List<InventoryCountProductLookupItem>> searchInventoryProducts({
    required String userId,
    required String warehouseNo,
    required String query,
  }) async {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return const <InventoryCountProductLookupItem>[];
    }

    final rows = await _database.readTable(_inventoryProductTable);
    final filtered =
        rows
            .where(
              (row) =>
                  row['userId']?.toString() == userId &&
                  row['warehouseNo']?.toString() == warehouseNo &&
                  _productSearchKey(row).contains(normalizedQuery),
            )
            .toList(growable: false)
          ..sort(_compareCachedRows);

    return filtered
        .take(20)
        .map(_inventoryProductFromRow)
        .toList(growable: false);
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

  bool _matchesCustomerCode({
    required String cachedCustomerCode,
    required String requestedCustomerCode,
  }) {
    if (requestedCustomerCode.isEmpty) {
      return true;
    }
    return cachedCustomerCode.isEmpty ||
        cachedCustomerCode == requestedCustomerCode;
  }

  int _customerPriority({
    required String cachedCustomerCode,
    required String requestedCustomerCode,
  }) {
    if (requestedCustomerCode.isEmpty) {
      return 0;
    }
    if (cachedCustomerCode == requestedCustomerCode) {
      return 0;
    }
    if (cachedCustomerCode.isEmpty) {
      return 1;
    }
    return 2;
  }

  String _customerSearchKey(Map<String, dynamic> row) {
    return _normalize(
      '${row['customerCode']} ${row['customerDisplayName']} '
      '${row['customerName']} ${row['customerTitle']} ${row['taxNumber']} '
      '${row['representativeName']}',
    );
  }

  String _productSearchKey(Map<String, dynamic> row) {
    return _normalize(
      '${row['stockCode']} ${row['stockName']} ${row['barcode']}',
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

  SearchProductLookupItem _acceptanceProductFromRow(Map<String, dynamic> row) {
    return SearchProductLookupItem(
      warehouseNo: _readInt(row['warehouseNo']),
      barcode: row['barcode']?.toString() ?? '',
      stockCode: row['stockCode']?.toString() ?? '',
      stockName: row['stockName']?.toString() ?? '',
      price: _readDouble(row['price']),
      priceTypeCode: _readInt(row['priceTypeCode']),
      unitName: row['unitName']?.toString() ?? '',
      unitMultiplier: _readDouble(row['unitMultiplier']),
      secondaryUnitName: row['secondaryUnitName']?.toString() ?? '',
      secondaryUnitMultiplier: _readDouble(row['secondaryUnitMultiplier']),
      salesBlockCode: _readNullableInt(row['salesBlockCode']),
      orderBlockCode: _readNullableInt(row['orderBlockCode']),
      goodsAcceptanceBlockCode: _readNullableInt(
        row['goodsAcceptanceBlockCode'],
      ),
      isSalesBlocked: _readBool(row['isSalesBlocked']),
      isOrderBlocked: _readBool(row['isOrderBlocked']),
      isGoodsAcceptanceBlocked: _readBool(row['isGoodsAcceptanceBlocked']),
      productManagerCode: row['productManagerCode']?.toString() ?? '',
    );
  }

  InventoryCountProductLookupItem _inventoryProductFromRow(
    Map<String, dynamic> row,
  ) {
    return InventoryCountProductLookupItem(
      warehouseNo: _readInt(row['warehouseNo']),
      barcode: row['barcode']?.toString() ?? '',
      stockCode: row['stockCode']?.toString() ?? '',
      stockName: row['stockName']?.toString() ?? '',
      unitName: row['unitName']?.toString() ?? '',
      price: _readDouble(row['price']),
      isGoodsAcceptanceBlocked: _readBool(row['isGoodsAcceptanceBlocked']),
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

  double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _readInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int? _readNullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }
}
