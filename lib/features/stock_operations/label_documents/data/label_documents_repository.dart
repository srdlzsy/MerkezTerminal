import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/label_documents/data/models/label_document_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';

abstract class LabelDocumentsRepository {
  Future<List<LabelDocumentListItem>> fetchRecentDocuments({
    required String accessToken,
    required String warehouseNo,
    int take,
  });

  Future<List<LabelDocumentListItem>> fetchAllDocuments({
    required String accessToken,
    required String warehouseNo,
  });

  Future<List<LabelDocumentProduct>> fetchDocumentProducts({
    required String accessToken,
    required int documentId,
    required String warehouseNo,
  });

  Future<List<LabelTag>> fetchTags({
    required String accessToken,
    required DateTime dateToGet,
  });

  Future<List<LabelPriceChangedProduct>> fetchPriceChangedProducts({
    required String accessToken,
    required DateTime dateTimeFilter,
  });

  Future<CreateLabelDocumentResult> createDocument({
    required String accessToken,
    required CreateLabelDocumentRequest request,
  });

  Future<List<SearchProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  });
}

class ApiLabelDocumentsRepository implements LabelDocumentsRepository {
  const ApiLabelDocumentsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<LabelDocumentListItem>> fetchRecentDocuments({
    required String accessToken,
    required String warehouseNo,
    int take = 10,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/stok-islemleri/etiket-belgeleri',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'warehouseNo': warehouseNo,
        'take': '$take',
      },
    );

    return response
        .map(
          (item) => LabelDocumentListItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<LabelDocumentListItem>> fetchAllDocuments({
    required String accessToken,
    required String warehouseNo,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/stok-islemleri/etiket-belgeleri/tumu',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
    );

    return response
        .map(
          (item) => LabelDocumentListItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<LabelDocumentProduct>> fetchDocumentProducts({
    required String accessToken,
    required int documentId,
    required String warehouseNo,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/stok-islemleri/etiket-belgeleri/$documentId',
      accessToken: accessToken,
      queryParameters: <String, String>{'warehouseNo': warehouseNo},
    );

    return response
        .map(
          (item) => LabelDocumentProduct.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<LabelTag>> fetchTags({
    required String accessToken,
    required DateTime dateToGet,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/stok-islemleri/etiket-belgeleri/etiketler',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'dateToGet': _toApiDate(dateToGet),
      },
    );

    return response
        .map(
          (item) => LabelTag.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<LabelPriceChangedProduct>> fetchPriceChangedProducts({
    required String accessToken,
    required DateTime dateTimeFilter,
  }) async {
    final response = await _apiClient.getJsonList(
      '/api/stok-islemleri/etiket-belgeleri/fiyati-degisen-urunler',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'dateTimeFilter': _toLegacyDateTime(dateTimeFilter),
      },
    );

    return response
        .map(
          (item) => LabelPriceChangedProduct.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<CreateLabelDocumentResult> createDocument({
    required String accessToken,
    required CreateLabelDocumentRequest request,
  }) async {
    final response = await _apiClient.postJsonMap(
      '/api/stok-islemleri/etiket-belgeleri',
      accessToken: accessToken,
      body: request.toJson(),
    );

    return CreateLabelDocumentResult.fromJson(response);
  }

  @override
  Future<List<SearchProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  }) async {
    final normalizedQuery = query.trim();
    final isBarcodeQuery = RegExp(r'^\d{8,}$').hasMatch(normalizedQuery);
    final isStockCodeQuery =
        !isBarcodeQuery &&
        normalizedQuery.contains(RegExp(r'\d')) &&
        !normalizedQuery.contains(' ');

    final response = await _apiClient.getJsonList(
      '/api/arama-islemleri/urunler',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'warehouseNo': warehouseNo,
        'take': '20',
        if (isBarcodeQuery)
          'barcode': normalizedQuery
        else if (isStockCodeQuery)
          'stockCode': normalizedQuery
        else
          'stockName': normalizedQuery,
      },
    );

    return response
        .map(
          (item) => SearchProductLookupItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }
}

String _toApiDate(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '${normalized.year}-$month-$day';
}

String _toLegacyDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final second = date.second.toString().padLeft(2, '0');
  return '$day.$month.${date.year} $hour:$minute:$second';
}
