import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/models/company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/models/offline_company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/offline_company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_record_status.dart';

import '../../support/memory_local_database.dart';

void main() {
  test('keeps pending drafts bounded without deleting existing data', () async {
    final repository = LocalOfflineCompanyAcceptancesRepository(
      database: MemoryLocalDatabase(),
    );
    for (
      var index = 0;
      index < LocalOfflineCompanyAcceptancesRepository.maxDraftsPerScope;
      index += 1
    ) {
      await repository.saveDraft(_acceptanceDraft('acceptance-$index', index));
    }

    await expectLater(
      repository.saveDraft(_acceptanceDraft('acceptance-over-limit', 999)),
      throwsA(isA<StateError>()),
    );
    final drafts = await repository.fetchDrafts(
      userId: 'user-1',
      warehouseNo: '110',
    );
    expect(
      drafts,
      hasLength(LocalOfflineCompanyAcceptancesRepository.maxDraftsPerScope),
    );
    expect(
      drafts.map((item) => item.id),
      isNot(contains('acceptance-over-limit')),
    );
  });
}

OfflineCompanyAcceptanceDraft _acceptanceDraft(String id, int orderNo) {
  final request = CompanyAcceptanceCreateRequest(
    clientRequestId: id,
    customerCode: 'CARI-1',
    movementDate: DateTime(2026, 11, 3),
    documentDate: DateTime(2026, 11, 3),
    documentSerie: 'TST',
    documentOrderNo: orderNo + 1,
    deliverer: '',
    receiver: '',
    description: '',
    allowOrderOverReceiving: false,
    lines: const <CompanyAcceptanceCreateLine>[],
  );
  return OfflineCompanyAcceptanceDraft.fromCreateRequest(
    request,
    userId: 'user-1',
    warehouseNo: '110',
    customerDisplayName: 'Test Firma',
    createdAt: DateTime(2026, 11, 3),
    status: OfflineRecordStatus.pending,
    lastSyncAttemptAt: null,
  );
}
