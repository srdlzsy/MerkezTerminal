import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/models/stock_receipt_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/models/virman_models.dart';

void main() {
  test('safe retry create models include clientRequestId in payload', () {
    const clientRequestId = '2e8f99f1-8ad5-4dfb-a375-82b93f9aa101';

    expect(
      WarehouseShipmentCreateRequest(
        clientRequestId: clientRequestId,
        targetWarehouseNo: 50,
        transitWarehouseNo: 60,
        movementDate: DateTime(2026, 4, 17),
        documentDate: DateTime(2026, 4, 17),
        documentNo: '',
        description: '',
        lines: const <WarehouseShipmentCreateLine>[
          WarehouseShipmentCreateLine(
            stockCode: '015792',
            quantity: 10,
            unitPrice: 0,
            unitPointer: 1,
            description: '',
            partyCode: '',
            lotNo: 0,
            projectCode: '',
          ),
        ],
      ).toJson()['clientRequestId'],
      clientRequestId,
    );

    expect(
      CompanyMovementCreateRequest(
        clientRequestId: clientRequestId,
        customerCode: '120.01.001',
        movementDate: DateTime(2026, 4, 17),
        documentDate: DateTime(2026, 4, 17),
        documentNo: '',
        description: '',
        deliverer: '',
        receiver: '',
        lines: const <CompanyMovementCreateLine>[
          CompanyMovementCreateLine(
            stockCode: '015792',
            quantity: 10,
            unitPrice: 0,
            unitPointer: 1,
            description: '',
            partyCode: '',
            lotNo: 0,
            projectCode: '',
            customerResponsibilityCenter: '',
            productResponsibilityCenter: '',
          ),
        ],
      ).toJson()['clientRequestId'],
      clientRequestId,
    );

    expect(
      StockReceiptCreateRequest(
        clientRequestId: clientRequestId,
        creator: 'VARDIYA-1',
        acceptor: 'SEF-01',
        movementDate: DateTime(2026, 4, 21),
        documentDate: DateTime(2026, 4, 21),
        documentNo: '',
        description: '',
        lines: const <StockReceiptCreateLine>[
          StockReceiptCreateLine(
            stockCode: '015792',
            quantity: 10,
            unitPointer: 1,
            description: '',
            partyCode: '',
            lotNo: 0,
            projectCode: '',
          ),
        ],
      ).toJson()['clientRequestId'],
      clientRequestId,
    );

    expect(
      VirmanCreateRequest(
        clientRequestId: clientRequestId,
        movementDate: DateTime(2026, 4, 21),
        documentDate: DateTime(2026, 4, 21),
        documentNo: '',
        description: '',
        lines: const <VirmanCreateLine>[
          VirmanCreateLine(
            stockCode: '015792',
            movementType: 0,
            quantity: 10,
            unitPointer: 1,
            description: '',
            partyCode: '',
            lotNo: 0,
            projectCode: '',
          ),
        ],
      ).toJson()['clientRequestId'],
      clientRequestId,
    );
  });
}
