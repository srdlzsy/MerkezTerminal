import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';

import '../../support/memory_local_database.dart';

void main() {
  test('full sync follows cursor pages and stores final sync token', () async {
    final localRepository = MobileProductCatalogLocalRepository(
      database: MemoryLocalDatabase(),
    );
    final remoteDataSource = _FakeCatalogRemoteDataSource(
      pages: <MobileProductCatalogPage>[
        _page(
          hasMore: true,
          nextCursor: 'cursor-2',
          items: <MobileProductCatalogItem>[
            _item(barcode: '8690000000001', stockCode: '001'),
          ],
        ),
        _page(
          hasMore: false,
          syncToken: '2026-06-08T10:35:00',
          items: <MobileProductCatalogItem>[
            _item(barcode: '8690000000002', stockCode: '002'),
          ],
        ),
      ],
    );
    final syncService = MobileProductCatalogSyncService(
      remoteDataSource: remoteDataSource,
      localRepository: localRepository,
    );

    final result = await syncService.syncCatalog(
      accessToken: 'token',
      warehouseNo: '110',
    );

    expect(result.wasFullSync, isTrue);
    expect(result.pagesFetched, 2);
    expect(result.metadata.syncToken, '2026-06-08T10:35:00');
    expect(result.metadata.itemCount, 2);
    expect(remoteDataSource.requests.first.since, isNull);
    expect(remoteDataSource.requests.last.cursor, 'cursor-2');

    final products = await localRepository.searchProducts(
      warehouseNo: '110',
      query: '8690000000001',
    );
    expect(products.single.stockCode, '001');
  });

  test(
    'incremental sync uses stored token and removes deleted barcodes',
    () async {
      final localRepository = MobileProductCatalogLocalRepository(
        database: MemoryLocalDatabase(),
      );
      final firstSync = MobileProductCatalogSyncService(
        remoteDataSource: _FakeCatalogRemoteDataSource(
          pages: <MobileProductCatalogPage>[
            _page(
              hasMore: false,
              syncToken: '2026-06-08T10:30:00',
              items: <MobileProductCatalogItem>[
                _item(barcode: '8690000000001', stockCode: '001', price: 100),
                _item(barcode: '8690000000002', stockCode: '002', price: 200),
              ],
            ),
          ],
        ),
        localRepository: localRepository,
      );
      await firstSync.syncCatalog(accessToken: 'token', warehouseNo: '110');

      final remoteDataSource = _FakeCatalogRemoteDataSource(
        pages: <MobileProductCatalogPage>[
          _page(
            hasMore: false,
            syncToken: '2026-06-08T10:40:00',
            items: <MobileProductCatalogItem>[
              _item(barcode: '8690000000001', stockCode: '001', price: 125.5),
            ],
            deletedBarcodes: <String>['8690000000002'],
          ),
        ],
      );
      final incrementalSync = MobileProductCatalogSyncService(
        remoteDataSource: remoteDataSource,
        localRepository: localRepository,
      );

      final result = await incrementalSync.syncCatalog(
        accessToken: 'token',
        warehouseNo: '110',
      );

      expect(result.wasFullSync, isFalse);
      expect(remoteDataSource.requests.single.since, '2026-06-08T10:30:00');
      expect(result.metadata.syncToken, '2026-06-08T10:40:00');
      expect(result.metadata.itemCount, 1);

      final updated = await localRepository.findByBarcode(
        warehouseNo: '110',
        barcode: '8690000000001',
      );
      final deleted = await localRepository.findByBarcode(
        warehouseNo: '110',
        barcode: '8690000000002',
      );

      expect(updated?.price, 125.5);
      expect(deleted, isNull);
    },
  );
}

MobileProductCatalogPage _page({
  required bool hasMore,
  String? nextCursor,
  String? syncToken,
  List<MobileProductCatalogItem> items = const <MobileProductCatalogItem>[],
  List<String> deletedBarcodes = const <String>[],
}) {
  return MobileProductCatalogPage(
    warehouseNo: 110,
    generatedAt: DateTime(2026, 6, 8, 10, 35),
    since: null,
    syncToken: syncToken,
    nextCursor: nextCursor,
    hasMore: hasMore,
    pageSize: 5000,
    items: items,
    deletedBarcodes: deletedBarcodes,
  );
}

MobileProductCatalogItem _item({
  required String barcode,
  required String stockCode,
  double price = 1,
}) {
  return MobileProductCatalogItem(
    warehouseNo: 110,
    barcode: barcode,
    lookupSource: 'barcode',
    stockCode: stockCode,
    stockName: 'Stok $stockCode',
    price: price,
    priceTypeCode: 1,
    unitPointer: 1,
    unitName: 'AD',
    unitMultiplier: 1,
    secondaryUnitName: 'KOLI',
    secondaryUnitMultiplier: 12,
    salesBlockCode: 0,
    orderBlockCode: 0,
    goodsAcceptanceBlockCode: 0,
    isSalesBlocked: false,
    isOrderBlocked: false,
    isGoodsAcceptanceBlocked: false,
    isPassive: false,
    isDeleted: false,
    productManagerCode: 'PER001',
    updatedAt: DateTime(2026, 6, 8, 10, 20),
  );
}

class _FakeCatalogRemoteDataSource
    implements MobileProductCatalogRemoteDataSource {
  _FakeCatalogRemoteDataSource({required this.pages});

  final List<MobileProductCatalogPage> pages;
  final List<_CatalogRequest> requests = <_CatalogRequest>[];

  @override
  Future<MobileProductCatalogPage> fetchPage({
    required String accessToken,
    required String warehouseNo,
    String? since,
    String? cursor,
    int pageSize = 5000,
  }) async {
    requests.add(
      _CatalogRequest(
        warehouseNo: warehouseNo,
        since: since,
        cursor: cursor,
        pageSize: pageSize,
      ),
    );

    return pages[requests.length - 1];
  }
}

class _CatalogRequest {
  const _CatalogRequest({
    required this.warehouseNo,
    required this.since,
    required this.cursor,
    required this.pageSize,
  });

  final String warehouseNo;
  final String? since;
  final String? cursor;
  final int pageSize;
}
