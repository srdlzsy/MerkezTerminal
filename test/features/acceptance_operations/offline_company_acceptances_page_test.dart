import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/models/company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/models/offline_company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/offline_company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/presentation/views/offline_company_acceptances_page.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/given_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/data/models/offline_inventory_count_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/data/offline_inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_service.dart';

import '../../support/memory_local_database.dart';

void main() {
  testWidgets(
    'opens offline company acceptance with document and lines steps',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final offlineRepository = _FakeOfflineCompanyAcceptancesRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineCompanyAcceptancesPage(
              offlineRepository: offlineRepository,
              onlineRepository: _FakeCompanyAcceptancesRepository(),
              ordersRepository: _FakeGivenCompanyOrdersRepository(),
              accessToken: 'token',
              offlineSyncService: OfflineSyncService(
                inventoryRepository: _FakeInventoryCountsRepository(),
                companyAcceptanceRepository:
                    _FakeCompanyAcceptancesRepository(),
                offlineInventoryRepository:
                    _FakeOfflineInventoryCountsRepository(),
                offlineCompanyAcceptanceRepository: offlineRepository,
              ),
              mobileCustomerCatalogRepository:
                  MobileCustomerCatalogLocalRepository(
                    database: MemoryLocalDatabase(),
                  ),
              mobileProductCatalogRepository:
                  MobileProductCatalogLocalRepository(
                    database: MemoryLocalDatabase(),
                  ),
              currentUserId: 'u1',
              defaultWarehouseNo: '110',
              userWarehouseName: 'TEST DEPO',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_task_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Yeni Offline Firma Mal Kabul'), findsOneWidget);
      expect(find.text('Belge'), findsWidgets);
      expect(find.text('Kalemler'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Cari ara'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Cari Kodu*'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Kalemlere Gec'),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cari Kodu*'),
        'CR-001',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Kalemlere Gec'));
      await tester.pumpAndSettle();

      expect(find.text('Giris satiri'), findsOneWidget);
      expect(find.text('CR-001'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Taslagi Kaydet'),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Belge'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FakeOfflineCompanyAcceptancesRepository
    implements OfflineCompanyAcceptancesRepository {
  final List<OfflineCompanyAcceptanceDraft> drafts =
      <OfflineCompanyAcceptanceDraft>[];

  @override
  Future<void> deleteDraft(String id) async {
    drafts.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<OfflineCompanyAcceptanceDraft>> fetchDrafts({
    required String userId,
    required String warehouseNo,
  }) async {
    return drafts
        .where(
          (item) =>
              item.matchesContext(userId: userId, warehouseNo: warehouseNo),
        )
        .toList(growable: false);
  }

  @override
  Future<OfflineCompanyAcceptanceDraft?> findDraft(String id) async {
    for (final draft in drafts) {
      if (draft.id == id) {
        return draft;
      }
    }

    return null;
  }

  @override
  Future<void> saveDraft(OfflineCompanyAcceptanceDraft draft) async {
    drafts
      ..removeWhere((item) => item.id == draft.id)
      ..add(draft);
  }
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
  }) async {
    return <CompanyMovementListItem>[];
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
    return <CustomerLookupItem>[];
  }

  @override
  Future<List<SearchProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
    String? customerCode,
  }) async {
    return <SearchProductLookupItem>[];
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
    return <CompanyOrderListItem>[];
  }

  @override
  Future<List<CustomerLookupItem>> searchCustomers({
    required String accessToken,
    required String query,
  }) async {
    return <CustomerLookupItem>[];
  }

  @override
  Future<List<CompanyOrderProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String customerCode,
    required String query,
  }) async {
    return <CompanyOrderProductLookupItem>[];
  }
}

class _FakeInventoryCountsRepository implements InventoryCountsRepository {
  @override
  Future<InventoryCountCreateResult> createCount({
    required String accessToken,
    required InventoryCountCreateRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<InventoryCountDetail> fetchCountDetail({
    required String accessToken,
    required int documentNo,
    required DateTime documentDate,
    required String warehouseNo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<InventoryCountListItem>> fetchCounts({
    required String accessToken,
    required InventoryCountListFilter filter,
  }) async {
    return <InventoryCountListItem>[];
  }

  @override
  Future<InventoryCountOfflineSyncStatus> fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BarcodeResolutionResult> resolveBarcode({
    required String accessToken,
    required BarcodeResolutionRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<InventoryCountProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  }) async {
    return <InventoryCountProductLookupItem>[];
  }
}

class _FakeOfflineInventoryCountsRepository
    implements OfflineInventoryCountsRepository {
  @override
  Future<void> deleteDraft(String id) async {}

  @override
  Future<List<OfflineInventoryCountDraft>> fetchDrafts({
    required String userId,
    required String warehouseNo,
  }) async {
    return <OfflineInventoryCountDraft>[];
  }

  @override
  Future<OfflineInventoryCountDraft?> findDraft(String id) async => null;

  @override
  Future<void> saveDraft(OfflineInventoryCountDraft draft) async {}
}
