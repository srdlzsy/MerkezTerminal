import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';

void main() {
  test('serializes orderLineGuid only when provided', () {
    const lineWithOrder = CompanyMovementCreateLine(
      stockCode: '015792',
      quantity: 2,
      unitPrice: 125,
      unitPointer: 1,
      description: 'Siparisli sevk',
      partyCode: '',
      lotNo: 0,
      projectCode: '',
      customerResponsibilityCenter: '',
      productResponsibilityCenter: '',
      orderLineGuid: '  8d4a5a77-1b3f-4f2a-93a1-b90a1b7d3c11  ',
    );

    const lineWithoutOrder = CompanyMovementCreateLine(
      stockCode: '015793',
      quantity: 1,
      unitPrice: 50,
      unitPointer: 1,
      description: '',
      partyCode: '',
      lotNo: 0,
      projectCode: '',
      customerResponsibilityCenter: '',
      productResponsibilityCenter: '',
    );

    expect(
      lineWithOrder.toJson()['orderLineGuid'],
      '8d4a5a77-1b3f-4f2a-93a1-b90a1b7d3c11',
    );
    expect(lineWithoutOrder.toJson().containsKey('orderLineGuid'), isFalse);
  });
}
