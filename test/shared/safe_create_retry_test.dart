import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_status.dart';
import 'package:furpa_merkez_terminal/shared/utils/safe_create_retry.dart';

void main() {
  test('uncertain transport and server failures require status checks', () {
    expect(shouldOfferSafeCreateRetry(0), isFalse);
    expect(shouldOfferSafeCreateRetry(503), isFalse);
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
        errorCode: 'MIKRO_WRITE_QUEUE_BUSY',
        retryable: true,
      ),
      SafeCreateFailureKind.queueBusy,
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

  test('queue busy preserves the request and allows the same retry', () {
    const conflict = ApiException(
      statusCode: 409,
      title: 'Conflict',
      errorCode: 'MIKRO_WRITE_QUEUE_BUSY',
      retryable: true,
    );
    final kind = classifySafeCreateException(conflict);

    expect(shouldKeepSafeCreatePending(kind), isTrue);
    expect(canRetrySafeCreate(kind), isTrue);
    expect(canStartNewSafeCreate(kind), isFalse);
    expect(safeCreatePendingActionLabel(kind), 'Ayni Kaydi Tekrar Dene');
    expect(safeCreateRetryErrorMessage(conflict), contains('yazimi baslamadi'));
  });

  test('document identity conflicts stay out of the pending queue', () {
    const conflict = ApiException(
      statusCode: 409,
      title: 'Conflict',
      errorCode: 'MIKRO_DOCUMENT_IDENTITY_CONFLICT',
      retryable: false,
      recommendedAction: 'EditAndRetry',
    );

    final kind = classifySafeCreateException(conflict);

    expect(kind, SafeCreateFailureKind.documentIdentityConflict);
    expect(shouldKeepSafeCreatePending(kind), isFalse);
    expect(canRetrySafeCreate(kind), isFalse);
    expect(safeCreatePendingActionLabel(kind), 'Seri / Sirayi Duzelt');
    expect(
      safeCreateRetryErrorMessage(conflict),
      contains('Offline listesine'),
    );
  });

  test('existing official documents stay out of the pending queue', () {
    final kind = classifySafeCreateFailure(
      statusCode: 409,
      errorCode: 'MIKRO_OFFICIAL_DOCUMENT_ALREADY_RECEIVED',
      retryable: false,
      recommendedAction: 'RefreshList',
    );

    expect(kind, SafeCreateFailureKind.officialDocumentAlreadyReceived);
    expect(shouldKeepSafeCreatePending(kind), isFalse);
    expect(canRetrySafeCreate(kind), isFalse);
    expect(safeCreatePendingActionLabel(kind), 'Listeyi Yenile');
  });

  test('manual review is preserved and blocks all create actions', () {
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
    expect(canStartNewSafeCreate(kind), isFalse);
    expect(safeCreatePendingActionLabel(kind), 'Destek gerekli');
    expect(safeCreateRetryErrorMessage(conflict), contains('yetkili'));
  });

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
    final kind = classifySafeCreateFailure(
      statusCode: 409,
      message: 'multiple Mikro documents: F120/1, F120/2',
    );

    expect(kind, SafeCreateFailureKind.multipleDocuments);
    expect(canRetrySafeCreate(kind), isFalse);
    expect(canStartNewSafeCreate(kind), isFalse);
    expect(safeCreatePendingActionLabel(kind), 'Destek gerekli');
  });

  test('preserves correlation id in classified create errors', () {
    const conflict = ApiException(
      statusCode: 409,
      title: 'Conflict',
      detail: 'Belge icerigi uyusmuyor.',
      errorCode: 'MIKRO_DOCUMENT_CONTENT_MISMATCH',
      retryable: false,
      correlationId: 'trace-789',
    );

    expect(
      safeCreateRetryErrorMessage(conflict),
      contains('Destek kodu: trace-789'),
    );
  });

  test('replaces legacy cancellation text with a safe Turkish message', () {
    const error = ApiException(statusCode: 500, title: 'A task was canceled.');

    final message = safeCreateRetryErrorMessage(error);

    expect(message, contains('sonucu belirsiz'));
    expect(message, isNot(contains('task was canceled')));
  });

  test('builds retry gate only for retryable responses', () {
    final now = DateTime(2026, 10, 13, 12);

    expect(
      safeCreateRetryNotBefore(retryable: true, retryAfterSeconds: 5, now: now),
      now.add(const Duration(seconds: 5)),
    );
    expect(
      safeCreateRetryNotBefore(
        retryable: false,
        retryAfterSeconds: 5,
        now: now,
      ),
      isNull,
    );
  });

  test(
    'status errors need decision metadata before replacing pending state',
    () {
      expect(
        hasSafeCreateDecisionMetadata(
          const ApiException(statusCode: 404, title: 'Kayit bulunamadi'),
        ),
        isTrue,
      );
      expect(
        hasSafeCreateDecisionMetadata(
          const ApiException(
            statusCode: 409,
            title: 'Islem devam ediyor',
            errorCode: 'MIKRO_WRITE_IN_PROGRESS',
            retryable: true,
          ),
        ),
        isTrue,
      );
    },
  );

  test('offline status keeps non-retryable review decisions pending', () {
    final status = OfflineSyncStatus<Object>(
      clientRequestId: 'request-review',
      operationCode: 'test.create',
      status: 'Failed',
      createdAtUtc: null,
      completedAtUtc: null,
      errorMessage: 'Document content mismatch.',
      errorCode: 'MIKRO_DOCUMENT_CONTENT_MISMATCH',
      retryable: false,
      retryAfterSeconds: null,
      result: null,
    );

    final kind = classifyOfflineSyncStatus(status);
    expect(kind, SafeCreateFailureKind.manualReview);
    expect(shouldKeepSafeCreatePending(kind), isTrue);
    expect(canRetrySafeCreate(kind), isFalse);
    expect(
      safeCreateOfflineSyncErrorMessage(status, fallback: 'Kayit basarisiz.'),
      contains('yetkili incelemesi gerekli'),
    );
  });

  test('cancelled safe write clears the local pending operation', () {
    final status = OfflineSyncStatus<Object>(
      clientRequestId: 'request-cancelled',
      operationCode: 'test.create',
      status: 'Cancelled',
      createdAtUtc: null,
      completedAtUtc: null,
      errorMessage: 'Yetkili tarafindan iptal edildi.',
      errorCode: 'SAFE_WRITE_CANCELLED',
      retryable: false,
      retryAfterSeconds: null,
      result: null,
    );

    final kind = classifyOfflineSyncStatus(status);

    expect(kind, SafeCreateFailureKind.cancelled);
    expect(shouldKeepSafeCreatePending(kind), isFalse);
    expect(canRetrySafeCreate(kind), isFalse);
    expect(
      safeCreateOfflineSyncErrorMessage(status, fallback: 'Kayit basarisiz.'),
      'Yetkili tarafindan iptal edildi.',
    );
  });
}
