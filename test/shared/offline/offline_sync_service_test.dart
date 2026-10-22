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
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
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
      foregroundRecoveryTimeout: Duration.zero,
      recoveryPollInterval: Duration.zero,
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

  test(
    'submitInventoryCount keeps processing draft when backend is busy',
    () async {
      inventoryRepository
        ..createError = const ApiException(
          statusCode: 0,
          title: 'Baglanti Hatasi',
          detail: 'No network',
        )
        ..offlineSyncStatus = InventoryCountOfflineSyncStatus(
          clientRequestId: 'request-processing',
          operationCode: 'inventory-count-create',
          status: 'processing',
          createdAtUtc: DateTime.utc(2026, 4, 23, 8),
          completedAtUtc: null,
          errorMessage: null,
          result: null,
        );

      final result = await service.submitInventoryCount(
        accessToken: 'token',
        userId: 'user-1',
        warehouseNo: '110',
        request: _buildRequest(clientRequestId: 'request-processing'),
      );

      expect(result.status, OfflineSubmissionStatus.processing);
      expect(
        offlineInventoryRepository.savedDrafts.single.status,
        OfflineRecordStatus.syncing,
      );
    },
  );

  test('submitInventoryCount keeps retryable failed status pending', () async {
    inventoryRepository
      ..createError = const ApiException(
        statusCode: 409,
        title: 'Sonuc dogrulanamadi',
        errorCode: 'MIKRO_WRITE_OUTCOME_UNCONFIRMED',
        retryable: true,
      )
      ..offlineSyncStatus = InventoryCountOfflineSyncStatus(
        clientRequestId: 'request-retryable',
        operationCode: 'inventory-count-create',
        status: 'failed',
        createdAtUtc: DateTime.utc(2026, 10, 13, 8),
        completedAtUtc: null,
        errorMessage: 'Mikro yazim sonucu dogrulanamadi.',
        errorCode: 'MIKRO_WRITE_OUTCOME_UNCONFIRMED',
        retryable: true,
        retryAfterSeconds: 5,
        recommendedAction: 'WaitAndCheck',
        result: null,
      );

    final result = await service.submitInventoryCount(
      accessToken: 'token',
      userId: 'user-1',
      warehouseNo: '110',
      request: _buildRequest(clientRequestId: 'request-retryable'),
    );

    expect(result.status, OfflineSubmissionStatus.processing);
    expect(offlineInventoryRepository.savedDrafts, hasLength(1));
    expect(
      offlineInventoryRepository.savedDrafts.single.status,
      OfflineRecordStatus.syncing,
    );
    expect(
      offlineInventoryRepository.savedDrafts.single.lastError,
      contains('otomatik kontrol edilecek'),
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
    'confirmed missing inventory count remains local without another status loop',
    () async {
      inventoryRepository.createError = const ApiException(
        statusCode: 409,
        title: 'Kayit tamamlanamadi',
        detail: 'Mikro kaydi olusmadi; guvenli tekrar tamamlansin.',
        errorCode: 'SAFE_WRITE_RETRY_EXHAUSTED',
        retryable: true,
        recommendedAction: 'RetrySameRequest',
      );
      final request = _buildRequest(
        clientRequestId: 'inventory-safe-retry-exhausted',
      );

      final result = await service.submitInventoryCount(
        accessToken: 'token',
        userId: 'user-1',
        warehouseNo: '110',
        request: request,
      );

      expect(result.status, OfflineSubmissionStatus.queued);
      expect(inventoryRepository.createCountCallCount, 1);
      expect(inventoryRepository.fetchOfflineSyncStatusCallCount, 0);
      final draft = offlineInventoryRepository.savedDrafts.single;
      expect(draft.hasBeenSubmitted, isFalse);
      expect(draft.clientRequestId, request.clientRequestId);
    },
  );

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

  test(
    'syncInventoryDraft checks a submitted draft without another create',
    () async {
      inventoryRepository.offlineSyncStatus = InventoryCountOfflineSyncStatus(
        clientRequestId: 'submitted-count',
        operationCode: 'inventory-count-create',
        status: 'completed',
        createdAtUtc: DateTime.utc(2026, 10, 21, 8),
        completedAtUtc: DateTime.utc(2026, 10, 21, 8, 1),
        errorMessage: null,
        result: _buildResult(documentNo: 45),
      );
      final draft = OfflineInventoryCountDraft.fromCreateRequest(
        _buildRequest(clientRequestId: 'submitted-count'),
        userId: 'user-1',
        warehouseNo: '110',
        status: OfflineRecordStatus.syncing,
        lastSyncAttemptAt: DateTime(2026, 10, 21, 8),
        hasBeenSubmitted: true,
      );
      await offlineInventoryRepository.saveDraft(draft);

      final result = await service.syncInventoryDraft(
        accessToken: 'token',
        draft: draft,
        statusCheckOnly: true,
        recheckExisting: true,
      );

      expect(result.status, OfflineDraftSyncResultStatus.synced);
      expect(inventoryRepository.createCountCallCount, 0);
      expect(inventoryRepository.fetchOfflineSyncStatusCallCount, 1);
      expect(offlineInventoryRepository.savedDrafts, isEmpty);
    },
  );

  test('syncPending leaves an unsent inventory draft on the device', () async {
    final draft = OfflineInventoryCountDraft.fromCreateRequest(
      _buildRequest(clientRequestId: 'local-count'),
      userId: 'user-1',
      warehouseNo: '110',
      status: OfflineRecordStatus.pending,
      lastSyncAttemptAt: null,
    );
    await offlineInventoryRepository.saveDraft(draft);

    await service.syncPending(
      accessToken: 'token',
      userId: 'user-1',
      warehouseNo: '110',
    );

    expect(inventoryRepository.createCountCallCount, 0);
    expect(inventoryRepository.fetchOfflineSyncStatusCallCount, 0);
    expect(offlineInventoryRepository.savedDrafts, hasLength(1));
  });

  test(
    'syncPending leaves an unsent company acceptance on the device',
    () async {
      await offlineCompanyAcceptanceRepository.saveDraft(
        _buildCompanyAcceptanceDraft(clientRequestId: 'local-acceptance'),
      );

      await service.syncPending(
        accessToken: 'token',
        userId: 'user-1',
        warehouseNo: '110',
      );

      expect(companyAcceptanceRepository.createCallCount, 0);
      expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 0);
      expect(offlineCompanyAcceptanceRepository.savedDrafts, hasLength(1));
    },
  );

  test('syncPending checks at most one draft per type and run', () async {
    for (var index = 0; index < 2; index += 1) {
      await offlineInventoryRepository.saveDraft(
        OfflineInventoryCountDraft.fromCreateRequest(
          _buildRequest(clientRequestId: 'submitted-count-$index'),
          userId: 'user-1',
          warehouseNo: '110',
          status: OfflineRecordStatus.syncing,
          lastSyncAttemptAt: null,
          hasBeenSubmitted: true,
        ),
      );
    }
    for (var index = 0; index < 4; index += 1) {
      await offlineCompanyAcceptanceRepository.saveDraft(
        _buildCompanyAcceptanceDraft(
          clientRequestId: 'submitted-acceptance-$index',
          hasBeenSubmitted: true,
        ),
      );
    }

    await service.syncPending(
      accessToken: 'token',
      userId: 'user-1',
      warehouseNo: '110',
    );

    expect(inventoryRepository.fetchOfflineSyncStatusCallCount, 1);
    expect(companyAcceptanceRepository.createCallCount, 0);
    expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 1);
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
    'syncInventoryDraft keeps http 400 as an unsent editable draft',
    () async {
      inventoryRepository.createError = const ApiException(
        statusCode: 400,
        title: 'Validasyon Hatasi',
        detail: 'Miktar gecersiz.',
        errorCode: 'MIKRO_WRITE_IN_PROGRESS',
        retryable: true,
        recommendedAction: 'WaitAndCheck',
      );
      final draft = _buildDraft(clientRequestId: 'count-validation');
      await offlineInventoryRepository.saveDraft(draft);

      final result = await service.syncInventoryDraft(
        accessToken: 'token',
        draft: draft,
      );

      expect(result.status, OfflineDraftSyncResultStatus.failed);
      expect(result.message, contains('Miktar gecersiz'));
      expect(inventoryRepository.createCountCallCount, 1);
      expect(inventoryRepository.fetchOfflineSyncStatusCallCount, 0);
      final savedDraft = offlineInventoryRepository.savedDrafts.single;
      expect(savedDraft.status, OfflineRecordStatus.pending);
      expect(savedDraft.hasBeenSubmitted, isFalse);
      expect(savedDraft.lastSyncAttemptAt, isNull);
      expect(savedDraft.retryNotBefore, isNull);
      expect(savedDraft.lastCheckedAt, isNull);
      expect(savedDraft.statusCheckCount, 0);
    },
  );

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
      final savedRequest = offlineCompanyAcceptanceRepository.savedDrafts.single
          .toCreateRequest();
      expect(savedRequest.officialDocumentKind, 'e-despatch');
      expect(savedRequest.officialDocumentNo, 'ST12026000002395');
      expect(savedRequest.documentSerie, 'fmk');
      expect(savedRequest.documentOrderNo, 1001);
      expect(savedRequest.toJson()['documentSerie'], 'FMK');
      expect(savedRequest.officialDocumentDate, DateTime(2026, 4, 20));
      expect(
        savedRequest.officialDocumentEttn,
        '550e8400-e29b-41d4-a716-446655440000',
      );
    },
  );

  test(
    'submitCompanyAcceptance keeps processing draft when backend is busy',
    () async {
      companyAcceptanceRepository
        ..createError = const ApiException(
          statusCode: 0,
          title: 'Baglanti Hatasi',
          detail: 'No network',
        )
        ..offlineSyncStatus = CompanyAcceptanceOfflineSyncStatus(
          clientRequestId: 'acceptance-processing',
          operationCode: 'company-acceptance-create',
          status: 'processing',
          createdAtUtc: DateTime.utc(2026, 4, 23, 8),
          completedAtUtc: null,
          errorMessage: null,
          result: null,
        );

      final result = await service.submitCompanyAcceptance(
        accessToken: 'token',
        userId: 'user-1',
        warehouseNo: '110',
        request: _buildCompanyAcceptanceRequest(
          clientRequestId: 'acceptance-processing',
        ),
      );

      expect(result.status, OfflineSubmissionStatus.processing);
      expect(
        offlineCompanyAcceptanceRepository.savedDrafts.single.status,
        OfflineRecordStatus.syncing,
      );
    },
  );

  test(
    'submitCompanyAcceptance resolves a completed record on the same submit',
    () async {
      service = OfflineSyncService(
        inventoryRepository: inventoryRepository,
        companyAcceptanceRepository: companyAcceptanceRepository,
        offlineInventoryRepository: offlineInventoryRepository,
        offlineCompanyAcceptanceRepository: offlineCompanyAcceptanceRepository,
        foregroundRecoveryTimeout: const Duration(seconds: 1),
        recoveryPollInterval: Duration.zero,
      );
      companyAcceptanceRepository
        ..createError = const ApiException(
          statusCode: 409,
          title: 'Isleniyor',
          errorCode: 'MIKRO_WRITE_IN_PROGRESS',
          retryable: true,
        )
        ..offlineSyncStatuses.addAll(<CompanyAcceptanceOfflineSyncStatus>[
          CompanyAcceptanceOfflineSyncStatus(
            clientRequestId: 'acceptance-foreground',
            operationCode: 'company-acceptance-create',
            status: 'processing',
            createdAtUtc: DateTime.utc(2026, 10, 19, 8),
            completedAtUtc: null,
            errorMessage: null,
            recommendedAction: 'WaitAndCheck',
            result: null,
          ),
          CompanyAcceptanceOfflineSyncStatus(
            clientRequestId: 'acceptance-foreground',
            operationCode: 'company-acceptance-create',
            status: 'completed',
            createdAtUtc: DateTime.utc(2026, 10, 19, 8),
            completedAtUtc: DateTime.utc(2026, 10, 19, 8, 1),
            errorMessage: null,
            recommendedAction: 'Completed',
            result: _buildCompanyAcceptanceResult(documentOrderNo: 84),
          ),
        ]);

      final result = await service.submitCompanyAcceptance(
        accessToken: 'token',
        userId: 'user-1',
        warehouseNo: '110',
        request: _buildCompanyAcceptanceRequest(
          clientRequestId: 'acceptance-foreground',
        ),
      );

      expect(result.status, OfflineSubmissionStatus.recovered);
      expect(result.onlineResult?.documentOrderNo, 84);
      expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 2);
      expect(offlineCompanyAcceptanceRepository.savedDrafts, isEmpty);
    },
  );

  test('submitCompanyAcceptance preserves retryable server failures', () async {
    companyAcceptanceRepository
      ..createError = const ApiException(
        statusCode: 500,
        title: 'A task was canceled.',
        errorCode: 'MIKRO_WRITE_OUTCOME_UNCONFIRMED',
        retryable: true,
        retryAfterSeconds: 5,
      )
      ..offlineSyncStatus = CompanyAcceptanceOfflineSyncStatus(
        clientRequestId: 'acceptance-uncertain',
        operationCode: 'company-acceptance-create',
        status: 'failed',
        createdAtUtc: DateTime.utc(2026, 10, 13, 7, 44),
        completedAtUtc: DateTime.utc(2026, 10, 13, 7, 45),
        errorMessage: 'A task was canceled.',
        errorCode: 'MIKRO_WRITE_OUTCOME_UNCONFIRMED',
        retryable: true,
        retryAfterSeconds: 5,
        recommendedAction: 'WaitAndCheck',
        result: null,
      );

    final result = await service.submitCompanyAcceptance(
      accessToken: 'token',
      userId: 'user-1',
      warehouseNo: '165',
      request: _buildCompanyAcceptanceRequest(
        clientRequestId: 'acceptance-uncertain',
      ),
    );

    expect(result.status, OfflineSubmissionStatus.processing);
    expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 1);
    final savedDraft = offlineCompanyAcceptanceRepository.savedDrafts.single;
    expect(savedDraft.clientRequestId, 'acceptance-uncertain');
    expect(savedDraft.status, OfflineRecordStatus.syncing);
    expect(savedDraft.lastError, contains('otomatik kontrol edilecek'));
    expect(savedDraft.lastError, isNot(contains('A task was canceled')));
  });

  test(
    'submitCompanyAcceptance keeps a missing write as an editable draft',
    () async {
      companyAcceptanceRepository
        ..createError = const ApiException(
          statusCode: 0,
          title: 'Baglanti Hatasi',
          detail: 'No network',
        )
        ..offlineSyncError = const ApiException(
          statusCode: 404,
          title: 'Kayit bulunamadi',
        )
        ..onCreate = () {
          if (companyAcceptanceRepository.createCallCount == 2) {
            companyAcceptanceRepository.createError = null;
          }
        };

      final result = await service.submitCompanyAcceptance(
        accessToken: 'token',
        userId: 'user-1',
        warehouseNo: '110',
        request: _buildCompanyAcceptanceRequest(
          clientRequestId: 'acceptance-inline-retry',
        ),
      );

      expect(result.status, OfflineSubmissionStatus.queued);
      expect(companyAcceptanceRepository.createCallCount, 1);
      expect(
        companyAcceptanceRepository.lastCreateClientRequestId,
        'acceptance-inline-retry',
      );
      final savedDraft = offlineCompanyAcceptanceRepository.savedDrafts.single;
      expect(savedDraft.hasBeenSubmitted, isFalse);
      expect(savedDraft.errorCode, 'LOCAL_SEND_RETRY_REQUIRED');
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
    'confirmed missing company acceptance remains an editable same-id draft after one safe retry',
    () async {
      companyAcceptanceRepository.createError = const ApiException(
        statusCode: 409,
        title: 'Kayit tamamlanamadi',
        detail: 'Mikro kaydi olusmadi; guvenli tekrar tamamlansin.',
        errorCode: 'SAFE_WRITE_RETRY_EXHAUSTED',
        retryable: true,
        recommendedAction: 'RetrySameRequest',
      );
      final request = _buildCompanyAcceptanceRequest(
        clientRequestId: 'acceptance-safe-retry-exhausted',
      );

      final result = await service.submitCompanyAcceptance(
        accessToken: 'token',
        userId: 'user-1',
        warehouseNo: '110',
        request: request,
      );

      expect(result.status, OfflineSubmissionStatus.queued);
      expect(companyAcceptanceRepository.createCallCount, 1);
      expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 0);
      final draft = offlineCompanyAcceptanceRepository.savedDrafts.single;
      expect(draft.hasBeenSubmitted, isFalse);
      expect(draft.effectiveClientRequestId, request.clientRequestId);
      expect(draft.errorCode, 'LOCAL_SEND_RETRY_REQUIRED');
    },
  );

  test(
    'syncCompanyAcceptanceDraft keeps http 400 as an unsent editable draft',
    () async {
      companyAcceptanceRepository.createError = const ApiException(
        statusCode: 400,
        title: 'Validasyon Hatasi',
        detail: 'Cari ve stok uyumsuz.',
        errorCode: 'MIKRO_WRITE_IN_PROGRESS',
        retryable: true,
        recommendedAction: 'WaitAndCheck',
      );
      final draft = _buildCompanyAcceptanceDraft(
        clientRequestId: 'acceptance-validation',
      );
      await offlineCompanyAcceptanceRepository.saveDraft(draft);

      final result = await service.syncCompanyAcceptanceDraft(
        accessToken: 'token',
        draft: draft,
      );

      expect(result.status, OfflineDraftSyncResultStatus.failed);
      expect(result.message, contains('Cari ve stok uyumsuz'));
      expect(companyAcceptanceRepository.createCallCount, 1);
      expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 0);
      final savedDraft = offlineCompanyAcceptanceRepository.savedDrafts.single;
      expect(savedDraft.status, OfflineRecordStatus.pending);
      expect(savedDraft.hasBeenSubmitted, isFalse);
      expect(savedDraft.lastSyncAttemptAt, isNull);
      expect(savedDraft.operationCode, isNull);
      expect(savedDraft.retryable, isNull);
      expect(savedDraft.recommendedAction, isNull);
    },
  );

  test(
    'submitCompanyAcceptance removes snapshot for document identity conflicts',
    () async {
      companyAcceptanceRepository.createError = const ApiException(
        statusCode: 409,
        title: 'Conflict',
        detail: 'Seri ve sira numarasi zaten kullaniliyor.',
        errorCode: 'MIKRO_DOCUMENT_IDENTITY_CONFLICT',
        retryable: false,
        recommendedAction: 'EditAndRetry',
      );

      await expectLater(
        service.submitCompanyAcceptance(
          accessToken: 'token',
          userId: 'user-1',
          warehouseNo: '110',
          request: _buildCompanyAcceptanceRequest(
            clientRequestId: 'acceptance-identity-conflict',
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.errorCode,
            'errorCode',
            'MIKRO_DOCUMENT_IDENTITY_CONFLICT',
          ),
        ),
      );

      expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 0);
      expect(offlineCompanyAcceptanceRepository.savedDrafts, isEmpty);
    },
  );

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
    'submitCompanyAcceptance preserves unresolved conflict for support',
    () async {
      companyAcceptanceRepository.createError = const ApiException(
        statusCode: 409,
        title: 'Islem zaten var',
      );

      final result = await service.submitCompanyAcceptance(
        accessToken: 'token',
        userId: 'user-1',
        warehouseNo: '110',
        request: _buildCompanyAcceptanceRequest(
          clientRequestId: 'acceptance-5',
        ),
      );

      expect(result.status, OfflineSubmissionStatus.needsReview);
      expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 1);
      final savedDraft = offlineCompanyAcceptanceRepository.savedDrafts.single;
      expect(savedDraft.clientRequestId, 'acceptance-5');
      expect(savedDraft.hasBeenSubmitted, isTrue);
      expect(savedDraft.retryable, isFalse);
      expect(savedDraft.status, OfflineRecordStatus.failed);
    },
  );

  test('submitCompanyAcceptance persists snapshot before POST', () async {
    var snapshotWasPresentDuringCreate = false;
    companyAcceptanceRepository.onCreate = () {
      final drafts = offlineCompanyAcceptanceRepository.savedDrafts;
      snapshotWasPresentDuringCreate =
          drafts.length == 1 &&
          drafts.single.clientRequestId == 'acceptance-snapshot' &&
          drafts.single.hasBeenSubmitted;
    };

    final result = await service.submitCompanyAcceptance(
      accessToken: 'token',
      userId: 'user-1',
      warehouseNo: '110',
      request: _buildCompanyAcceptanceRequest(
        clientRequestId: 'acceptance-snapshot',
      ),
    );

    expect(result.status, OfflineSubmissionStatus.synced);
    expect(snapshotWasPresentDuringCreate, isTrue);
    expect(offlineCompanyAcceptanceRepository.savedDrafts, isEmpty);
  });

  test(
    'submitted company acceptance checks status before another POST',
    () async {
      companyAcceptanceRepository.offlineSyncStatus =
          CompanyAcceptanceOfflineSyncStatus(
            clientRequestId: 'acceptance-processing-status',
            operationCode: 'company-acceptance-create',
            status: 'processing',
            createdAtUtc: DateTime.utc(2026, 10, 16, 8),
            completedAtUtc: null,
            errorMessage: null,
            errorCode: 'MIKRO_WRITE_IN_PROGRESS',
            retryable: true,
            retryAfterSeconds: 5,
            result: null,
          );
      final draft = _buildCompanyAcceptanceDraft(
        clientRequestId: 'acceptance-processing-status',
        hasBeenSubmitted: true,
      );

      final result = await service.syncCompanyAcceptanceDraft(
        accessToken: 'token',
        draft: draft,
      );

      expect(result.status, OfflineDraftSyncResultStatus.processing);
      expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 1);
      expect(companyAcceptanceRepository.createCallCount, 0);
    },
  );

  test(
    'missing company acceptance reservation returns to the editable draft',
    () async {
      companyAcceptanceRepository.offlineSyncError = const ApiException(
        statusCode: 404,
        title: 'Kayit bulunamadi',
      );
      final draft = _buildCompanyAcceptanceDraft(
        clientRequestId: 'acceptance-missing-reservation',
        hasBeenSubmitted: true,
      );

      final result = await service.syncCompanyAcceptanceDraft(
        accessToken: 'token',
        draft: draft,
      );

      expect(result.status, OfflineDraftSyncResultStatus.deferred);
      expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 1);
      expect(companyAcceptanceRepository.createCallCount, 0);
      final savedDraft = offlineCompanyAcceptanceRepository.savedDrafts.single;
      expect(savedDraft.hasBeenSubmitted, isFalse);
      expect(savedDraft.errorCode, 'LOCAL_SEND_RETRY_REQUIRED');
    },
  );

  test(
    'missing reservation after resend waits for explicit local retry',
    () async {
      companyAcceptanceRepository
        ..offlineSyncError = const ApiException(
          statusCode: 404,
          title: 'Kayit bulunamadi',
        )
        ..createError = const ApiException(
          statusCode: 0,
          title: 'Baglanti Hatasi',
          detail: 'No network',
        );
      final draft = _buildCompanyAcceptanceDraft(
        clientRequestId: 'acceptance-resend-not-received',
        hasBeenSubmitted: true,
      );

      final result = await service.syncCompanyAcceptanceDraft(
        accessToken: 'token',
        draft: draft,
      );

      expect(result.status, OfflineDraftSyncResultStatus.deferred);
      expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 1);
      expect(companyAcceptanceRepository.createCallCount, 0);
      final savedDraft = offlineCompanyAcceptanceRepository.savedDrafts.single;
      expect(savedDraft.hasBeenSubmitted, isFalse);
      expect(savedDraft.retryable, isTrue);
      expect(savedDraft.errorCode, 'LOCAL_SEND_RETRY_REQUIRED');
      expect(savedDraft.lastError, contains('taslaginda korundu'));
      expect(savedDraft.retryNotBefore, isNull);

      final automaticResult = await service.syncCompanyAcceptanceDraft(
        accessToken: 'token',
        draft: savedDraft,
      );

      expect(automaticResult.status, OfflineDraftSyncResultStatus.deferred);
      expect(companyAcceptanceRepository.createCallCount, 0);
    },
  );

  test(
    'manual status check converts missing reservation to explicit local retry',
    () async {
      companyAcceptanceRepository.offlineSyncError = const ApiException(
        statusCode: 404,
        title: 'Kayit bulunamadi',
      );
      final draft = _buildCompanyAcceptanceDraft(
        clientRequestId: 'acceptance-manual-check-missing',
        hasBeenSubmitted: true,
      );

      final result = await service.syncCompanyAcceptanceDraft(
        accessToken: 'token',
        draft: draft,
        statusCheckOnly: true,
      );

      expect(result.status, OfflineDraftSyncResultStatus.deferred);
      expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 1);
      expect(companyAcceptanceRepository.createCallCount, 0);
      final savedDraft = offlineCompanyAcceptanceRepository.savedDrafts.single;
      expect(savedDraft.hasBeenSubmitted, isFalse);
      expect(savedDraft.errorCode, 'LOCAL_SEND_RETRY_REQUIRED');
      expect(savedDraft.lastError, contains('taslaginda korundu'));
    },
  );

  test(
    'missing status does not reopen a non retryable support decision',
    () async {
      companyAcceptanceRepository.offlineSyncError = const ApiException(
        statusCode: 404,
        title: 'Kayit bulunamadi',
      );
      final draft =
          _buildCompanyAcceptanceDraft(
            clientRequestId: 'acceptance-support-missing-status',
            hasBeenSubmitted: true,
          ).copyWith(
            status: OfflineRecordStatus.failed,
            errorCode: 'MIKRO_DOCUMENT_CONTENT_MISMATCH',
            retryable: false,
          );

      final result = await service.syncCompanyAcceptanceDraft(
        accessToken: 'token',
        draft: draft,
        statusCheckOnly: true,
      );

      expect(result.status, OfflineDraftSyncResultStatus.failed);
      expect(companyAcceptanceRepository.createCallCount, 0);
      final savedDraft = offlineCompanyAcceptanceRepository.savedDrafts.single;
      expect(savedDraft.hasBeenSubmitted, isTrue);
      expect(savedDraft.retryable, isFalse);
      expect(savedDraft.errorCode, 'MIKRO_DOCUMENT_CONTENT_MISMATCH');
    },
  );

  test('queue busy company acceptance returns to the editable draft', () async {
    companyAcceptanceRepository.offlineSyncStatus =
        CompanyAcceptanceOfflineSyncStatus(
          clientRequestId: 'acceptance-queue-busy',
          operationCode: 'company-acceptance-create',
          status: 'failed',
          createdAtUtc: DateTime.utc(2026, 10, 16, 8),
          completedAtUtc: DateTime.utc(2026, 10, 16, 8, 1),
          errorMessage: 'Depo yazma kuyrugu mesgul.',
          errorCode: 'MIKRO_WRITE_QUEUE_BUSY',
          retryable: true,
          retryAfterSeconds: 5,
          result: null,
        );
    final draft = _buildCompanyAcceptanceDraft(
      clientRequestId: 'acceptance-queue-busy',
      hasBeenSubmitted: true,
    ).copyWith(errorCode: 'MIKRO_WRITE_QUEUE_BUSY', retryable: true);

    final result = await service.syncCompanyAcceptanceDraft(
      accessToken: 'token',
      draft: draft,
    );

    expect(result.status, OfflineDraftSyncResultStatus.deferred);
    expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 1);
    expect(companyAcceptanceRepository.createCallCount, 0);
    final savedDraft = offlineCompanyAcceptanceRepository.savedDrafts.single;
    expect(savedDraft.hasBeenSubmitted, isFalse);
    expect(savedDraft.errorCode, 'LOCAL_SEND_RETRY_REQUIRED');
  });

  test('first queue busy status does not start another POST', () async {
    companyAcceptanceRepository.offlineSyncStatus =
        CompanyAcceptanceOfflineSyncStatus(
          clientRequestId: 'acceptance-first-queue-busy',
          operationCode: 'company-acceptance-create',
          status: 'failed',
          createdAtUtc: DateTime.utc(2026, 10, 16, 8),
          completedAtUtc: DateTime.utc(2026, 10, 16, 8, 1),
          errorMessage: 'Depo yazma kuyrugu mesgul.',
          errorCode: 'MIKRO_WRITE_QUEUE_BUSY',
          retryable: true,
          retryAfterSeconds: 5,
          result: null,
        );
    final draft = _buildCompanyAcceptanceDraft(
      clientRequestId: 'acceptance-first-queue-busy',
      hasBeenSubmitted: true,
    );

    final result = await service.syncCompanyAcceptanceDraft(
      accessToken: 'token',
      draft: draft,
    );

    expect(result.status, OfflineDraftSyncResultStatus.deferred);
    expect(companyAcceptanceRepository.createCallCount, 0);
    final savedDraft = offlineCompanyAcceptanceRepository.savedDrafts.single;
    expect(savedDraft.errorCode, 'LOCAL_SEND_RETRY_REQUIRED');
    expect(savedDraft.hasBeenSubmitted, isFalse);
    expect(savedDraft.retryNotBefore, isNull);
  });

  test(
    'uncertain company acceptance is not automatically posted again',
    () async {
      companyAcceptanceRepository.offlineSyncStatus =
          CompanyAcceptanceOfflineSyncStatus(
            clientRequestId: 'acceptance-uncertain-status',
            operationCode: 'company-acceptance-create',
            status: 'failed',
            createdAtUtc: DateTime.utc(2026, 10, 16, 8),
            completedAtUtc: DateTime.utc(2026, 10, 16, 8, 1),
            errorMessage: 'Mikro sonucu henuz kesinlesmedi.',
            errorCode: 'MIKRO_WRITE_OUTCOME_UNCONFIRMED',
            retryable: true,
            retryAfterSeconds: 5,
            result: null,
          );
      final draft = _buildCompanyAcceptanceDraft(
        clientRequestId: 'acceptance-uncertain-status',
        hasBeenSubmitted: true,
      );

      final result = await service.syncCompanyAcceptanceDraft(
        accessToken: 'token',
        draft: draft,
      );

      expect(result.status, OfflineDraftSyncResultStatus.processing);
      expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 1);
      expect(companyAcceptanceRepository.createCallCount, 0);
    },
  );

  test('support state can be checked without another POST', () async {
    companyAcceptanceRepository.offlineSyncStatus =
        CompanyAcceptanceOfflineSyncStatus(
          clientRequestId: 'acceptance-support-status',
          operationCode: 'company-acceptance-create',
          status: 'failed',
          createdAtUtc: DateTime.utc(2026, 10, 16, 8),
          completedAtUtc: DateTime.utc(2026, 10, 16, 8, 1),
          errorMessage: 'Yetkili incelemesi gerekli.',
          errorCode: 'MIKRO_DOCUMENT_CONTENT_MISMATCH',
          retryable: false,
          result: null,
        );
    final draft = _buildCompanyAcceptanceDraft(
      clientRequestId: 'acceptance-support-status',
      hasBeenSubmitted: true,
    ).copyWith(errorCode: 'MIKRO_DOCUMENT_CONTENT_MISMATCH', retryable: false);

    final result = await service.syncCompanyAcceptanceDraft(
      accessToken: 'token',
      draft: draft,
      statusCheckOnly: true,
    );

    expect(result.status, OfflineDraftSyncResultStatus.failed);
    expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 1);
    expect(companyAcceptanceRepository.createCallCount, 0);
  });

  test('cancelled company acceptance clears its local snapshot', () async {
    companyAcceptanceRepository.offlineSyncStatus =
        CompanyAcceptanceOfflineSyncStatus(
          clientRequestId: 'acceptance-cancelled',
          operationCode: 'company-acceptance-create',
          status: 'Cancelled',
          createdAtUtc: DateTime.utc(2026, 10, 16, 8),
          completedAtUtc: DateTime.utc(2026, 10, 16, 8, 1),
          errorMessage: 'Kayit yetkili tarafindan iptal edildi.',
          errorCode: 'SAFE_WRITE_CANCELLED',
          retryable: false,
          result: null,
        );
    final draft = _buildCompanyAcceptanceDraft(
      clientRequestId: 'acceptance-cancelled',
      hasBeenSubmitted: true,
    ).copyWith(retryable: false);
    await offlineCompanyAcceptanceRepository.saveDraft(draft);

    final result = await service.syncCompanyAcceptanceDraft(
      accessToken: 'token',
      draft: draft,
      statusCheckOnly: true,
    );

    expect(result.status, OfflineDraftSyncResultStatus.cancelled);
    expect(result.message, contains('iptal edildi'));
    expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 1);
    expect(companyAcceptanceRepository.createCallCount, 0);
    expect(offlineCompanyAcceptanceRepository.savedDrafts, isEmpty);
  });

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
    'syncCompanyAcceptanceDraft defers an unresolved server failure',
    () async {
      companyAcceptanceRepository.createError = const ApiException(
        statusCode: 503,
        title: 'Servis gecici olarak kullanilamiyor',
      );

      final result = await service.syncCompanyAcceptanceDraft(
        accessToken: 'token',
        draft: _buildCompanyAcceptanceDraft(
          clientRequestId: 'draft-server-failure',
        ),
      );

      expect(result.status, OfflineDraftSyncResultStatus.deferred);
      expect(companyAcceptanceRepository.fetchOfflineSyncStatusCallCount, 1);
      expect(
        offlineCompanyAcceptanceRepository.savedDrafts.single.status,
        OfflineRecordStatus.pending,
      );
    },
  );

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

  test(
    'syncCompanyAcceptanceDraft fails legacy drafts without document identity',
    () async {
      final serializedDraft =
          _buildCompanyAcceptanceDraft(clientRequestId: 'legacy-draft').toJson()
            ..remove('documentSerie')
            ..remove('documentOrderNo');
      final draft = OfflineCompanyAcceptanceDraft.fromJson(serializedDraft);

      final result = await service.syncCompanyAcceptanceDraft(
        accessToken: 'token',
        draft: draft,
      );

      expect(result.status, OfflineDraftSyncResultStatus.failed);
      expect(
        result.message,
        'Evrak serisi ve sirasi zorunlu. Eski offline taslagi yeniden olusturun.',
      );
      expect(
        offlineCompanyAcceptanceRepository.savedDrafts.single.status,
        OfflineRecordStatus.failed,
      );
    },
  );

  test('migrates legacy company acceptance document number when valid', () {
    final serializedDraft =
        _buildCompanyAcceptanceDraft(clientRequestId: 'legacy-valid').toJson()
          ..remove('documentSerie')
          ..remove('documentOrderNo')
          ..['documentNo'] = 'FMK000001001';

    final draft = OfflineCompanyAcceptanceDraft.fromJson(serializedDraft);

    expect(draft.documentSerie, 'FMK');
    expect(draft.documentOrderNo, 1001);
    expect(draft.documentLabel, 'FMK.1001');
  });
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
    documentSerie: 'fmk',
    documentOrderNo: 1001,
    officialDocumentKind: 'e-despatch',
    officialDocumentNo: 'ST12026000002395',
    officialDocumentDate: DateTime(2026, 4, 20),
    officialDocumentEttn: '550e8400-e29b-41d4-a716-446655440000',
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
  bool hasBeenSubmitted = false,
}) {
  return OfflineCompanyAcceptanceDraft.fromCreateRequest(
    _buildCompanyAcceptanceRequest(clientRequestId: clientRequestId),
    userId: 'user-1',
    warehouseNo: '110',
    customerDisplayName: 'Test Cari',
    createdAt: DateTime(2026, 4, 23, 9),
    status: OfflineRecordStatus.pending,
    lastSyncAttemptAt: null,
    hasBeenSubmitted: hasBeenSubmitted,
  );
}

class _FakeInventoryCountsRepository implements InventoryCountsRepository {
  ApiException? createError;
  InventoryCountOfflineSyncStatus? offlineSyncStatus;
  int fetchOfflineSyncStatusCallCount = 0;
  int createCountCallCount = 0;

  @override
  Future<BarcodeResolutionResult> resolveBarcode({
    required String accessToken,
    required BarcodeResolutionRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<InventoryCountCreateResult> createCount({
    required String accessToken,
    required InventoryCountCreateRequest request,
  }) async {
    createCountCallCount += 1;
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
          status: 'unknown',
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
    bool includeDelisted = true,
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
  Future<void> completeDraft(String id) => deleteDraft(id);

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
  ApiException? offlineSyncError;
  CompanyAcceptanceOfflineSyncStatus? offlineSyncStatus;
  final List<CompanyAcceptanceOfflineSyncStatus> offlineSyncStatuses =
      <CompanyAcceptanceOfflineSyncStatus>[];
  int fetchOfflineSyncStatusCallCount = 0;
  int createCallCount = 0;
  String? lastCreateClientRequestId;
  void Function()? onCreate;

  @override
  Future<CompanyAcceptanceCreateResult> createAcceptance({
    required String accessToken,
    required CompanyAcceptanceCreateRequest request,
  }) async {
    createCallCount += 1;
    lastCreateClientRequestId = request.clientRequestId;
    onCreate?.call();
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
    final error = offlineSyncError;
    if (error != null) {
      throw error;
    }
    if (offlineSyncStatuses.isNotEmpty) {
      return offlineSyncStatuses.removeAt(0);
    }
    return offlineSyncStatus ??
        CompanyAcceptanceOfflineSyncStatus(
          clientRequestId: clientRequestId,
          operationCode: 'company-acceptance-create',
          status: 'unknown',
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
  Future<void> completeDraft(String id) => deleteDraft(id);

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
