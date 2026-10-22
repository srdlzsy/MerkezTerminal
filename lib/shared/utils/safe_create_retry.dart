import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_status.dart';

const String safeCreateRetryConflictMessage =
    'Bu kayit denemesinin sonucu belirsiz. Ayni bilgilerle Tekrar Dene, '
    'icerigi degistirecekseniz yeni islem olarak tekrar kaydedin.';

enum SafeCreateFailureKind {
  notRetryable,
  uncertain,
  processing,
  queueBusy,
  documentIdentityConflict,
  officialDocumentAlreadyReceived,
  payloadChanged,
  multipleDocuments,
  manualReview,
  waitAndCheck,
  retrySameRequest,
  recheckExisting,
  statusNotFound,
  cancelled,
}

SafeCreateFailureKind classifySafeCreateFailure({
  required int? statusCode,
  String? message,
  String? errorCode,
  bool? retryable,
  String? recommendedAction,
}) {
  switch ((recommendedAction ?? '').trim().toLowerCase()) {
    case 'completed':
      return SafeCreateFailureKind.uncertain;
    case 'waitandcheck':
      return SafeCreateFailureKind.waitAndCheck;
    case 'retrysamerequest':
      return SafeCreateFailureKind.retrySameRequest;
    case 'editandretry':
      return SafeCreateFailureKind.documentIdentityConflict;
    case 'refreshlist':
      return SafeCreateFailureKind.officialDocumentAlreadyReceived;
    case 'recheckexisting':
      return SafeCreateFailureKind.recheckExisting;
    case 'restoreoriginalrequest':
      return SafeCreateFailureKind.payloadChanged;
    case 'needsreview':
      return SafeCreateFailureKind.manualReview;
    case 'clearcancelled':
      return SafeCreateFailureKind.cancelled;
  }

  switch ((errorCode ?? '').trim().toUpperCase()) {
    case 'MIKRO_WRITE_IN_PROGRESS':
      return SafeCreateFailureKind.processing;
    case 'MIKRO_WRITE_QUEUE_BUSY':
      return SafeCreateFailureKind.queueBusy;
    case 'MIKRO_WRITE_OUTCOME_UNCONFIRMED':
      return SafeCreateFailureKind.uncertain;
    case 'MIKRO_DOCUMENT_INCOMPLETE':
      return SafeCreateFailureKind.waitAndCheck;
    case 'SAFE_WRITE_RETRY_ALLOWED':
      return SafeCreateFailureKind.retrySameRequest;
    case 'SAFE_WRITE_RETRY_EXHAUSTED':
    case 'SAFE_WRITE_RETRY_DEFERRED':
      return SafeCreateFailureKind.retrySameRequest;
    case 'MIKRO_DOCUMENT_CONTENT_MISMATCH':
      return SafeCreateFailureKind.manualReview;
    case 'MIKRO_DOCUMENT_IDENTITY_CONFLICT':
      return SafeCreateFailureKind.documentIdentityConflict;
    case 'MIKRO_OFFICIAL_DOCUMENT_ALREADY_RECEIVED':
      return SafeCreateFailureKind.officialDocumentAlreadyReceived;
    case 'CLIENT_REQUEST_PAYLOAD_MISMATCH':
      return SafeCreateFailureKind.payloadChanged;
    case 'SAFE_WRITE_CANCELLED':
      return SafeCreateFailureKind.cancelled;
  }

  final normalized = (message ?? '').trim().toLowerCase();
  if (statusCode == 404) {
    return SafeCreateFailureKind.retrySameRequest;
  }
  if (statusCode == 409) {
    if (normalized.contains('multiple mikro documents') ||
        normalized.contains('birden fazla mikro')) {
      return SafeCreateFailureKind.multipleDocuments;
    }
    if (normalized.contains('manual review') ||
        normalized.contains('manuel inceleme') ||
        normalized.contains('yetkili incelemesi') ||
        normalized.contains('does not match the requested document content')) {
      return SafeCreateFailureKind.manualReview;
    }
    if (normalized.contains('different request payload') ||
        normalized.contains('farkli payload') ||
        normalized.contains('farklı payload') ||
        normalized.contains('icerigi degismis') ||
        normalized.contains('içeriği değişmiş')) {
      return SafeCreateFailureKind.payloadChanged;
    }

    // Kodsuz eski/genel 409 cevaplari otomatik retry edilmez.
    return retryable == true
        ? SafeCreateFailureKind.uncertain
        : SafeCreateFailureKind.notRetryable;
  }
  if (statusCode == 0 || (statusCode != null && statusCode >= 500)) {
    return SafeCreateFailureKind.uncertain;
  }
  return SafeCreateFailureKind.notRetryable;
}

SafeCreateFailureKind classifySafeCreateException(ApiException error) {
  // HTTP 400 is a definitive request/form error. It must never inherit
  // safe-write metadata and enter a status-check or retry loop.
  if (error.statusCode == 400) {
    return SafeCreateFailureKind.notRetryable;
  }
  return classifySafeCreateFailure(
    statusCode: error.statusCode,
    message: error.message,
    errorCode: error.errorCode,
    retryable: error.retryable,
    recommendedAction: error.recommendedAction,
  );
}

bool hasSafeCreateDecisionMetadata(ApiException error) {
  return error.statusCode == 404 ||
      error.retryable != null ||
      (error.errorCode?.trim().isNotEmpty ?? false) ||
      (error.recommendedAction?.trim().isNotEmpty ?? false);
}

bool canRetrySafeCreate(SafeCreateFailureKind kind) {
  return false;
}

bool shouldCheckSafeCreateStatus(SafeCreateFailureKind kind) {
  // ApiClient resolves safe-create status during the foreground request.
  // Remaining technical records are reconciled once when their page opens;
  // users must not be given a manual check loop.
  return false;
}

bool shouldRecheckSafeCreate(SafeCreateFailureKind kind) {
  // Recheck is an internal recovery detail. Terminal users must not be put in
  // a repeating validate/check loop for a create they already submitted.
  return false;
}

Future<OfflineSyncStatus<T>> resolveSafeCreateStatus<T>({
  required OfflineSyncStatusProvider<T> statusProvider,
  required String accessToken,
  required String clientRequestId,
  required SafeCreateFailureKind currentKind,
  OfflineSyncRecheckProvider<T>? recheckProvider,
}) async {
  final status = await statusProvider.fetchOfflineSyncStatus(
    accessToken: accessToken,
    clientRequestId: clientRequestId,
  );
  if (!shouldRecheckSafeCreate(currentKind) ||
      recheckProvider == null ||
      status.recommendedAction?.trim() != 'RecheckExisting' ||
      status.operationCode.trim().isEmpty) {
    return status;
  }
  return recheckProvider.recheckOfflineSyncStatus(
    accessToken: accessToken,
    clientRequestId: clientRequestId,
    operationCode: status.operationCode,
  );
}

SafeCreateFailureKind classifyOfflineSyncStatus<T>(
  OfflineSyncStatus<T> status,
) {
  if (status.isProcessing) {
    return SafeCreateFailureKind.processing;
  }
  if (status.isCancelled) {
    return SafeCreateFailureKind.cancelled;
  }
  if (status.isCompleted && status.result == null) {
    return SafeCreateFailureKind.uncertain;
  }
  return classifySafeCreateFailure(
    statusCode: status.retryable == true ? 409 : 400,
    message: status.errorMessage,
    errorCode: status.errorCode,
    retryable: status.retryable,
    recommendedAction: status.recommendedAction,
  );
}

String safeCreateOfflineSyncErrorMessage<T>(
  OfflineSyncStatus<T> status, {
  required String fallback,
}) {
  if (status.isCancelled) {
    return status.errorMessage?.trim().isNotEmpty == true
        ? status.errorMessage!.trim()
        : 'Bu kayit yetkili tarafindan iptal edildi. Mikro evraki olusturulmadi.';
  }
  final normalizedMessage = status.errorMessage?.trim() ?? '';
  final error = ApiException(
    statusCode: status.retryable == true ? 409 : 400,
    title: normalizedMessage.isEmpty ? fallback : normalizedMessage,
    errorCode: status.errorCode,
    retryable: status.retryable,
    retryAfterSeconds: status.retryAfterSeconds,
    recoveryState: status.recoveryState,
    recommendedAction: status.recommendedAction,
  );
  return _safeCreateRetryErrorMessageForKind(
    error,
    classifyOfflineSyncStatus(status),
  );
}

Duration safeCreateRetryWait(DateTime? retryNotBefore, {DateTime? now}) {
  if (retryNotBefore == null) return Duration.zero;
  final wait = retryNotBefore.difference(now ?? DateTime.now());
  return wait.isNegative ? Duration.zero : wait;
}

DateTime? safeCreateRetryNotBefore({
  required bool? retryable,
  required int? retryAfterSeconds,
  DateTime? now,
}) {
  if (retryable != true ||
      retryAfterSeconds == null ||
      retryAfterSeconds <= 0) {
    return null;
  }
  return (now ?? DateTime.now()).add(Duration(seconds: retryAfterSeconds));
}

String safeCreateRetryWaitMessage(Duration wait) {
  final seconds = wait.inSeconds + (wait.inMilliseconds % 1000 == 0 ? 0 : 1);
  return 'Sunucu bu kayit icin bekleme suresi bildirdi. '
      '$seconds saniye sonra tekrar deneyin.';
}

bool shouldKeepSafeCreatePending(SafeCreateFailureKind kind) {
  return kind == SafeCreateFailureKind.uncertain ||
      kind == SafeCreateFailureKind.processing ||
      kind == SafeCreateFailureKind.waitAndCheck;
}

bool canStartNewSafeCreate(SafeCreateFailureKind kind) {
  return kind == SafeCreateFailureKind.payloadChanged;
}

String safeCreatePendingActionLabel(SafeCreateFailureKind kind) {
  return switch (kind) {
    SafeCreateFailureKind.payloadChanged => 'Yeni Bagimsiz Islem',
    SafeCreateFailureKind.documentIdentityConflict => 'Seri / Sirayi Duzelt',
    SafeCreateFailureKind.officialDocumentAlreadyReceived => 'Listeyi Yenile',
    SafeCreateFailureKind.recheckExisting => 'Taslakta Korundu',
    SafeCreateFailureKind.manualReview ||
    SafeCreateFailureKind.multipleDocuments ||
    SafeCreateFailureKind.statusNotFound => 'Destek gerekli',
    SafeCreateFailureKind.notRetryable => 'Islem Kullanilamaz',
    SafeCreateFailureKind.cancelled => 'Yetkili Tarafindan Iptal Edildi',
    SafeCreateFailureKind.waitAndCheck ||
    SafeCreateFailureKind.processing ||
    SafeCreateFailureKind.uncertain => 'Sonuc Otomatik Kontrol Edilecek',
    SafeCreateFailureKind.retrySameRequest ||
    SafeCreateFailureKind.queueBusy => 'Taslakta Bekliyor',
  };
}

bool shouldOfferSafeCreateRetry(
  int? statusCode, {
  String? message,
  String? errorCode,
  bool? retryable,
}) {
  return canRetrySafeCreate(
    classifySafeCreateFailure(
      statusCode: statusCode,
      message: message,
      errorCode: errorCode,
      retryable: retryable,
      recommendedAction: null,
    ),
  );
}

String safeCreateRetryErrorMessage(ApiException error) {
  return _safeCreateRetryErrorMessageForKind(
    error,
    classifySafeCreateException(error),
  );
}

String _safeCreateRetryErrorMessageForKind(
  ApiException error,
  SafeCreateFailureKind kind,
) {
  final message = switch (kind) {
    SafeCreateFailureKind.queueBusy =>
      'Kayit Mikro yazma sirasina giremedi. Bilgiler cihaz taslaginda '
          'korundu; bu ekrandan otomatik tekrar gonderilmeyecek.',
    SafeCreateFailureKind.processing =>
      'Kayit Mikro tarafinda halen isleniyor. Sonuc uygulama tarafindan '
          'otomatik kontrol edilecek; girdiginiz bilgiler korunuyor.',
    SafeCreateFailureKind.payloadChanged =>
      'Bu kayit denemesinin icerigi degismis. Devam etmek icin acikca '
          'Yeni Islem olarak kaydedin.',
    SafeCreateFailureKind.documentIdentityConflict =>
      'Bu seri ve sira numarasi Mikro\'da zaten kullaniliyor. Yeni evrak '
          'yazimi baslamadi ve kayit Offline listesine alinmadi. Seri veya '
          'sira numarasini degistirip yeniden kaydedin.',
    SafeCreateFailureKind.officialDocumentAlreadyReceived =>
      'Bu cari ve resmi belge numarasiyla mal kabul zaten kaydedilmis. '
          'Ikinci evrak olusturulmadi ve kayit Offline listesine alinmadi. '
          'Listeyi yenileyip mevcut evraki kontrol edin.',
    SafeCreateFailureKind.multipleDocuments =>
      'Ayni kayit iziyle birden fazla Mikro evraki bulundu. Tekrar '
              'kaydetmeyin ve e-irsaliye gondermeyin. ${error.detail ?? ''}'
          .trim(),
    SafeCreateFailureKind.manualReview =>
      'Mikro bu istek kimligiyle bir evrak buldu ancak temel belge bilgileri '
              'eslesmedi. Evrak yeniden gonderilmedi; girdiginiz bilgiler '
              'cihaz taslaginda korundu. ${error.detail ?? ''}'
          .trim(),
    SafeCreateFailureKind.recheckExisting =>
      'Mikro kaydi bu evrakla tam eslesmedi. Evrak yeniden gonderilmedi; '
          'girdiginiz bilgiler cihaz taslaginda korundu.',
    SafeCreateFailureKind.waitAndCheck =>
      'Kayit sonucu henuz kesinlesmedi. Girdiginiz bilgiler korunuyor ve '
          'sonuc uygulama tarafindan otomatik kontrol edilecek.',
    SafeCreateFailureKind.retrySameRequest =>
      'Mikro tarafinda bu istege ait belge bulunmadigi dogrulandi. Saklanan '
          'bilgiler cihaz taslaginda korundu; otomatik tekrar gonderilmedi.',
    SafeCreateFailureKind.statusNotFound =>
      'Bu guvenli kaydin sunucu durum izi bulunamadi. Yeni kimlik uretmeyin; '
          'destek birimine bildirin.',
    SafeCreateFailureKind.uncertain =>
      error.statusCode == 409 || _isLegacyCancellationMessage(error.message)
          ? safeCreateRetryConflictMessage
          : error.message,
    SafeCreateFailureKind.notRetryable => error.message,
    SafeCreateFailureKind.cancelled =>
      'Bu kayit yetkili tarafindan iptal edildi. Mikro evraki olusturulmadi.',
  };
  return error.messageWithSupportCode(message);
}

bool _isLegacyCancellationMessage(String message) {
  final normalized = message.trim().toLowerCase();
  return normalized.contains('task was canceled') ||
      normalized.contains('task was cancelled') ||
      normalized.contains('operation was canceled') ||
      normalized.contains('operation was cancelled') ||
      normalized.contains('request was canceled') ||
      normalized.contains('request was cancelled');
}
