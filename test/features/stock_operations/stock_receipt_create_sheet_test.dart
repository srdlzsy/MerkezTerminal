import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/models/stock_receipt_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/stock_receipts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/presentation/widgets/stock_receipt_create_sheet.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';

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
    expect(find.text('Creator'), findsOneWidget);
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
    expect(find.text('Giris satiri'), findsOneWidget);
    expect(find.text('Satir 1'), findsOneWidget);
    expect(find.text('Test Urun'), findsOneWidget);
    expect(find.text('8690000000012'), findsWidgets);
  });
}

class _FakeStockReceiptsRepository implements StockReceiptsRepository {
  const _FakeStockReceiptsRepository({
    this.products = const <SearchProductLookupItem>[],
  });

  final List<SearchProductLookupItem> products;

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
