import 'package:furpa_merkez_terminal/core/network/api_exception.dart';

const String safeCreateRetryConflictMessage =
    'Bu kayit denemesinin sonucu belirsiz. Ayni bilgilerle Tekrar Dene, '
    'icerigi degistirecekseniz yeni islem olarak tekrar kaydedin.';

bool shouldOfferSafeCreateRetry(int? statusCode) {
  return statusCode == 0 || statusCode == 409;
}

String safeCreateRetryErrorMessage(ApiException error) {
  if (error.statusCode == 409) {
    return safeCreateRetryConflictMessage;
  }

  return error.message;
}
