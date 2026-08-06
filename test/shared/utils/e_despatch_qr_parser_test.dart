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
    expect(payload.actualDespatchDate, DateTime(2025, 9, 16));
    expect(payload.actualDespatchTime, '08:40:54');
    expect(payload.senderTaxNoOrTckn, '0740367730');
    expect(payload.receiverTaxNoOrTckn, '3880115910');
    expect(payload.scenario, 'TEMELIRSALIYE');
    expect(payload.documentTypeCode, 'SEVK');
    expect(payload.carrierTaxNoOrTckn, '39352001182');
    expect(payload.licensePlate, isNull);
    expect(payload.hasShippingInfo, isTrue);
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

  test('parses standard e-despatch JSON QR payload fields', () {
    final payload = parseEDespatchQrPayload(
      '{"vkntckn":"1111111111",'
      '"avkntckn":"2222222222",'
      '"senaryo":"TEMELIRSALIYE",'
      '"tip":"SEVK",'
      '"tarih":"2022-08-17",'
      '"no":"IRS2022000000001",'
      '"ettn":"04e35a51-7c00-45d0-968c-6f7c60834525",'
      '"sevktarihi":"2022-08-17",'
      '"sevkzamani":"09:32:13",'
      '"tasiyicivkn":"3333333333",'
      '"plaka":"06AA0606"}',
    );

    expect(payload.ettn, '04e35a51-7c00-45d0-968c-6f7c60834525');
    expect(payload.documentNo, 'IRS2022000000001');
    expect(payload.issueDate, DateTime(2022, 8, 17));
    expect(payload.actualDespatchDate, DateTime(2022, 8, 17));
    expect(payload.actualDespatchTime, '09:32:13');
    expect(payload.senderTaxNoOrTckn, '1111111111');
    expect(payload.receiverTaxNoOrTckn, '2222222222');
    expect(payload.scenario, 'TEMELIRSALIYE');
    expect(payload.documentTypeCode, 'SEVK');
    expect(payload.carrierTaxNoOrTckn, '3333333333');
    expect(payload.licensePlate, '06AA0606');
  });

  test('parses invoice QR monetary fields', () {
    final payload = parseEDespatchQrPayload(
      '{"vkntckn":"1111111111",'
      '"avkntckn":"2222222222",'
      '"senaryo":"TEMELFATURA",'
      '"tip":"SATIS",'
      '"tarih":"2022-08-17",'
      '"no":"GIB2022000000001",'
      '"ettn":"04e26a62-7c00-46d0-878c-6f7c60834525",'
      '"parabirimi":"TRY",'
      '"malhizmettoplam":"1000.00",'
      '"kdvmatrah(8)":"1000.00",'
      '"hesaplanankdv(8)":"80.00",'
      '"vergidahil":"1080.00",'
      '"odenecek":"1080.00"}',
    );

    expect(payload.ettn, '04e26a62-7c00-46d0-878c-6f7c60834525');
    expect(payload.currencyCode, 'TRY');
    expect(payload.goodsServicesTotalAmount, 1000);
    expect(payload.vatBaseAmounts, <String, double>{'8': 1000});
    expect(payload.calculatedVatAmounts, <String, double>{'8': 80});
    expect(payload.taxInclusiveAmount, 1080);
    expect(payload.payableAmount, 1080);
    expect(payload.hasMonetaryInfo, isTrue);
  });
}
