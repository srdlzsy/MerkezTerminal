import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/data/models/suggested_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/data/suggested_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/presentation/view_models/suggested_company_orders_controller.dart';

void main() {
  test('loads suggested company orders and converts selected lines', () async {
    final repository = _FakeSuggestedCompanyOrdersRepository();
    final controller = SuggestedCompanyOrdersController(
      repository: repository,
      accessToken: 'token',
    );
    addTearDown(controller.dispose);

    await controller.loadSuggestions(supplierCode: '32000999');

    expect(repository.lastFilter?.supplierCode, '32000999');
    expect(controller.items, hasLength(2));
    expect(controller.selectedCount, 0);

    final item = controller.items.first;
    controller.toggleItem(item);
    controller.updateQuantity(item, '30');

    final result = await controller.convertSelected(
      orderDate: DateTime(2026, 7, 1),
      deliveryDate: DateTime(2026, 7, 2),
      description1: 'Oneriden olustu',
    );

    expect(result?.documentNoLabel, 'F110.55');
    expect(repository.lastRequest?.supplierCode, '32000999');
    expect(repository.lastRequest?.description1, 'Oneriden olustu');
    expect(repository.lastRequest?.lines, hasLength(1));
    expect(repository.lastRequest?.lines.single.stockCode, '010001');
    expect(repository.lastRequest?.lines.single.quantity, 30);
    expect(repository.lastRequest?.lines.single.recommendedQuantity, 25);
    expect(repository.lastRequest?.lines.single.unitPrice, 15.75);
    expect(controller.selectedCount, 0);
  });

  test('does not convert without a selected line', () async {
    final controller = SuggestedCompanyOrdersController(
      repository: _FakeSuggestedCompanyOrdersRepository(),
      accessToken: 'token',
    );
    addTearDown(controller.dispose);

    await controller.loadSuggestions(supplierCode: '32000999');

    final result = await controller.convertSelected(
      orderDate: DateTime(2026, 7, 1),
      deliveryDate: DateTime(2026, 7, 2),
      description1: '',
    );

    expect(result, isNull);
    expect(controller.convertError, contains('en az bir satir'));
  });
}

class _FakeSuggestedCompanyOrdersRepository
    implements SuggestedCompanyOrdersRepository {
  SuggestedCompanyOrderFilter? lastFilter;
  SuggestedCompanyOrderConvertRequest? lastRequest;

  @override
  Future<List<SuggestedCompanyOrderListItem>> fetchSuggestions({
    required String accessToken,
    required SuggestedCompanyOrderFilter filter,
  }) async {
    lastFilter = filter;
    return const <SuggestedCompanyOrderListItem>[
      SuggestedCompanyOrderListItem(
        supplierCode: '32000999',
        supplierName: 'TEDARIKCI A.S.',
        stockCode: '010001',
        stockName: 'Domates',
        modelCode: '01',
        barcode: '8690000000001',
        targetOnHand: 4,
        salesQuantity: 86,
        openCompanyOrderQuantity: 2,
        packageFactor: 5,
        minDay: 7,
        recommendedDay: 7,
        maxDay: 0,
        recommendedStockQuantity: 14,
        needQuantity: 8,
        suggestedOrderQuantity: 25,
        purchasePrice: 15.75,
        minimumPurchaseQuantity: 24,
        deliveryDay: 2,
      ),
      SuggestedCompanyOrderListItem(
        supplierCode: '32000999',
        supplierName: 'TEDARIKCI A.S.',
        stockCode: '010002',
        stockName: 'Biber',
        modelCode: '01',
        barcode: '8690000000002',
        targetOnHand: 8,
        salesQuantity: 30,
        openCompanyOrderQuantity: 0,
        packageFactor: 1,
        minDay: 7,
        recommendedDay: 7,
        maxDay: 0,
        recommendedStockQuantity: 12,
        needQuantity: 4,
        suggestedOrderQuantity: 4,
        purchasePrice: 8.5,
        minimumPurchaseQuantity: 0,
        deliveryDay: 1,
      ),
    ];
  }

  @override
  Future<CompanyOrderCreateResult> convertToOrder({
    required String accessToken,
    required SuggestedCompanyOrderConvertRequest request,
  }) async {
    lastRequest = request;
    return CompanyOrderCreateResult(
      documentSerie: 'F110',
      documentOrderNo: 55,
      orderDate: request.orderDate,
      deliveryDate: request.deliveryDate,
      warehouseNo: 110,
      customerCode: request.supplierCode,
      lineCount: request.lines.length,
      totalQuantity: request.lines.fold<double>(
        0,
        (total, line) => total + line.quantity,
      ),
      totalAmount: request.lines.fold<double>(
        0,
        (total, line) => total + (line.quantity * line.unitPrice),
      ),
      writeConnectionName: 'test',
    );
  }

  @override
  Future<List<CustomerLookupItem>> searchSuppliers({
    required String accessToken,
    required String query,
  }) async {
    return const <CustomerLookupItem>[
      CustomerLookupItem(
        customerCode: '32000999',
        customerName: 'TEDARIKCI',
        customerTitle: 'TEDARIKCI A.S.',
        customerDisplayName: 'TEDARIKCI A.S.',
        taxNumber: '1234567890',
        representativeCode: '',
        representativeName: '',
        invoiceAddressNo: 0,
        shippingAddressNo: 0,
        isLocked: false,
        isClosed: false,
      ),
    ];
  }
}
