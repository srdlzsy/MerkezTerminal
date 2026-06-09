import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/storage/local_database.dart';
import 'package:furpa_merkez_terminal/core/storage/local_sqlite_database.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';

class MobileWarehouseCatalogItem {
  const MobileWarehouseCatalogItem({
    required this.warehouseNo,
    required this.warehouseName,
    required this.companyNo,
    required this.branchNo,
    required this.groupCode,
    required this.warehouseType,
    required this.responsibilityCenterCode,
    required this.projectCode,
    required this.address,
    required this.district,
    required this.province,
    required this.isInventoryExcluded,
    required this.isDeleted,
    this.updatedAt,
    this.cachedAt,
  });

  final int warehouseNo;
  final String warehouseName;
  final int companyNo;
  final int branchNo;
  final String groupCode;
  final int warehouseType;
  final String responsibilityCenterCode;
  final String projectCode;
  final String address;
  final String district;
  final String province;
  final bool isInventoryExcluded;
  final bool isDeleted;
  final DateTime? updatedAt;
  final DateTime? cachedAt;

  WarehouseLookupItem toWarehouseLookupItem() {
    return WarehouseLookupItem(
      warehouseNo: warehouseNo,
      warehouseName: warehouseName,
      address: address,
      district: district,
      province: province,
    );
  }

  MobileWarehouseCatalogItem copyWith({DateTime? cachedAt}) {
    return MobileWarehouseCatalogItem(
      warehouseNo: warehouseNo,
      warehouseName: warehouseName,
      companyNo: companyNo,
      branchNo: branchNo,
      groupCode: groupCode,
      warehouseType: warehouseType,
      responsibilityCenterCode: responsibilityCenterCode,
      projectCode: projectCode,
      address: address,
      district: district,
      province: province,
      isInventoryExcluded: isInventoryExcluded,
      isDeleted: isDeleted,
      updatedAt: updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'warehouseNo': warehouseNo,
      'warehouseName': warehouseName,
      'companyNo': companyNo,
      'branchNo': branchNo,
      'groupCode': groupCode,
      'warehouseType': warehouseType,
      'responsibilityCenterCode': responsibilityCenterCode,
      'projectCode': projectCode,
      'address': address,
      'district': district,
      'province': province,
      'isInventoryExcluded': isInventoryExcluded,
      'isDeleted': isDeleted,
      'updatedAt': updatedAt?.toIso8601String(),
      'cachedAt': cachedAt?.toIso8601String(),
    };
  }

  factory MobileWarehouseCatalogItem.fromJson(JsonMap json) {
    return MobileWarehouseCatalogItem(
      warehouseNo: _readInt(json['warehouseNo']),
      warehouseName: _readString(json['warehouseName']),
      companyNo: _readInt(json['companyNo']),
      branchNo: _readInt(json['branchNo']),
      groupCode: _readString(json['groupCode']),
      warehouseType: _readInt(json['warehouseType']),
      responsibilityCenterCode: _readString(json['responsibilityCenterCode']),
      projectCode: _readString(json['projectCode']),
      address: _readString(json['address']),
      district: _readString(json['district']),
      province: _readString(json['province']),
      isInventoryExcluded: _readBool(json['isInventoryExcluded']),
      isDeleted: _readBool(json['isDeleted']),
      updatedAt: _readDate(json['updatedAt']),
      cachedAt: _readDate(json['cachedAt']),
    );
  }
}

class MobileWarehouseCatalogPage {
  const MobileWarehouseCatalogPage({
    required this.generatedAt,
    required this.since,
    required this.syncToken,
    required this.nextCursor,
    required this.hasMore,
    required this.pageSize,
    required this.items,
    required this.deletedWarehouseNos,
  });

  final DateTime? generatedAt;
  final String? since;
  final String? syncToken;
  final String? nextCursor;
  final bool hasMore;
  final int pageSize;
  final List<MobileWarehouseCatalogItem> items;
  final List<int> deletedWarehouseNos;

  factory MobileWarehouseCatalogPage.fromJson(JsonMap json) {
    return MobileWarehouseCatalogPage(
      generatedAt: _readDate(json['generatedAt']),
      since: _readNullableString(json['since']),
      syncToken: _readNullableString(json['syncToken']),
      nextCursor: _readNullableString(json['nextCursor']),
      hasMore: _readBool(json['hasMore']),
      pageSize: _readInt(json['pageSize']),
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => MobileWarehouseCatalogItem.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
      deletedWarehouseNos:
          (json['deletedWarehouseNos'] as List<dynamic>? ?? const <dynamic>[])
              .map(_readInt)
              .where((item) => item > 0)
              .toList(growable: false),
    );
  }
}

class MobileWarehouseCatalogMetadata {
  const MobileWarehouseCatalogMetadata({
    required this.syncToken,
    required this.generatedAt,
    required this.lastCompletedAt,
    required this.itemCount,
  });

  final String syncToken;
  final DateTime? generatedAt;
  final DateTime lastCompletedAt;
  final int itemCount;

  MobileWarehouseCatalogMetadata copyWith({
    String? syncToken,
    DateTime? generatedAt,
    DateTime? lastCompletedAt,
    int? itemCount,
  }) {
    return MobileWarehouseCatalogMetadata(
      syncToken: syncToken ?? this.syncToken,
      generatedAt: generatedAt ?? this.generatedAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'syncToken': syncToken,
      'generatedAt': generatedAt?.toIso8601String(),
      'lastCompletedAt': lastCompletedAt.toIso8601String(),
      'itemCount': itemCount,
    };
  }

  factory MobileWarehouseCatalogMetadata.fromJson(JsonMap json) {
    return MobileWarehouseCatalogMetadata(
      syncToken: _readString(json['syncToken']),
      generatedAt: _readDate(json['generatedAt']),
      lastCompletedAt:
          _readDate(json['lastCompletedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      itemCount: _readInt(json['itemCount']),
    );
  }
}

abstract class MobileWarehouseCatalogRemoteDataSource {
  Future<MobileWarehouseCatalogPage> fetchPage({
    required String accessToken,
    String? since,
    String? cursor,
    int pageSize = 5000,
  });
}

class ApiMobileWarehouseCatalogRemoteDataSource
    implements MobileWarehouseCatalogRemoteDataSource {
  const ApiMobileWarehouseCatalogRemoteDataSource({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<MobileWarehouseCatalogPage> fetchPage({
    required String accessToken,
    String? since,
    String? cursor,
    int pageSize = 5000,
  }) async {
    final normalizedCursor = cursor?.trim() ?? '';
    final normalizedSince = since?.trim() ?? '';
    final effectivePageSize = pageSize <= 0
        ? 5000
        : pageSize > 10000
        ? 10000
        : pageSize;
    final response = await _apiClient.getJsonMap(
      '/api/mobile-sync/depo-katalogu',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'pageSize': effectivePageSize.toString(),
        if (normalizedCursor.isNotEmpty) 'cursor': normalizedCursor,
        if (normalizedCursor.isEmpty && normalizedSince.isNotEmpty)
          'since': normalizedSince,
      },
    );

    return MobileWarehouseCatalogPage.fromJson(response);
  }
}

class MobileWarehouseCatalogLocalRepository {
  MobileWarehouseCatalogLocalRepository({LocalDatabase? database})
    : _database = database ?? LocalSqliteDatabase();

  final LocalDatabase _database;

  static const String _itemTable = 'mobile_warehouse_catalog.items.v1';
  static const String _metadataKey = 'mobile_warehouse_catalog.metadata.v1';

  Future<MobileWarehouseCatalogMetadata?> fetchMetadata() async {
    final document = await _database.readDocument(_metadataKey);
    if (document == null) {
      return null;
    }
    return MobileWarehouseCatalogMetadata.fromJson(document);
  }

  Future<List<MobileWarehouseCatalogItem>> searchWarehouses({
    required String query,
    int limit = 50,
  }) async {
    final normalizedQuery = _normalize(query);
    final rows = await _database.readTable(_itemTable);
    final items =
        rows
            .map(MobileWarehouseCatalogItem.fromJson)
            .where((item) => !item.isDeleted)
            .where(
              (item) =>
                  normalizedQuery.isEmpty ||
                  _warehouseSearchKey(item).contains(normalizedQuery),
            )
            .toList(growable: false)
          ..sort(
            (left, right) => _searchScore(
              left,
              normalizedQuery,
            ).compareTo(_searchScore(right, normalizedQuery)),
          );

    return items.take(limit).toList(growable: false);
  }

  Future<int> countItems() async {
    final rows = await _database.readTable(_itemTable);
    return rows.where((row) => !_readBool(row['isDeleted'])).length;
  }

  Future<void> applyCatalogDelta({
    required List<MobileWarehouseCatalogItem> items,
    required List<int> deletedWarehouseNos,
  }) async {
    final rows = await _database.readTable(_itemTable);
    final rowMap = _rowsByKey(rows);
    final now = DateTime.now().toUtc();

    for (final item in items) {
      final key = _itemKey(item.warehouseNo);
      if (key == null) {
        continue;
      }
      if (item.isDeleted) {
        rowMap.remove(key);
        continue;
      }
      rowMap[key] = item.copyWith(cachedAt: now).toJson();
    }

    for (final warehouseNo in deletedWarehouseNos) {
      final key = _itemKey(warehouseNo);
      if (key != null) {
        rowMap.remove(key);
      }
    }

    await _database.writeTable(
      _itemTable,
      rowMap.values.toList(growable: false),
    );
  }

  Future<void> replaceCatalog({
    required List<MobileWarehouseCatalogItem> items,
    required List<int> deletedWarehouseNos,
    required MobileWarehouseCatalogMetadata metadata,
  }) async {
    final incomingRows = <String, JsonMap>{};
    final now = DateTime.now().toUtc();

    for (final item in items) {
      final key = _itemKey(item.warehouseNo);
      if (key == null || item.isDeleted) {
        continue;
      }
      incomingRows[key] = item.copyWith(cachedAt: now).toJson();
    }

    for (final warehouseNo in deletedWarehouseNos) {
      final key = _itemKey(warehouseNo);
      if (key != null) {
        incomingRows.remove(key);
      }
    }

    await _database.writeTable(
      _itemTable,
      incomingRows.values.toList(growable: false),
    );
    await saveMetadata(metadata.copyWith(itemCount: incomingRows.length));
  }

  Future<void> saveMetadata(MobileWarehouseCatalogMetadata metadata) async {
    await _database.writeDocument(_metadataKey, metadata.toJson());
  }

  Map<String, JsonMap> _rowsByKey(List<JsonMap> rows) {
    final rowMap = <String, JsonMap>{};
    for (final row in rows) {
      final key = _itemKey(_readInt(row['warehouseNo']));
      if (key != null) {
        rowMap[key] = row;
      }
    }
    return rowMap;
  }

  String? _itemKey(int warehouseNo) {
    if (warehouseNo <= 0) {
      return null;
    }
    return warehouseNo.toString();
  }

  String _warehouseSearchKey(MobileWarehouseCatalogItem item) {
    return _normalize(
      '${item.warehouseNo} ${item.warehouseName} ${item.groupCode} '
      '${item.responsibilityCenterCode} ${item.projectCode} ${item.address} '
      '${item.district} ${item.province}',
    );
  }

  int _searchScore(MobileWarehouseCatalogItem item, String normalizedQuery) {
    if (normalizedQuery.isEmpty) {
      return 4;
    }
    if (item.warehouseNo.toString() == normalizedQuery) {
      return 0;
    }
    if (item.warehouseNo.toString().startsWith(normalizedQuery)) {
      return 1;
    }
    if (_normalize(item.warehouseName).startsWith(normalizedQuery)) {
      return 2;
    }
    return 3;
  }
}

class MobileWarehouseCatalogSyncResult {
  const MobileWarehouseCatalogSyncResult({
    required this.metadata,
    required this.pagesFetched,
    required this.upsertedCount,
    required this.deletedCount,
    required this.wasFullSync,
  });

  final MobileWarehouseCatalogMetadata metadata;
  final int pagesFetched;
  final int upsertedCount;
  final int deletedCount;
  final bool wasFullSync;
}

class MobileWarehouseCatalogSyncService {
  MobileWarehouseCatalogSyncService({
    required MobileWarehouseCatalogRemoteDataSource remoteDataSource,
    required MobileWarehouseCatalogLocalRepository localRepository,
  }) : _remoteDataSource = remoteDataSource,
       _localRepository = localRepository;

  final MobileWarehouseCatalogRemoteDataSource _remoteDataSource;
  final MobileWarehouseCatalogLocalRepository _localRepository;
  bool _isSyncRunning = false;

  bool get isSyncRunning => _isSyncRunning;

  Future<MobileWarehouseCatalogSyncResult> syncCatalog({
    required String accessToken,
    int pageSize = 5000,
    bool forceFull = false,
  }) async {
    if (_isSyncRunning) {
      throw const ApiException(
        statusCode: 0,
        title: 'Sync Devam Ediyor',
        detail: 'Depo katalog sync islemi zaten calisiyor.',
      );
    }

    _isSyncRunning = true;
    try {
      final currentMetadata = await _localRepository.fetchMetadata();
      final currentSyncToken = currentMetadata?.syncToken.trim() ?? '';
      final wasFullSync = forceFull || currentSyncToken.isEmpty;
      final fullSyncItems = <MobileWarehouseCatalogItem>[];
      final fullSyncDeletedWarehouseNos = <int>[];
      var cursor = '';
      var pagesFetched = 0;
      var upsertedCount = 0;
      var deletedCount = 0;
      MobileWarehouseCatalogPage? lastPage;

      do {
        final page = await _remoteDataSource.fetchPage(
          accessToken: accessToken,
          since: wasFullSync ? null : currentSyncToken,
          cursor: cursor.isEmpty ? null : cursor,
          pageSize: pageSize,
        );

        pagesFetched += 1;
        upsertedCount += page.items.length;
        deletedCount += page.deletedWarehouseNos.length;
        lastPage = page;

        if (wasFullSync) {
          fullSyncItems.addAll(page.items);
          fullSyncDeletedWarehouseNos.addAll(page.deletedWarehouseNos);
        } else {
          await _localRepository.applyCatalogDelta(
            items: page.items,
            deletedWarehouseNos: page.deletedWarehouseNos,
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
            detail: 'Depo katalog devam sayfasi icin nextCursor bos dondu.',
          );
        }
        cursor = nextCursor;
      } while (true);

      final completedPage = lastPage;
      final now = DateTime.now().toUtc();
      final syncToken = (completedPage.syncToken?.trim().isNotEmpty ?? false)
          ? completedPage.syncToken!.trim()
          : (completedPage.generatedAt ?? now).toIso8601String();
      var metadata = MobileWarehouseCatalogMetadata(
        syncToken: syncToken,
        generatedAt: completedPage.generatedAt,
        lastCompletedAt: now,
        itemCount: 0,
      );

      if (wasFullSync) {
        await _localRepository.replaceCatalog(
          items: fullSyncItems,
          deletedWarehouseNos: fullSyncDeletedWarehouseNos,
          metadata: metadata,
        );
      } else {
        metadata = metadata.copyWith(
          itemCount: await _localRepository.countItems(),
        );
        await _localRepository.saveMetadata(metadata);
      }

      final savedMetadata = await _localRepository.fetchMetadata() ?? metadata;
      return MobileWarehouseCatalogSyncResult(
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

int _readInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _normalize(String value) {
  return value.trim().toLowerCase();
}
