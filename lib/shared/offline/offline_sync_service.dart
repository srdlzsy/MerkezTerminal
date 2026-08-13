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

enum OfflineSubmissionStatus { synced, recovered, queued, processing }

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

enum OfflineDraftSyncResultStatus { synced, processing, failed, deferred }

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
          lastError: error.message,
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
    try {
      final result = await _companyAcceptanceRepository.createAcceptance(
        accessToken: accessToken,
        request: request,
      );
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
          return CompanyAcceptanceSubmissionResult(
            status: OfflineSubmissionStatus.recovered,
            onlineResult: recovery.result,
          );
        }
        if (recovery.status == _CreateRecoveryStatus.processing) {
          await _offlineCompanyAcceptanceRepository.saveDraft(
            OfflineCompanyAcceptanceDraft.fromCreateRequest(
              request,
              userId: userId,
              warehouseNo: warehouseNo,
              customerDisplayName: customerDisplayName ?? '',
              createdAt: createdAt ?? DateTime.now(),
              status: OfflineRecordStatus.syncing,
              lastSyncAttemptAt: DateTime.now(),
              lastError: recovery.message ?? 'Kayit sunucuda isleniyor.',
            ),
          );
          return const CompanyAcceptanceSubmissionResult(
            status: OfflineSubmissionStatus.processing,
          );
        }
      }

      if (!_shouldQueueAfterCreate(error)) {
        rethrow;
      }

      await _offlineCompanyAcceptanceRepository.saveDraft(
        OfflineCompanyAcceptanceDraft.fromCreateRequest(
          request,
          userId: userId,
          warehouseNo: warehouseNo,
          customerDisplayName: customerDisplayName ?? '',
          createdAt: createdAt ?? DateTime.now(),
          status: OfflineRecordStatus.pending,
          lastSyncAttemptAt: DateTime.now(),
          lastError: error.message,
        ),
      );
      return const CompanyAcceptanceSubmissionResult(
        status: OfflineSubmissionStatus.queued,
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
  }) async {
    final syncingDraft = draft.copyWith(
      status: OfflineRecordStatus.syncing,
      lastSyncAttemptAt: DateTime.now(),
      lastError: null,
    );
    await _offlineCompanyAcceptanceRepository.saveDraft(syncingDraft);

    try {
      await _companyAcceptanceRepository.createAcceptance(
        accessToken: accessToken,
        request: syncingDraft.toCreateRequest(),
      );
      await _offlineCompanyAcceptanceRepository.deleteDraft(syncingDraft.id);
      return const OfflineDraftSyncResult(
        status: OfflineDraftSyncResultStatus.synced,
      );
    } on ApiException catch (error) {
      final recovery = await _recoverCompanyAcceptanceRequest(
        accessToken: accessToken,
        clientRequestId: syncingDraft.clientRequestId,
      );
      if (recovery.status == _CreateRecoveryStatus.completed) {
        await _offlineCompanyAcceptanceRepository.deleteDraft(syncingDraft.id);
        return const OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.synced,
        );
      }
      if (recovery.status == _CreateRecoveryStatus.processing) {
        await _offlineCompanyAcceptanceRepository.saveDraft(
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
      if (recovery.status == _CreateRecoveryStatus.failed) {
        await _offlineCompanyAcceptanceRepository.saveDraft(
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
        await _offlineCompanyAcceptanceRepository.saveDraft(
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

      await _offlineCompanyAcceptanceRepository.saveDraft(
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
        final result = await syncCompanyAcceptanceDraft(
          accessToken: accessToken,
          draft: draft,
        );
        if (result.status == OfflineDraftSyncResultStatus.deferred ||
            result.status == OfflineDraftSyncResultStatus.processing) {
          break;
        }
      }
    } finally {
      _isSyncRunning = false;
    }
  }

  bool _shouldQueueAfterCreate(ApiException error) {
    return _isConnectionFailure(error);
  }

  bool _shouldTryCreateRecovery(ApiException error) {
    return error.statusCode == 409 || error.statusCode == 0;
  }

  bool _shouldDeferSync(ApiException error) {
    return _isConnectionFailure(error) || error.statusCode == 401;
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
      if (status.isCompleted) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.completed,
          result: status.result,
        );
      }
      if (status.isProcessing) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.processing,
          message: status.errorMessage,
        );
      }
      if (status.isFailed) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.failed,
          message: status.errorMessage,
        );
      }
    } on ApiException {
      return const _CreateRecovery(status: _CreateRecoveryStatus.unknown);
    }

    return const _CreateRecovery(status: _CreateRecoveryStatus.unknown);
  }

  Future<_CreateRecovery<CompanyAcceptanceCreateResult>>
  _recoverCompanyAcceptanceRequest({
    required String accessToken,
    required String clientRequestId,
  }) async {
    if (clientRequestId.trim().isEmpty) {
      return const _CreateRecovery(status: _CreateRecoveryStatus.unknown);
    }

    try {
      final status = await _companyAcceptanceRepository.fetchOfflineSyncStatus(
        accessToken: accessToken,
        clientRequestId: clientRequestId,
      );
      if (status.isCompleted) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.completed,
          result: status.result,
        );
      }
      if (status.isProcessing) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.processing,
          message: status.errorMessage,
        );
      }
      if (status.isFailed) {
        return _CreateRecovery(
          status: _CreateRecoveryStatus.failed,
          message: status.errorMessage,
        );
      }
    } on ApiException {
      return const _CreateRecovery(status: _CreateRecoveryStatus.unknown);
    }

    return const _CreateRecovery(status: _CreateRecoveryStatus.unknown);
  }
}

enum _CreateRecoveryStatus { completed, processing, failed, unknown }

class _CreateRecovery<T> {
  const _CreateRecovery({required this.status, this.result, this.message});

  final _CreateRecoveryStatus status;
  final T? result;
  final String? message;
}
