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
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_status.dart';
import 'package:furpa_merkez_terminal/shared/utils/safe_create_retry.dart';

enum OfflineSubmissionStatus {
  synced,
  recovered,
  queued,
  processing,
  needsReview,
  cancelled,
}

class InventoryCountSubmissionResult {
  const InventoryCountSubmissionResult({
    required this.status,
    this.onlineResult,
  });

  final OfflineSubmissionStatus status;
  final InventoryCountCreateResult? onlineResult;
}

class CompanyAcceptanceSubmissionResult {
  const CompanyAcceptanceSubmissionResult({
    required this.status,
    this.onlineResult,
  });

  final OfflineSubmissionStatus status;
  final CompanyAcceptanceCreateResult? onlineResult;
}

enum OfflineDraftSyncResultStatus {
  synced,
  processing,
  failed,
  deferred,
  cancelled,
}

class OfflineDraftSyncResult {
  const OfflineDraftSyncResult({required this.status, this.message});

  final OfflineDraftSyncResultStatus status;
  final String? message;
}

class OfflineSyncService {
  OfflineSyncService({
    required InventoryCountsRepository inventoryRepository,
    required CompanyAcceptancesRepository companyAcceptanceRepository,
    required OfflineInventoryCountsRepository offlineInventoryRepository,
    required OfflineCompanyAcceptancesRepository
    offlineCompanyAcceptanceRepository,
  }) : _inventoryRepository = inventoryRepository,
       _companyAcceptanceRepository = companyAcceptanceRepository,
       _offlineInventoryRepository = offlineInventoryRepository,
       _offlineCompanyAcceptanceRepository = offlineCompanyAcceptanceRepository;

  final InventoryCountsRepository _inventoryRepository;
  final CompanyAcceptancesRepository _companyAcceptanceRepository;
  final OfflineInventoryCountsRepository _offlineInventoryRepository;
  final OfflineCompanyAcceptancesRepository _offlineCompanyAcceptanceRepository;

  bool _isSyncRunning = false;

  Future<InventoryCountSubmissionResult> submitInventoryCount({
    required String accessToken,
    required String userId,
    required String warehouseNo,
    required InventoryCountCreateRequest request,
  }) async {
    try {
      final result = await _inventoryRepository.createCount(
        accessToken: accessToken,
        request: request,
      );
      return InventoryCountSubmissionResult(
        status: OfflineSubmissionStatus.synced,
        onlineResult: result,
      );
    } on ApiException catch (error) {
      if (_shouldTryCreateRecovery(error)) {
        final recovery = await _recoverInventoryRequest(
          accessToken: accessToken,
          clientRequestId: request.clientRequestId ?? '',
        );
        if (recovery.status == _CreateRecoveryStatus.completed) {
          return InventoryCountSubmissionResult(
            status: OfflineSubmissionStatus.recovered,
            onlineResult: recovery.result,
          );
        }
        if (recovery.status == _CreateRecoveryStatus.cancelled) {
          return const InventoryCountSubmissionResult(
            status: OfflineSubmissionStatus.cancelled,
          );
        }
        if (recovery.status == _CreateRecoveryStatus.processing) {
          await _offlineInventoryRepository.saveDraft(
            OfflineInventoryCountDraft.fromCreateRequest(
              request,
              userId: userId,
              warehouseNo: warehouseNo,
              status: OfflineRecordStatus.syncing,
              lastSyncAttemptAt: DateTime.now(),
              lastError: recovery.message ?? 'Kayit sunucuda isleniyor.',
            ),
          );
          return const InventoryCountSubmissionResult(
            status: OfflineSubmissionStatus.processing,
          );
        }
        if (recovery.status == _CreateRecoveryStatus.retryable) {
          await _offlineInventoryRepository.saveDraft(
            OfflineInventoryCountDraft.fromCreateRequest(
              request,
              userId: userId,
              warehouseNo: warehouseNo,
              status: OfflineRecordStatus.pending,
              lastSyncAttemptAt: DateTime.now(),
              lastError: recovery.message,
            ),
          );
          return const InventoryCountSubmissionResult(
            status: OfflineSubmissionStatus.queued,
          );
        }
        if (recovery.status == _CreateRecoveryStatus.failed) {
          rethrow;
        }
      }

      if (!_shouldQueueAfterCreate(error)) {
        rethrow;
      }

      await _offlineInventoryRepository.saveDraft(
        OfflineInventoryCountDraft.fromCreateRequest(
          request,
          userId: userId,
          warehouseNo: warehouseNo,
          status: OfflineRecordStatus.pending,
          lastSyncAttemptAt: DateTime.now(),
          lastError: _pendingCreateMessage(error),
        ),
      );
      return const InventoryCountSubmissionResult(
        status: OfflineSubmissionStatus.queued,
      );
    }
  }

  Future<CompanyAcceptanceSubmissionResult> submitCompanyAcceptance({
    required String accessToken,
    required String userId,
    required String warehouseNo,
    required CompanyAcceptanceCreateRequest request,
    String? customerDisplayName,
    DateTime? createdAt,
  }) async {
    final now = DateTime.now();
    final snapshot = OfflineCompanyAcceptanceDraft.fromCreateRequest(
      request,
      userId: userId,
      warehouseNo: warehouseNo,
      customerDisplayName: customerDisplayName ?? '',
      createdAt: createdAt ?? now,
      status: OfflineRecordStatus.syncing,
      lastSyncAttemptAt: now,
      lastError: 'Mikro sonucu kontrol ediliyor.',
      hasBeenSubmitted: true,
      operationCode: 'company-acceptance-create',
      retryable: true,
      retryNotBefore: now.add(const Duration(seconds: 5)),
    );
    await _offlineCompanyAcceptanceRepository.saveDraft(snapshot);

    try {
      final result = await _companyAcceptanceRepository.createAcceptance(
        accessToken: accessToken,
        request: request,
      );
      await _offlineCompanyAcceptanceRepository.deleteDraft(snapshot.id);
      return CompanyAcceptanceSubmissionResult(
        status: OfflineSubmissionStatus.synced,
        onlineResult: result,
      );
    } on ApiException catch (error) {
      if (_shouldTryCreateRecovery(error)) {
        final recovery = await _recoverCompanyAcceptanceRequest(
          accessToken: accessToken,
          clientRequestId: request.clientRequestId ?? '',
        );
        if (recovery.status == _CreateRecoveryStatus.completed) {
          await _offlineCompanyAcceptanceRepository.deleteDraft(snapshot.id);
          return CompanyAcceptanceSubmissionResult(
            status: OfflineSubmissionStatus.recovered,
            onlineResult: recovery.result,
          );
        }
        if (recovery.status == _CreateRecoveryStatus.cancelled) {
          await _offlineCompanyAcceptanceRepository.deleteDraft(snapshot.id);
          return const CompanyAcceptanceSubmissionResult(
            status: OfflineSubmissionStatus.cancelled,
          );
        }
        if (recovery.status == _CreateRecoveryStatus.processing) {
          await _saveCompanyAcceptanceRecovery(
            snapshot,
            recovery,
            status: OfflineRecordStatus.syncing,
          );
          return const CompanyAcceptanceSubmissionResult(
            status: OfflineSubmissionStatus.processing,
          );
        }
        if (recovery.status == _CreateRecoveryStatus.retryable) {
          await _saveCompanyAcceptanceRecovery(
            snapshot,
            recovery,
            status: OfflineRecordStatus.pending,
          );
          return const CompanyAcceptanceSubmissionResult(
            status: OfflineSubmissionStatus.queued,
          );
        }
        if (recovery.status == _CreateRecoveryStatus.failed ||
            recovery.status == _CreateRecoveryStatus.statusNotFound) {
          await _saveCompanyAcceptanceRecovery(
            snapshot,
            recovery,
            status: OfflineRecordStatus.failed,
          );
          return const CompanyAcceptanceSubmissionResult(
            status: OfflineSubmissionStatus.needsReview,
          );
        }
        if (recovery.status == _CreateRecoveryStatus.unknown &&
            _shouldQueueAfterCreate(error)) {
          await _offlineCompanyAcceptanceRepository.saveDraft(
            snapshot.copyWith(
              status: OfflineRecordStatus.pending,
              lastSyncAttemptAt: DateTime.now(),
              lastCheckedAt: DateTime.now(),
              lastError: _pendingCreateMessage(error),
              operationCode: 'company-acceptance-create',
              retryable: false,
              recommendedAction: 'WaitAndCheck',
              recoveryState: 'OutcomeUnconfirmed',
              retryAfterSeconds: 5,
              retryNotBefore: DateTime.now().add(const Duration(seconds: 5)),
              statusCheckCount: snapshot.statusCheckCount + 1,
            ),
          );
          return const CompanyAcceptanceSubmissionResult(
            status: OfflineSubmissionStatus.queued,
          );
        }
      }

      final failureKind = classifySafeCreateException(error);
      final shouldPreserve =
          _shouldQueueAfterCreate(error) ||
          error.statusCode == 401 ||
          error.statusCode == 409 ||
          failureKind == SafeCreateFailureKind.manualReview ||
          failureKind == SafeCreateFailureKind.payloadChanged ||
          failureKind == SafeCreateFailureKind.multipleDocuments ||
          failureKind == SafeCreateFailureKind.statusNotFound;
      if (!shouldPreserve) {
        await _offlineCompanyAcceptanceRepository.deleteDraft(snapshot.id);
        rethrow;
      }

      await _offlineCompanyAcceptanceRepository.saveDraft(
        snapshot.copyWith(
          status: canRetrySafeCreate(failureKind)
              ? OfflineRecordStatus.pending
              : OfflineRecordStatus.failed,
          lastSyncAttemptAt: DateTime.now(),
          lastCheckedAt: DateTime.now(),
          lastError: safeCreateRetryErrorMessage(error),
          operationCode: 'company-acceptance-create',
          errorCode: error.errorCode,
          retryable: canRetrySafeCreate(failureKind),
          retryAfterSeconds: error.retryAfterSeconds,
          retryNotBefore: _nextCompanyAcceptanceCheck(
            snapshot,
            error.retryAfterSeconds,
          ),
          correlationId: error.correlationId,
          relatedClientRequestId: error.relatedClientRequestId,
          statusCheckCount: snapshot.statusCheckCount + 1,
        ),
      );
      if (error.statusCode == 401) {
        rethrow;
      }
      return CompanyAcceptanceSubmissionResult(
        status: canRetrySafeCreate(failureKind)
            ? OfflineSubmissionStatus.queued
            : OfflineSubmissionStatus.needsReview,
      );
    }
  }

  Future<OfflineDraftSyncResult> syncInventoryDraft({
    required String accessToken,
    required OfflineInventoryCountDraft draft,
  }) async {
    final syncingDraft = draft.copyWith(
      status: OfflineRecordStatus.syncing,
      lastSyncAttemptAt: DateTime.now(),
      lastError: null,
    );
    await _offlineInventoryRepository.saveDraft(syncingDraft);

    try {
      await _inventoryRepository.createCount(
        accessToken: accessToken,
        request: syncingDraft.toCreateRequest(),
      );
      await _offlineInventoryRepository.deleteDraft(syncingDraft.id);
      return const OfflineDraftSyncResult(
        status: OfflineDraftSyncResultStatus.synced,
      );
    } on ApiException catch (error) {
      final recovery = await _recoverInventoryRequest(
        accessToken: accessToken,
        clientRequestId: syncingDraft.clientRequestId,
      );
      if (recovery.status == _CreateRecoveryStatus.completed) {
        await _offlineInventoryRepository.deleteDraft(syncingDraft.id);
        return const OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.synced,
        );
      }
      if (recovery.status == _CreateRecoveryStatus.cancelled) {
        await _offlineInventoryRepository.deleteDraft(syncingDraft.id);
        return OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.cancelled,
          message:
              recovery.message ??
              'Bu sayim yetkili tarafindan iptal edildi. Mikro evraki olusturulmadi.',
        );
      }
      if (recovery.status == _CreateRecoveryStatus.processing) {
        await _offlineInventoryRepository.saveDraft(
          syncingDraft.copyWith(
            status: OfflineRecordStatus.syncing,
            lastError: recovery.message ?? 'Kayit sunucuda isleniyor.',
          ),
        );
        return OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.processing,
          message: recovery.message ?? 'Kayit sunucuda isleniyor.',
        );
      }
      if (recovery.status == _CreateRecoveryStatus.retryable) {
        await _offlineInventoryRepository.saveDraft(
          syncingDraft.copyWith(
            status: OfflineRecordStatus.pending,
            lastError: recovery.message,
          ),
        );
        return OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.deferred,
          message: recovery.message,
        );
      }
      if (recovery.status == _CreateRecoveryStatus.failed) {
        await _offlineInventoryRepository.saveDraft(
          syncingDraft.copyWith(
            status: OfflineRecordStatus.failed,
            lastError: recovery.message,
          ),
        );
        return OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.failed,
          message: recovery.message,
        );
      }

      if (_shouldDeferSync(error)) {
        await _offlineInventoryRepository.saveDraft(
          syncingDraft.copyWith(
            status: OfflineRecordStatus.pending,
            lastError: error.message,
          ),
        );
        return OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.deferred,
          message: error.message,
        );
      }

      await _offlineInventoryRepository.saveDraft(
        syncingDraft.copyWith(
          status: OfflineRecordStatus.failed,
          lastError: error.message,
        ),
      );
      return OfflineDraftSyncResult(
        status: OfflineDraftSyncResultStatus.failed,
        message: error.message,
      );
    }
  }

  Future<OfflineDraftSyncResult> syncCompanyAcceptanceDraft({
    required String accessToken,
    required OfflineCompanyAcceptanceDraft draft,
    bool manualRetry = false,
    bool statusCheckOnly = false,
    bool recheckExisting = false,
  }) async {
    if (draft.documentSerie.trim().isEmpty || draft.documentOrderNo <= 0) {
      const message =
          'Evrak serisi ve sirasi zorunlu. Eski offline taslagi yeniden olusturun.';
      await _offlineCompanyAcceptanceRepository.saveDraft(
        draft.copyWith(status: OfflineRecordStatus.failed, lastError: message),
      );
      return const OfflineDraftSyncResult(
        status: OfflineDraftSyncResultStatus.failed,
        message: message,
      );
    }

    if (!statusCheckOnly &&
        draft.retryable == false &&
        draft.hasBeenSubmitted) {
      return OfflineDraftSyncResult(
        status: OfflineDraftSyncResultStatus.failed,
        message:
            draft.lastError ??
            'Bu belge tekrar gonderilmemeli; yetkili incelemesi gerekli.',
      );
    }

    final retryNotBefore = draft.retryNotBefore;
    if (!statusCheckOnly &&
        retryNotBefore != null &&
        retryNotBefore.isAfter(DateTime.now())) {
      final seconds = retryNotBefore.difference(DateTime.now()).inSeconds + 1;
      return OfflineDraftSyncResult(
        status: OfflineDraftSyncResultStatus.deferred,
        message: '$seconds saniye sonra durum yeniden kontrol edilecek.',
      );
    }

    var draftToSubmit = draft;
    if (draft.hasBeenSubmitted) {
      final recovery = await _recoverCompanyAcceptanceRequest(
        accessToken: accessToken,
        clientRequestId: draft.effectiveClientRequestId,
        recheckExisting: recheckExisting,
      );
      if (recovery.status == _CreateRecoveryStatus.completed) {
        await _offlineCompanyAcceptanceRepository.deleteDraft(draft.id);
        return const OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.synced,
        );
      }
      if (recovery.status == _CreateRecoveryStatus.cancelled) {
        await _offlineCompanyAcceptanceRepository.deleteDraft(draft.id);
        return OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.cancelled,
          message:
              recovery.message ??
              'Bu mal kabul yetkili tarafindan iptal edildi. Mikro evraki olusturulmadi.',
        );
      }
      if (recovery.status == _CreateRecoveryStatus.processing) {
        await _saveCompanyAcceptanceRecovery(
          draft,
          recovery,
          status: OfflineRecordStatus.syncing,
        );
        return OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.processing,
          message: recovery.message ?? 'Mikro sonucu kontrol ediliyor.',
        );
      }
      if (recovery.status == _CreateRecoveryStatus.failed ||
          recovery.status == _CreateRecoveryStatus.statusNotFound) {
        await _saveCompanyAcceptanceRecovery(
          draft,
          recovery,
          status: OfflineRecordStatus.failed,
        );
        return OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.failed,
          message: recovery.message,
        );
      }
      if (recovery.status == _CreateRecoveryStatus.retryable) {
        final errorCode = recovery.errorCode?.trim().toUpperCase() ?? '';
        final wasWaitingForQueue =
            draft.errorCode?.trim().toUpperCase() == 'MIKRO_WRITE_QUEUE_BUSY';
        final canSubmitAgain =
            !statusCheckOnly &&
            (recovery.recommendedAction == 'RetrySameRequest' ||
                errorCode == 'SAFE_WRITE_RETRY_ALLOWED' ||
                (errorCode == 'MIKRO_WRITE_QUEUE_BUSY' && wasWaitingForQueue));
        if (!canSubmitAgain) {
          await _saveCompanyAcceptanceRecovery(
            draft,
            recovery,
            status: OfflineRecordStatus.pending,
          );
          return OfflineDraftSyncResult(
            status: OfflineDraftSyncResultStatus.deferred,
            message: recovery.message,
          );
        }
        draftToSubmit = draft.copyWith(
          relatedClientRequestId: recovery.relatedClientRequestId,
          operationCode: recovery.operationCode,
          errorCode: recovery.errorCode,
          retryable: true,
          lastCheckedAt: DateTime.now(),
        );
      } else if (recovery.status == _CreateRecoveryStatus.unknown) {
        await _offlineCompanyAcceptanceRepository.saveDraft(
          draft.copyWith(
            status: OfflineRecordStatus.pending,
            lastCheckedAt: DateTime.now(),
            lastError:
                recovery.message ??
                'Sunucu durumu su anda okunamadi. Kayit cihazda korunuyor.',
            retryNotBefore: _nextCompanyAcceptanceCheck(draft, null),
            statusCheckCount: draft.statusCheckCount + 1,
          ),
        );
        return OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.deferred,
          message: recovery.message,
        );
      }
    }

    final syncingDraft = draftToSubmit.copyWith(
      status: OfflineRecordStatus.syncing,
      lastSyncAttemptAt: DateTime.now(),
      lastError: 'Mikro sonucu kontrol ediliyor.',
      hasBeenSubmitted: true,
      operationCode: draftToSubmit.operationCode ?? 'company-acceptance-create',
      retryable: true,
      retryNotBefore: _nextCompanyAcceptanceCheck(draftToSubmit, null),
    );
    await _offlineCompanyAcceptanceRepository.saveDraft(syncingDraft);

    try {
      await _companyAcceptanceRepository.createAcceptance(
        accessToken: accessToken,
        request: draftToSubmit.toCreateRequest(),
      );
      await _offlineCompanyAcceptanceRepository.deleteDraft(syncingDraft.id);
      return const OfflineDraftSyncResult(
        status: OfflineDraftSyncResultStatus.synced,
      );
    } on ApiException catch (error) {
      final recovery = await _recoverCompanyAcceptanceRequest(
        accessToken: accessToken,
        clientRequestId: syncingDraft.effectiveClientRequestId,
        recheckExisting: false,
      );
      if (recovery.status == _CreateRecoveryStatus.completed) {
        await _offlineCompanyAcceptanceRepository.deleteDraft(syncingDraft.id);
        return const OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.synced,
        );
      }
      if (recovery.status == _CreateRecoveryStatus.cancelled) {
        await _offlineCompanyAcceptanceRepository.deleteDraft(syncingDraft.id);
        return OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.cancelled,
          message:
              recovery.message ??
              'Bu mal kabul yetkili tarafindan iptal edildi. Mikro evraki olusturulmadi.',
        );
      }
      if (recovery.status == _CreateRecoveryStatus.processing) {
        await _saveCompanyAcceptanceRecovery(
          syncingDraft,
          recovery,
          status: OfflineRecordStatus.syncing,
        );
        return OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.processing,
          message: recovery.message ?? 'Kayit sunucuda isleniyor.',
        );
      }
      if (recovery.status == _CreateRecoveryStatus.retryable) {
        await _saveCompanyAcceptanceRecovery(
          syncingDraft,
          recovery,
          status: OfflineRecordStatus.pending,
        );
        return OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.deferred,
          message: recovery.message,
        );
      }
      if (recovery.status == _CreateRecoveryStatus.failed ||
          recovery.status == _CreateRecoveryStatus.statusNotFound) {
        await _saveCompanyAcceptanceRecovery(
          syncingDraft,
          recovery,
          status: OfflineRecordStatus.failed,
        );
        return OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.failed,
          message: recovery.message,
        );
      }

      if (_shouldDeferSync(error)) {
        await _offlineCompanyAcceptanceRepository.saveDraft(
          syncingDraft.copyWith(
            status: OfflineRecordStatus.pending,
            lastCheckedAt: DateTime.now(),
            lastError: safeCreateRetryErrorMessage(error),
            errorCode: error.errorCode,
            retryable: true,
            retryAfterSeconds: error.retryAfterSeconds,
            retryNotBefore: _nextCompanyAcceptanceCheck(
              syncingDraft,
              error.retryAfterSeconds,
            ),
            correlationId: error.correlationId,
            relatedClientRequestId: error.relatedClientRequestId,
            statusCheckCount: syncingDraft.statusCheckCount + 1,
          ),
        );
        return OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.deferred,
          message: error.message,
        );
      }

      await _offlineCompanyAcceptanceRepository.saveDraft(
        syncingDraft.copyWith(
          status: OfflineRecordStatus.failed,
          lastCheckedAt: DateTime.now(),
          lastError: safeCreateRetryErrorMessage(error),
          errorCode: error.errorCode,
          retryable: false,
          correlationId: error.correlationId,
          relatedClientRequestId: error.relatedClientRequestId,
          statusCheckCount: syncingDraft.statusCheckCount + 1,
        ),
      );
      return OfflineDraftSyncResult(
        status: OfflineDraftSyncResultStatus.failed,
        message: error.message,
      );
    }
  }

  Future<void> syncPending({
    required String accessToken,
    required String userId,
    required String warehouseNo,
  }) async {
    if (_isSyncRunning) {
      return;
    }

    _isSyncRunning = true;
    try {
      final inventoryDrafts = await _offlineInventoryRepository.fetchDrafts(
        userId: userId,
        warehouseNo: warehouseNo,
      );

      for (final draft in inventoryDrafts) {
        final lastAttempt = draft.lastSyncAttemptAt;
        if (lastAttempt != null &&
            DateTime.now().difference(lastAttempt) <
                const Duration(seconds: 45)) {
          continue;
        }
        final result = await syncInventoryDraft(
          accessToken: accessToken,
          draft: draft,
        );
        if (result.status == OfflineDraftSyncResultStatus.deferred ||
            result.status == OfflineDraftSyncResultStatus.processing) {
          break;
        }
      }

      final companyAcceptanceDrafts = await _offlineCompanyAcceptanceRepository
          .fetchDrafts(userId: userId, warehouseNo: warehouseNo);

      for (final draft in companyAcceptanceDrafts) {
        if (draft.retryable == false && draft.hasBeenSubmitted) {
          final retryNotBefore = draft.retryNotBefore;
          if (retryNotBefore != null &&
              retryNotBefore.isAfter(DateTime.now())) {
            continue;
          }
          await syncCompanyAcceptanceDraft(
            accessToken: accessToken,
            draft: draft,
            statusCheckOnly: true,
          );
          continue;
        }
        await syncCompanyAcceptanceDraft(
          accessToken: accessToken,
          draft: draft,
        );
      }
    } finally {
      _isSyncRunning = false;
    }
  }

  Future<void> _saveCompanyAcceptanceRecovery(
    OfflineCompanyAcceptanceDraft draft,
    _CreateRecovery<CompanyAcceptanceCreateResult> recovery, {
    required OfflineRecordStatus status,
  }) {
    final now = DateTime.now();
    final retryable =
        recovery.retryable ??
        (recovery.status == _CreateRecoveryStatus.processing ||
            recovery.status == _CreateRecoveryStatus.retryable);
    final fallbackMessage = switch (recovery.status) {
      _CreateRecoveryStatus.processing => 'Mikro sonucu kontrol ediliyor.',
      _CreateRecoveryStatus.statusNotFound =>
        'Bu guvenli kaydin sunucu durum izi bulunamadi. Destek gerekli.',
      _CreateRecoveryStatus.failed =>
        'Bu belge tekrar gonderilmemeli; yetkili incelemesi gerekli.',
      _CreateRecoveryStatus.cancelled =>
        'Bu kayit yetkili tarafindan iptal edildi. Mikro evraki olusturulmadi.',
      _ => 'Kayit sonucu henuz kesinlesmedi.',
    };
    return _offlineCompanyAcceptanceRepository.saveDraft(
      draft.copyWith(
        status: status,
        lastSyncAttemptAt: now,
        lastCheckedAt: now,
        lastError: recovery.message?.trim().isNotEmpty == true
            ? recovery.message
            : fallbackMessage,
        hasBeenSubmitted: true,
        operationCode:
            recovery.operationCode ??
            draft.operationCode ??
            'company-acceptance-create',
        errorCode: recovery.errorCode,
        retryable: retryable,
        retryAfterSeconds: recovery.retryAfterSeconds,
        retryNotBefore: retryable
            ? _nextCompanyAcceptanceCheck(draft, recovery.retryAfterSeconds)
            : draft.retryNotBefore,
        correlationId: recovery.correlationId,
        relatedClientRequestId: recovery.relatedClientRequestId,
        statusCheckCount: draft.statusCheckCount + 1,
        recoveryState: recovery.recoveryState,
        recommendedAction: recovery.recommendedAction,
      ),
    );
  }

  DateTime _nextCompanyAcceptanceCheck(
    OfflineCompanyAcceptanceDraft draft,
    int? retryAfterSeconds,
  ) {
    const backoffSeconds = <int>[5, 10, 20, 30];
    final fallbackIndex = draft.statusCheckCount.clamp(
      0,
      backoffSeconds.length - 1,
    );
    final requestedSeconds = retryAfterSeconds == null || retryAfterSeconds <= 0
        ? backoffSeconds[fallbackIndex]
        : retryAfterSeconds;
    final boundedSeconds = requestedSeconds.clamp(5, 30);
    return DateTime.now().add(Duration(seconds: boundedSeconds));
  }

  bool _shouldQueueAfterCreate(ApiException error) {
    return _isConnectionFailure(error) ||
        error.retryable == true ||
        _isUncertainServerFailure(error);
  }

  bool _shouldTryCreateRecovery(ApiException error) {
    return error.statusCode == 409 ||
        error.statusCode == 0 ||
        error.retryable == true ||
        _isUncertainServerFailure(error);
  }

  bool _shouldDeferSync(ApiException error) {
    return _isConnectionFailure(error) ||
        error.statusCode == 401 ||
        error.retryable == true ||
        _isUncertainServerFailure(error);
  }

  bool _isUncertainServerFailure(ApiException error) {
    return error.statusCode >= 500 && error.statusCode < 600;
  }

  String _pendingCreateMessage(ApiException error) {
    if (_isConnectionFailure(error)) {
      return error.message;
    }
    return _retryableRecoveryMessage(error.message, error.retryAfterSeconds);
  }

  bool _isConnectionFailure(ApiException error) {
    if (error.statusCode != 0) {
      return false;
    }

    final title = error.title.toLowerCase();
    return title == 'timeout' ||
        title.contains('baglanti') ||
        title.contains('connection') ||
        title.contains('internet') ||
        title.contains('network');
  }

  Future<_CreateRecovery<InventoryCountCreateResult>> _recoverInventoryRequest({
    required String accessToken,
    required String clientRequestId,
  }) async {
    if (clientRequestId.trim().isEmpty) {
      return const _CreateRecovery(status: _CreateRecoveryStatus.unknown);
    }

    try {
      final status = await _inventoryRepository.fetchOfflineSyncStatus(
        accessToken: accessToken,
        clientRequestId: clientRequestId,
      );
      final decision = classifySafeCreateFailure(
        statusCode: status.retryable == true ? 409 : 400,
        message: status.errorMessage,
        errorCode: status.errorCode,
        retryable: status.retryable,
        recommendedAction: status.recommendedAction,
      );
      if (status.isCompleted) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.completed,
          result: status.result,
          operationCode: status.operationCode,
          recoveryState: status.recoveryState,
          recommendedAction: status.recommendedAction,
        );
      }
      if (status.isCancelled) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.cancelled,
          message:
              status.errorMessage ??
              'Bu kayit yetkili tarafindan iptal edildi. Mikro evraki olusturulmadi.',
          operationCode: status.operationCode,
          errorCode: status.errorCode ?? 'SAFE_WRITE_CANCELLED',
          retryable: false,
          recoveryState: status.recoveryState,
          recommendedAction: status.recommendedAction,
        );
      }
      if (status.isProcessing ||
          decision == SafeCreateFailureKind.waitAndCheck ||
          decision == SafeCreateFailureKind.uncertain) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.processing,
          message: safeCreateRetryErrorMessage(
            ApiException(
              statusCode: status.retryable == true ? 409 : 400,
              title: status.errorMessage ?? 'Mikro sonucu kontrol ediliyor.',
              errorCode: status.errorCode,
              retryable: status.retryable,
              retryAfterSeconds: status.retryAfterSeconds,
              recoveryState: status.recoveryState,
              recommendedAction: status.recommendedAction,
            ),
          ),
          operationCode: status.operationCode,
          errorCode: status.errorCode ?? 'MIKRO_WRITE_IN_PROGRESS',
          retryable: true,
          retryAfterSeconds: status.retryAfterSeconds,
          recoveryState: status.recoveryState,
          recommendedAction: status.recommendedAction,
        );
      }
      if (status.isFailed) {
        if (decision == SafeCreateFailureKind.retrySameRequest ||
            decision == SafeCreateFailureKind.queueBusy) {
          return _CreateRecovery(
            status: _CreateRecoveryStatus.retryable,
            message: _retryableRecoveryMessage(
              status.errorMessage,
              status.retryAfterSeconds,
            ),
            operationCode: status.operationCode,
            errorCode:
                status.errorCode ??
                (decision == SafeCreateFailureKind.retrySameRequest
                    ? 'SAFE_WRITE_RETRY_ALLOWED'
                    : null),
            retryable: true,
            retryAfterSeconds: status.retryAfterSeconds,
            recoveryState: status.recoveryState,
            recommendedAction: status.recommendedAction,
          );
        }
        return _CreateRecovery(
          status: _CreateRecoveryStatus.failed,
          message: status.errorMessage,
          operationCode: status.operationCode,
          errorCode: status.errorCode,
          retryable: false,
          retryAfterSeconds: status.retryAfterSeconds,
          recoveryState: status.recoveryState,
          recommendedAction: status.recommendedAction,
        );
      }
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.retryable,
          message:
              'Sunucuda bu istegin rezervasyonu bulunamadi. Saklanan ayni '
              'kayit guvenli sekilde yeniden gonderilecek.',
          errorCode: 'SAFE_WRITE_RETRY_ALLOWED',
          retryable: true,
          correlationId: error.correlationId,
          relatedClientRequestId: error.relatedClientRequestId,
        );
      }
      final decision = classifySafeCreateException(error);
      if (decision == SafeCreateFailureKind.retrySameRequest ||
          decision == SafeCreateFailureKind.queueBusy) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.retryable,
          message: _retryableRecoveryMessage(
            error.message,
            error.retryAfterSeconds,
          ),
          errorCode: error.errorCode,
          retryable: true,
          retryAfterSeconds: error.retryAfterSeconds,
          correlationId: error.correlationId,
          relatedClientRequestId: error.relatedClientRequestId,
        );
      }
      if (decision == SafeCreateFailureKind.waitAndCheck ||
          decision == SafeCreateFailureKind.processing ||
          decision == SafeCreateFailureKind.uncertain) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.processing,
          message: safeCreateRetryErrorMessage(error),
          errorCode: error.errorCode,
          retryable: error.retryable,
          retryAfterSeconds: error.retryAfterSeconds,
          correlationId: error.correlationId,
          relatedClientRequestId: error.relatedClientRequestId,
          recoveryState: error.recoveryState,
          recommendedAction: error.recommendedAction,
        );
      }
      return _CreateRecovery(
        status: _CreateRecoveryStatus.unknown,
        message: error.message,
        errorCode: error.errorCode,
        retryable: error.retryable,
        retryAfterSeconds: error.retryAfterSeconds,
        correlationId: error.correlationId,
        relatedClientRequestId: error.relatedClientRequestId,
      );
    }

    return const _CreateRecovery(status: _CreateRecoveryStatus.unknown);
  }

  Future<_CreateRecovery<CompanyAcceptanceCreateResult>>
  _recoverCompanyAcceptanceRequest({
    required String accessToken,
    required String clientRequestId,
    bool recheckExisting = false,
  }) async {
    if (clientRequestId.trim().isEmpty) {
      return const _CreateRecovery(status: _CreateRecoveryStatus.unknown);
    }

    try {
      final status = await _companyAcceptanceRepository.fetchOfflineSyncStatus(
        accessToken: accessToken,
        clientRequestId: clientRequestId,
      );
      var decision = classifySafeCreateFailure(
        statusCode: status.retryable == true ? 409 : 400,
        message: status.errorMessage,
        errorCode: status.errorCode,
        retryable: status.retryable,
        recommendedAction: status.recommendedAction,
      );
      if (recheckExisting &&
          decision == SafeCreateFailureKind.recheckExisting &&
          _companyAcceptanceRepository
              is OfflineSyncRecheckProvider<CompanyAcceptanceCreateResult>) {
        final provider =
            _companyAcceptanceRepository
                as OfflineSyncRecheckProvider<CompanyAcceptanceCreateResult>;
        final rechecked = await provider.recheckOfflineSyncStatus(
          accessToken: accessToken,
          clientRequestId: clientRequestId,
          operationCode: status.operationCode,
        );
        if (rechecked.isCompleted) {
          return _CreateRecovery(
            status: _CreateRecoveryStatus.completed,
            result: rechecked.result,
            operationCode: rechecked.operationCode,
            recoveryState: rechecked.recoveryState,
            recommendedAction: rechecked.recommendedAction,
          );
        }
        if (rechecked.isCancelled) {
          return _CreateRecovery(
            status: _CreateRecoveryStatus.cancelled,
            message: rechecked.errorMessage,
            operationCode: rechecked.operationCode,
            errorCode: rechecked.errorCode ?? 'SAFE_WRITE_CANCELLED',
            retryable: false,
            recoveryState: rechecked.recoveryState,
            recommendedAction: rechecked.recommendedAction,
          );
        }
        decision = classifyOfflineSyncStatus(rechecked);
        return _CreateRecovery(
          status: switch (decision) {
            SafeCreateFailureKind.waitAndCheck ||
            SafeCreateFailureKind.processing ||
            SafeCreateFailureKind.uncertain => _CreateRecoveryStatus.processing,
            SafeCreateFailureKind.retrySameRequest ||
            SafeCreateFailureKind.queueBusy => _CreateRecoveryStatus.retryable,
            _ => _CreateRecoveryStatus.failed,
          },
          message: safeCreateOfflineSyncErrorMessage(
            rechecked,
            fallback: 'Mikro kaydi yeniden kontrol edildi.',
          ),
          operationCode: rechecked.operationCode,
          errorCode: rechecked.errorCode,
          retryable: rechecked.retryable,
          retryAfterSeconds: rechecked.retryAfterSeconds,
          recoveryState: rechecked.recoveryState,
          recommendedAction: rechecked.recommendedAction,
        );
      }
      if (status.isCompleted) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.completed,
          result: status.result,
          operationCode: status.operationCode,
          recoveryState: status.recoveryState,
          recommendedAction: status.recommendedAction,
        );
      }
      if (status.isCancelled) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.cancelled,
          message:
              status.errorMessage ??
              'Bu kayit yetkili tarafindan iptal edildi. Mikro evraki olusturulmadi.',
          operationCode: status.operationCode,
          errorCode: status.errorCode ?? 'SAFE_WRITE_CANCELLED',
          retryable: false,
          recoveryState: status.recoveryState,
          recommendedAction: status.recommendedAction,
        );
      }
      if (status.isProcessing ||
          decision == SafeCreateFailureKind.waitAndCheck ||
          decision == SafeCreateFailureKind.uncertain) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.processing,
          message: safeCreateRetryErrorMessage(
            ApiException(
              statusCode: status.retryable == true ? 409 : 400,
              title: status.errorMessage ?? 'Mikro sonucu kontrol ediliyor.',
              errorCode: status.errorCode,
              retryable: status.retryable,
              retryAfterSeconds: status.retryAfterSeconds,
              recoveryState: status.recoveryState,
              recommendedAction: status.recommendedAction,
            ),
          ),
          operationCode: status.operationCode,
          errorCode: status.errorCode ?? 'MIKRO_WRITE_IN_PROGRESS',
          retryable: true,
          retryAfterSeconds: status.retryAfterSeconds,
          recoveryState: status.recoveryState,
          recommendedAction: status.recommendedAction,
        );
      }
      if (status.isFailed) {
        if (decision == SafeCreateFailureKind.retrySameRequest ||
            decision == SafeCreateFailureKind.queueBusy) {
          return _CreateRecovery(
            status: _CreateRecoveryStatus.retryable,
            message: _retryableRecoveryMessage(
              status.errorMessage,
              status.retryAfterSeconds,
            ),
            operationCode: status.operationCode,
            errorCode:
                status.errorCode ??
                (decision == SafeCreateFailureKind.retrySameRequest
                    ? 'SAFE_WRITE_RETRY_ALLOWED'
                    : null),
            retryable: true,
            retryAfterSeconds: status.retryAfterSeconds,
            recoveryState: status.recoveryState,
            recommendedAction: status.recommendedAction,
          );
        }
        return _CreateRecovery(
          status: _CreateRecoveryStatus.failed,
          message: status.errorMessage,
          operationCode: status.operationCode,
          errorCode: status.errorCode,
          retryable: false,
          retryAfterSeconds: status.retryAfterSeconds,
          recoveryState: status.recoveryState,
          recommendedAction: status.recommendedAction,
        );
      }
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.retryable,
          message:
              'Sunucuda bu istegin rezervasyonu bulunamadi. Saklanan ayni '
              'kayit guvenli sekilde yeniden gonderilecek.',
          errorCode: 'SAFE_WRITE_RETRY_ALLOWED',
          retryable: true,
          correlationId: error.correlationId,
          relatedClientRequestId: error.relatedClientRequestId,
        );
      }
      final decision = classifySafeCreateException(error);
      if (decision == SafeCreateFailureKind.retrySameRequest ||
          decision == SafeCreateFailureKind.queueBusy) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.retryable,
          message: _retryableRecoveryMessage(
            error.message,
            error.retryAfterSeconds,
          ),
          errorCode: error.errorCode,
          retryable: true,
          retryAfterSeconds: error.retryAfterSeconds,
          correlationId: error.correlationId,
          relatedClientRequestId: error.relatedClientRequestId,
        );
      }
      if (decision == SafeCreateFailureKind.waitAndCheck ||
          decision == SafeCreateFailureKind.processing ||
          decision == SafeCreateFailureKind.uncertain) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.processing,
          message: safeCreateRetryErrorMessage(error),
          errorCode: error.errorCode,
          retryable: error.retryable,
          retryAfterSeconds: error.retryAfterSeconds,
          correlationId: error.correlationId,
          relatedClientRequestId: error.relatedClientRequestId,
          recoveryState: error.recoveryState,
          recommendedAction: error.recommendedAction,
        );
      }
      return _CreateRecovery(
        status: _CreateRecoveryStatus.unknown,
        message: error.message,
        errorCode: error.errorCode,
        retryable: error.retryable,
        retryAfterSeconds: error.retryAfterSeconds,
        correlationId: error.correlationId,
        relatedClientRequestId: error.relatedClientRequestId,
      );
    }

    return const _CreateRecovery(status: _CreateRecoveryStatus.unknown);
  }
}

String _retryableRecoveryMessage(String? message, int? retryAfterSeconds) {
  final normalized = message?.trim() ?? '';
  final displayMessage = _isLegacyCancellationMessage(normalized)
      ? 'Kayit sonucu henuz kesinlesmedi.'
      : normalized;
  final wait = retryAfterSeconds != null && retryAfterSeconds > 0
      ? ' $retryAfterSeconds saniye sonra ayni kayitla tekrar deneyin.'
      : ' Ayni kayitla daha sonra tekrar deneyin.';
  return '${displayMessage.isEmpty ? 'Kayit sonucu henuz kesinlesmedi.' : displayMessage}$wait';
}

bool _isLegacyCancellationMessage(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('task was canceled') ||
      normalized.contains('task was cancelled') ||
      normalized.contains('operation was canceled') ||
      normalized.contains('operation was cancelled') ||
      normalized.contains('request was canceled') ||
      normalized.contains('request was cancelled');
}

enum _CreateRecoveryStatus {
  completed,
  cancelled,
  processing,
  retryable,
  failed,
  statusNotFound,
  unknown,
}

class _CreateRecovery<T> {
  const _CreateRecovery({
    required this.status,
    this.result,
    this.message,
    this.operationCode,
    this.errorCode,
    this.retryable,
    this.retryAfterSeconds,
    this.correlationId,
    this.relatedClientRequestId,
    this.recoveryState,
    this.recommendedAction,
  });

  final _CreateRecoveryStatus status;
  final T? result;
  final String? message;
  final String? operationCode;
  final String? errorCode;
  final bool? retryable;
  final int? retryAfterSeconds;
  final String? correlationId;
  final String? relatedClientRequestId;
  final String? recoveryState;
  final String? recommendedAction;
}
