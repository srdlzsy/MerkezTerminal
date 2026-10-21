import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';

void main() {
  test('technical Flutter error is replaced with Turkish user guidance', () {
    const error = ApiException(
      statusCode: 500,
      title: 'Internal Server Error',
      detail: 'Null check operator used on a null value',
      correlationId: 'destek-123',
    );

    expect(error.message, contains('Sunucu hatasi'));
    expect(error.message, contains('Beklenmeyen bir sunucu hatasi'));
    expect(error.message, contains('Destek kodu: destek-123'));
    expect(error.message, isNot(contains('Null check operator')));
  });

  test('Turkish business detail is preserved', () {
    const error = ApiException(
      statusCode: 400,
      title: 'Gecersiz istek',
      detail: 'Miktar sifirdan buyuk olmali.',
    );

    expect(error.message, 'Gecersiz istek: Miktar sifirdan buyuk olmali.');
  });

  test('unexpected terminal runtime error is hidden from the user', () {
    final message = userFacingErrorMessage(
      StateError('Null check operator used on a null value'),
    );

    expect(message, contains('Formdaki bilgiler korundu'));
    expect(message, isNot(contains('Null check operator')));
  });
}
