import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';

void main() {
  test('company movement detail reads deliverer and receiver', () {
    final detail = CompanyMovementDetail.fromJson(<String, dynamic>{
      'header': <String, dynamic>{
        'deliverer': 'Ahmet Yilmaz',
        'receiver': 'Mehmet Demir',
      },
      'items': <dynamic>[],
    });

    expect(detail.header.deliverer, 'Ahmet Yilmaz');
    expect(detail.header.receiver, 'Mehmet Demir');
  });

  test('company movement list reads deliverer and receiver', () {
    final item = CompanyMovementListItem.fromJson(<String, dynamic>{
      'deliverer': 'Ahmet Yilmaz',
      'receiver': 'Mehmet Demir',
    });

    expect(item.deliverer, 'Ahmet Yilmaz');
    expect(item.receiver, 'Mehmet Demir');
  });
}
