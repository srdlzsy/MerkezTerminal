import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/received_warehouse_orders/data/received_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/outgoing_warehouse_shipments_repository.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/presentation/widgets/outgoing_warehouse_shipment_create_sheet.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';

import '../../support/memory_local_database.dart';

void main() {
  testWidgets('renders create sheet header fields without layout exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutgoingWarehouseShipmentCreateSheet(
            repository: _FakeOutgoingWarehouseShipmentsRepository(),
            receivedWarehouseOrdersRepository:
                _FakeReceivedWarehouseOrdersRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileWarehouseCatalogRepository:
                _emptyWarehouseCatalogRepository(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Yeni Giden Depolar Arasi Sevk'), findsOneWidget);
    expect(find.text('Hedef depo no*'), findsOneWidget);
  });

  testWidgets('opens create lookup sheets on terminal width without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutgoingWarehouseShipmentCreateSheet(
            repository: _FakeOutgoingWarehouseShipmentsRepository(),
            receivedWarehouseOrdersRepository:
                _FakeReceivedWarehouseOrdersRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileWarehouseCatalogRepository:
                _emptyWarehouseCatalogRepository(),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextField, 'Hedef depo no*'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Depo Ara'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Arama'), 'merkez');
    await tester.tap(find.text('Ara'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('50 - MERKEZ DEPO'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Siparisli'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Depo Siparisi Sec'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Depo Siparisi Sec'), findsWidgets);
  });

  testWidgets('keeps fresh manual shipment row and merges duplicate quantity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutgoingWarehouseShipmentCreateSheet(
            repository: _FakeOutgoingWarehouseShipmentsRepository(),
            receivedWarehouseOrdersRepository:
                _FakeReceivedWarehouseOrdersRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileWarehouseCatalogRepository:
                _emptyWarehouseCatalogRepository(),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextField, 'Hedef depo no*'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50 - MERKEZ DEPO'));
    await tester.pumpAndSettle();

    await _enterShipmentBarcode(tester);

    const productInfo =
        'Test Urun | Kod 015792 | Birim KL | Barkod 8690000000012';
    expect(find.text('Giris satiri'), findsOneWidget);
    expect(find.text('Satir 1'), findsOneWidget);
    expect(find.text(productInfo), findsOneWidget);

    await _enterShipmentBarcode(tester);

    expect(find.text(productInfo), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}

Future<void> _enterShipmentBarcode(WidgetTester tester) async {
  final productField = find
      .widgetWithText(TextFormField, 'Barkod / stok kodu / urun adi')
      .first;
  await tester.ensureVisible(productField);
  await tester.pumpAndSettle();

  await tester.enterText(productField, '8690000000012');
  await tester.tap(find.widgetWithText(FilledButton, 'Urun').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('015792 - Test Urun'));
  await tester.pumpAndSettle();
}

MobileWarehouseCatalogLocalRepository _emptyWarehouseCatalogRepository() {
  return MobileWarehouseCatalogLocalRepository(database: MemoryLocalDatabase());
}

class _FakeOutgoingWarehouseShipmentsRepository
    implements OutgoingWarehouseShipmentsRepository {
  @override
  bool get supportsEDespatch => true;

  @override
  Future<WarehouseShipmentCreateResult> createShipment({
    required String accessToken,
    required WarehouseShipmentCreateRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WarehouseShipmentPdfDocument> fetchEDespatchPdf({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    return WarehouseShipmentPdfDocument(
      fileName: 'test.pdf',
      bytes: Uint8List(0),
    );
  }

  @override
  Future<WarehouseShipmentDetail> fetchShipmentDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<WarehouseShipmentListItem>> fetchShipments({
    required String accessToken,
    required WarehouseShipmentListFilter filter,
  }) async {
    return const <WarehouseShipmentListItem>[];
  }

  @override
  Future<EDespatchSendResult> sendEDespatch({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
    required EDespatchSendRequest request,
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
        unitName: 'KL',
        unitMultiplier: 2,
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

class _FakeReceivedWarehouseOrdersRepository
    implements ReceivedWarehouseOrdersRepository {
  @override
  bool get supportsCreate => false;

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
  }) async {
    return const <WarehouseOrderListItem>[];
  }

  @override
  Future<List<ProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  }) async {
    return const <ProductLookupItem>[];
  }

  @override
  Future<List<WarehouseLookupItem>> searchWarehouses({
    required String accessToken,
    String? query,
  }) async {
    return const <WarehouseLookupItem>[];
  }
}
