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
    this.recoveryState,
    this.recommendedAction,
  });

  final int statusCode;
  final String title;
  final String? detail;
  final String? errorCode;
  final bool? retryable;
  final int? retryAfterSeconds;
  final String? relatedClientRequestId;
  final String? correlationId;
  final String? recoveryState;
  final String? recommendedAction;

  String get message {
    final localizedTitle = userFacingTitle(statusCode, title);
    final normalizedDetail = userFacingDetail(statusCode, detail)?.trim();
    final baseMessage = normalizedDetail == null || normalizedDetail.isEmpty
        ? localizedTitle
        : '$localizedTitle: $normalizedDetail';

    return messageWithSupportCode(baseMessage);
  }

  static String userFacingTitle(int statusCode, String value) {
    final normalized = value.trim().toLowerCase();
    final isGenericEnglishTitle = const <String>{
      'bad request',
      'unauthorized',
      'forbidden',
      'not found',
      'conflict',
      'bad gateway',
      'service unavailable',
      'gateway timeout',
      'internal server error',
      'server error',
      'timeout',
      'request failed',
      'istek basarisiz',
    }.contains(normalized);

    if (!isGenericEnglishTitle &&
        value.trim().isNotEmpty &&
        !_looksTechnicalOrEnglish(value)) {
      return value.trim();
    }

    return switch (statusCode) {
      0 => 'Baglanti hatasi',
      400 => 'Gecersiz istek',
      401 => 'Oturum gecersiz',
      403 => 'Yetki yetersiz',
      404 => 'Kayit bulunamadi',
      409 => 'Islem cakismasi',
      502 => 'Dis servis hatasi',
      503 => 'Servis gecici olarak kullanilamiyor',
      504 => 'Islem zaman asimina ugradi',
      _ when statusCode >= 500 => 'Sunucu hatasi',
      _ => 'Islem tamamlanamadi',
    };
  }

  static String? userFacingDetail(int statusCode, String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isNotEmpty && !_looksTechnicalOrEnglish(normalized)) {
      return normalized;
    }

    return switch (statusCode) {
      0 =>
        'Sunucuya baglanilamadi. Internet baglantisini kontrol edip yeniden deneyin.',
      400 => 'Eksik veya hatali alanlari kontrol edip yeniden kaydedin.',
      401 => 'Oturumunuzun suresi dolmus olabilir. Lutfen tekrar giris yapin.',
      403 => 'Bu islemi yapmak icin yetkiniz bulunmuyor.',
      404 => 'Aradiginiz kayit bulunamadi. Listeyi yenileyip kontrol edin.',
      409 =>
        'Islem mevcut bir kayitla veya devam eden baska bir islemle cakisti. Ekrani yenileyip kontrol edin.',
      502 =>
        'Bagli dis servisten yanit alinamadi. Kisa bir sure sonra yeniden deneyin.',
      503 =>
        'Sunucu gecici olarak kullanilamiyor. Kisa bir sure sonra yeniden deneyin.',
      504 =>
        'Islem zamaninda tamamlanamadi. Kisa bir sure sonra yeniden deneyin.',
      _ when statusCode >= 500 =>
        'Beklenmeyen bir sunucu hatasi olustu. Yeniden deneyin; sorun surerse destek kodunu yetkiliye iletin.',
      _ => normalized.isEmpty ? null : normalized,
    };
  }

  static bool _looksTechnicalOrEnglish(String value) {
    final normalized = value.toLowerCase();
    return const <String>[
      ' is required',
      ' was not found',
      ' must be ',
      ' can not ',
      ' cannot ',
      ' could not ',
      ' does not ',
      ' did not ',
      ' already exists',
      ' at least ',
      ' invalid ',
      ' is invalid',
      'invalid or expired',
      ' failed',
      'unexpected error',
      'execution strategy',
      'user-initiated transaction',
      'null check operator',
      'null reference',
      'stack trace',
      'socketexception',
      'clientexception',
      'expired',
      'unauthorized',
      'forbidden',
      'duplicate key',
    ].any(normalized.contains);
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

String userFacingErrorMessage(Object error) {
  if (error is ApiException) {
    return error.message;
  }

  final raw = error.toString().replaceFirst('Exception: ', '').trim();
  final normalized = raw.toLowerCase();
  if (raw.isEmpty ||
      const <String>[
        'null check operator',
        'null reference',
        'stack trace',
        'typeerror',
        'nosuchmethoderror',
        'rangeerror',
        'socketexception',
        'clientexception',
      ].any(normalized.contains)) {
    return 'Islem sirasinda beklenmeyen bir hata olustu. Formdaki bilgiler korundu; yeniden deneyin.';
  }

  return raw;
}
