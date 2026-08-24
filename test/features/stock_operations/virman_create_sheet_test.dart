import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/models/virman_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/virman_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/presentation/widgets/virman_create_sheet.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';

import '../../support/memory_local_database.dart';
import '../../support/pda_create_screen_contract.dart';

void main() {
  testWidgets('passes pda create screen contract with keyboard inset', (
    tester,
  ) async {
    await expectPdaCreateScreenContract(
      tester,
      buildSubject: () => VirmanCreateSheet(
        repository: _FakeVirmanRepository(),
        accessToken: 'token',
        defaultWarehouseNo: '110',
        mobileProductCatalogRepository: MobileProductCatalogLocalRepository(
          database: MemoryLocalDatabase(),
        ),
      ),
      entryRowFinder: find.text('Virman urunu ekle'),
      saveButtonFinder: find.widgetWithText(FilledButton, 'Virmani Kaydet'),
    );
  });
}

class _FakeVirmanRepository implements VirmanRepository {
  @override
  Future<VirmanCreateResult> createVirman({
    required String accessToken,
    required VirmanCreateRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<VirmanDetail> fetchVirmanDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<VirmanListItem>> fetchVirmans({
    required String accessToken,
    required VirmanListFilter filter,
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
