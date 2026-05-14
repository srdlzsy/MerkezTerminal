import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/outgoing_warehouse_shipments_repository.dart';

abstract class IncomingWarehouseShipmentsRepository
    implements OutgoingWarehouseShipmentsRepository {}

class ApiIncomingWarehouseShipmentsRepository
    implements IncomingWarehouseShipmentsRepository {
  const ApiIncomingWarehouseShipmentsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  bool get supportsEDespatch => false;

  @override
  Future<List<WarehouseShipmentListItem>> fetchShipments({
    required String accessToken,
    required WarehouseShipmentListFilter filter,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/sevk-islemleri/depolar-arasi-sevkler/gelen',
      accessToken: accessToken,
      queryParameters: filter.toQueryParameters(),
    );

    return response
        .map(
          (item) => WarehouseShipmentListItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<WarehouseShipmentDetail> fetchShipmentDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/sevk-islemleri/depolar-arasi-sevkler/gelen/'
      '$documentSerie/$documentOrderNo',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
    );

    return WarehouseShipmentDetail.fromJson(response);
  }

  @override
  Future<WarehouseShipmentCreateResult> createShipment({
    required String accessToken,
    required WarehouseShipmentCreateRequest request,
  }) async {
    throw UnsupportedError(
      'Gelen depolar arasi sevkler ekraninda create islemi desteklenmiyor.',
    );
  }

  @override
  Future<EDespatchSendResult> sendEDespatch({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
    required EDespatchSendRequest request,
  }) async {
    throw UnsupportedError(
      'Gelen depolar arasi sevkler ekraninda e-irsaliye desteklenmiyor.',
    );
  }

  @override
  Future<WarehouseShipmentPdfDocument> fetchEDespatchPdf({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    throw UnsupportedError(
      'Gelen depolar arasi sevkler ekraninda e-irsaliye PDF desteklenmiyor.',
    );
  }

  @override
  Future<List<WarehouseLookupItem>> searchWarehouses({
    required String accessToken,
    String? query,
  }) async {
    throw UnsupportedError(
      'Gelen depolar arasi sevkler ekraninda depo arama desteklenmiyor.',
    );
  }

  @override
  Future<List<ProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  }) async {
    throw UnsupportedError(
      'Gelen depolar arasi sevkler ekraninda urun arama desteklenmiyor.',
    );
  }
}
