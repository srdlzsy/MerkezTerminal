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

  test('persists safe sync metadata and related request identity', () {
    final retryAt = DateTime(2026, 10, 16, 12, 30);
    final original = _draft(_request(serie: 'ERS', orderNo: 5530)).copyWith(
      hasBeenSubmitted: true,
      operationCode: 'company-acceptance-create',
      errorCode: 'MIKRO_WRITE_QUEUE_BUSY',
      retryable: true,
      retryAfterSeconds: 10,
      retryNotBefore: retryAt,
      correlationId: 'support-1',
      relatedClientRequestId: 'original-request-id',
      lastCheckedAt: retryAt,
      statusCheckCount: 2,
    );

    final restored = OfflineCompanyAcceptanceDraft.fromJson(original.toJson());

    expect(restored.hasBeenSubmitted, isTrue);
    expect(restored.errorCode, 'MIKRO_WRITE_QUEUE_BUSY');
    expect(restored.retryable, isTrue);
    expect(restored.retryAfterSeconds, 10);
    expect(restored.retryNotBefore, retryAt);
    expect(restored.correlationId, 'support-1');
    expect(restored.effectiveClientRequestId, 'original-request-id');
    expect(restored.toCreateRequest().clientRequestId, 'original-request-id');
    expect(restored.statusCheckCount, 2);
  });

  test('treats an attempted legacy draft as already submitted', () {
    final legacyJson = _draft(_request(serie: 'ERS', orderNo: 5530)).toJson()
      ..remove('hasBeenSubmitted')
      ..['status'] = 'failed'
      ..['lastSyncAttemptAt'] = '2026-10-16T10:45:35.000';

    final restored = OfflineCompanyAcceptanceDraft.fromJson(legacyJson);

    expect(restored.hasBeenSubmitted, isTrue);
  });

  test('keeps an untouched legacy offline draft unsubmitted', () {
    final legacyJson = _draft(_request(serie: 'ERS', orderNo: 5530)).toJson()
      ..remove('hasBeenSubmitted')
      ..['status'] = 'pending'
      ..['lastSyncAttemptAt'] = null;

    final restored = OfflineCompanyAcceptanceDraft.fromJson(legacyJson);

    expect(restored.hasBeenSubmitted, isFalse);
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
