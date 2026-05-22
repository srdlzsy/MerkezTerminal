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
}

class _FakeStockReceiptsRepository implements StockReceiptsRepository {
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
    return const <SearchProductLookupItem>[];
  }
}
