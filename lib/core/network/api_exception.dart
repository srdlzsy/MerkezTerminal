class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.title,
    this.detail,
  });

  final int statusCode;
  final String title;
  final String? detail;

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
