import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/models/suggested_warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/suggested_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/presentation/views/suggested_warehouse_orders_page.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';

import '../../support/memory_local_database.dart';

void main() {
  testWidgets('renders suggested warehouse orders on terminal width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SuggestedWarehouseOrdersPage(
            repository: _FakeSuggestedWarehouseOrdersRepository(),
            accessToken: 'token',
            canCreate: true,
            defaultWarehouseNo: '110',
            userWarehouseName: 'KESTEL 1',
            mobileWarehouseCatalogRepository:
                MobileWarehouseCatalogLocalRepository(
                  database: MemoryLocalDatabase(),
                ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '50');
    await tester.tap(find.byTooltip('Listele'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Onerilen Depo Siparisleri'), findsOneWidget);
    expect(find.text('Domates'), findsOneWidget);
    expect(find.byTooltip('Tumunu Sec'), findsOneWidget);

    await tester.tap(find.byTooltip('Tumunu Sec'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Siparis Miktari*'), findsWidgets);
    expect(find.byTooltip('Siparise Cevir'), findsOneWidget);
  });

  testWidgets('uses source product flow for selected special warehouse', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeSuggestedWarehouseOrdersRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SuggestedWarehouseOrdersPage(
            repository: repository,
            accessToken: 'token',
            canCreate: true,
            defaultWarehouseNo: '110',
            userWarehouseName: 'KESTEL 1',
            mobileWarehouseCatalogRepository:
                MobileWarehouseCatalogLocalRepository(
                  database: MemoryLocalDatabase(),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Kaynak depo ara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('70 - SARKUTERI DEPO'));
    await tester.pumpAndSettle();

    expect(repository.lastFilter?.sourceWarehouseNo, 70);
    expect(repository.lastFilter?.useSourceProducts, isTrue);
    expect(find.text('Sarkuteri Test Urun'), findsOneWidget);
  });
}

class _FakeSuggestedWarehouseOrdersRepository
    implements SuggestedWarehouseOrdersRepository {
  SuggestedWarehouseOrderFilter? lastFilter;

  @override
  Future<List<SuggestedWarehouseOrderListItem>> fetchSuggestions({
    required String accessToken,
    required SuggestedWarehouseOrderFilter filter,
  }) async {
    lastFilter = filter;
    if (filter.useSourceProducts) {
      return const <SuggestedWarehouseOrderListItem>[
        SuggestedWarehouseOrderListItem(
          sourceWarehouseNo: 70,
          sourceWarehouseName: 'SARKUTERI DEPO',
          stockCode: 'SRK001',
          stockName: 'Sarkuteri Test Urun',
          modelCode: '70',
          modelName: 'Sarkuteri',
          barcode: '7000001',
          unitName: 'KG',
          targetOnHand: 0,
          sourceOnHand: 0,
          salesQuantity: 0,
          openIncomingOrderQuantity: 0,
          packageFactor: 0,
          minDay: 0,
          recommendedDay: 0,
          maxDay: 0,
          recommendedStockQuantity: 0,
          needQuantity: 0,
          suggestedOrderQuantity: 0,
        ),
      ];
    }

    return const <SuggestedWarehouseOrderListItem>[
      SuggestedWarehouseOrderListItem(
        stockCode: '010001',
        stockName: 'Domates',
        modelCode: '01',
        barcode: '8690000000001',
        targetOnHand: 2,
        sourceOnHand: 120,
        salesQuantity: 86,
        openIncomingOrderQuantity: 3,
        packageFactor: 1,
        minDay: 0,
        recommendedDay: 7,
        maxDay: 0,
        recommendedStockQuantity: 14,
        needQuantity: 9,
        suggestedOrderQuantity: 9,
      ),
    ];
  }

  @override
  Future<WarehouseOrderCreateResult> convertToOrder({
    required String accessToken,
    required SuggestedWarehouseOrderConvertRequest request,
  }) async {
    return WarehouseOrderCreateResult(
      documentSerie: 'D50',
      documentOrderNo: 91,
      orderDate: request.orderDate,
      deliveryDate: request.deliveryDate,
      inWarehouseNo: 110,
      outWarehouseNo: request.sourceWarehouseNo,
      lineCount: request.lines.length,
      totalQuantity: request.lines.fold<double>(
        0,
        (total, line) => total + line.quantity,
      ),
      writeConnectionName: 'test',
    );
  }

  @override
  Future<List<WarehouseLookupItem>> searchWarehouses({
    required String accessToken,
    String? query,
  }) async {
    return const <WarehouseLookupItem>[
      WarehouseLookupItem(
        warehouseNo: 70,
        warehouseName: 'SARKUTERI DEPO',
        address: '',
        district: '',
        province: '',
      ),
      WarehouseLookupItem(
        warehouseNo: 50,
        warehouseName: 'MERKEZ',
        address: '',
        district: '',
        province: '',
      ),
    ];
  }
}
