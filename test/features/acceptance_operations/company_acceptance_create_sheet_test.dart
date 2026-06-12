import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/models/company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/presentation/widgets/company_acceptance_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/given_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';

import '../../support/memory_local_database.dart';

void main() {
  testWidgets(
    'keeps fresh company acceptance row and merges duplicate quantity',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompanyAcceptanceCreateSheet(
              repository: _FakeCompanyAcceptancesRepository(),
              ordersRepository: _FakeGivenCompanyOrdersRepository(),
              accessToken: 'token',
              defaultWarehouseNo: '110',
              mobileCustomerCatalogRepository:
                  MobileCustomerCatalogLocalRepository(
                    database: MemoryLocalDatabase(),
                  ),
              mobileProductCatalogRepository:
                  MobileProductCatalogLocalRepository(
                    database: MemoryLocalDatabase(),
                  ),
            ),
          ),
        ),
      );

      await _pickProduct(tester);

      expect(find.text('Giris satiri'), findsOneWidget);
      expect(find.text('Satir 1'), findsOneWidget);
      expect(find.textContaining('015792 | Test Urun | KL'), findsOneWidget);

      await _pickProduct(tester);

      expect(find.textContaining('015792 | Test Urun | KL'), findsOneWidget);
      expect(find.text('4'), findsNWidgets(2));
    },
  );
}

Future<void> _pickProduct(WidgetTester tester) async {
  final lookupFinder = find.widgetWithText(
    TextFormField,
    'Barkod / stok kodu / urun adi',
  );
  if (lookupFinder.evaluate().isEmpty) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
  }

  await tester.enterText(
    lookupFinder.first,
    '8690000000012',
  );

  final searchButton = find.widgetWithText(FilledButton, 'Urun').first;
  await tester.ensureVisible(searchButton);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Urun').first);
  await tester.pumpAndSettle();

  await tester.tap(find.text('015792 - Test Urun').last);
  await tester.pumpAndSettle();
}

class _FakeCompanyAcceptancesRepository
    implements CompanyAcceptancesRepository {
  @override
  Future<CompanyAcceptanceCreateResult> createAcceptance({
    required String accessToken,
    required CompanyAcceptanceCreateRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CompanyMovementDetail> fetchAcceptanceDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<CompanyMovementListItem>> fetchAcceptances({
    required String accessToken,
    required CompanyMovementListFilter filter,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CompanyAcceptanceOfflineSyncStatus> fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CompanyAcceptanceEDespatchPrefill> resolveEDespatchByEttn({
    required String accessToken,
    required String warehouseNo,
    required String ettn,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerLookupItem>> searchCustomers({
    required String accessToken,
    required String query,
  }) async {
    return const <CustomerLookupItem>[];
  }

  @override
  Future<List<SearchProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
    String? customerCode,
  }) async {
    return const <SearchProductLookupItem>[
      SearchProductLookupItem(
        warehouseNo: 110,
        barcode: '8690000000012',
        stockCode: '015792',
        stockName: 'Test Urun',
        price: 125,
        priceTypeCode: 0,
        unitName: 'KL',
        unitMultiplier: 2,
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
    ];
  }
}

class _FakeGivenCompanyOrdersRepository
    implements GivenCompanyOrdersRepository {
  @override
  bool get supportsCreate => true;

  @override
  Future<CompanyOrderCreateResult> createOrder({
    required String accessToken,
    required CompanyOrderCreateRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CompanyOrderDetail> fetchOrderDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<CompanyOrderListItem>> fetchOrders({
    required String accessToken,
    required CompanyOrderListFilter filter,
  }) async {
    return const <CompanyOrderListItem>[];
  }

  @override
  Future<List<CustomerLookupItem>> searchCustomers({
    required String accessToken,
    required String query,
  }) async {
    return const <CustomerLookupItem>[];
  }

  @override
  Future<List<CompanyOrderProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String customerCode,
    required String query,
  }) async {
    return const <CompanyOrderProductLookupItem>[];
  }
}
