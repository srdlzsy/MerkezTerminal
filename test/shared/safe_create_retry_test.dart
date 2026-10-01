import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/shared/utils/safe_create_retry.dart';

void main() {
  test('safe create retry offers retry only for uncertain create statuses', () {
    expect(shouldOfferSafeCreateRetry(0), isTrue);
    expect(shouldOfferSafeCreateRetry(409), isTrue);
    expect(shouldOfferSafeCreateRetry(503), isTrue);
    expect(shouldOfferSafeCreateRetry(400), isFalse);
    expect(shouldOfferSafeCreateRetry(null), isFalse);
  });

  test(
    'safe create retry explains conflict as a retry/new operation state',
    () {
      const conflict = ApiException(statusCode: 409, title: 'Conflict');
      const validation = ApiException(statusCode: 400, title: 'Validation');

      expect(
        safeCreateRetryErrorMessage(conflict),
        contains('yeni islem olarak tekrar kaydedin'),
      );
      expect(safeCreateRetryErrorMessage(validation), 'Validation');
    },
  );

  test('classifies create conflicts without losing the pending operation', () {
    expect(
      classifySafeCreateFailure(
        statusCode: 409,
        message: 'Request is already being processed',
      ),
      SafeCreateFailureKind.processing,
    );
    expect(
      classifySafeCreateFailure(
        statusCode: 409,
        message: 'Same clientRequestId has different request payload',
      ),
      SafeCreateFailureKind.payloadChanged,
    );
    expect(
      classifySafeCreateFailure(
        statusCode: 409,
        message: 'multiple Mikro documents: F120/1, F120/2',
      ),
      SafeCreateFailureKind.multipleDocuments,
    );
  });

  test('offers retry for processing and server uncertainty only', () {
    expect(
      shouldOfferSafeCreateRetry(
        409,
        message: 'Kayit Mikro tarafinda halen isleniyor.',
      ),
      isTrue,
    );
    expect(
      shouldOfferSafeCreateRetry(
        409,
        message: 'Bu kayit denemesinin icerigi degismis.',
      ),
      isFalse,
    );
    expect(shouldOfferSafeCreateRetry(500), isTrue);
  });
}
