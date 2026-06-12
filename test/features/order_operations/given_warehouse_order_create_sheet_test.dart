import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_warehouse_orders/presentation/widgets/given_warehouse_order_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';

import '../../support/memory_local_database.dart';

void main() {
  testWidgets(
    'keeps compact product entry actions in one row on terminal width',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GivenWarehouseOrderCreateSheet(
              repository: _FakeWarehouseOrdersRepository(),
              accessToken: 'token',
              defaultWarehouseNo: '110',
              mobileWarehouseCatalogRepository:
                  MobileWarehouseCatalogLocalRepository(
                    database: MemoryLocalDatabase(),
                  ),
            ),
          ),
        ),
      );

      await _pickWarehouse(tester);

      expect(tester.takeException(), isNull);

      final fieldTop = tester
          .getTopLeft(
            find
                .widgetWithText(TextFormField, 'Barkod / stok kodu / urun adi')
                .first,
          )
          .dy;
      final productTop = tester
          .getTopLeft(find.widgetWithText(FilledButton, 'Urun').first)
          .dy;
      final cameraTop = tester
          .getTopLeft(find.byIcon(Icons.photo_camera_back_rounded).first)
          .dy;

      expect(productTop, moreOrLessEquals(fieldTop, epsilon: 20));
      expect(cameraTop, moreOrLessEquals(fieldTop, epsilon: 20));
    },
  );

  testWidgets('keeps a fresh barcode entry row after adding a product', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GivenWarehouseOrderCreateSheet(
            repository: _FakeWarehouseOrdersRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileWarehouseCatalogRepository:
                MobileWarehouseCatalogLocalRepository(
                  database: MemoryLocalDatabase(),
                ),
          ),
        ),
      ),
    );

    await _pickWarehouse(tester);

    await _pickWarehouseOrderProduct(tester);

    expect(find.text('Giris'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('Okutmaya hazir'), findsOneWidget);
    expect(find.text('Test Urun'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Test Urun')).dy,
      greaterThan(tester.getTopLeft(find.text('Giris')).dy),
    );
  });
}

Future<void> _pickWarehouse(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Sec'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('50 - MERKEZ DEPO'));
  await tester.pumpAndSettle();
}

Future<void> _pickWarehouseOrderProduct(WidgetTester tester) async {
  final productField = find
      .widgetWithText(TextFormField, 'Barkod / stok kodu / urun adi')
      .first;
  await tester.ensureVisible(productField);
  await tester.enterText(productField, '8690000000012');
  await tester.tap(find.widgetWithText(FilledButton, 'Urun').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('015792 - Test Urun'));
  await tester.pumpAndSettle();
}

class _FakeWarehouseOrdersRepository implements WarehouseOrdersRepository {
  @override
  bool get supportsCreate => true;

  @override
  Future<WarehouseOrderCreateResult> createOrder({
    required String accessToken,
    required WarehouseOrderCreateRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WarehouseOrderDetail> fetchOrderDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<WarehouseOrderListItem>> fetchOrders({
    required String accessToken,
    required WarehouseOrderListFilter filter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<ProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  }) async {
    return const <ProductLookupItem>[
      ProductLookupItem(
        warehouseNo: 110,
        barcode: '8690000000012',
        stockCode: '015792',
        stockName: 'Test Urun',
        price: 125,
        unitName: 'AD',
        isOrderBlocked: false,
      ),
    ];
  }

  @override
  Future<List<WarehouseLookupItem>> searchWarehouses({
    required String accessToken,
    String? query,
  }) async {
    return const <WarehouseLookupItem>[
      WarehouseLookupItem(
        warehouseNo: 50,
        warehouseName: 'MERKEZ DEPO',
        address: '',
        district: 'Osmangazi',
        province: 'Bursa',
      ),
    ];
  }
}
