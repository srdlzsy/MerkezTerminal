import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/company_movements_repository.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/presentation/views/company_movements_page.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/presentation/widgets/company_movement_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_repository.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_status.dart';
import 'package:furpa_merkez_terminal/shared/pending_create/pending_create_repository.dart';

import '../../support/barcode_resolution_test_data.dart';
import '../../support/memory_local_database.dart';
import '../../support/pda_create_screen_contract.dart';

void main() {
  testWidgets('prefills customer carried from cari lookup', (tester) async {
    const customer = CustomerLookupItem(
      customerCode: 'CR001',
      customerName: 'Tasinan Firma',
      customerTitle: 'Tasinan Firma A.S.',
      customerDisplayName: 'Tasinan Firma',
      taxNumber: '1234567890',
      representativeCode: '',
      representativeName: '',
      invoiceAddressNo: 1,
      shippingAddressNo: 1,
      isLocked: false,
      isClosed: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanyMovementCreateSheet(
            repository: _FakeCompanyMovementsRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '50',
            mobileCustomerCatalogRepository: _emptyCustomerCatalogRepository(),
            title: 'Yeni Firma Iadesi',
            helperText: '',
            submitLabel: 'Kaydet',
            initialCustomer: customer,
          ),
        ),
      ),
    );

    final customerField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Cari'),
    );
    expect(customerField.controller?.text, contains('Tasinan Firma'));
  });

  testWidgets('opens detail page before detail request completes', (
    tester,
  ) async {
    final detailCompleter = Completer<CompanyMovementDetail>();
    final item = CompanyMovementListItem.fromJson(<String, dynamic>{
      'documentSerie': 'F50',
      'documentOrderNo': 42,
      'customerCode': 'CARI-1',
      'customerDisplayName': 'Test Cari',
      'warehouseNo': 50,
      'warehouseName': 'MERKEZ DEPO',
      'lineCount': 1,
      'totalQuantity': 2,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CompanyMovementsPage(
          repository: _FakeCompanyMovementsRepository(
            movements: <CompanyMovementListItem>[item],
            detailCompleter: detailCompleter,
          ),
          accessToken: 'token',
          canCreate: false,
          pendingCreateRepository: LocalPendingCreateRepository(
            database: MemoryLocalDatabase(),
          ),
          defaultWarehouseNo: '50',
          mobileCustomerCatalogRepository: _emptyCustomerCatalogRepository(),
          userWarehouseName: 'MERKEZ DEPO',
          title: 'Firma Iadeleri',
          subtitle: 'Firma iade evraklari listelenir.',
          createTitle: 'Yeni Iade',
          createHelperText: 'Cari secildikten sonra iade satirlari eklenir.',
          createButtonLabel: 'Yeni Iade',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final documentFinder = find.text('F50.42').hitTestable();
    await tester.ensureVisible(find.text('F50.42'));
    await tester.pumpAndSettle();
    expect(documentFinder, findsOneWidget);

    await tester.tap(documentFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('F50.42')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    detailCompleter.complete(
      CompanyMovementDetail.fromJson(<String, dynamic>{
        'header': <String, dynamic>{
          'documentSerie': 'F50',
          'documentOrderNo': 42,
        },
        'items': <dynamic>[],
      }),
    );
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(AppBar))).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('opens company return create sheet from header action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanyMovementsPage(
            repository: _FakeCompanyMovementsRepository(),
            accessToken: 'token',
            canCreate: true,
            defaultWarehouseNo: '50',
            mobileCustomerCatalogRepository: _emptyCustomerCatalogRepository(),
            userWarehouseName: 'MERKEZ DEPO',
            title: 'Firma Iadeleri',
            subtitle: 'Firma iade evraklari listelenir.',
            createTitle: 'Yeni  Iade',
            createHelperText: 'Cari secildikten sonra iade satirlari eklenir.',
            createButtonLabel: 'Yeni  Iade',
            pendingCreateRepository: LocalPendingCreateRepository(
              database: MemoryLocalDatabase(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yeni  Iade'), findsOneWidget);

    await tester.tap(find.text('Yeni  Iade'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Cari'), findsOneWidget);
    expect(find.text('Satirlar'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Kaydet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Yeni  Iade'), findsNothing);
  });

  testWidgets('restores a persisted uncertain create with the same request', (
    tester,
  ) async {
    final database = MemoryLocalDatabase();
    final pendingRepository = LocalPendingCreateRepository(database: database);
    final repository = _FakeCompanyMovementsRepository(
      createError: const ApiException(
        statusCode: 409,
        title: 'Islem devam ediyor',
        errorCode: 'MIKRO_WRITE_IN_PROGRESS',
        retryable: true,
      ),
    );
    await pendingRepository.save(
      PendingCreateOperation(
        moduleKey: 'iade-islemleri.firma-iadeleri',
        userId: 'user-1',
        warehouseNo: '50',
        payload: CompanyMovementCreateRequest(
          clientRequestId: 'request-1',
          customerCode: 'CARI-1',
          movementDate: DateTime(2026, 10, 1),
          documentDate: DateTime(2026, 10, 1),
          documentNo: '',
          description: '',
          deliverer: '',
          receiver: '',
          lines: const <CompanyMovementCreateLine>[
            CompanyMovementCreateLine(
              stockCode: 'STOK-1',
              quantity: 2,
              unitPrice: 0,
              unitPointer: 1,
              description: '',
              partyCode: '',
              lotNo: 0,
              projectCode: '',
              customerResponsibilityCenter: '',
              productResponsibilityCenter: '',
            ),
          ],
        ).toJson(),
        updatedAt: DateTime(2026, 10, 1),
        failureKind: 'uncertain',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanyMovementsPage(
            repository: repository,
            accessToken: 'token',
            canCreate: true,
            currentUserId: 'user-1',
            draftModuleKey: 'iade-islemleri.firma-iadeleri',
            pendingCreateRepository: pendingRepository,
            defaultWarehouseNo: '50',
            mobileCustomerCatalogRepository: _emptyCustomerCatalogRepository(),
            userWarehouseName: 'MERKEZ DEPO',
            title: 'Firma Iadeleri',
            subtitle: 'Firma iade evraklari listelenir.',
            createTitle: 'Yeni Iade',
            createHelperText: 'Cari secildikten sonra iade satirlari eklenir.',
            createButtonLabel: 'Yeni Iade',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Durumu Kontrol Et'), findsNothing);
    expect(find.text('Yeni Iade'), findsOneWidget);
    expect(repository.createRequests, isEmpty);
    expect(repository.fetchOfflineSyncStatusCallCount, 1);
  });

  testWidgets(
    'reconciles and clears a completed pending create automatically',
    (tester) async {
      final database = MemoryLocalDatabase();
      final pendingRepository = LocalPendingCreateRepository(
        database: database,
      );
      await pendingRepository.save(
        _pendingCompanyMovement(failureKind: 'processing'),
      );
      final completedResult = CompanyMovementCreateResult(
        documentSerie: 'F50',
        documentOrderNo: 87990,
        movementDate: DateTime(2026, 10, 1),
        documentDate: DateTime(2026, 10, 1),
        documentNo: '',
        warehouseNo: 50,
        customerCode: 'CARI-1',
        lineCount: 1,
        totalQuantity: 2,
        totalAmount: 0,
        writeConnectionName: 'Mikro',
      );
      final repository = _FakeCompanyMovementsRepository(
        offlineSyncStatus: OfflineSyncStatus<CompanyMovementCreateResult>(
          clientRequestId: 'request-1',
          operationCode: 'iade-islemleri.firma-iadeleri.create',
          status: 'Completed',
          createdAtUtc: DateTime.utc(2026, 10, 1),
          completedAtUtc: DateTime.utc(2026, 10, 1, 0, 1),
          errorMessage: null,
          errorCode: null,
          retryable: false,
          retryAfterSeconds: null,
          result: completedResult,
          recommendedAction: 'Completed',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _companyMovementsPage(
              pendingRepository,
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.createRequests, isEmpty);
      expect(repository.fetchOfflineSyncStatusCallCount, 1);
      expect(repository.fetchMovementsCallCount, 2);
      expect(find.text('Durumu Kontrol Et'), findsNothing);
      expect(find.text('Yeni Iade'), findsOneWidget);
      expect(
        await pendingRepository.read(
          moduleKey: 'iade-islemleri.firma-iadeleri',
          userId: 'user-1',
          warehouseNo: '50',
        ),
        isNull,
      );
    },
  );

  testWidgets('clears legacy manual review without blocking new creates', (
    tester,
  ) async {
    final database = MemoryLocalDatabase();
    final pendingRepository = LocalPendingCreateRepository(database: database);
    await pendingRepository.save(
      _pendingCompanyMovement(failureKind: 'manualReview'),
    );

    await tester.pumpWidget(
      MaterialApp(home: _companyMovementsPage(pendingRepository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Destek gerekli'), findsNothing);
    expect(find.text('Yeni Iade'), findsOneWidget);
    expect(
      await pendingRepository.read(
        moduleKey: 'iade-islemleri.firma-iadeleri',
        userId: 'user-1',
        warehouseNo: '50',
      ),
      isNull,
    );
  });

  testWidgets(
    'keeps retryable failed create pending and allows independent new',
    (tester) async {
      final database = MemoryLocalDatabase();
      final pendingRepository = LocalPendingCreateRepository(
        database: database,
      );
      await pendingRepository.save(
        _pendingCompanyMovement(failureKind: 'uncertain'),
      );
      final repository = _FakeCompanyMovementsRepository(
        createError: const ApiException(
          statusCode: 409,
          title: 'Sonuc dogrulanamadi',
          errorCode: 'MIKRO_WRITE_OUTCOME_UNCONFIRMED',
          retryable: true,
        ),
        offlineSyncStatus: OfflineSyncStatus<CompanyMovementCreateResult>(
          clientRequestId: 'request-1',
          operationCode: 'iade-islemleri.firma-iadeleri.create',
          status: 'Failed',
          createdAtUtc: DateTime.utc(2026, 10, 13, 8),
          completedAtUtc: null,
          errorMessage: 'Mikro yazim sonucu dogrulanamadi.',
          errorCode: 'MIKRO_WRITE_OUTCOME_UNCONFIRMED',
          retryable: true,
          retryAfterSeconds: 60,
          result: null,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _companyMovementsPage(
              pendingRepository,
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.createRequests, isEmpty);
      expect(repository.fetchOfflineSyncStatusCallCount, 1);
      expect(find.text('Durumu Kontrol Et'), findsNothing);
      expect(find.text('Yeni Iade'), findsOneWidget);
      expect(
        await pendingRepository.read(
          moduleKey: 'iade-islemleri.firma-iadeleri',
          userId: 'user-1',
          warehouseNo: '50',
        ),
        isNotNull,
      );
    },
  );

  testWidgets(
    'clears payload mismatch and returns to the normal create action',
    (tester) async {
      final database = MemoryLocalDatabase();
      final pendingRepository = LocalPendingCreateRepository(
        database: database,
      );
      await pendingRepository.save(
        _pendingCompanyMovement(failureKind: 'payloadChanged'),
      );

      await tester.pumpWidget(
        MaterialApp(home: _companyMovementsPage(pendingRepository)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yeni Bagimsiz Islem'), findsNothing);
      expect(find.text('Yeni Iade'), findsOneWidget);
      await tester.tap(find.text('Yeni Iade'));
      await tester.pumpAndSettle();

      expect(find.text('Cari'), findsOneWidget);
      expect(
        await pendingRepository.read(
          moduleKey: 'iade-islemleri.firma-iadeleri',
          userId: 'user-1',
          warehouseNo: '50',
        ),
        isNull,
      );
    },
  );

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
          body: CompanyMovementCreateSheet(
            repository: _FakeCompanyMovementsRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '50',
            mobileCustomerCatalogRepository: _emptyCustomerCatalogRepository(),
            title: 'Yeni Firma Iadesi',
            helperText: 'Cari secildikten sonra iade satirlari eklenir.',
            submitLabel: 'Iadeyi Kaydet',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Yeni Firma Iadesi'), findsOneWidget);
    expect(find.text('Cari'), findsOneWidget);
  });

  testWidgets('passes pda create screen contract with keyboard inset', (
    tester,
  ) async {
    await expectPdaCreateScreenContract(
      tester,
      buildSubject: () => CompanyMovementCreateSheet(
        repository: _FakeCompanyMovementsRepository(
          barcodeResolution: buildBarcodeResolutionResult(
            operationType: 'shipment',
            screenCode: 'giden-firma-sevkleri',
          ),
        ),
        accessToken: 'token',
        defaultWarehouseNo: '50',
        mobileCustomerCatalogRepository: _emptyCustomerCatalogRepository(),
        title: 'Yeni Firma Iadesi',
        helperText: 'Cari secildikten sonra iade satirlari eklenir.',
        submitLabel: 'Iadeyi Kaydet',
      ),
      prepare: _addCompanyMovementLine,
      entryRowFinder: find.text('Giris satiri'),
      saveButtonFinder: find.widgetWithText(FilledButton, 'Iadeyi Kaydet'),
      lineItemFinder: find.text('Test Urun'),
    );
  });

  testWidgets('unit barcode starts from one even when package factor is 12', (
    tester,
  ) async {
    final repository = _FakeCompanyMovementsRepository(
      barcodeResolution: buildBarcodeResolutionResult(
        unitMultiplier: 12,
        operationType: 'shipment',
        screenCode: 'giden-firma-sevkleri',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanyMovementCreateSheet(
            repository: repository,
            accessToken: 'token',
            defaultWarehouseNo: '50',
            mobileCustomerCatalogRepository: _emptyCustomerCatalogRepository(),
            title: 'Yeni Firma Sevki',
            helperText: 'Sevk satirlari eklenir.',
            submitLabel: 'Kaydet',
          ),
        ),
      ),
    );

    final lookup = find.byType(TextFormField).last;
    await tester.enterText(lookup, '8690000000012');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repository.barcodeRequests, hasLength(1));
    final hasQuantityOne = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .any((field) => field.controller?.text == '1');
    expect(hasQuantityOne, isTrue);
  });

  testWidgets('autosaves and restores company movement draft fields', (
    tester,
  ) async {
    final database = MemoryLocalDatabase();
    final draftRepository = LocalCreateDraftRepository(database: database);
    final draft = CreateDraft.empty(
      moduleKey: 'company-shipment',
      userId: '7',
      warehouseNo: '50',
      title: 'Yeni Firma Sevki',
    );

    Widget buildSheet(CreateDraft currentDraft) {
      return MaterialApp(
        home: Scaffold(
          body: CompanyMovementCreateSheet(
            repository: _FakeCompanyMovementsRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '50',
            mobileCustomerCatalogRepository: _emptyCustomerCatalogRepository(),
            title: 'Yeni Firma Sevki',
            helperText: 'Sevk satirlari eklenir.',
            submitLabel: 'Kaydet',
            draft: currentDraft,
            draftRepository: draftRepository,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildSheet(draft));
    await tester.enterText(find.byType(TextFormField).first, 'Cari-42');
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();

    final savedDrafts = await draftRepository.fetchDrafts(
      moduleKey: 'company-shipment',
      userId: '7',
      warehouseNo: '50',
    );
    expect(savedDrafts, hasLength(1));
    expect(savedDrafts.single.payload['customerText'], 'Cari-42');

    await tester.pumpWidget(buildSheet(savedDrafts.single));
    await tester.pump();

    final customerField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(customerField.controller?.text, 'Cari-42');
  });
}

Future<void> _addCompanyMovementLine(WidgetTester tester) async {
  final lookup = find.byType(TextFormField).last;
  await tester.enterText(lookup, '8690000000012');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  final addButton = find.widgetWithText(FilledButton, 'Ekle').first;
  await tester.ensureVisible(addButton);
  await tester.tap(addButton);
  await tester.pumpAndSettle();
}

MobileCustomerCatalogLocalRepository _emptyCustomerCatalogRepository() {
  return MobileCustomerCatalogLocalRepository(database: MemoryLocalDatabase());
}

CompanyMovementsPage _companyMovementsPage(
  PendingCreateRepository pendingRepository, {
  CompanyMovementsRepository? repository,
}) {
  return CompanyMovementsPage(
    repository: repository ?? _FakeCompanyMovementsRepository(),
    accessToken: 'token',
    canCreate: true,
    currentUserId: 'user-1',
    draftModuleKey: 'iade-islemleri.firma-iadeleri',
    pendingCreateRepository: pendingRepository,
    defaultWarehouseNo: '50',
    mobileCustomerCatalogRepository: _emptyCustomerCatalogRepository(),
    userWarehouseName: 'MERKEZ DEPO',
    title: 'Firma Iadeleri',
    subtitle: 'Firma iade evraklari listelenir.',
    createTitle: 'Yeni Iade',
    createHelperText: 'Cari secildikten sonra iade satirlari eklenir.',
    createButtonLabel: 'Yeni Iade',
  );
}

PendingCreateOperation _pendingCompanyMovement({required String failureKind}) {
  return PendingCreateOperation(
    moduleKey: 'iade-islemleri.firma-iadeleri',
    userId: 'user-1',
    warehouseNo: '50',
    payload: CompanyMovementCreateRequest(
      clientRequestId: 'request-1',
      customerCode: 'CARI-1',
      movementDate: DateTime(2026, 10, 1),
      documentDate: DateTime(2026, 10, 1),
      documentNo: '',
      description: '',
      deliverer: '',
      receiver: '',
      lines: const <CompanyMovementCreateLine>[
        CompanyMovementCreateLine(
          stockCode: 'STOK-1',
          quantity: 2,
          unitPrice: 0,
          unitPointer: 1,
          description: '',
          partyCode: '',
          lotNo: 0,
          projectCode: '',
          customerResponsibilityCenter: '',
          productResponsibilityCenter: '',
        ),
      ],
    ).toJson(),
    updatedAt: DateTime(2026, 10, 1),
    failureKind: failureKind,
  );
}

class _FakeCompanyMovementsRepository
    implements
        CompanyMovementsRepository,
        BarcodeResolutionRepository,
        OfflineSyncStatusProvider<CompanyMovementCreateResult> {
  _FakeCompanyMovementsRepository({
    this.movements = const <CompanyMovementListItem>[],
    this.detailCompleter,
    this.createError,
    this.offlineSyncStatus,
    this.barcodeResolution,
  });

  final List<CompanyMovementListItem> movements;
  final Completer<CompanyMovementDetail>? detailCompleter;
  final ApiException? createError;
  final OfflineSyncStatus<CompanyMovementCreateResult>? offlineSyncStatus;
  final BarcodeResolutionResult? barcodeResolution;
  final List<BarcodeResolutionRequest> barcodeRequests =
      <BarcodeResolutionRequest>[];
  int fetchOfflineSyncStatusCallCount = 0;
  int fetchMovementsCallCount = 0;
  final List<CompanyMovementCreateRequest> createRequests =
      <CompanyMovementCreateRequest>[];

  @override
  bool get supportsCreate => true;

  @override
  bool get supportsEDespatch => true;

  @override
  Future<BarcodeResolutionResult> resolveBarcode({
    required String accessToken,
    required BarcodeResolutionRequest request,
  }) async {
    barcodeRequests.add(request);
    final resolution = barcodeResolution;
    if (resolution == null) {
      throw const ApiException(statusCode: 404, title: 'Bulunamadi');
    }
    return resolution;
  }

  @override
  Future<CompanyMovementCreateResult> createMovement({
    required String accessToken,
    required CompanyMovementCreateRequest request,
  }) async {
    createRequests.add(request);
    if (createError case final error?) {
      throw error;
    }
    throw UnimplementedError();
  }

  @override
  Future<OfflineSyncStatus<CompanyMovementCreateResult>>
  fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
  }) async {
    fetchOfflineSyncStatusCallCount += 1;
    final status = offlineSyncStatus;
    if (status != null) return status;
    throw const ApiException(statusCode: 404, title: 'Kayit bulunamadi');
  }

  @override
  Future<CompanyMovementPdfDocument> fetchEDespatchPdf({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    return CompanyMovementPdfDocument(
      fileName: 'test.pdf',
      bytes: Uint8List(0),
    );
  }

  @override
  Future<CompanyMovementDetail> fetchMovementDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) {
    if (detailCompleter case final completer?) {
      return completer.future;
    }
    throw UnimplementedError();
  }

  @override
  Future<List<CompanyMovementListItem>> fetchMovements({
    required String accessToken,
    required CompanyMovementListFilter filter,
  }) async {
    fetchMovementsCallCount += 1;
    return movements;
  }

  @override
  Future<EDespatchSendResult> sendEDespatch({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
    required EDespatchSendRequest request,
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
    bool includeDelisted = true,
  }) async {
    return const <SearchProductLookupItem>[];
  }
}
