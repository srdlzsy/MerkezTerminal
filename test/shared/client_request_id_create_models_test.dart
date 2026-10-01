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

  test('safe retry create models restore the exact persisted payload', () {
    const clientRequestId = 'persisted-request-123';
    final requests = <Map<String, dynamic>>[
      CompanyMovementCreateRequest(
        clientRequestId: clientRequestId,
        customerCode: '120.01.001',
        movementDate: DateTime(2026, 10, 1),
        documentDate: DateTime(2026, 10, 1),
        documentNo: 'FS-1',
        description: 'Firma sevki',
        deliverer: 'Ali',
        receiver: 'Veli',
        lines: const <CompanyMovementCreateLine>[
          CompanyMovementCreateLine(
            stockCode: '015792',
            quantity: 4,
            unitPrice: 12.5,
            unitPointer: 1,
            description: 'Satir',
            partyCode: 'P1',
            lotNo: 2,
            projectCode: 'PRJ',
            customerResponsibilityCenter: 'CRM',
            productResponsibilityCenter: 'URM',
            orderLineGuid: 'order-line-1',
          ),
        ],
      ).toJson(),
      StockReceiptCreateRequest(
        clientRequestId: clientRequestId,
        creator: 'Olusturan',
        acceptor: 'Onaylayan',
        movementDate: DateTime(2026, 10, 1),
        documentDate: DateTime(2026, 10, 1),
        documentNo: 'ZF-1',
        description: 'Zayiat',
        lines: const <StockReceiptCreateLine>[
          StockReceiptCreateLine(
            stockCode: '015792',
            quantity: 3,
            unitPointer: 1,
            description: 'Satir',
            partyCode: 'P1',
            lotNo: 2,
            projectCode: 'PRJ',
          ),
        ],
      ).toJson(),
      VirmanCreateRequest(
        clientRequestId: clientRequestId,
        movementDate: DateTime(2026, 10, 1),
        documentDate: DateTime(2026, 10, 1),
        documentNo: 'VR-1',
        description: 'Virman',
        lines: const <VirmanCreateLine>[
          VirmanCreateLine(
            stockCode: '015792',
            movementType: 1,
            quantity: 2,
            unitPointer: 1,
            description: 'Satir',
            partyCode: 'P1',
            lotNo: 2,
            projectCode: 'PRJ',
          ),
        ],
      ).toJson(),
    ];

    expect(
      CompanyMovementCreateRequest.fromJson(requests[0]).toJson(),
      requests[0],
    );
    expect(
      StockReceiptCreateRequest.fromJson(requests[1]).toJson(),
      requests[1],
    );
    expect(VirmanCreateRequest.fromJson(requests[2]).toJson(), requests[2]);
  });
}
