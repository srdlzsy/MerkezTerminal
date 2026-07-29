import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/data/models/suggested_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/data/suggested_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/presentation/views/suggested_company_orders_page.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';

import '../../support/memory_local_database.dart';

void main() {
  testWidgets('renders suggested company orders on terminal width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SuggestedCompanyOrdersPage(
            repository: _FakeSuggestedCompanyOrdersRepository(),
            accessToken: 'token',
            canCreate: true,
            defaultWarehouseNo: '110',
            userWarehouseName: 'KESTEL 1',
            mobileCustomerCatalogRepository:
                MobileCustomerCatalogLocalRepository(
                  database: MemoryLocalDatabase(),
                ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '32000999');
    await tester.tap(find.byTooltip('Listele'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Onerilen Firma Siparisleri'), findsOneWidget);
    expect(find.text('Domates'), findsOneWidget);
    expect(find.byTooltip('Tumunu Sec'), findsOneWidget);

    await tester.tap(find.byTooltip('Tumunu Sec'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Siparis Miktari*'), findsWidgets);
    expect(find.byTooltip('Siparise Cevir'), findsOneWidget);
  });
}

class _FakeSuggestedCompanyOrdersRepository
    implements SuggestedCompanyOrdersRepository {
  @override
  Future<List<SuggestedCompanyOrderListItem>> fetchSuggestions({
    required String accessToken,
    required SuggestedCompanyOrderFilter filter,
  }) async {
    return const <SuggestedCompanyOrderListItem>[
      SuggestedCompanyOrderListItem(
        supplierCode: '32000999',
        supplierName: 'TEDARIKCI A.S.',
        stockCode: '010001',
        stockName: 'Domates',
        modelCode: '01',
        barcode: '8690000000001',
        targetOnHand: 4,
        salesQuantity: 86,
        openCompanyOrderQuantity: 2,
        packageFactor: 5,
        minDay: 7,
        recommendedDay: 7,
        maxDay: 0,
        recommendedStockQuantity: 14,
        needQuantity: 8,
        suggestedOrderQuantity: 25,
        purchasePrice: 15.75,
        minimumPurchaseQuantity: 24,
        deliveryDay: 2,
      ),
    ];
  }

  @override
  Future<CompanyOrderCreateResult> convertToOrder({
    required String accessToken,
    required SuggestedCompanyOrderConvertRequest request,
  }) async {
    return CompanyOrderCreateResult(
      documentSerie: 'F110',
      documentOrderNo: 55,
      orderDate: request.orderDate,
      deliveryDate: request.deliveryDate,
      warehouseNo: 110,
      customerCode: request.supplierCode,
      lineCount: request.lines.length,
      totalQuantity: request.lines.fold<double>(
        0,
        (total, line) => total + line.quantity,
      ),
      totalAmount: request.lines.fold<double>(
        0,
        (total, line) => total + (line.quantity * line.unitPrice),
      ),
      writeConnectionName: 'test',
    );
  }

  @override
  Future<List<CustomerLookupItem>> searchSuppliers({
    required String accessToken,
    required String query,
  }) async {
    return const <CustomerLookupItem>[
      CustomerLookupItem(
        customerCode: '32000999',
        customerName: 'TEDARIKCI',
        customerTitle: 'TEDARIKCI A.S.',
        customerDisplayName: 'TEDARIKCI A.S.',
        taxNumber: '1234567890',
        representativeCode: '',
        representativeName: '',
        invoiceAddressNo: 0,
        shippingAddressNo: 0,
        isLocked: false,
        isClosed: false,
      ),
    ];
  }
}
