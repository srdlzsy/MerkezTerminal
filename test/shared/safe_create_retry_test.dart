import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/shared/utils/safe_create_retry.dart';

void main() {
  test('safe create retry offers retry only for uncertain create statuses', () {
    expect(shouldOfferSafeCreateRetry(0), isTrue);
    expect(shouldOfferSafeCreateRetry(409), isTrue);
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
}
