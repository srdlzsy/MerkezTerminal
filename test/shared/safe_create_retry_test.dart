import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/shared/utils/safe_create_retry.dart';

void main() {
  test('only uncertain transport and server failures can be retried', () {
    expect(shouldOfferSafeCreateRetry(0), isTrue);
    expect(shouldOfferSafeCreateRetry(503), isTrue);
    expect(shouldOfferSafeCreateRetry(409), isFalse);
    expect(shouldOfferSafeCreateRetry(400), isFalse);
    expect(shouldOfferSafeCreateRetry(null), isFalse);
  });

  test('maps safe create error codes to the documented actions', () {
    expect(
      classifySafeCreateFailure(
        statusCode: 409,
        errorCode: 'MIKRO_WRITE_IN_PROGRESS',
        retryable: true,
      ),
      SafeCreateFailureKind.processing,
    );
    expect(
      classifySafeCreateFailure(
        statusCode: 409,
        errorCode: 'MIKRO_WRITE_OUTCOME_UNCONFIRMED',
        retryable: true,
      ),
      SafeCreateFailureKind.uncertain,
    );
    expect(
      classifySafeCreateFailure(
        statusCode: 409,
        errorCode: 'MIKRO_DOCUMENT_CONTENT_MISMATCH',
        retryable: false,
      ),
      SafeCreateFailureKind.manualReview,
    );
    expect(
      classifySafeCreateFailure(
        statusCode: 409,
        errorCode: 'CLIENT_REQUEST_PAYLOAD_MISMATCH',
        retryable: false,
      ),
      SafeCreateFailureKind.payloadChanged,
    );
  });

  test(
    'manual review is preserved and only allows an independent operation',
    () {
      const conflict = ApiException(
        statusCode: 409,
        title: 'Conflict',
        detail: 'Belge icerigi uyusmuyor.',
        errorCode: 'MIKRO_DOCUMENT_CONTENT_MISMATCH',
        retryable: false,
      );
      final kind = classifySafeCreateException(conflict);

      expect(shouldKeepSafeCreatePending(kind), isTrue);
    expect(canRetrySafeCreate(kind), isFalse);
      expect(canStartNewSafeCreate(kind), isTrue);
      expect(safeCreatePendingActionLabel(kind), 'Yeni Bagimsiz Islem');
      expect(safeCreateRetryErrorMessage(conflict), contains('yetkili'));
    },
  );

  test('payload mismatch requires an explicit new operation', () {
    final kind = classifySafeCreateFailure(
      statusCode: 409,
      errorCode: 'CLIENT_REQUEST_PAYLOAD_MISMATCH',
      retryable: false,
    );

    expect(shouldKeepSafeCreatePending(kind), isTrue);
    expect(canRetrySafeCreate(kind), isFalse);
    expect(canStartNewSafeCreate(kind), isTrue);
    expect(safeCreatePendingActionLabel(kind), 'Yeni Bagimsiz Islem');
  });

  test('legacy multiple-document message still requires review', () {
    expect(
      classifySafeCreateFailure(
        statusCode: 409,
        message: 'multiple Mikro documents: F120/1, F120/2',
      ),
      SafeCreateFailureKind.multipleDocuments,
    );
  });
}
