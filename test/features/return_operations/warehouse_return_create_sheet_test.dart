import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/warehouse_returns_repository.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/presentation/widgets/warehouse_return_create_sheet.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';

import '../../support/barcode_resolution_test_data.dart';
import '../../support/memory_local_database.dart';
import '../../support/pda_create_screen_contract.dart';

void main() {
  testWidgets('passes pda create screen contract with keyboard inset', (
    tester,
  ) async {
    await expectPdaCreateScreenContract(
      tester,
      buildSubject: () => WarehouseReturnCreateSheet(
        repository: _FakeWarehouseReturnsRepository(),
        accessToken: 'token',
        defaultWarehouseNo: '110',
        mobileWarehouseCatalogRepository: MobileWarehouseCatalogLocalRepository(
          database: MemoryLocalDatabase(),
        ),
      ),
      prepare: _pickTargetWarehouse,
      entryRowFinder: find.text('Giris satiri'),
      saveButtonFinder: find.widgetWithText(FilledButton, 'Iadeyi Kaydet'),
    );
  });

  testWidgets('adds return lines at top and merges duplicate products', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WarehouseReturnCreateSheet(
            repository: _FakeWarehouseReturnsRepository(),
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

    await tester.tap(find.widgetWithText(FilledButton, 'Sec'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50 - MERKEZ DEPO'));
    await tester.pumpAndSettle();

    await _pickProduct(tester);

    final productInfo = find.text('Test Urun');
    expect(productInfo, findsOneWidget);
    expect(find.text('1 kalem'), findsOneWidget);
    expect(find.text('015792'), findsOneWidget);
    expect(find.text('AD'), findsOneWidget);
    expect(find.text('8690000000012'), findsOneWidget);

    expect(find.text('Giris satiri'), findsOneWidget);
    expect(find.text('Satir 1'), findsOneWidget);
    expect(find.text('Satir 2'), findsNothing);
    expect(
      tester.getTopLeft(productInfo).dy,
      greaterThan(tester.getTopLeft(find.text('Giris satiri')).dy),
    );

    await _pickProduct(tester);

    expect(find.text('1 kalem'), findsOneWidget);
    expect(productInfo, findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}

Future<void> _pickTargetWarehouse(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Sec'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('50 - MERKEZ DEPO').last);
  await tester.pumpAndSettle();
}

Future<void> _pickProduct(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Urun').first);
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).last, '8690000000012');
  await tester.tap(find.widgetWithText(FilledButton, 'Ara').last);
  await tester.pumpAndSettle();

  final productTile = find.ancestor(
    of: find.text('015792 - Test Urun').last,
    matching: find.byType(ListTile),
  );
  await tester.tap(productTile);
  await tester.pumpAndSettle();
  await _confirmPendingProduct(tester);
}

Future<void> _confirmPendingProduct(WidgetTester tester) async {
  final addButton = find.widgetWithText(FilledButton, 'Kaleme Ekle').first;
  await tester.ensureVisible(addButton);
  await tester.pumpAndSettle();
  await tester.tap(addButton);
  await tester.pumpAndSettle();
}

class _FakeWarehouseReturnsRepository implements WarehouseReturnsRepository {
  @override
  Future<BarcodeResolutionResult> resolveBarcode({
    required String accessToken,
    required BarcodeResolutionRequest request,
  }) async {
    return buildBarcodeResolutionResult(
      barcode: request.barcode,
      warehouseNo: int.tryParse(request.warehouseNo ?? '') ?? 110,
      unitMultiplier: 2,
      isCaseBarcode: true,
      matchedUnitsPerCase: 2,
      operationType: request.operationType ?? '',
      screenCode: request.screenCode ?? '',
    );
  }

  @override
  Future<WarehouseReturnCreateResult> createReturn({
    required String accessToken,
    required WarehouseReturnCreateRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WarehouseReturnDetail> fetchReturnDetail({
    required String accessToken,
    required WarehouseReturnDirection direction,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<WarehouseReturnListItem>> fetchReturns({
    required String accessToken,
    required WarehouseReturnDirection direction,
    required WarehouseReturnListFilter filter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WarehouseReturnPdfDocument> fetchEDespatchPdf({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    return WarehouseReturnPdfDocument(
      fileName: 'empty.pdf',
      bytes: Uint8List(0),
    );
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
        unitName: 'AD',
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
