import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_status.dart';

Future<OfflineSyncStatus<T>> recheckMobileSafeWrite<T>({
  required ApiClient apiClient,
  required String accessToken,
  required String clientRequestId,
  required String operationCode,
  required OfflineSyncResultParser<T> resultParser,
}) async {
  final response = await apiClient.postJsonMap(
    '/api/mobile-sync/guvenli-yazmalar/$clientRequestId/yeniden-dogrula',
    accessToken: accessToken,
    body: <String, dynamic>{'operationCode': operationCode},
  );
  return OfflineSyncStatus<T>.fromReviewJson(
    response,
    fallbackClientRequestId: clientRequestId,
    fallbackOperationCode: operationCode,
    resultParser: resultParser,
  );
}
