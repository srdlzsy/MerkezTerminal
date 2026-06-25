import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/company_movements_repository.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/presentation/views/company_movements_page.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/presentation/widgets/company_movement_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';

import '../../support/memory_local_database.dart';

void main() {
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
  });

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
    await tester.enterText(find.byType(TextFormField).at(1), 'IRS-42');
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();

    final savedDrafts = await draftRepository.fetchDrafts(
      moduleKey: 'company-shipment',
      userId: '7',
      warehouseNo: '50',
    );
    expect(savedDrafts, hasLength(1));
    expect(savedDrafts.single.payload['documentNo'], 'IRS-42');

    await tester.pumpWidget(buildSheet(savedDrafts.single));
    await tester.pump();

    final documentNoField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(1),
    );
    expect(documentNoField.controller?.text, 'IRS-42');
  });
}

MobileCustomerCatalogLocalRepository _emptyCustomerCatalogRepository() {
  return MobileCustomerCatalogLocalRepository(database: MemoryLocalDatabase());
}

class _FakeCompanyMovementsRepository implements CompanyMovementsRepository {
  @override
  bool get supportsCreate => true;

  @override
  bool get supportsEDespatch => true;

  @override
  Future<CompanyMovementCreateResult> createMovement({
    required String accessToken,
    required CompanyMovementCreateRequest request,
  }) {
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  @override
  Future<List<CompanyMovementListItem>> fetchMovements({
    required String accessToken,
    required CompanyMovementListFilter filter,
  }) async {
    return const <CompanyMovementListItem>[];
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
  }) async {
    return const <SearchProductLookupItem>[];
  }
}
