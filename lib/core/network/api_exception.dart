class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.title,
    this.detail,
    this.errorCode,
    this.retryable,
    this.retryAfterSeconds,
    this.relatedClientRequestId,
    this.correlationId,
  });

  final int statusCode;
  final String title;
  final String? detail;
  final String? errorCode;
  final bool? retryable;
  final int? retryAfterSeconds;
  final String? relatedClientRequestId;
  final String? correlationId;

  String get message {
    final normalizedDetail = detail?.trim();
    final baseMessage = normalizedDetail == null || normalizedDetail.isEmpty
        ? title
        : '$title: $normalizedDetail';

    return messageWithSupportCode(baseMessage);
  }

  String messageWithSupportCode(String value) {
    final normalizedCorrelationId = correlationId?.trim() ?? '';
    if (normalizedCorrelationId.isEmpty ||
        value.contains('Destek kodu: $normalizedCorrelationId')) {
      return value;
    }

    return '$value\nDestek kodu: $normalizedCorrelationId';
  }

  @override
  String toString() => message;
}
