import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/label_documents/data/label_documents_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/label_documents/data/models/label_document_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/label_documents/presentation/views/label_documents_page.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';

import '../../support/pda_create_screen_contract.dart';

void main() {
  testWidgets('passes pda create screen contract with keyboard inset', (
    tester,
  ) async {
    await expectPdaCreateScreenContract(
      tester,
      buildSubject: () => LabelDocumentCreateSheet(
        repository: _FakeLabelDocumentsRepository(),
        accessToken: 'token',
        defaultWarehouseNo: '110',
      ),
      entryRowFinder: find.text('Giris satiri'),
      saveButtonFinder: find.widgetWithText(FilledButton, 'Belge Olustur'),
    );
  });
}

class _FakeLabelDocumentsRepository implements LabelDocumentsRepository {
  @override
  Future<CreateLabelDocumentResult> createDocument({
    required String accessToken,
    required CreateLabelDocumentRequest request,
  }) => throw UnimplementedError();

  @override
  Future<List<LabelDocumentListItem>> fetchAllDocuments({
    required String accessToken,
    required String warehouseNo,
  }) async => const <LabelDocumentListItem>[];

  @override
  Future<List<LabelDocumentProduct>> fetchDocumentProducts({
    required String accessToken,
    required int documentId,
    required String warehouseNo,
  }) async => const <LabelDocumentProduct>[];

  @override
  Future<List<LabelPriceChangedProduct>> fetchPriceChangedProducts({
    required String accessToken,
    required DateTime dateTimeFilter,
  }) async => const <LabelPriceChangedProduct>[];

  @override
  Future<List<LabelDocumentListItem>> fetchRecentDocuments({
    required String accessToken,
    required String warehouseNo,
    int take = 10,
  }) async => const <LabelDocumentListItem>[];

  @override
  Future<List<LabelTag>> fetchTags({
    required String accessToken,
    required DateTime dateToGet,
  }) async => const <LabelTag>[];

  @override
  Future<List<SearchProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
    bool includeDelisted = true,
  }) async => const <SearchProductLookupItem>[];
}
