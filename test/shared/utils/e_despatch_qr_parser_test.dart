import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/utils/e_despatch_qr_parser.dart';

void main() {
  test('parses TEC-XT e-despatch QR payload with star separated ETTN', () {
    final payload = parseEDespatchQrPayload(
      'ĞİvkntcknİŞİ0740367730İöİavkntcknİŞİ3880115910İöİ'
      'senaryoİŞİTEMELIRSALIYEİöİtıpİŞİSEVKİöİtarıhİŞİ2025*09*16İöİ'
      'noİŞİARS2025000009471İöİ'
      'ettnİŞİ7D8D0571*A003*4EA2*A51F*6F0C517D97A0İöİ'
      'sevktarıhıİŞİ2025*09*16İöİsevkzamanıİŞİ08Ş40Ş54İöİ'
      'tasıyıcıvknİŞİ39352001182İöİplakaİŞİİÜ',
    );

    expect(payload.ettn, '7d8d0571-a003-4ea2-a51f-6f0c517d97a0');
    expect(payload.documentNo, 'ARS2025000009471');
    expect(payload.issueDate, DateTime(2025, 9, 16));
    expect(payload.senderTaxNoOrTckn, '0740367730');
    expect(payload.receiverTaxNoOrTckn, '3880115910');
  });

  test('extracts compact and hyphenated ETTN values', () {
    expect(
      extractEDespatchEttn('7D8D0571A0034EA2A51F6F0C517D97A0'),
      '7d8d0571-a003-4ea2-a51f-6f0c517d97a0',
    );
    expect(
      extractEDespatchEttn('ettn=7D8D0571-A003-4EA2-A51F-6F0C517D97A0'),
      '7d8d0571-a003-4ea2-a51f-6f0c517d97a0',
    );
  });
}
