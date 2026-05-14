import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/models/virman_models.dart';

abstract class VirmanRepository {
  Future<List<VirmanListItem>> fetchVirmans({
    required String accessToken,
    required VirmanListFilter filter,
  });

  Future<VirmanDetail> fetchVirmanDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  });

  Future<VirmanCreateResult> createVirman({
    required String accessToken,
    required VirmanCreateRequest request,
  });
}

class ApiVirmanRepository implements VirmanRepository {
  const ApiVirmanRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<VirmanListItem>> fetchVirmans({
    required String accessToken,
    required VirmanListFilter filter,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/stok-islemleri/virmanlar',
      accessToken: accessToken,
      queryParameters: filter.toQueryParameters(),
    );

    return response
        .map(
          (item) =>
              VirmanListItem.fromJson(item as JsonMap? ?? <String, dynamic>{}),
        )
        .toList(growable: false);
  }

  @override
  Future<VirmanDetail> fetchVirmanDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/stok-islemleri/virmanlar/$documentSerie/$documentOrderNo',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
    );

    return VirmanDetail.fromJson(response);
  }

  @override
  Future<VirmanCreateResult> createVirman({
    required String accessToken,
    required VirmanCreateRequest request,
  }) async {
    final response = await _apiClient.postJsonMap(
      '/api/stok-islemleri/virmanlar',
      accessToken: accessToken,
      body: request.toJson(),
    );

    return VirmanCreateResult.fromJson(response);
  }
}
