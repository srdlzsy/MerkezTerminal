import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/models/virman_models.dart';

void main() {
  test('VirmanListItem reads incoming and outgoing summary fields', () {
    final item = VirmanListItem.fromJson(<String, dynamic>{
      'documentNo': 'VRM-0001',
      'documentSerie': 'F110',
      'documentOrderNo': 15,
      'warehouseNo': 110,
      'warehouseName': 'KESTEL',
      'movementTypes': <int>[1, 0],
      'lineCount': 4,
      'totalQuantity': 18,
      'totalAmount': 450,
      'incomingLineCount': 2,
      'outgoingLineCount': 2,
      'incomingQuantity': 12,
      'outgoingQuantity': 6,
    });

    expect(item.incomingLineCount, 2);
    expect(item.outgoingLineCount, 2);
    expect(item.incomingQuantity, 12);
    expect(item.outgoingQuantity, 6);
  });

  test('VirmanCreateResult reads incoming and outgoing summary fields', () {
    final item = VirmanCreateResult.fromJson(<String, dynamic>{
      'documentSerie': 'F110',
      'documentOrderNo': 16,
      'documentNo': 'VRM-0002',
      'warehouseNo': 110,
      'movementTypes': <int>[1, 0],
      'lineCount': 2,
      'totalQuantity': 8,
      'totalAmount': 200,
      'writeConnectionName': 'test',
      'incomingLineCount': 1,
      'outgoingLineCount': 1,
      'incomingQuantity': 6,
      'outgoingQuantity': 2,
    });

    expect(item.incomingLineCount, 1);
    expect(item.outgoingLineCount, 1);
    expect(item.incomingQuantity, 6);
    expect(item.outgoingQuantity, 2);
  });
}
