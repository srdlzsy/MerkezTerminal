import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/models/company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/presentation/widgets/company_acceptance_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/given_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';

import '../../support/memory_local_database.dart';
import '../../support/pda_create_screen_contract.dart';

void main() {
  testWidgets('passes pda create screen contract with keyboard inset', (
    tester,
  ) async {
    await expectPdaCreateScreenContract(
      tester,
      buildSubject: () => CompanyAcceptanceCreateSheet(
        repository: _FakeCompanyAcceptancesRepository(),
        ordersRepository: _FakeGivenCompanyOrdersRepository(),
        accessToken: 'token',
        defaultWarehouseNo: '110',
        mobileCustomerCatalogRepository: MobileCustomerCatalogLocalRepository(
          database: MemoryLocalDatabase(),
        ),
        mobileProductCatalogRepository: MobileProductCatalogLocalRepository(
          database: MemoryLocalDatabase(),
        ),
      ),
      prepare: _goToLineStepIfNeeded,
      entryRowFinder: find.text('Giris satiri'),
      saveButtonFinder: find.widgetWithText(FilledButton, 'Mal Kabul Et'),
    );
  });

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
      expect(find.text('Test Urun'), findsOneWidget);
      expect(find.text('015792'), findsOneWidget);
      expect(find.text('KL'), findsOneWidget);

      await _pickProduct(tester);

      expect(find.text('Test Urun'), findsOneWidget);
      expect(find.text('4'), findsNWidgets(2));
    },
  );

  testWidgets('renders two-step company acceptance flow on terminal width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 780);
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
            mobileProductCatalogRepository: MobileProductCatalogLocalRepository(
              database: MemoryLocalDatabase(),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Belge'), findsWidgets);
    expect(find.text('Kalemler'), findsOneWidget);

    await _goToLineStepIfNeeded(tester);

    expect(find.text('Giris satiri'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Barkod / stok kodu / urun adi'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows Turkish length validation for company acceptance header', (
    tester,
  ) async {
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
            mobileProductCatalogRepository: MobileProductCatalogLocalRepository(
              database: MemoryLocalDatabase(),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cari Arama'),
      'Test Cari',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cari Kodu*'),
      'CR001',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Belge No / Seri'),
      'BELGE-NO-BU-COK-UZUN-OLAN-BIR-DEGER',
    );
    await tester.pump();

    final nextButton = find.widgetWithText(FilledButton, 'Kalemlere Gec');
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Belge no / seri en fazla 29 karakter olabilir'),
      findsOneWidget,
    );
    expect(
      find
          .widgetWithText(TextFormField, 'Barkod / stok kodu / urun adi')
          .evaluate(),
      isEmpty,
    );
  });

  testWidgets('shows editable dispatch and actual quantities before add', (
    tester,
  ) async {
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
            mobileProductCatalogRepository: MobileProductCatalogLocalRepository(
              database: MemoryLocalDatabase(),
            ),
          ),
        ),
      ),
    );

    await _selectProductWithoutConfirm(tester);

    expect(
      find.widgetWithText(TextFormField, 'Irsaliye Miktari*'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'Fiili Kabul*'), findsOneWidget);

    final dispatchField = find.widgetWithText(
      TextFormField,
      'Irsaliye Miktari*',
    );
    final acceptedField = find.widgetWithText(TextFormField, 'Fiili Kabul*');

    await tester.enterText(dispatchField, '7');
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.widget<TextFormField>(acceptedField).controller?.text, '7');

    await tester.enterText(acceptedField, '5');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(dispatchField, '9');
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.widget<TextFormField>(acceptedField).controller?.text, '5');

    final lookupField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Barkod / stok kodu / urun adi').first,
    );
    expect(lookupField.controller?.text, isEmpty);
    expect(lookupField.controller?.selection.isCollapsed, isTrue);
  });

  testWidgets(
    'keeps e-document lookup compact when focused on terminal width',
    (tester) async {
      tester.view.physicalSize = const Size(320, 780);
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

      final ettnField = find.widgetWithText(TextFormField, 'ETTN / QR');
      expect(ettnField, findsOneWidget);

      final fieldHeight = tester.getSize(ettnField).height;
      final selectorBottom = tester.getBottomLeft(find.text('Kalemler')).dy;
      expect(tester.getTopLeft(ettnField).dy, greaterThan(selectorBottom));

      await tester.tap(ettnField);
      await tester.pumpAndSettle();
      await tester.enterText(ettnField, '12345678-1234-1234-1234-123456789012');
      await tester.pumpAndSettle();

      expect(tester.getSize(ettnField).height, fieldHeight);
      expect(tester.getTopLeft(ettnField).dy, greaterThan(selectorBottom));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('allows supplier document date before movement date', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final draft =
        CreateDraft.empty(
          moduleKey: 'mal-kabul-islemleri.firma-mal-kabulleri',
          userId: '7',
          warehouseNo: '110',
          title: 'Yeni Firma Mal Kabul',
        ).copyWith(
          payload: <String, dynamic>{
            'customerText': 'Test Cari',
            'customerCode': 'CR001',
            'movementDate': '2026-08-05T00:00:00',
            'documentDate': '2026-08-01T00:00:00',
          },
        );

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
            mobileProductCatalogRepository: MobileProductCatalogLocalRepository(
              database: MemoryLocalDatabase(),
            ),
            draft: draft,
          ),
        ),
      ),
    );

    await _goToLineStepIfNeeded(tester);

    expect(find.text('Giris satiri'), findsOneWidget);
    expect(
      find.text('Belge tarihi hareket tarihinden sonra olamaz.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('carries resolved official document fields into create request', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeCompanyAcceptancesRepository()
      ..eDocumentPrefill = _buildEDespatchPrefill();
    CompanyAcceptanceCreateRequest? capturedRequest;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    capturedRequest = await Navigator.of(context)
                        .push<CompanyAcceptanceCreateRequest>(
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              body: CompanyAcceptanceCreateSheet(
                                repository: repository,
                                ordersRepository:
                                    _FakeGivenCompanyOrdersRepository(),
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
                  },
                  child: const Text('Ac'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Ac'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'ETTN / QR'),
      '3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Bul').first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await _pickProduct(tester);
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Mal Kabul Et'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Mal Kabul Et'));
    await tester.pumpAndSettle();

    expect(capturedRequest, isNotNull);
    expect(capturedRequest!.officialDocumentKind, 'e-despatch');
    expect(capturedRequest!.officialDocumentNo, 'ST12026000002395');
    expect(capturedRequest!.officialDocumentDate, DateTime(2026, 4, 20));
    expect(
      capturedRequest!.officialDocumentEttn,
      '3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111',
    );
    expect(capturedRequest!.toJson()['officialDocumentKind'], 'e-despatch');
  });

  testWidgets('autosaves and restores company acceptance draft fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = MemoryLocalDatabase();
    final draftRepository = LocalCreateDraftRepository(database: database);
    final draft = CreateDraft.empty(
      moduleKey: 'mal-kabul-islemleri.firma-mal-kabulleri',
      userId: '7',
      warehouseNo: '110',
      title: 'Yeni Firma Mal Kabul',
    );

    Widget buildSheet(CreateDraft currentDraft) {
      return MaterialApp(
        home: Scaffold(
          body: CompanyAcceptanceCreateSheet(
            key: ValueKey(currentDraft.updatedAt.microsecondsSinceEpoch),
            repository: _FakeCompanyAcceptancesRepository(),
            ordersRepository: _FakeGivenCompanyOrdersRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            mobileCustomerCatalogRepository:
                MobileCustomerCatalogLocalRepository(database: database),
            mobileProductCatalogRepository: MobileProductCatalogLocalRepository(
              database: database,
            ),
            draft: currentDraft,
            draftRepository: draftRepository,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildSheet(draft));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cari Arama'),
      'Test Cari',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cari Kodu*'),
      'CR001',
    );
    await tester.pump();

    final immediateDrafts = await draftRepository.fetchDrafts(
      moduleKey: 'mal-kabul-islemleri.firma-mal-kabulleri',
      userId: '7',
      warehouseNo: '110',
    );
    expect(immediateDrafts, hasLength(1));
    expect(immediateDrafts.single.payload['customerText'], 'Test Cari');
    expect(immediateDrafts.single.payload['customerCode'], 'CR001');

    await _pickProduct(tester);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();

    final savedDrafts = await draftRepository.fetchDrafts(
      moduleKey: 'mal-kabul-islemleri.firma-mal-kabulleri',
      userId: '7',
      warehouseNo: '110',
    );
    expect(savedDrafts, hasLength(1));
    expect(savedDrafts.single.payload['customerText'], 'Test Cari');
    expect(savedDrafts.single.payload['customerCode'], 'CR001');
    final lines = savedDrafts.single.payload['lines'] as List<dynamic>;
    expect(lines, hasLength(1));
    expect((lines.single as Map<String, dynamic>)['stockCode'], '015792');

    await tester.pumpWidget(buildSheet(savedDrafts.single));
    await tester.pump();

    if (find.widgetWithText(TextFormField, 'Cari Arama').evaluate().isEmpty) {
      await tester.tap(find.text('Belge').first);
      await tester.pumpAndSettle();
    }

    final customerField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Cari Arama'),
    );
    final customerCodeField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Cari Kodu*'),
    );
    expect(customerField.controller?.text, 'Test Cari');
    expect(customerCodeField.controller?.text, 'CR001');
    await _goToLineStepIfNeeded(tester);
    expect(find.text('Test Urun'), findsOneWidget);
    expect(find.text('015792'), findsOneWidget);
    expect(find.text('KL'), findsOneWidget);
  });
}

Future<void> _pickProduct(WidgetTester tester) async {
  await _selectProductWithoutConfirm(tester);
  await _confirmPendingProduct(tester);
}

Future<void> _selectProductWithoutConfirm(WidgetTester tester) async {
  await _goToLineStepIfNeeded(tester);

  final lookupFinder = find.widgetWithText(
    TextFormField,
    'Barkod / stok kodu / urun adi',
  );

  await tester.enterText(lookupFinder.first, '8690000000012');

  final searchButton = find.widgetWithText(FilledButton, 'Urun').first;
  await tester.ensureVisible(searchButton);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Urun').first);
  await tester.pumpAndSettle();

  expect(find.text('Urun Ara'), findsNothing);
}

Future<void> _confirmPendingProduct(WidgetTester tester) async {
  final addButton = find.widgetWithText(FilledButton, 'Kaleme Ekle').first;
  await tester.ensureVisible(addButton);
  await tester.pumpAndSettle();
  await tester.tap(addButton);
  await tester.pumpAndSettle();
}

Future<void> _goToLineStepIfNeeded(WidgetTester tester) async {
  if (find
      .widgetWithText(TextFormField, 'Barkod / stok kodu / urun adi')
      .evaluate()
      .isNotEmpty) {
    return;
  }

  final customerField = find.widgetWithText(TextFormField, 'Cari Arama');
  if (customerField.evaluate().isNotEmpty) {
    final widget = tester.widget<TextFormField>(customerField.first);
    if ((widget.controller?.text.trim() ?? '').isEmpty) {
      await tester.enterText(customerField.first, 'Test Cari');
    }
  }

  final customerCodeField = find.widgetWithText(TextFormField, 'Cari Kodu*');
  if (customerCodeField.evaluate().isNotEmpty) {
    final widget = tester.widget<TextFormField>(customerCodeField.first);
    if ((widget.controller?.text.trim() ?? '').isEmpty) {
      await tester.enterText(customerCodeField.first, 'CR001');
    }
  }

  await tester.pump();
  final nextButton = find.widgetWithText(FilledButton, 'Kalemlere Gec');
  await tester.ensureVisible(nextButton);
  await tester.pumpAndSettle();
  await tester.tap(nextButton);
  await tester.pumpAndSettle();
}

class _FakeCompanyAcceptancesRepository
    implements CompanyAcceptancesRepository {
  CompanyAcceptanceEDespatchPrefill? eDocumentPrefill;

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
    final prefill = eDocumentPrefill;
    if (prefill == null) {
      throw UnimplementedError();
    }

    return Future<CompanyAcceptanceEDespatchPrefill>.value(prefill);
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

CompanyAcceptanceEDespatchPrefill _buildEDespatchPrefill() {
  return CompanyAcceptanceEDespatchPrefill(
    isFound: true,
    warehouseNo: 110,
    receivingContext: 'firma-mal-kabulleri',
    ettn: '3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111',
    sourceDocumentKind: 'e-despatch',
    sourceDocumentLabel: 'E-Irsaliye',
    sourceDocumentNumber: 'ST12026000002395',
    despatchNumber: 'ST12026000002395',
    issueDate: DateTime(2026, 4, 20),
    actualDespatchDate: DateTime(2026, 4, 20),
    profileId: '',
    despatchAdviceTypeCode: 'SEVK',
    invoiceNumber: '',
    invoiceDate: null,
    invoiceTotal: null,
    taxExclusiveAmount: null,
    taxTotal: null,
    currencyCode: '',
    despatchReferences: const <String>[],
    warnings: const <String>[],
    notes: const <String>[],
    sender: const CompanyAcceptanceEDespatchParty(
      title: 'ORNEK TEDARIKCI A.S.',
      taxNoOrTckn: '1234567890',
      alias: '',
      city: '',
    ),
    receiver: const CompanyAcceptanceEDespatchParty(
      title: 'FURPA KESTEL 1',
      taxNoOrTckn: '0987654321',
      alias: '',
      city: '',
    ),
    primaryCustomerSuggestion: const CompanyAcceptanceCustomerSuggestion(
      customerCode: 'CR001',
      customerName: 'Test Cari',
      taxNoOrTckn: '1234567890',
      matchReason: 'vkn-tckn',
      isPrimarySuggestion: true,
    ),
    totalLineCount: 1,
    matchedLineCount: 1,
    unmatchedLineCount: 0,
    suggestedCustomers: const <CompanyAcceptanceCustomerSuggestion>[],
    lines: const <CompanyAcceptanceEDespatchLine>[],
  );
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

  @override
  Future<List<CompanyOrderProductLookupItem>> fetchCustomerProducts({
    required String accessToken,
    required String warehouseNo,
    required String customerCode,
    String? search,
    int take = 500,
  }) async {
    return const <CompanyOrderProductLookupItem>[];
  }
}
