import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/models/virman_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/virman_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/presentation/widgets/virman_create_sheet.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';

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

  testWidgets('reliable history suggestion adds incoming virman line', (
    tester,
  ) async {
    final repository = _FakeVirmanRepository(
      products: <SearchProductLookupItem>[_sourceProduct],
      suggestion: _reliableSuggestion,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VirmanCreateSheet(
            repository: repository,
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileProductCatalogRepository: MobileProductCatalogLocalRepository(
              database: MemoryLocalDatabase(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final lookup = find.descendant(
      of: find.byType(ProductLookupField),
      matching: find.byType(EditableText),
    );
    await tester.enterText(lookup, '015550');
    await tester.tap(find.widgetWithText(FilledButton, 'Urun').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Miktar').first,
      '6',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Ekle').first);
    await tester.pumpAndSettle();

    expect(repository.suggestionRequestCount, 1);
    expect(find.text('SODA SADE TEKLI'), findsOneWidget);
    expect(find.textContaining('Gecmis virmanlardan onerildi'), findsOneWidget);
    expect(find.textContaining('36'), findsWidgets);
    expect(find.textContaining('Giris'), findsWidgets);
  });
}

class _FakeVirmanRepository implements VirmanRepository {
  _FakeVirmanRepository({
    this.products = const <SearchProductLookupItem>[],
    this.suggestion,
  });

  final List<SearchProductLookupItem> products;
  final VirmanConversionSuggestion? suggestion;
  int suggestionRequestCount = 0;

  @override
  Future<VirmanConversionSuggestion> fetchConversionSuggestion({
    required String accessToken,
    required String sourceStockCode,
    required double sourceQuantity,
  }) async {
    suggestionRequestCount += 1;
    return suggestion ?? _unreliableSuggestion;
  }

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
    bool includeDelisted = true,
  }) async {
    return products;
  }
}

const SearchProductLookupItem _sourceProduct = SearchProductLookupItem(
  warehouseNo: 110,
  barcode: '8690000000001',
  stockCode: '015550',
  stockName: "SODA SADE 6'LI",
  price: 0,
  priceTypeCode: 0,
  unitName: 'ADET',
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
);

const VirmanConversionSuggestion _reliableSuggestion =
    VirmanConversionSuggestion(
      sourceStockCode: '015550',
      sourceStockName: "SODA SADE 6'LI",
      sourceUnitName: 'ADET',
      sourceQuantity: 6,
      targetStockCode: '015733',
      targetStockName: 'SODA SADE TEKLI',
      targetUnitName: 'ADET',
      multiplier: 6,
      targetQuantity: 36,
      sampleCount: 500,
      targetMatchCount: 500,
      multiplierMatchCount: 492,
      targetConfidencePercent: 100,
      multiplierConfidencePercent: 98.4,
      confidencePercent: 98.4,
      isReliable: true,
      suggestionSource: 'VirmanHistory',
      lookbackStartDate: null,
      lookbackEndDate: null,
      minimumSampleCount: 10,
      maximumSampleCount: 500,
      minimumConfidencePercent: 95,
      warning: null,
    );

const VirmanConversionSuggestion _unreliableSuggestion =
    VirmanConversionSuggestion(
      sourceStockCode: '',
      sourceStockName: '',
      sourceUnitName: '',
      sourceQuantity: 0,
      targetStockCode: null,
      targetStockName: null,
      targetUnitName: null,
      multiplier: null,
      targetQuantity: null,
      sampleCount: 0,
      targetMatchCount: 0,
      multiplierMatchCount: 0,
      targetConfidencePercent: 0,
      multiplierConfidencePercent: 0,
      confidencePercent: 0,
      isReliable: false,
      suggestionSource: 'None',
      lookbackStartDate: null,
      lookbackEndDate: null,
      minimumSampleCount: 10,
      maximumSampleCount: 500,
      minimumConfidencePercent: 95,
      warning: 'Guvenilir otomatik donusum bulunamadi.',
    );
