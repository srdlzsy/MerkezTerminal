import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/data/models/suggested_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/models/suggested_warehouse_order_models.dart';
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

    expect(
      WarehouseOrderCreateRequest(
        clientRequestId: clientRequestId,
        outWarehouseNo: 50,
        orderDate: DateTime(2026, 4, 17),
        deliveryDate: DateTime(2026, 4, 18),
        description: 'Depo siparisi',
        lines: const <WarehouseOrderCreateLine>[
          WarehouseOrderCreateLine(
            stockCode: '015792',
            quantity: 10,
            recommendedQuantity: 0,
            unitPrice: 0,
            unitPointer: 1,
            description: '',
            packageCode: '',
            projectCode: '',
            responsibilityCenter: '',
          ),
        ],
      ).toJson()['clientRequestId'],
      clientRequestId,
    );

    expect(
      CompanyOrderCreateRequest(
        clientRequestId: clientRequestId,
        customerCode: '32000999',
        orderDate: DateTime(2026, 4, 17),
        deliveryDate: DateTime(2026, 4, 18),
        description1: 'Firma siparisi',
        description2: '',
        deliverer: 'Ali',
        receiver: 'Veli',
        lines: const <CompanyOrderCreateLine>[
          CompanyOrderCreateLine(
            stockCode: '015792',
            quantity: 10,
            recommendedQuantity: 0,
            unitPrice: 12.5,
            unitPointer: 1,
            description1: '',
            description2: '',
            packageCode: '',
            projectCode: '',
            customerResponsibilityCenter: '',
            productResponsibilityCenter: '',
          ),
        ],
      ).toJson()['clientRequestId'],
      clientRequestId,
    );

    expect(
      SuggestedWarehouseOrderConvertRequest(
        clientRequestId: clientRequestId,
        forceCreateNew: true,
        sourceWarehouseNo: 50,
        targetWarehouseNo: 120,
        orderDate: DateTime(2026, 10, 1),
        deliveryDate: DateTime(2026, 10, 2),
        description: 'Onerilen depo siparisi',
        lines: const <SuggestedWarehouseOrderConvertLine>[
          SuggestedWarehouseOrderConvertLine(
            stockCode: '015792',
            quantity: 6,
            recommendedQuantity: 5,
            unitPrice: 10,
            unitPointer: 1,
            description: '',
            packageCode: '',
            projectCode: '',
            responsibilityCenter: '',
          ),
        ],
      ).toJson(),
      containsPair('clientRequestId', clientRequestId),
    );

    expect(
      SuggestedCompanyOrderConvertRequest(
        clientRequestId: clientRequestId,
        forceCreateNew: true,
        supplierCode: '32000999',
        warehouseNo: 120,
        orderDate: DateTime(2026, 10, 1),
        deliveryDate: DateTime(2026, 10, 2),
        description1: 'Onerilen firma siparisi',
        description2: '',
        deliverer: '',
        receiver: '',
        lines: const <SuggestedCompanyOrderConvertLine>[
          SuggestedCompanyOrderConvertLine(
            stockCode: '015792',
            quantity: 8,
            recommendedQuantity: 7,
            unitPrice: 12.5,
            unitPointer: 1,
            description1: '',
            description2: '',
            packageCode: '',
            projectCode: '',
            customerResponsibilityCenter: '',
            productResponsibilityCenter: '',
          ),
        ],
      ).toJson(),
      containsPair('clientRequestId', clientRequestId),
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
      WarehouseOrderCreateRequest(
        clientRequestId: clientRequestId,
        forceCreateNew: true,
        outWarehouseNo: 50,
        orderDate: DateTime(2026, 10, 1),
        deliveryDate: DateTime(2026, 10, 2),
        description: 'Depo siparisi',
        lines: const <WarehouseOrderCreateLine>[
          WarehouseOrderCreateLine(
            stockCode: '015792',
            quantity: 6,
            recommendedQuantity: 5,
            unitPrice: 10,
            unitPointer: 1,
            description: 'Satir',
            packageCode: 'PKT',
            projectCode: 'PRJ',
            responsibilityCenter: 'SRM',
          ),
        ],
      ).toJson(),
      CompanyOrderCreateRequest(
        clientRequestId: clientRequestId,
        forceCreateNew: true,
        customerCode: '32000999',
        orderDate: DateTime(2026, 10, 1),
        deliveryDate: DateTime(2026, 10, 2),
        description1: 'Firma siparisi',
        description2: 'Aciklama 2',
        deliverer: 'Ali',
        receiver: 'Veli',
        lines: const <CompanyOrderCreateLine>[
          CompanyOrderCreateLine(
            stockCode: '015792',
            quantity: 8,
            recommendedQuantity: 7,
            unitPrice: 12.5,
            unitPointer: 1,
            description1: 'Satir 1',
            description2: 'Satir 2',
            packageCode: 'PKT',
            projectCode: 'PRJ',
            customerResponsibilityCenter: 'CRM',
            productResponsibilityCenter: 'URM',
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
    expect(
      WarehouseOrderCreateRequest.fromJson(requests[3]).toJson(),
      requests[3],
    );
    expect(
      CompanyOrderCreateRequest.fromJson(requests[4]).toJson(),
      requests[4],
    );
  });
}
