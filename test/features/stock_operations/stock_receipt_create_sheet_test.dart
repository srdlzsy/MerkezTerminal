import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/models/stock_receipt_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/stock_receipts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/presentation/widgets/stock_receipt_create_sheet.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';

import '../../support/barcode_resolution_test_data.dart';
import '../../support/pda_create_screen_contract.dart';

void main() {
  testWidgets('renders create sheet on 320px terminal width without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockReceiptCreateSheet(
            repository: _FakeStockReceiptsRepository(),
            kind: StockReceiptKind.outage,
            accessToken: 'token',
            defaultWarehouseNo: '50',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Yeni Zayiat Fisi'), findsOneWidget);
    expect(find.text('Olusturan*'), findsOneWidget);
    expect(find.text('Onaylayan*'), findsOneWidget);
  });

  testWidgets('passes pda create screen contract with keyboard inset', (
    tester,
  ) async {
    await expectPdaCreateScreenContract(
      tester,
      buildSubject: () => StockReceiptCreateSheet(
        repository: _FakeStockReceiptsRepository(),
        kind: StockReceiptKind.outage,
        accessToken: 'token',
        defaultWarehouseNo: '50',
      ),
      entryRowFinder: find.text('Giris satiri'),
      saveButtonFinder: find.widgetWithText(FilledButton, 'Kaydet'),
    );
  });

  testWidgets('shows required warnings for api header fields', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockReceiptCreateSheet(
            repository: _FakeStockReceiptsRepository(),
            kind: StockReceiptKind.outage,
            accessToken: 'token',
            defaultWarehouseNo: '50',
          ),
        ),
      ),
    );

    final saveButton = find.widgetWithText(FilledButton, 'Kaydet');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Olusturan zorunlu'), findsOneWidget);
    expect(find.text('Onaylayan zorunlu'), findsOneWidget);
  });

  testWidgets('adds single product search result without opening picker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockReceiptCreateSheet(
            repository: _FakeStockReceiptsRepository(
              products: const <SearchProductLookupItem>[
                SearchProductLookupItem(
                  warehouseNo: 50,
                  barcode: '8690000000012',
                  stockCode: '015792',
                  stockName: 'Test Urun',
                  price: 125,
                  priceTypeCode: 0,
                  unitName: 'AD',
                  unitMultiplier: 1,
                  secondaryUnitName: '',
                  secondaryUnitMultiplier: 0,
                  salesBlockCode: null,
                  orderBlockCode: null,
                  goodsAcceptanceBlockCode: null,
                  isSalesBlocked: false,
                  isOrderBlocked: false,
                  isGoodsAcceptanceBlocked: false,
                  productManagerCode: '',
                ),
              ],
            ),
            kind: StockReceiptKind.outage,
            accessToken: 'token',
            defaultWarehouseNo: '50',
          ),
        ),
      ),
    );

    final productField = find
        .widgetWithText(TextFormField, 'Barkod / stok kodu / urun adi')
        .first;
    await tester.enterText(productField, '8690000000012');
    await tester.tap(find.widgetWithText(FilledButton, 'Urun').first);
    await tester.pumpAndSettle();

    expect(find.text('Urun Ara'), findsNothing);
    await _confirmPendingProduct(tester);
    expect(find.text('1 kalem'), findsOneWidget);
    expect(find.text('Giris satiri'), findsOneWidget);
    expect(find.text('Satir 1'), findsOneWidget);
    expect(find.text('Test Urun'), findsOneWidget);
    expect(find.text('8690000000012'), findsWidgets);
  });

  testWidgets('keeps unresolved lookup as entry row without adding a line', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockReceiptCreateSheet(
            repository: _FakeStockReceiptsRepository(),
            kind: StockReceiptKind.outage,
            accessToken: 'token',
            defaultWarehouseNo: '50',
          ),
        ),
      ),
    );

    final productField = find
        .widgetWithText(TextFormField, 'Barkod / stok kodu / urun adi')
        .first;
    await tester.enterText(productField, '9999999999999');
    await tester.tap(find.widgetWithText(FilledButton, 'Urun').first);
    await tester.pumpAndSettle();

    expect(find.text('1 kalem'), findsNothing);
    expect(find.text('Giris satiri'), findsOneWidget);
    expect(find.text('Satir 1'), findsNothing);
    expect(find.text('Urun bulunamadi.'), findsWidgets);
    expect(
      find.widgetWithText(TextFormField, 'Barkod / stok kodu / urun adi'),
      findsOneWidget,
    );
  });
}

Future<void> _confirmPendingProduct(WidgetTester tester) async {
  final addButton = find.widgetWithText(FilledButton, 'Kaleme Ekle').first;
  await tester.ensureVisible(addButton);
  await tester.pumpAndSettle();
  await tester.tap(addButton);
  await tester.pumpAndSettle();
}

class _FakeStockReceiptsRepository implements StockReceiptsRepository {
  const _FakeStockReceiptsRepository({
    this.products = const <SearchProductLookupItem>[],
  });

  final List<SearchProductLookupItem> products;

  @override
  Future<BarcodeResolutionResult> resolveBarcode({
    required String accessToken,
    required BarcodeResolutionRequest request,
  }) async {
    for (final product in products) {
      if (product.barcode == request.barcode ||
          product.stockCode == request.barcode) {
        return buildBarcodeResolutionResult(
          barcode: product.barcode,
          warehouseNo: product.warehouseNo,
          stockCode: product.stockCode,
          stockName: product.stockName,
          unitName: product.unitName,
          unitMultiplier: product.unitMultiplier,
          salesPrice: product.price,
          priceTypeCode: product.priceTypeCode,
          operationType: request.operationType ?? '',
          screenCode: request.screenCode ?? '',
        );
      }
    }

    return buildBarcodeResolutionResult(
      barcode: request.barcode,
      warehouseNo: int.tryParse(request.warehouseNo ?? '') ?? 50,
      isFound: false,
      isUsableInOperation: false,
      errors: const <String>['Urun bulunamadi.'],
    );
  }

  @override
  Future<StockReceiptCreateResult> createReceipt({
    required String accessToken,
    required StockReceiptKind kind,
    required StockReceiptCreateRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StockReceiptDetail> fetchReceiptDetail({
    required String accessToken,
    required StockReceiptKind kind,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<StockReceiptListItem>> fetchReceipts({
    required String accessToken,
    required StockReceiptKind kind,
    required StockReceiptListFilter filter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<SearchProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  }) async {
    return products;
  }
}
