import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/data/models/suggested_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/models/suggested_warehouse_order_models.dart';

void main() {
  test('suggested warehouse order snapshot restores exact safe request', () {
    final request = SuggestedWarehouseOrderConvertRequest(
      clientRequestId: 'a38f40bb-b117-48f3-ab5e-3ae3b9cad201',
      forceCreateNew: true,
      sourceWarehouseNo: 56,
      targetWarehouseNo: 120,
      orderDate: DateTime(2026, 10, 16),
      deliveryDate: DateTime(2026, 10, 17),
      description: 'Onerilen depo siparisi',
      lines: const <SuggestedWarehouseOrderConvertLine>[
        SuggestedWarehouseOrderConvertLine(
          stockCode: '010416',
          quantity: 12,
          recommendedQuantity: 10,
          unitPrice: 4.5,
          unitPointer: 1,
          description: 'Satir',
          packageCode: 'KOLI',
          projectCode: 'PRJ',
          responsibilityCenter: 'SRM',
        ),
      ],
    );

    expect(
      SuggestedWarehouseOrderConvertRequest.fromJson(request.toJson()).toJson(),
      request.toJson(),
    );
  });

  test('suggested company order snapshot restores exact safe request', () {
    final request = SuggestedCompanyOrderConvertRequest(
      clientRequestId: '94c6fa36-3575-46b3-938e-df829a11513d',
      forceCreateNew: true,
      supplierCode: '32000999',
      warehouseNo: 120,
      orderDate: DateTime(2026, 10, 16),
      deliveryDate: DateTime(2026, 10, 17),
      description1: 'Onerilen firma siparisi',
      description2: 'Aciklama 2',
      deliverer: 'Ali',
      receiver: 'Veli',
      lines: const <SuggestedCompanyOrderConvertLine>[
        SuggestedCompanyOrderConvertLine(
          stockCode: '010416',
          quantity: 24,
          recommendedQuantity: 20,
          unitPrice: 8.75,
          unitPointer: 1,
          description1: 'Satir 1',
          description2: 'Satir 2',
          packageCode: 'KOLI',
          projectCode: 'PRJ',
          customerResponsibilityCenter: 'CRM',
          productResponsibilityCenter: 'URM',
        ),
      ],
    );

    expect(
      SuggestedCompanyOrderConvertRequest.fromJson(request.toJson()).toJson(),
      request.toJson(),
    );
  });

  test('forceCreateNew is omitted unless explicitly enabled', () {
    final warehouseRequest = SuggestedWarehouseOrderConvertRequest(
      sourceWarehouseNo: 50,
      orderDate: DateTime(2026, 10, 16),
      deliveryDate: DateTime(2026, 10, 17),
      description: '',
      lines: const <SuggestedWarehouseOrderConvertLine>[],
    );
    final companyRequest = SuggestedCompanyOrderConvertRequest(
      supplierCode: '32000999',
      orderDate: DateTime(2026, 10, 16),
      deliveryDate: DateTime(2026, 10, 17),
      description1: '',
      description2: '',
      deliverer: '',
      receiver: '',
      lines: const <SuggestedCompanyOrderConvertLine>[],
    );

    expect(warehouseRequest.toJson(), isNot(contains('forceCreateNew')));
    expect(companyRequest.toJson(), isNot(contains('forceCreateNew')));
  });
}
