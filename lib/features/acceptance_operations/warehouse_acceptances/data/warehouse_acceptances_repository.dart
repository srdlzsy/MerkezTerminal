import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/models/warehouse_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';

abstract class WarehouseAcceptancesRepository {
  Future<List<WarehouseAcceptanceListItem>> fetchAcceptances({
    required String accessToken,
    required WarehouseAcceptanceListFilter filter,
  });

  Future<WarehouseAcceptanceDetail> fetchAcceptanceDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  });

  Future<WarehouseAcceptanceResult> acceptShipment({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required WarehouseAcceptanceRequest request,
  });
}

class ApiWarehouseAcceptancesRepository
    implements WarehouseAcceptancesRepository {
  const ApiWarehouseAcceptancesRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<WarehouseAcceptanceListItem>> fetchAcceptances({
    required String accessToken,
    required WarehouseAcceptanceListFilter filter,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/mal-kabul-islemleri/depo-mal-kabulleri',
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
  Future<WarehouseAcceptanceDetail> fetchAcceptanceDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/mal-kabul-islemleri/depo-mal-kabulleri/'
      '$documentSerie/$documentOrderNo',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
    );

    return WarehouseAcceptanceDetail.fromJson(response);
  }

  @override
  Future<WarehouseAcceptanceResult> acceptShipment({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required WarehouseAcceptanceRequest request,
  }) async {
    final response = await _apiClient.postJsonMap(
      '/api/mal-kabul-islemleri/depo-mal-kabulleri/'
      '$documentSerie/$documentOrderNo/kabul',
      accessToken: accessToken,
      body: request.toJson(),
    );

    return WarehouseAcceptanceResult.fromJson(response);
  }
}
