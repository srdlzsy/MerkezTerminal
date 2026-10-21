import 'package:flutter/foundation.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/pending_create/pending_create_repository.dart';

Future<void> completeLocalCreateState({
  required PendingCreateRepository pendingRepository,
  required String moduleKey,
  required String userId,
  required String warehouseNo,
  required String clientRequestId,
  CreateDraftRepository? draftRepository,
  String? draftId,
}) async {
  await _retryCleanup(
    () => pendingRepository.complete(
      moduleKey: moduleKey,
      userId: userId,
      warehouseNo: warehouseNo,
      clientRequestId: clientRequestId,
    ),
    label: 'pending create completion',
  );

  final normalizedDraftId = draftId?.trim() ?? '';
  if (draftRepository != null && normalizedDraftId.isNotEmpty) {
    await deleteCompletedDraftBestEffort(
      draftRepository: draftRepository,
      draftId: normalizedDraftId,
    );
  }
}

Future<void> deleteCompletedDraftBestEffort({
  required CreateDraftRepository draftRepository,
  required String draftId,
}) {
  return _retryCleanup(
    () => draftRepository.deleteDraft(draftId),
    label: 'completed create draft cleanup',
  );
}

Future<void> _retryCleanup(
  Future<void> Function() action, {
  required String label,
}) async {
  Object? lastError;
  StackTrace? lastStackTrace;
  for (var attempt = 0; attempt < 3; attempt += 1) {
    try {
      await action();
      return;
    } on Object catch (error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 50 * (attempt + 1)));
      }
    }
  }
  debugPrint('$label failed after create succeeded: $lastError');
  if (lastStackTrace != null) {
    debugPrintStack(stackTrace: lastStackTrace);
  }
}
