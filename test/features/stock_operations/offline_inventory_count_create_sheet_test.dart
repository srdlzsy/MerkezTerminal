import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/presentation/views/offline_inventory_counts_page.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';

import '../../support/memory_local_database.dart';
import '../../support/pda_create_screen_contract.dart';

void main() {
  testWidgets('passes pda create screen contract with keyboard inset', (
    tester,
  ) async {
    await expectPdaCreateScreenContract(
      tester,
      buildSubject: () => OfflineInventoryCountCreateSheet(
        onlineRepository: _FakeInventoryCountsRepository(),
        accessToken: 'token',
        currentUserId: 'user-1',
        defaultWarehouseNo: '110',
        mobileProductCatalogRepository: MobileProductCatalogLocalRepository(
          database: MemoryLocalDatabase(),
        ),
      ),
      entryRowFinder: find.text('Giris satiri'),
      saveButtonFinder: find.widgetWithText(FilledButton, 'Taslagi Kaydet'),
    );
  });

  testWidgets('shows the updated total after an offline repeat scan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineInventoryCountCreateSheet(
            onlineRepository: _FakeInventoryCountsRepository(),
            accessToken: 'token',
            currentUserId: 'user-1',
            defaultWarehouseNo: '110',
            mobileProductCatalogRepository: MobileProductCatalogLocalRepository(
              database: MemoryLocalDatabase(),
            ),
          ),
        ),
      ),
    );

    final firstLookup = find.widgetWithText(TextField, 'Online urun ara');
    await tester.enterText(firstLookup, '8690000000012');
    await tester.tap(find.widgetWithText(FilledButton, 'Bul').first);
    await tester.pumpAndSettle();

    final pendingLookup = find.widgetWithText(
      TextField,
      'Barkod okut / urun degistir',
    );
    await tester.enterText(pendingLookup, '8690000000012');
    await tester.tap(find.widgetWithText(FilledButton, 'Bul').first);
    await tester.pump();

    expect(find.text('Test Urun: toplam 2 AD sayildi.'), findsOneWidget);
  });
}

class _FakeInventoryCountsRepository implements InventoryCountsRepository {
  @override
  Future<InventoryCountCreateResult> createCount({
    required String accessToken,
    required InventoryCountCreateRequest request,
  }) => throw UnimplementedError();

  @override
  Future<InventoryCountDetail> fetchCountDetail({
    required String accessToken,
    required int documentNo,
    required DateTime documentDate,
    required String warehouseNo,
  }) => throw UnimplementedError();

  @override
  Future<List<InventoryCountListItem>> fetchCounts({
    required String accessToken,
    required InventoryCountListFilter filter,
  }) async => const <InventoryCountListItem>[];

  @override
  Future<InventoryCountOfflineSyncStatus> fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
  }) => throw UnimplementedError();

  @override
  Future<BarcodeResolutionResult> resolveBarcode({
    required String accessToken,
    required BarcodeResolutionRequest request,
  }) => throw UnimplementedError();

  @override
  Future<List<InventoryCountProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
    bool includeDelisted = true,
  }) async => const <InventoryCountProductLookupItem>[
    InventoryCountProductLookupItem(
      warehouseNo: 110,
      barcode: '8690000000012',
      stockCode: '015792',
      stockName: 'Test Urun',
      unitName: 'AD',
      price: 125,
      isGoodsAcceptanceBlocked: false,
    ),
  ];
}
