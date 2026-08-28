import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/presentation/widgets/given_company_order_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/company_orders_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';

import '../../support/memory_local_database.dart';
import '../../support/pda_create_screen_contract.dart';

void main() {
  testWidgets('passes pda create screen contract with keyboard inset', (
    tester,
  ) async {
    await expectPdaCreateScreenContract(
      tester,
      buildSubject: () => GivenCompanyOrderCreateSheet(
        repository: _FakeCompanyOrdersRepository(),
        accessToken: 'token',
        defaultWarehouseNo: '110',
        mobileCustomerCatalogRepository: MobileCustomerCatalogLocalRepository(
          database: MemoryLocalDatabase(),
        ),
      ),
      entryRowFinder: find.text('Giris satiri'),
      saveButtonFinder: find.widgetWithText(FilledButton, 'Siparisi Olustur'),
    );
  });

  testWidgets('shows deliverer and receiver fields for selected customer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 8, 28);
    final draft = CreateDraft(
      id: 'given-company-order-draft',
      moduleKey: 'siparis-islemleri.verilen-firma-siparisleri',
      userId: '7',
      warehouseNo: '110',
      title: 'Yeni Verilen Firma Siparisi',
      createdAt: now,
      updatedAt: now,
      payload: <String, dynamic>{
        'customerCode': 'CR001',
        'deliverer': 'Ali',
        'receiver': 'Veli',
        'selectedCustomer': <String, dynamic>{
          'customerCode': 'CR001',
          'customerName': 'Test Cari',
          'customerDisplayName': 'Test Cari',
          'representativeCode': 'S01',
          'taxNumber': '1234567890',
        },
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GivenCompanyOrderCreateSheet(
            repository: _FakeCompanyOrdersRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileCustomerCatalogRepository:
                MobileCustomerCatalogLocalRepository(
                  database: MemoryLocalDatabase(),
                ),
            draft: draft,
          ),
        ),
      ),
    );

    expect(find.widgetWithText(TextFormField, 'Teslim Eden'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Teslim Alan'), findsOneWidget);

    final delivererField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Teslim Eden'),
    );
    final receiverField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Teslim Alan'),
    );

    expect(delivererField.controller?.text, 'Ali');
    expect(receiverField.controller?.text, 'Veli');
  });

  testWidgets('loads selected customer products with empty quantities', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final draft = _selectedCustomerDraft();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GivenCompanyOrderCreateSheet(
            repository: const _FakeCompanyOrdersRepository(
              customerProducts: <CompanyOrderProductLookupItem>[
                CompanyOrderProductLookupItem(
                  warehouseNo: 110,
                  barcode: '8690000000001',
                  stockCode: '010001',
                  stockName: 'Test Cari Urunu',
                  price: 15.75,
                  unitName: 'AD',
                  unitMultiplier: 12,
                  secondaryUnitName: 'KOLI',
                  caseBarcode: '18690000000018',
                  minimumPurchaseQuantity: 24,
                  deliveryDay: 2,
                  unitPointer: 2,
                  isOrderBlocked: false,
                  isSalesBlocked: false,
                ),
              ],
            ),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileCustomerCatalogRepository:
                MobileCustomerCatalogLocalRepository(
                  database: MemoryLocalDatabase(),
                ),
            draft: draft,
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Firma urunleri'));
    await tester.pumpAndSettle();

    expect(find.text('Test Cari Urunu'), findsOneWidget);
    expect(find.textContaining('Koli ici 12'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Boslari sil'), findsOneWidget);
  });
}

CreateDraft _selectedCustomerDraft() {
  final now = DateTime(2026, 8, 28);
  return CreateDraft(
    id: 'given-company-order-draft',
    moduleKey: 'siparis-islemleri.verilen-firma-siparisleri',
    userId: '7',
    warehouseNo: '110',
    title: 'Yeni Verilen Firma Siparisi',
    createdAt: now,
    updatedAt: now,
    payload: <String, dynamic>{
      'customerCode': 'CR001',
      'deliverer': 'Ali',
      'receiver': 'Veli',
      'selectedCustomer': <String, dynamic>{
        'customerCode': 'CR001',
        'customerName': 'Test Cari',
        'customerDisplayName': 'Test Cari',
        'representativeCode': 'S01',
        'taxNumber': '1234567890',
      },
    },
  );
}

class _FakeCompanyOrdersRepository implements CompanyOrdersRepository {
  const _FakeCompanyOrdersRepository({
    this.customerProducts = const <CompanyOrderProductLookupItem>[],
  });

  final List<CompanyOrderProductLookupItem> customerProducts;

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
  Future<List<CompanyOrderProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String customerCode,
    required String query,
  }) async {
    return const <CompanyOrderProductLookupItem>[];
  }

  @override
  Future<List<CompanyOrderProductLookupItem>> fetchCustomerProducts({
    required String accessToken,
    required String warehouseNo,
    required String customerCode,
    String? search,
    int take = 500,
  }) async {
    return customerProducts;
  }
}
