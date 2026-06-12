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

enum OfflineSubmissionStatus { synced, recovered, queued }

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
        final recovered = await _recoverInventoryRequest(
          accessToken: accessToken,
          clientRequestId: request.clientRequestId ?? '',
        );
        if (recovered != null) {
          return InventoryCountSubmissionResult(
            status: OfflineSubmissionStatus.recovered,
            onlineResult: recovered,
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
        final recovered = await _recoverCompanyAcceptanceRequest(
          accessToken: accessToken,
          clientRequestId: request.clientRequestId ?? '',
        );
        if (recovered != null) {
          return CompanyAcceptanceSubmissionResult(
            status: OfflineSubmissionStatus.recovered,
            onlineResult: recovered,
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
      final recovered = await _recoverInventoryRequest(
        accessToken: accessToken,
        clientRequestId: syncingDraft.clientRequestId,
      );
      if (recovered != null) {
        await _offlineInventoryRepository.deleteDraft(syncingDraft.id);
        return const OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.synced,
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
      final recovered = await _recoverCompanyAcceptanceRequest(
        accessToken: accessToken,
        clientRequestId: syncingDraft.clientRequestId,
      );
      if (recovered != null) {
        await _offlineCompanyAcceptanceRepository.deleteDraft(syncingDraft.id);
        return const OfflineDraftSyncResult(
          status: OfflineDraftSyncResultStatus.synced,
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
        if (result.status == OfflineDraftSyncResultStatus.deferred) {
          return;
        }
      }

      final companyAcceptanceDrafts = await _offlineCompanyAcceptanceRepository
          .fetchDrafts(userId: userId, warehouseNo: warehouseNo);

      for (final draft in companyAcceptanceDrafts) {
        final result = await syncCompanyAcceptanceDraft(
          accessToken: accessToken,
          draft: draft,
        );
        if (result.status == OfflineDraftSyncResultStatus.deferred) {
          return;
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

  Future<InventoryCountCreateResult?> _recoverInventoryRequest({
    required String accessToken,
    required String clientRequestId,
  }) async {
    if (clientRequestId.trim().isEmpty) {
      return null;
    }

    try {
      final status = await _inventoryRepository.fetchOfflineSyncStatus(
        accessToken: accessToken,
        clientRequestId: clientRequestId,
      );
      if (status.isCompleted) {
        return status.result;
      }
    } on ApiException {
      return null;
    }

    return null;
  }

  Future<CompanyAcceptanceCreateResult?> _recoverCompanyAcceptanceRequest({
    required String accessToken,
    required String clientRequestId,
  }) async {
    if (clientRequestId.trim().isEmpty) {
      return null;
    }

    try {
      final status = await _companyAcceptanceRepository.fetchOfflineSyncStatus(
        accessToken: accessToken,
        clientRequestId: clientRequestId,
      );
      if (status.isCompleted) {
        return status.result;
      }
    } on ApiException {
      return null;
    }

    return null;
  }
}
