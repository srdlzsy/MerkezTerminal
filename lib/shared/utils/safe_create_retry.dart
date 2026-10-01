import 'package:furpa_merkez_terminal/core/network/api_exception.dart';

const String safeCreateRetryConflictMessage =
    'Bu kayit denemesinin sonucu belirsiz. Ayni bilgilerle Tekrar Dene, '
    'icerigi degistirecekseniz yeni islem olarak tekrar kaydedin.';

enum SafeCreateFailureKind {
  notRetryable,
  uncertain,
  processing,
  payloadChanged,
  multipleDocuments,
}

SafeCreateFailureKind classifySafeCreateFailure({
  required int? statusCode,
  String? message,
}) {
  final normalized = (message ?? '').trim().toLowerCase();
  if (statusCode == 409) {
    if (normalized.contains('multiple mikro documents') ||
        normalized.contains('birden fazla mikro')) {
      return SafeCreateFailureKind.multipleDocuments;
    }
    if (normalized.contains('different request payload') ||
        normalized.contains('farkli payload') ||
        normalized.contains('farklı payload') ||
        normalized.contains('icerigi degismis') ||
        normalized.contains('içeriği değişmiş')) {
      return SafeCreateFailureKind.payloadChanged;
    }
    if (normalized.contains('already being processed') ||
        normalized.contains('halen isleniyor') ||
        normalized.contains('halen işleniyor')) {
      return SafeCreateFailureKind.processing;
    }
    return SafeCreateFailureKind.uncertain;
  }
  if (statusCode == 0 || (statusCode != null && statusCode >= 500)) {
    return SafeCreateFailureKind.uncertain;
  }
  return SafeCreateFailureKind.notRetryable;
}

bool shouldOfferSafeCreateRetry(int? statusCode, {String? message}) {
  final kind = classifySafeCreateFailure(
    statusCode: statusCode,
    message: message,
  );
  return kind == SafeCreateFailureKind.uncertain ||
      kind == SafeCreateFailureKind.processing;
}

String safeCreateRetryErrorMessage(ApiException error) {
  final kind = classifySafeCreateFailure(
    statusCode: error.statusCode,
    message: error.message,
  );
  switch (kind) {
    case SafeCreateFailureKind.processing:
      return 'Kayit Mikro tarafinda halen isleniyor. Ayni kaydi yeni bir '
          'islem olarak gondermeyin; kisa bir sure sonra Tekrar Dene kullanin.';
    case SafeCreateFailureKind.payloadChanged:
      return 'Bu kayit denemesinin icerigi degismis. Devam etmek icin yeni '
          'islem olarak tekrar kaydedin.';
    case SafeCreateFailureKind.multipleDocuments:
      return 'Ayni kayit iziyle birden fazla Mikro evraki bulundu. Tekrar '
              'kaydetmeyin ve e-irsaliye gondermeyin. ${error.detail ?? ''}'
          .trim();
    case SafeCreateFailureKind.uncertain:
      return error.statusCode == 409
          ? safeCreateRetryConflictMessage
          : error.message;
    case SafeCreateFailureKind.notRetryable:
      return error.message;
  }
}
