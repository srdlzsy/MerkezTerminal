class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.title,
    this.detail,
    this.errorCode,
    this.retryable,
    this.correlationId,
  });

  final int statusCode;
  final String title;
  final String? detail;
  final String? errorCode;
  final bool? retryable;
  final String? correlationId;

  String get message {
    final normalizedDetail = detail?.trim();

    if (normalizedDetail == null || normalizedDetail.isEmpty) {
      return title;
    }

    return '$title: $normalizedDetail';
  }

  @override
  String toString() => message;
}
