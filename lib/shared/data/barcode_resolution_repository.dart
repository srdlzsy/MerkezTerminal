import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';

abstract class BarcodeResolutionRepository {
  Future<BarcodeResolutionResult> resolveBarcode({
    required String accessToken,
    required BarcodeResolutionRequest request,
  });
}

class ApiBarcodeResolutionRepository implements BarcodeResolutionRepository {
  const ApiBarcodeResolutionRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<BarcodeResolutionResult> resolveBarcode({
    required String accessToken,
    required BarcodeResolutionRequest request,
  }) async {
    final response = await _apiClient.getJsonMap(
      '/api/arama-islemleri/barkodlar/${request.encodedBarcode}/cozumle',
      accessToken: accessToken,
      queryParameters: request.toQueryParameters(),
    );

    return BarcodeResolutionResult.fromJson(response);
  }
}
