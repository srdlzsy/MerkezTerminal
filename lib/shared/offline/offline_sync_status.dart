typedef OfflineSyncResultParser<T> = T Function(Map<String, dynamic> json);

abstract interface class OfflineSyncStatusProvider<T> {
  Future<OfflineSyncStatus<T>> fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
  });
}

abstract interface class OfflineSyncRecheckProvider<T> {
  Future<OfflineSyncStatus<T>> recheckOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
    required String operationCode,
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
    this.recoveryState,
    this.recommendedAction,
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
  final String? recoveryState;
  final String? recommendedAction;

  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  DateTime? retryNotBefore([DateTime? now]) {
    if (recommendedAction?.trim() == 'WaitAndCheck') {
      final seconds = retryAfterSeconds;
      return (now ?? DateTime.now()).add(
        Duration(seconds: seconds != null && seconds > 0 ? seconds : 5),
      );
    }
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
      recoveryState: _readNullableString(json['recoveryState']),
      recommendedAction: _readNullableString(json['recommendedAction']),
    );
  }

  factory OfflineSyncStatus.fromReviewJson(
    Map<String, dynamic> json, {
    required String fallbackClientRequestId,
    required String fallbackOperationCode,
    required OfflineSyncResultParser<T> resultParser,
  }) {
    final safeWriteValue = json['safeWrite'];
    final safeWrite = safeWriteValue is Map
        ? safeWriteValue.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    final resultJson = json['result'];
    final outcome = _readNullableString(json['outcome']);
    final status =
        _readNullableString(safeWrite['status']) ??
        _readNullableString(json['status']) ??
        (outcome == 'Completed' || outcome == 'AlreadyCompleted'
            ? 'Completed'
            : outcome == 'Cancelled' || outcome == 'AlreadyCancelled'
            ? 'Cancelled'
            : 'Failed');
    return OfflineSyncStatus<T>(
      clientRequestId:
          _readNullableString(safeWrite['clientRequestId']) ??
          _readNullableString(json['clientRequestId']) ??
          fallbackClientRequestId,
      operationCode:
          _readNullableString(safeWrite['operationCode']) ??
          _readNullableString(json['operationCode']) ??
          fallbackOperationCode,
      status: status,
      createdAtUtc: _readDate(
        safeWrite['createdAtUtc'] ?? json['createdAtUtc'],
      ),
      completedAtUtc: _readDate(
        safeWrite['completedAtUtc'] ?? json['completedAtUtc'],
      ),
      errorMessage:
          _readNullableString(safeWrite['errorMessage']) ??
          _readNullableString(json['errorMessage']) ??
          _readNullableString(json['message']),
      errorCode:
          _readNullableString(safeWrite['errorCode']) ??
          _readNullableString(json['errorCode']),
      retryable: _readBool(safeWrite['retryable'] ?? json['retryable']),
      retryAfterSeconds: _readInt(
        safeWrite['retryAfterSeconds'] ?? json['retryAfterSeconds'],
      ),
      result: resultJson is Map
          ? resultParser(
              resultJson.map((key, value) => MapEntry(key.toString(), value)),
            )
          : null,
      recoveryState: _readNullableString(json['recoveryState']),
      recommendedAction: _readNullableString(json['recommendedAction']),
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
