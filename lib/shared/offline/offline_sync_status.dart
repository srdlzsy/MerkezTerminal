typedef OfflineSyncResultParser<T> = T Function(Map<String, dynamic> json);

abstract interface class OfflineSyncStatusProvider<T> {
  Future<OfflineSyncStatus<T>> fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
  });
}

class OfflineSyncStatus<T> {
  const OfflineSyncStatus({
    required this.clientRequestId,
    required this.operationCode,
    required this.status,
    required this.createdAtUtc,
    required this.completedAtUtc,
    required this.errorMessage,
    required this.errorCode,
    required this.retryable,
    required this.retryAfterSeconds,
    required this.result,
  });

  final String clientRequestId;
  final String operationCode;
  final String status;
  final DateTime? createdAtUtc;
  final DateTime? completedAtUtc;
  final String? errorMessage;
  final String? errorCode;
  final bool? retryable;
  final int? retryAfterSeconds;
  final T? result;

  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isFailed => status.toLowerCase() == 'failed';

  DateTime? retryNotBefore([DateTime? now]) {
    final seconds = retryAfterSeconds;
    if (retryable != true || seconds == null || seconds <= 0) {
      return null;
    }
    return (now ?? DateTime.now()).add(Duration(seconds: seconds));
  }

  factory OfflineSyncStatus.fromJson(
    Map<String, dynamic> json, {
    required OfflineSyncResultParser<T> resultParser,
  }) {
    final resultJson = json['result'];
    return OfflineSyncStatus<T>(
      clientRequestId: _readString(json['clientRequestId']),
      operationCode: _readString(json['operationCode']),
      status: _readString(json['status']),
      createdAtUtc: _readDate(json['createdAtUtc']),
      completedAtUtc: _readDate(json['completedAtUtc']),
      errorMessage: _readNullableString(json['errorMessage']),
      errorCode: _readNullableString(json['errorCode']),
      retryable: _readBool(json['retryable']),
      retryAfterSeconds: _readInt(json['retryAfterSeconds']),
      result: resultJson is Map
          ? resultParser(
              resultJson.map((key, value) => MapEntry(key.toString(), value)),
            )
          : null,
    );
  }
}

String _readString(Object? value) => value?.toString() ?? '';

String? _readNullableString(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

DateTime? _readDate(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : DateTime.tryParse(normalized);
}

bool? _readBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true') return true;
  if (normalized == 'false') return false;
  return null;
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
