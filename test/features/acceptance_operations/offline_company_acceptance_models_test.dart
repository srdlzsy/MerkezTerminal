import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/models/company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/models/offline_company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_record_status.dart';

void main() {
  test('matches a pending acceptance by document series and order number', () {
    final draft = _draft(_request(serie: 'ERS', orderNo: 5530));

    expect(
      draft.matchesDocumentIdentity(_request(serie: 'ers', orderNo: 5530)),
      isTrue,
    );
    expect(
      draft.matchesDocumentIdentity(_request(serie: 'ERS', orderNo: 5531)),
      isFalse,
    );
  });

  test('matches a pending acceptance by normalized ETTN', () {
    final draft = _draft(
      _request(
        serie: 'ERS',
        orderNo: 5530,
        ettn: '11111111-2222-3333-4444-555555555555',
      ),
    );

    expect(
      draft.matchesDocumentIdentity(
        _request(
          serie: 'FARKLI',
          orderNo: 1,
          ettn: '11111111222233334444555555555555',
        ),
      ),
      isTrue,
    );
  });
}

OfflineCompanyAcceptanceDraft _draft(CompanyAcceptanceCreateRequest request) {
  return OfflineCompanyAcceptanceDraft.fromCreateRequest(
    request,
    userId: 'user-1',
    warehouseNo: '56',
    customerDisplayName: 'Firma',
    createdAt: DateTime(2026, 10, 15),
    status: OfflineRecordStatus.pending,
    lastSyncAttemptAt: null,
  );
}

CompanyAcceptanceCreateRequest _request({
  required String serie,
  required int orderNo,
  String? ettn,
}) {
  return CompanyAcceptanceCreateRequest(
    clientRequestId: '$serie-$orderNo-${ettn ?? ''}',
    customerCode: 'CARI-1',
    movementDate: DateTime(2026, 10, 15),
    documentDate: DateTime(2026, 10, 15),
    documentSerie: serie,
    documentOrderNo: orderNo,
    officialDocumentEttn: ettn,
    deliverer: '',
    receiver: '',
    description: '',
    allowOrderOverReceiving: false,
    lines: const <CompanyAcceptanceCreateLine>[],
  );
}
