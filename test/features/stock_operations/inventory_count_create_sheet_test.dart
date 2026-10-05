import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/presentation/widgets/inventory_count_create_sheet.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';

import '../../support/barcode_resolution_test_data.dart';
import '../../support/memory_local_database.dart';
import '../../support/pda_create_screen_contract.dart';

void main() {
  testWidgets('passes pda create screen contract with keyboard inset', (
    tester,
  ) async {
    await expectPdaCreateScreenContract(
      tester,
      buildSubject: () => InventoryCountCreateSheet(
        repository: _FakeInventoryCountsRepository(),
        accessToken: 'token',
        defaultWarehouseNo: '110',
        mobileProductCatalogRepository: MobileProductCatalogLocalRepository(
          database: MemoryLocalDatabase(),
        ),
      ),
      entryRowFinder: find.text('Giris satiri'),
      saveButtonFinder: find.widgetWithText(FilledButton, 'Sayimi Kaydet'),
    );
  });

  testWidgets(
    'shows the existing list quantity when a counted product returns',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryCountCreateSheet(
              repository: _FakeInventoryCountsRepository(),
              accessToken: 'token',
              defaultWarehouseNo: '110',
              mobileProductCatalogRepository:
                  MobileProductCatalogLocalRepository(
                    database: MemoryLocalDatabase(),
                  ),
            ),
          ),
        ),
      );

      Future<void> scanTestProduct() async {
        final lookup = find.widgetWithText(
          TextFormField,
          'Barkod / stok kodu / urun adi',
        );
        await tester.enterText(lookup, '8690000000012');
        await tester.tap(find.widgetWithText(FilledButton, 'Urun').first);
        await tester.pumpAndSettle();
      }

      await scanTestProduct();
      expect(find.text('Ekle'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Ekle'));
      await tester.pumpAndSettle();

      await scanTestProduct();

      expect(find.text('Listede: 1 AD'), findsOneWidget);
      expect(find.textContaining('Kaleme Ekle'), findsNothing);
    },
  );

  testWidgets(
    'shows the updated total when the same barcode is scanned again',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryCountCreateSheet(
              repository: _FakeInventoryCountsRepository(),
              accessToken: 'token',
              defaultWarehouseNo: '110',
              mobileProductCatalogRepository:
                  MobileProductCatalogLocalRepository(
                    database: MemoryLocalDatabase(),
                  ),
            ),
          ),
        ),
      );

      final firstLookup = find.widgetWithText(
        TextFormField,
        'Barkod / stok kodu / urun adi',
      );
      await tester.enterText(firstLookup, '8690000000012');
      await tester.tap(find.widgetWithText(FilledButton, 'Urun').first);
      await tester.pumpAndSettle();

      final pendingLookup = find.widgetWithText(
        TextFormField,
        'Barkod okut / urun degistir',
      );
      await tester.enterText(pendingLookup, '8690000000012');
      await tester.tap(find.widgetWithText(FilledButton, 'Urun').first);
      await tester.pump();

      expect(find.text('Test Urun: toplam 2 AD sayildi.'), findsOneWidget);
    },
  );
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
  }) {
    throw UnimplementedError();
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
  }) async {
    return buildBarcodeResolutionResult(
      barcode: request.barcode,
      warehouseNo: int.tryParse(request.warehouseNo ?? '') ?? 110,
      operationType: request.operationType ?? '',
      screenCode: request.screenCode ?? '',
    );
  }

  @override
  Future<List<InventoryCountProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
    bool includeDelisted = true,
  }) async {
    return const <InventoryCountProductLookupItem>[];
  }
}
