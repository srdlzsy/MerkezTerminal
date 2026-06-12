import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/storage/local_database.dart';
import 'package:furpa_merkez_terminal/core/storage/local_sqlite_database.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';

class MobileProductCatalogItem {
  const MobileProductCatalogItem({
    required this.warehouseNo,
    required this.barcode,
    required this.lookupSource,
    required this.stockCode,
    required this.stockName,
    required this.price,
    required this.priceTypeCode,
    required this.unitPointer,
    required this.unitName,
    required this.unitMultiplier,
    required this.secondaryUnitName,
    required this.secondaryUnitMultiplier,
    required this.salesBlockCode,
    required this.orderBlockCode,
    required this.goodsAcceptanceBlockCode,
    required this.isSalesBlocked,
    required this.isOrderBlocked,
    required this.isGoodsAcceptanceBlocked,
    required this.isPassive,
    required this.isDeleted,
    required this.productManagerCode,
    this.updatedAt,
    this.cachedAt,
  });

  final int warehouseNo;
  final String barcode;
  final String lookupSource;
  final String stockCode;
  final String stockName;
  final double price;
  final int priceTypeCode;
  final int unitPointer;
  final String unitName;
  final double unitMultiplier;
  final String secondaryUnitName;
  final double secondaryUnitMultiplier;
  final int? salesBlockCode;
  final int? orderBlockCode;
  final int? goodsAcceptanceBlockCode;
  final bool isSalesBlocked;
  final bool isOrderBlocked;
  final bool isGoodsAcceptanceBlocked;
  final bool isPassive;
  final bool isDeleted;
  final String productManagerCode;
  final DateTime? updatedAt;
  final DateTime? cachedAt;

  String get displayLabel => '$stockCode - $stockName';

  SearchProductLookupItem toSearchProductLookupItem() {
    return SearchProductLookupItem(
      warehouseNo: warehouseNo,
      barcode: barcode,
      stockCode: stockCode,
      stockName: stockName,
      price: price,
      priceTypeCode: priceTypeCode,
      unitName: unitName,
      unitMultiplier: unitMultiplier,
      secondaryUnitName: secondaryUnitName,
      secondaryUnitMultiplier: secondaryUnitMultiplier,
      salesBlockCode: salesBlockCode,
      orderBlockCode: orderBlockCode,
      goodsAcceptanceBlockCode: goodsAcceptanceBlockCode,
      isSalesBlocked: isSalesBlocked,
      isOrderBlocked: isOrderBlocked,
      isGoodsAcceptanceBlocked: isGoodsAcceptanceBlocked,
      productManagerCode: productManagerCode,
    );
  }

  InventoryCountProductLookupItem toInventoryCountProductLookupItem() {
    return InventoryCountProductLookupItem(
      warehouseNo: warehouseNo,
      barcode: barcode,
      stockCode: stockCode,
      stockName: stockName,
      unitName: unitName,
      unitMultiplier: unitMultiplier,
      price: price,
      isGoodsAcceptanceBlocked: isGoodsAcceptanceBlocked,
    );
  }

  MobileProductCatalogItem copyWith({int? warehouseNo, DateTime? cachedAt}) {
    return MobileProductCatalogItem(
      warehouseNo: warehouseNo ?? this.warehouseNo,
      barcode: barcode,
      lookupSource: lookupSource,
      stockCode: stockCode,
      stockName: stockName,
      price: price,
      priceTypeCode: priceTypeCode,
      unitPointer: unitPointer,
      unitName: unitName,
      unitMultiplier: unitMultiplier,
      secondaryUnitName: secondaryUnitName,
      secondaryUnitMultiplier: secondaryUnitMultiplier,
      salesBlockCode: salesBlockCode,
      orderBlockCode: orderBlockCode,
      goodsAcceptanceBlockCode: goodsAcceptanceBlockCode,
      isSalesBlocked: isSalesBlocked,
      isOrderBlocked: isOrderBlocked,
      isGoodsAcceptanceBlocked: isGoodsAcceptanceBlocked,
      isPassive: isPassive,
      isDeleted: isDeleted,
      productManagerCode: productManagerCode,
      updatedAt: updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'warehouseNo': warehouseNo,
      'barcode': barcode,
      'lookupSource': lookupSource,
      'stockCode': stockCode,
      'stockName': stockName,
      'price': price,
      'priceTypeCode': priceTypeCode,
      'unitPointer': unitPointer,
      'unitName': unitName,
      'unitMultiplier': unitMultiplier,
      'secondaryUnitName': secondaryUnitName,
      'secondaryUnitMultiplier': secondaryUnitMultiplier,
      'salesBlockCode': salesBlockCode,
      'orderBlockCode': orderBlockCode,
      'goodsAcceptanceBlockCode': goodsAcceptanceBlockCode,
      'isSalesBlocked': isSalesBlocked,
      'isOrderBlocked': isOrderBlocked,
      'isGoodsAcceptanceBlocked': isGoodsAcceptanceBlocked,
      'isPassive': isPassive,
      'isDeleted': isDeleted,
      'productManagerCode': productManagerCode,
      'updatedAt': updatedAt?.toIso8601String(),
      'cachedAt': cachedAt?.toIso8601String(),
    };
  }

  factory MobileProductCatalogItem.fromJson(JsonMap json) {
    return MobileProductCatalogItem(
      warehouseNo: _readInt(json['warehouseNo']),
      barcode: _readString(json['barcode']),
      lookupSource: _readString(json['lookupSource']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      price: _readDouble(json['price']),
      priceTypeCode: _readInt(json['priceTypeCode']),
      unitPointer: _readInt(json['unitPointer']),
      unitName: _readString(json['unitName']),
      unitMultiplier: _readDouble(json['unitMultiplier']),
      secondaryUnitName: _readString(json['secondaryUnitName']),
      secondaryUnitMultiplier: _readDouble(json['secondaryUnitMultiplier']),
      salesBlockCode: _readNullableInt(json['salesBlockCode']),
      orderBlockCode: _readNullableInt(json['orderBlockCode']),
      goodsAcceptanceBlockCode: _readNullableInt(
        json['goodsAcceptanceBlockCode'],
      ),
      isSalesBlocked: _readBool(json['isSalesBlocked']),
      isOrderBlocked: _readBool(json['isOrderBlocked']),
      isGoodsAcceptanceBlocked: _readBool(json['isGoodsAcceptanceBlocked']),
      isPassive: _readBool(json['isPassive']),
      isDeleted: _readBool(json['isDeleted']),
      productManagerCode: _readString(json['productManagerCode']),
      updatedAt: _readDate(json['updatedAt']),
      cachedAt: _readDate(json['cachedAt']),
    );
  }
}

class MobileProductCatalogPage {
  const MobileProductCatalogPage({
    required this.warehouseNo,
    required this.generatedAt,
    required this.since,
    required this.syncToken,
    required this.nextCursor,
    required this.hasMore,
    required this.pageSize,
    required this.items,
    required this.deletedBarcodes,
  });

  final int warehouseNo;
  final DateTime? generatedAt;
  final String? since;
  final String? syncToken;
  final String? nextCursor;
  final bool hasMore;
  final int pageSize;
  final List<MobileProductCatalogItem> items;
  final List<String> deletedBarcodes;

  factory MobileProductCatalogPage.fromJson(JsonMap json) {
    return MobileProductCatalogPage(
      warehouseNo: _readInt(json['warehouseNo']),
      generatedAt: _readDate(json['generatedAt']),
      since: _readNullableString(json['since']),
      syncToken: _readNullableString(json['syncToken']),
      nextCursor: _readNullableString(json['nextCursor']),
      hasMore: _readBool(json['hasMore']),
      pageSize: _readInt(json['pageSize']),
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => MobileProductCatalogItem.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
      deletedBarcodes:
          (json['deletedBarcodes'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList(growable: false),
    );
  }
}

class MobileProductCatalogMetadata {
  const MobileProductCatalogMetadata({
    required this.warehouseNo,
    required this.syncToken,
    required this.generatedAt,
    required this.lastCompletedAt,
    required this.itemCount,
  });

  final int warehouseNo;
  final String syncToken;
  final DateTime? generatedAt;
  final DateTime lastCompletedAt;
  final int itemCount;

  MobileProductCatalogMetadata copyWith({
    String? syncToken,
    DateTime? generatedAt,
    DateTime? lastCompletedAt,
    int? itemCount,
  }) {
    return MobileProductCatalogMetadata(
      warehouseNo: warehouseNo,
      syncToken: syncToken ?? this.syncToken,
      generatedAt: generatedAt ?? this.generatedAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'warehouseNo': warehouseNo,
      'syncToken': syncToken,
      'generatedAt': generatedAt?.toIso8601String(),
      'lastCompletedAt': lastCompletedAt.toIso8601String(),
      'itemCount': itemCount,
    };
  }

  factory MobileProductCatalogMetadata.fromJson(JsonMap json) {
    return MobileProductCatalogMetadata(
      warehouseNo: _readInt(json['warehouseNo']),
      syncToken: _readString(json['syncToken']),
      generatedAt: _readDate(json['generatedAt']),
      lastCompletedAt:
          _readDate(json['lastCompletedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      itemCount: _readInt(json['itemCount']),
    );
  }
}

abstract class MobileProductCatalogRemoteDataSource {
  Future<MobileProductCatalogPage> fetchPage({
    required String accessToken,
    required String warehouseNo,
    String? since,
    String? cursor,
    int pageSize = 5000,
  });
}

class ApiMobileProductCatalogRemoteDataSource
    implements MobileProductCatalogRemoteDataSource {
  const ApiMobileProductCatalogRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<MobileProductCatalogPage> fetchPage({
    required String accessToken,
    required String warehouseNo,
    String? since,
    String? cursor,
    int pageSize = 5000,
  }) async {
    final normalizedWarehouseNo = warehouseNo.trim();
    final normalizedCursor = cursor?.trim() ?? '';
    final normalizedSince = since?.trim() ?? '';
    final effectivePageSize = pageSize <= 0
        ? 5000
        : pageSize > 10000
        ? 10000
        : pageSize;

    final response = await _apiClient.getJsonMap(
      '/api/mobile-sync/urun-fiyat-katalogu',
      accessToken: accessToken,
      queryParameters: <String, String>{
        if (normalizedWarehouseNo.isNotEmpty)
          'warehouseNo': normalizedWarehouseNo,
        'pageSize': effectivePageSize.toString(),
        if (normalizedCursor.isNotEmpty) 'cursor': normalizedCursor,
        if (normalizedCursor.isEmpty && normalizedSince.isNotEmpty)
          'since': normalizedSince,
      },
    );

    return MobileProductCatalogPage.fromJson(response);
  }
}

class MobileProductCatalogLocalRepository {
  MobileProductCatalogLocalRepository({LocalDatabase? database})
    : _database = database ?? LocalSqliteDatabase();

  final LocalDatabase _database;

  static const String _itemTable = 'mobile_product_catalog.items.v1';
  static const String _metadataKeyPrefix = 'mobile_product_catalog.metadata.v1';

  Future<MobileProductCatalogMetadata?> fetchMetadata({
    required String warehouseNo,
  }) async {
    final normalizedWarehouseNo = _readInt(warehouseNo);
    final document = await _database.readDocument(
      _metadataKey(normalizedWarehouseNo),
    );
    if (document == null) {
      return null;
    }

    return MobileProductCatalogMetadata.fromJson(document);
  }

  Future<List<MobileProductCatalogItem>> searchProducts({
    required String warehouseNo,
    required String query,
    int limit = 20,
  }) async {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return const <MobileProductCatalogItem>[];
    }

    final normalizedWarehouseNo = _readInt(warehouseNo);
    final rows = await _database.readTable(_itemTable);
    final items =
        rows
            .where(
              (row) => _readInt(row['warehouseNo']) == normalizedWarehouseNo,
            )
            .map(MobileProductCatalogItem.fromJson)
            .where((item) => !item.isDeleted)
            .where((item) => _productSearchKey(item).contains(normalizedQuery))
            .toList(growable: false)
          ..sort(
            (left, right) => _searchScore(
              left,
              normalizedQuery,
            ).compareTo(_searchScore(right, normalizedQuery)),
          );

    return items.take(limit).toList(growable: false);
  }

  Future<MobileProductCatalogItem?> findByBarcode({
    required String warehouseNo,
    required String barcode,
  }) async {
    final normalizedBarcode = _normalize(barcode);
    if (normalizedBarcode.isEmpty) {
      return null;
    }

    final normalizedWarehouseNo = _readInt(warehouseNo);
    final rows = await _database.readTable(_itemTable);
    for (final row in rows) {
      if (_readInt(row['warehouseNo']) != normalizedWarehouseNo) {
        continue;
      }
      if (_normalize(row['barcode']?.toString() ?? '') != normalizedBarcode) {
        continue;
      }

      final item = MobileProductCatalogItem.fromJson(row);
      if (!item.isDeleted) {
        return item;
      }
    }

    return null;
  }

  Future<int> countWarehouseItems({required String warehouseNo}) async {
    final normalizedWarehouseNo = _readInt(warehouseNo);
    final rows = await _database.readTable(_itemTable);
    return rows
        .where(
          (row) =>
              _readInt(row['warehouseNo']) == normalizedWarehouseNo &&
              !_readBool(row['isDeleted']),
        )
        .length;
  }

  Future<void> applyCatalogDelta({
    required int warehouseNo,
    required List<MobileProductCatalogItem> items,
    required List<String> deletedBarcodes,
  }) async {
    final rows = await _database.readTable(_itemTable);
    final rowMap = _rowsByKey(rows);
    final now = DateTime.now().toUtc();

    for (final item in items) {
      final normalizedItem = item.copyWith(
        warehouseNo: item.warehouseNo == 0 ? warehouseNo : item.warehouseNo,
        cachedAt: now,
      );
      final key = _itemKey(normalizedItem);
      if (key == null) {
        continue;
      }
      if (normalizedItem.isDeleted) {
        rowMap.remove(key);
        continue;
      }

      rowMap[key] = normalizedItem.toJson();
    }

    for (final barcode in deletedBarcodes) {
      final key = _itemKeyFromValues(
        warehouseNo: warehouseNo,
        barcode: barcode,
        stockCode: '',
      );
      if (key != null) {
        rowMap.remove(key);
      }
    }

    await _database.writeTable(
      _itemTable,
      rowMap.values.toList(growable: false),
    );
  }

  Future<void> replaceWarehouseCatalog({
    required int warehouseNo,
    required List<MobileProductCatalogItem> items,
    required List<String> deletedBarcodes,
    required MobileProductCatalogMetadata metadata,
  }) async {
    final rows = await _database.readTable(_itemTable);
    final otherRows = rows
        .where((row) => _readInt(row['warehouseNo']) != warehouseNo)
        .toList(growable: false);
    final incomingRows = <String, JsonMap>{};
    final now = DateTime.now().toUtc();

    for (final item in items) {
      final normalizedItem = item.copyWith(
        warehouseNo: item.warehouseNo == 0 ? warehouseNo : item.warehouseNo,
        cachedAt: now,
      );
      final key = _itemKey(normalizedItem);
      if (key == null || normalizedItem.isDeleted) {
        continue;
      }
      incomingRows[key] = normalizedItem.toJson();
    }

    for (final barcode in deletedBarcodes) {
      final key = _itemKeyFromValues(
        warehouseNo: warehouseNo,
        barcode: barcode,
        stockCode: '',
      );
      if (key != null) {
        incomingRows.remove(key);
      }
    }

    await _database.writeTable(_itemTable, <JsonMap>[
      ...otherRows,
      ...incomingRows.values,
    ]);
    await saveMetadata(metadata.copyWith(itemCount: incomingRows.length));
  }

  Future<void> saveMetadata(MobileProductCatalogMetadata metadata) async {
    await _database.writeDocument(
      _metadataKey(metadata.warehouseNo),
      metadata.toJson(),
    );
  }

  Map<String, JsonMap> _rowsByKey(List<JsonMap> rows) {
    final rowMap = <String, JsonMap>{};
    for (final row in rows) {
      final key = _itemKeyFromValues(
        warehouseNo: _readInt(row['warehouseNo']),
        barcode: row['barcode']?.toString() ?? '',
        stockCode: row['stockCode']?.toString() ?? '',
      );
      if (key == null) {
        continue;
      }
      rowMap[key] = row;
    }
    return rowMap;
  }

  String _metadataKey(int warehouseNo) {
    return '$_metadataKeyPrefix.$warehouseNo';
  }

  String? _itemKey(MobileProductCatalogItem item) {
    return _itemKeyFromValues(
      warehouseNo: item.warehouseNo,
      barcode: item.barcode,
      stockCode: item.stockCode,
    );
  }

  String? _itemKeyFromValues({
    required int warehouseNo,
    required String barcode,
    required String stockCode,
  }) {
    final normalizedBarcode = _normalize(barcode);
    if (normalizedBarcode.isNotEmpty) {
      return 'b|$warehouseNo|$normalizedBarcode';
    }

    final normalizedStockCode = _normalize(stockCode);
    if (normalizedStockCode.isNotEmpty) {
      return 's|$warehouseNo|$normalizedStockCode';
    }

    return null;
  }

  String _productSearchKey(MobileProductCatalogItem item) {
    return _normalize('${item.barcode} ${item.stockCode} ${item.stockName}');
  }

  int _searchScore(MobileProductCatalogItem item, String normalizedQuery) {
    if (_normalize(item.barcode) == normalizedQuery) {
      return 0;
    }
    if (_normalize(item.stockCode) == normalizedQuery) {
      return 1;
    }
    if (_normalize(item.barcode).startsWith(normalizedQuery)) {
      return 2;
    }
    if (_normalize(item.stockCode).startsWith(normalizedQuery)) {
      return 3;
    }
    return 4;
  }
}

class MobileProductCatalogSyncResult {
  const MobileProductCatalogSyncResult({
    required this.metadata,
    required this.pagesFetched,
    required this.upsertedCount,
    required this.deletedCount,
    required this.wasFullSync,
  });

  final MobileProductCatalogMetadata metadata;
  final int pagesFetched;
  final int upsertedCount;
  final int deletedCount;
  final bool wasFullSync;
}

class MobileProductCatalogSyncService {
  MobileProductCatalogSyncService({
    required MobileProductCatalogRemoteDataSource remoteDataSource,
    required MobileProductCatalogLocalRepository localRepository,
  }) : _remoteDataSource = remoteDataSource,
       _localRepository = localRepository;

  final MobileProductCatalogRemoteDataSource _remoteDataSource;
  final MobileProductCatalogLocalRepository _localRepository;
  bool _isSyncRunning = false;

  bool get isSyncRunning => _isSyncRunning;

  Future<MobileProductCatalogSyncResult> syncCatalog({
    required String accessToken,
    required String warehouseNo,
    int pageSize = 5000,
    bool forceFull = false,
  }) async {
    if (_isSyncRunning) {
      throw const ApiException(
        statusCode: 0,
        title: 'Sync Devam Ediyor',
        detail: 'Urun fiyat katalog sync islemi zaten calisiyor.',
      );
    }

    _isSyncRunning = true;
    try {
      final normalizedWarehouseNo = warehouseNo.trim();
      final warehouseNoAsInt = _readInt(normalizedWarehouseNo);
      final currentMetadata = await _localRepository.fetchMetadata(
        warehouseNo: normalizedWarehouseNo,
      );
      final currentSyncToken = currentMetadata?.syncToken.trim() ?? '';
      final wasFullSync = forceFull || currentSyncToken.isEmpty;
      final fullSyncItems = <MobileProductCatalogItem>[];
      final fullSyncDeletedBarcodes = <String>[];
      var cursor = '';
      var pagesFetched = 0;
      var upsertedCount = 0;
      var deletedCount = 0;
      MobileProductCatalogPage? lastPage;

      do {
        final page = await _remoteDataSource.fetchPage(
          accessToken: accessToken,
          warehouseNo: normalizedWarehouseNo,
          since: wasFullSync ? null : currentSyncToken,
          cursor: cursor.isEmpty ? null : cursor,
          pageSize: pageSize,
        );
        final resolvedWarehouseNo = page.warehouseNo == 0
            ? warehouseNoAsInt
            : page.warehouseNo;

        pagesFetched += 1;
        upsertedCount += page.items.length;
        deletedCount += page.deletedBarcodes.length;
        lastPage = page;

        if (wasFullSync) {
          fullSyncItems.addAll(page.items);
          fullSyncDeletedBarcodes.addAll(page.deletedBarcodes);
        } else {
          await _localRepository.applyCatalogDelta(
            warehouseNo: resolvedWarehouseNo,
            items: page.items,
            deletedBarcodes: page.deletedBarcodes,
          );
        }

        if (!page.hasMore) {
          break;
        }

        final nextCursor = page.nextCursor?.trim() ?? '';
        if (nextCursor.isEmpty) {
          throw const ApiException(
            statusCode: 0,
            title: 'Eksik Cursor',
            detail: 'Katalog devam sayfasi icin nextCursor bos dondu.',
          );
        }
        cursor = nextCursor;
      } while (true);

      final completedPage = lastPage;

      final resolvedWarehouseNo = completedPage.warehouseNo == 0
          ? warehouseNoAsInt
          : completedPage.warehouseNo;
      final now = DateTime.now().toUtc();
      final syncToken = (completedPage.syncToken?.trim().isNotEmpty ?? false)
          ? completedPage.syncToken!.trim()
          : (completedPage.generatedAt ?? now).toIso8601String();
      var metadata = MobileProductCatalogMetadata(
        warehouseNo: resolvedWarehouseNo,
        syncToken: syncToken,
        generatedAt: completedPage.generatedAt,
        lastCompletedAt: now,
        itemCount: 0,
      );

      if (wasFullSync) {
        await _localRepository.replaceWarehouseCatalog(
          warehouseNo: resolvedWarehouseNo,
          items: fullSyncItems,
          deletedBarcodes: fullSyncDeletedBarcodes,
          metadata: metadata,
        );
      } else {
        final itemCount = await _localRepository.countWarehouseItems(
          warehouseNo: resolvedWarehouseNo.toString(),
        );
        metadata = metadata.copyWith(itemCount: itemCount);
        await _localRepository.saveMetadata(metadata);
      }

      final savedMetadata =
          await _localRepository.fetchMetadata(
            warehouseNo: resolvedWarehouseNo.toString(),
          ) ??
          metadata;

      return MobileProductCatalogSyncResult(
        metadata: savedMetadata,
        pagesFetched: pagesFetched,
        upsertedCount: upsertedCount,
        deletedCount: deletedCount,
        wasFullSync: wasFullSync,
      );
    } finally {
      _isSyncRunning = false;
    }
  }
}

DateTime? _readDate(Object? value) {
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

String _readString(Object? value) {
  return value?.toString() ?? '';
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

String _normalize(String value) {
  return value.trim().toLowerCase();
}
