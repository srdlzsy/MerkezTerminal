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
  payloadChanged,
  multipleDocuments,
  manualReview,
}

SafeCreateFailureKind classifySafeCreateFailure({
  required int? statusCode,
  String? message,
  String? errorCode,
  bool? retryable,
}) {
  switch ((errorCode ?? '').trim().toUpperCase()) {
    case 'MIKRO_WRITE_IN_PROGRESS':
      return SafeCreateFailureKind.processing;
    case 'MIKRO_WRITE_QUEUE_BUSY':
      return SafeCreateFailureKind.queueBusy;
    case 'MIKRO_WRITE_OUTCOME_UNCONFIRMED':
      return SafeCreateFailureKind.uncertain;
    case 'MIKRO_DOCUMENT_CONTENT_MISMATCH':
      return SafeCreateFailureKind.manualReview;
    case 'CLIENT_REQUEST_PAYLOAD_MISMATCH':
      return SafeCreateFailureKind.payloadChanged;
  }

  final normalized = (message ?? '').trim().toLowerCase();
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
  return classifySafeCreateFailure(
    statusCode: error.statusCode,
    message: error.message,
    errorCode: error.errorCode,
    retryable: error.retryable,
  );
}

bool hasSafeCreateDecisionMetadata(ApiException error) {
  return error.retryable != null ||
      (error.errorCode?.trim().isNotEmpty ?? false);
}

bool canRetrySafeCreate(SafeCreateFailureKind kind) {
  return kind == SafeCreateFailureKind.uncertain ||
      kind == SafeCreateFailureKind.processing ||
      kind == SafeCreateFailureKind.queueBusy;
}

SafeCreateFailureKind classifyOfflineSyncStatus<T>(
  OfflineSyncStatus<T> status,
) {
  if (status.isProcessing) {
    return SafeCreateFailureKind.processing;
  }
  if (status.isCompleted && status.result == null) {
    return SafeCreateFailureKind.uncertain;
  }
  return classifySafeCreateFailure(
    statusCode: status.retryable == true ? 409 : 400,
    message: status.errorMessage,
    errorCode: status.errorCode,
    retryable: status.retryable,
  );
}

String safeCreateOfflineSyncErrorMessage<T>(
  OfflineSyncStatus<T> status, {
  required String fallback,
}) {
  final normalizedMessage = status.errorMessage?.trim() ?? '';
  return safeCreateRetryErrorMessage(
    ApiException(
      statusCode: status.retryable == true ? 409 : 400,
      title: normalizedMessage.isEmpty ? fallback : normalizedMessage,
      errorCode: status.errorCode,
      retryable: status.retryable,
      retryAfterSeconds: status.retryAfterSeconds,
    ),
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
  return kind != SafeCreateFailureKind.notRetryable;
}

bool canStartNewSafeCreate(SafeCreateFailureKind kind) {
  return kind == SafeCreateFailureKind.payloadChanged ||
      kind == SafeCreateFailureKind.manualReview ||
      kind == SafeCreateFailureKind.multipleDocuments;
}

String safeCreatePendingActionLabel(SafeCreateFailureKind kind) {
  return switch (kind) {
    SafeCreateFailureKind.manualReview ||
    SafeCreateFailureKind.multipleDocuments ||
    SafeCreateFailureKind.payloadChanged => 'Yeni Bagimsiz Islem',
    SafeCreateFailureKind.notRetryable => 'Islem Kullanilamaz',
    _ => 'Kaydi Tekrar Dene',
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
    ),
  );
}

String safeCreateRetryErrorMessage(ApiException error) {
  final kind = classifySafeCreateException(error);
  final message = switch (kind) {
    SafeCreateFailureKind.queueBusy =>
      'Ayni belge serisindeki onceki islem halen devam ediyor. Bu kaydin '
          'Mikro yazimi baslamadi. Kisa bir sure sonra ayni kayitla Tekrar '
          'Dene kullanin; yeni bir islem baslatmayin.',
    SafeCreateFailureKind.processing =>
      'Kayit Mikro tarafinda halen isleniyor. Ayni kaydi yeni bir '
          'islem olarak gondermeyin; kisa bir sure sonra Tekrar Dene kullanin.',
    SafeCreateFailureKind.payloadChanged =>
      'Bu kayit denemesinin icerigi degismis. Devam etmek icin acikca '
          'Yeni Islem olarak kaydedin.',
    SafeCreateFailureKind.multipleDocuments =>
      'Ayni kayit iziyle birden fazla Mikro evraki bulundu. Tekrar '
              'kaydetmeyin ve e-irsaliye gondermeyin. ${error.detail ?? ''}'
          .trim(),
    SafeCreateFailureKind.manualReview =>
      'Mikro evrak icerigi bu kayitla eslesmiyor. Tekrar kaydetmeyin; '
              'yetkili incelemesi gerekli. ${error.detail ?? ''}'
          .trim(),
    SafeCreateFailureKind.uncertain =>
      error.statusCode == 409 ? safeCreateRetryConflictMessage : error.message,
    SafeCreateFailureKind.notRetryable => error.message,
  };
  return error.messageWithSupportCode(message);
}
