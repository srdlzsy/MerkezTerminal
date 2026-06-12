import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/models/company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/models/offline_company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/offline_company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/data/models/offline_inventory_count_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/data/offline_inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_record_status.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_service.dart';

void main() {
  late _FakeInventoryCountsRepository inventoryRepository;
  late _FakeOfflineInventoryCountsRepository offlineInventoryRepository;
  late _FakeCompanyAcceptancesRepository companyAcceptanceRepository;
  late _FakeOfflineCompanyAcceptancesRepository
  offlineCompanyAcceptanceRepository;
  late OfflineSyncService service;

  setUp(() {
    inventoryRepository = _FakeInventoryCountsRepository();
    offlineInventoryRepository = _FakeOfflineInventoryCountsRepository();
    companyAcceptanceRepository = _FakeCompanyAcceptancesRepository();
    offlineCompanyAcceptanceRepository =
        _FakeOfflineCompanyAcceptancesRepository();
    service = OfflineSyncService(
      inventoryRepository: inventoryRepository,
      companyAcceptanceRepository: companyAcceptanceRepository,
      offlineInventoryRepository: offlineInventoryRepository,
      offlineCompanyAcceptanceRepository: offlineCompanyAcceptanceRepository,
    );
  });

  test('submitInventoryCount queues draft for connection failures', () async {
    inventoryRepository.createError = const ApiException(
      statusCode: 0,
      title: 'Baglanti Hatasi',
      detail: 'No network',
    );

    final result = await service.submitInventoryCount(
      accessToken: 'token',
      userId: 'user-1',
      warehouseNo: '110',
      request: _buildRequest(clientRequestId: 'request-1'),
    );

    expect(result.status, OfflineSubmissionStatus.queued);
    expect(offlineInventoryRepository.savedDrafts, hasLength(1));
    expect(offlineInventoryRepository.savedDrafts.single.id, 'request-1');
    expect(
      offlineInventoryRepository.savedDrafts.single.lastError,
      'Baglanti Hatasi: No network',
    );
  });

  test('submitInventoryCount does not queue backend errors', () async {
    inventoryRepository.createError = const ApiException(
      statusCode: 400,
      title: 'Validasyon Hatasi',
      detail: 'Miktar zorunlu.',
    );

    await expectLater(
      service.submitInventoryCount(
        accessToken: 'token',
        userId: 'user-1',
        warehouseNo: '110',
        request: _buildRequest(clientRequestId: 'request-2'),
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Validasyon Hatasi: Miktar zorunlu.',
        ),
      ),
    );

    expect(inventoryRepository.fetchOfflineSyncStatusCallCount, 0);
    expect(offlineInventoryRepository.savedDrafts, isEmpty);
  });

  test(
    'submitInventoryCount does not queue non-network status zero errors',
    () async {
      inventoryRepository.createError = const ApiException(
        statusCode: 0,
        title: 'Beklenmeyen Yanit',
        detail: 'Sunucudan nesne tipinde JSON yaniti bekleniyordu.',
      );

      await expectLater(
        service.submitInventoryCount(
          accessToken: 'token',
          userId: 'user-1',
          warehouseNo: '110',
          request: _buildRequest(clientRequestId: 'request-3'),
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.title,
            'title',
            'Beklenmeyen Yanit',
          ),
        ),
      );

      expect(inventoryRepository.fetchOfflineSyncStatusCallCount, 1);
      expect(offlineInventoryRepository.savedDrafts, isEmpty);
    },
  );

  test(
    'submitInventoryCount recovers completed conflict without queueing',
    () async {
      inventoryRepository
        ..createError = const ApiException(
          statusCode: 409,
          title: 'Islem zaten var',
        )
        ..offlineSyncStatus = InventoryCountOfflineSyncStatus(
          clientRequestId: 'request-4',
          operationCode: 'inventory-count-create',
          status: 'completed',
          createdAtUtc: DateTime.utc(2026, 4, 23, 8),
          completedAtUtc: DateTime.utc(2026, 4, 23, 8, 1),
          errorMessage: null,
          result: _buildResult(documentNo: 31),
        );

      final result = await service.submitInventoryCount(
        accessToken: 'token',
        userId: 'user-1',
        warehouseNo: '110',
        request: _buildRequest(clientRequestId: 'request-4'),
      );

      expect(result.status, OfflineSubmissionStatus.recovered);
      expect(result.onlineResult?.documentNo, 31);
      expect(offlineInventoryRepository.savedDrafts, isEmpty);
    },
  );

  test(
    'submitInventoryCount rethrows unresolved conflict without queueing',
    () async {
      inventoryRepository.createError = const ApiException(
        statusCode: 409,
        title: 'Islem zaten var',
      );

      await expectLater(
        service.submitInventoryCount(
          accessToken: 'token',
          userId: 'user-1',
          warehouseNo: '110',
          request: _buildRequest(clientRequestId: 'request-5'),
        ),
        throwsA(
          isA<ApiException>().having((error) => error.statusCode, 'code', 409),
        ),
      );

      expect(inventoryRepository.fetchOfflineSyncStatusCallCount, 1);
      expect(offlineInventoryRepository.savedDrafts, isEmpty);
    },
  );

  test('syncInventoryDraft defers connection failures', () async {
    inventoryRepository.createError = const ApiException(
      statusCode: 0,
      title: 'Baglanti Hatasi',
      detail: 'No network',
    );

    final result = await service.syncInventoryDraft(
      accessToken: 'token',
      draft: _buildDraft(clientRequestId: 'draft-1'),
    );

    expect(result.status, OfflineDraftSyncResultStatus.deferred);
    expect(
      offlineInventoryRepository.savedDrafts.single.status,
      OfflineRecordStatus.pending,
    );
  });

  test('syncInventoryDraft fails non-network status zero errors', () async {
    inventoryRepository.createError = const ApiException(
      statusCode: 0,
      title: 'Beklenmeyen Yanit',
      detail: 'Sunucudan nesne tipinde JSON yaniti bekleniyordu.',
    );

    final result = await service.syncInventoryDraft(
      accessToken: 'token',
      draft: _buildDraft(clientRequestId: 'draft-2'),
    );

    expect(result.status, OfflineDraftSyncResultStatus.failed);
    expect(
      offlineInventoryRepository.savedDrafts.single.status,
      OfflineRecordStatus.failed,
    );
  });

  test(
    'submitCompanyAcceptance queues draft for connection failures',
    () async {
      companyAcceptanceRepository.createError = const ApiException(
        statusCode: 0,
        title: 'Baglanti Hatasi',
        detail: 'No network',
      );

      final result = await service.submitCompanyAcceptance(
        accessToken: 'token',
        userId: 'user-1',
        warehouseNo: '110',
        request: _buildCompanyAcceptanceRequest(
          clientRequestId: 'acceptance-1',
        ),
        customerDisplayName: 'Test Cari',
        createdAt: DateTime(2026, 4, 23, 9),
      );

      expect(result.status, OfflineSubmissionStatus.queued);
      expect(offlineCompanyAcceptanceRepository.savedDrafts, hasLength(1));
      expect(
        offlineCompanyAcceptanceRepository.savedDrafts.single.id,
        'acceptance-1',
      );
      expect(
        offlineCompanyAcceptanceRepository.savedDrafts.single.lastError,
        'Baglanti Hatasi: No network',
      );
    },
  );

  test('submitCompanyAcceptance does not queue backend errors', () async {
    companyAcceptanceRepository.createError = const ApiException(
      statusCode: 400,
      title: 'Validasyon Hatasi',
      detail: 'Cari kodu zorunlu.',
    );

    await expectLater(
      service.submitCompanyAcceptance(
        accessToken: 'token',
        userId: 'user-1',
        warehouseNo: '110',
        request: _buildCompanyAcceptanceRequest(
          clientRequestId: 'acceptance-2',
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Validasyon Hatasi: Cari kodu zorunlu.',
        ),
      ),
    );

    expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 0);
    expect(offlineCompanyAcceptanceRepository.savedDrafts, isEmpty);
  });

  test(
    'submitCompanyAcceptance does not queue non-network status zero errors',
    () async {
      companyAcceptanceRepository.createError = const ApiException(
        statusCode: 0,
        title: 'Beklenmeyen Yanit',
        detail: 'Sunucudan nesne tipinde JSON yaniti bekleniyordu.',
      );

      await expectLater(
        service.submitCompanyAcceptance(
          accessToken: 'token',
          userId: 'user-1',
          warehouseNo: '110',
          request: _buildCompanyAcceptanceRequest(
            clientRequestId: 'acceptance-3',
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.title,
            'title',
            'Beklenmeyen Yanit',
          ),
        ),
      );

      expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 1);
      expect(offlineCompanyAcceptanceRepository.savedDrafts, isEmpty);
    },
  );

  test(
    'submitCompanyAcceptance recovers completed conflict without queueing',
    () async {
      companyAcceptanceRepository
        ..createError = const ApiException(
          statusCode: 409,
          title: 'Islem zaten var',
        )
        ..offlineSyncStatus = CompanyAcceptanceOfflineSyncStatus(
          clientRequestId: 'acceptance-4',
          operationCode: 'company-acceptance-create',
          status: 'completed',
          createdAtUtc: DateTime.utc(2026, 4, 23, 8),
          completedAtUtc: DateTime.utc(2026, 4, 23, 8, 1),
          errorMessage: null,
          result: _buildCompanyAcceptanceResult(documentOrderNo: 42),
        );

      final result = await service.submitCompanyAcceptance(
        accessToken: 'token',
        userId: 'user-1',
        warehouseNo: '110',
        request: _buildCompanyAcceptanceRequest(
          clientRequestId: 'acceptance-4',
        ),
      );

      expect(result.status, OfflineSubmissionStatus.recovered);
      expect(result.onlineResult?.documentOrderNo, 42);
      expect(offlineCompanyAcceptanceRepository.savedDrafts, isEmpty);
    },
  );

  test(
    'submitCompanyAcceptance rethrows unresolved conflict without queueing',
    () async {
      companyAcceptanceRepository.createError = const ApiException(
        statusCode: 409,
        title: 'Islem zaten var',
      );

      await expectLater(
        service.submitCompanyAcceptance(
          accessToken: 'token',
          userId: 'user-1',
          warehouseNo: '110',
          request: _buildCompanyAcceptanceRequest(
            clientRequestId: 'acceptance-5',
          ),
        ),
        throwsA(
          isA<ApiException>().having((error) => error.statusCode, 'code', 409),
        ),
      );

      expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 1);
      expect(offlineCompanyAcceptanceRepository.savedDrafts, isEmpty);
    },
  );

  test('syncCompanyAcceptanceDraft defers connection failures', () async {
    companyAcceptanceRepository.createError = const ApiException(
      statusCode: 0,
      title: 'Baglanti Hatasi',
      detail: 'No network',
    );

    final result = await service.syncCompanyAcceptanceDraft(
      accessToken: 'token',
      draft: _buildCompanyAcceptanceDraft(clientRequestId: 'draft-3'),
    );

    expect(result.status, OfflineDraftSyncResultStatus.deferred);
    expect(
      offlineCompanyAcceptanceRepository.savedDrafts.single.status,
      OfflineRecordStatus.pending,
    );
  });

  test(
    'syncCompanyAcceptanceDraft fails non-network status zero errors',
    () async {
      companyAcceptanceRepository.createError = const ApiException(
        statusCode: 0,
        title: 'Beklenmeyen Yanit',
        detail: 'Sunucudan nesne tipinde JSON yaniti bekleniyordu.',
      );

      final result = await service.syncCompanyAcceptanceDraft(
        accessToken: 'token',
        draft: _buildCompanyAcceptanceDraft(clientRequestId: 'draft-4'),
      );

      expect(result.status, OfflineDraftSyncResultStatus.failed);
      expect(
        offlineCompanyAcceptanceRepository.savedDrafts.single.status,
        OfflineRecordStatus.failed,
      );
    },
  );
}

InventoryCountCreateRequest _buildRequest({required String clientRequestId}) {
  return InventoryCountCreateRequest(
    clientRequestId: clientRequestId,
    name: 'Sayim',
    documentDate: DateTime(2026, 4, 23),
    lines: const <InventoryCountCreateLine>[
      InventoryCountCreateLine(
        stockCode: '015792',
        quantity: 12,
        barcode: '8690000000012',
        unitPointer: 1,
      ),
    ],
  );
}

InventoryCountCreateResult _buildResult({required int documentNo}) {
  return InventoryCountCreateResult(
    documentNo: documentNo,
    documentDate: DateTime(2026, 4, 23),
    warehouseNo: 110,
    name: 'Sayim',
    lineCount: 1,
    totalQuantity: 12,
    writeConnectionName: 'testMikroConnection',
  );
}

OfflineInventoryCountDraft _buildDraft({required String clientRequestId}) {
  return OfflineInventoryCountDraft.fromCreateRequest(
    _buildRequest(clientRequestId: clientRequestId),
    userId: 'user-1',
    warehouseNo: '110',
    status: OfflineRecordStatus.pending,
    lastSyncAttemptAt: null,
  );
}

CompanyAcceptanceCreateRequest _buildCompanyAcceptanceRequest({
  required String clientRequestId,
}) {
  return CompanyAcceptanceCreateRequest(
    customerCode: '320.01.001',
    movementDate: DateTime(2026, 4, 23),
    documentDate: DateTime(2026, 4, 23),
    documentNo: 'IRS-1',
    deliverer: 'Teslim Eden',
    receiver: 'Teslim Alan',
    description: 'Firma mal kabul',
    allowOrderOverReceiving: false,
    clientRequestId: clientRequestId,
    lines: const <CompanyAcceptanceCreateLine>[
      CompanyAcceptanceCreateLine(
        stockCode: '015792',
        dispatchQuantity: 10,
        acceptedQuantity: 8,
        unitPrice: 125,
        unitPointer: 1,
        lastConsumingDate: null,
        orderGuid: null,
        description: '',
        partyCode: '',
        lotNo: 0,
        projectCode: '',
        customerResponsibilityCenter: '',
        productResponsibilityCenter: '',
      ),
    ],
  );
}

CompanyAcceptanceCreateResult _buildCompanyAcceptanceResult({
  required int documentOrderNo,
}) {
  return CompanyAcceptanceCreateResult(
    documentSerie: 'FMK',
    documentOrderNo: documentOrderNo,
    movementDate: DateTime(2026, 4, 23),
    documentDate: DateTime(2026, 4, 23),
    documentNo: 'IRS-1',
    warehouseNo: 110,
    customerCode: '320.01.001',
    lineCount: 1,
    totalReceivedQuantity: 10,
    totalOrderLinkedQuantity: 0,
    totalOrderlessQuantity: 10,
    totalOrderOverReceivedQuantity: 0,
    totalAmount: 1250,
    writeConnectionName: 'testMikroConnection',
    totalDispatchQuantity: 10,
    totalNetAcceptedQuantity: 8,
    totalReturnedQuantity: 2,
    autoCreatedReturnLineCount: 1,
    autoCreatedReturnDocumentSerie: 'FI',
    autoCreatedReturnDocumentOrderNo: 7,
    returnEDespatchStatus: 'Yok',
    lines: const <CompanyAcceptanceCreateLineResult>[],
  );
}

OfflineCompanyAcceptanceDraft _buildCompanyAcceptanceDraft({
  required String clientRequestId,
}) {
  return OfflineCompanyAcceptanceDraft.fromCreateRequest(
    _buildCompanyAcceptanceRequest(clientRequestId: clientRequestId),
    userId: 'user-1',
    warehouseNo: '110',
    customerDisplayName: 'Test Cari',
    createdAt: DateTime(2026, 4, 23, 9),
    status: OfflineRecordStatus.pending,
    lastSyncAttemptAt: null,
  );
}

class _FakeInventoryCountsRepository implements InventoryCountsRepository {
  ApiException? createError;
  InventoryCountOfflineSyncStatus? offlineSyncStatus;
  int fetchOfflineSyncStatusCallCount = 0;

  @override
  Future<InventoryCountCreateResult> createCount({
    required String accessToken,
    required InventoryCountCreateRequest request,
  }) async {
    final error = createError;
    if (error != null) {
      throw error;
    }

    return _buildResult(documentNo: 30);
  }

  @override
  Future<InventoryCountOfflineSyncStatus> fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
  }) async {
    fetchOfflineSyncStatusCallCount += 1;
    return offlineSyncStatus ??
        InventoryCountOfflineSyncStatus(
          clientRequestId: clientRequestId,
          operationCode: 'inventory-count-create',
          status: 'processing',
          createdAtUtc: DateTime.utc(2026, 4, 23, 8),
          completedAtUtc: null,
          errorMessage: null,
          result: null,
        );
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
  Future<List<InventoryCountProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  }) {
    throw UnimplementedError();
  }
}

class _FakeOfflineInventoryCountsRepository
    implements OfflineInventoryCountsRepository {
  final List<OfflineInventoryCountDraft> savedDrafts =
      <OfflineInventoryCountDraft>[];

  @override
  Future<void> saveDraft(OfflineInventoryCountDraft draft) async {
    savedDrafts.removeWhere((item) => item.id == draft.id);
    savedDrafts.add(draft);
  }

  @override
  Future<void> deleteDraft(String id) async {
    savedDrafts.removeWhere((draft) => draft.id == id);
  }

  @override
  Future<List<OfflineInventoryCountDraft>> fetchDrafts({
    required String userId,
    required String warehouseNo,
  }) async {
    return savedDrafts
        .where(
          (draft) =>
              draft.matchesContext(userId: userId, warehouseNo: warehouseNo),
        )
        .toList(growable: false);
  }

  @override
  Future<OfflineInventoryCountDraft?> findDraft(String id) async {
    for (final draft in savedDrafts) {
      if (draft.id == id) {
        return draft;
      }
    }

    return null;
  }
}

class _FakeCompanyAcceptancesRepository
    implements CompanyAcceptancesRepository {
  ApiException? createError;
  CompanyAcceptanceOfflineSyncStatus? offlineSyncStatus;
  int fetchOfflineSyncStatusCallCount = 0;

  @override
  Future<CompanyAcceptanceCreateResult> createAcceptance({
    required String accessToken,
    required CompanyAcceptanceCreateRequest request,
  }) async {
    final error = createError;
    if (error != null) {
      throw error;
    }

    return _buildCompanyAcceptanceResult(documentOrderNo: 41);
  }

  @override
  Future<CompanyAcceptanceOfflineSyncStatus> fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
  }) async {
    fetchOfflineSyncStatusCallCount += 1;
    return offlineSyncStatus ??
        CompanyAcceptanceOfflineSyncStatus(
          clientRequestId: clientRequestId,
          operationCode: 'company-acceptance-create',
          status: 'processing',
          createdAtUtc: DateTime.utc(2026, 4, 23, 8),
          completedAtUtc: null,
          errorMessage: null,
          result: null,
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOfflineCompanyAcceptancesRepository
    implements OfflineCompanyAcceptancesRepository {
  final List<OfflineCompanyAcceptanceDraft> savedDrafts =
      <OfflineCompanyAcceptanceDraft>[];

  @override
  Future<void> saveDraft(OfflineCompanyAcceptanceDraft draft) async {
    savedDrafts.removeWhere((item) => item.id == draft.id);
    savedDrafts.add(draft);
  }

  @override
  Future<void> deleteDraft(String id) async {
    savedDrafts.removeWhere((draft) => draft.id == id);
  }

  @override
  Future<List<OfflineCompanyAcceptanceDraft>> fetchDrafts({
    required String userId,
    required String warehouseNo,
  }) async {
    return savedDrafts
        .where(
          (draft) =>
              draft.matchesContext(userId: userId, warehouseNo: warehouseNo),
        )
        .toList(growable: false);
  }

  @override
  Future<OfflineCompanyAcceptanceDraft?> findDraft(String id) async {
    for (final draft in savedDrafts) {
      if (draft.id == id) {
        return draft;
      }
    }

    return null;
  }
}
