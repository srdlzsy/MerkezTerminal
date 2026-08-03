import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';

void main() {
  test(
    'keeps manual e-despatch payload when no registered driver is selected',
    () {
      const request = EDespatchSendRequest(
        plaque: '16 ABC 123',
        driverNameSurname: 'Ad Soyad',
        driverTckn: '11111111111',
      );

      expect(request.toJson(), <String, dynamic>{
        'plaque': '16 ABC 123',
        'driverNameSurname': 'Ad Soyad',
        'driverTckn': '11111111111',
      });
    },
  );

  test('sends only driverId when selected driver has no manual overrides', () {
    const request = EDespatchSendRequest(
      driverId: ' 1bc27065-f775-468f-9fc9-0e1ad107d105 ',
      plaque: ' ',
      driverNameSurname: ' ',
      driverTckn: ' ',
    );

    expect(request.toJson(), <String, dynamic>{
      'driverId': '1bc27065-f775-468f-9fc9-0e1ad107d105',
    });
  });

  test('keeps filled manual overrides with selected driverId', () {
    const request = EDespatchSendRequest(
      driverId: '1bc27065-f775-468f-9fc9-0e1ad107d105',
      plaque: '16 XYZ 999',
      driverNameSurname: '',
      driverTckn: '',
    );

    expect(request.toJson(), <String, dynamic>{
      'driverId': '1bc27065-f775-468f-9fc9-0e1ad107d105',
      'plaque': '16 XYZ 999',
    });
  });
}
