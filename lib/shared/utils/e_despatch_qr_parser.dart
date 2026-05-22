class EDespatchQrPayload {
  const EDespatchQrPayload({
    required this.ettn,
    required this.documentNo,
    required this.issueDate,
    required this.actualDespatchDate,
    required this.senderTaxNoOrTckn,
    required this.receiverTaxNoOrTckn,
  });

  final String? ettn;
  final String? documentNo;
  final DateTime? issueDate;
  final DateTime? actualDespatchDate;
  final String? senderTaxNoOrTckn;
  final String? receiverTaxNoOrTckn;

  bool get hasDocumentPrefill =>
      (documentNo?.trim().isNotEmpty ?? false) || issueDate != null;
}

EDespatchQrPayload parseEDespatchQrPayload(String rawValue) {
  return EDespatchQrPayload(
    ettn: extractEDespatchEttn(rawValue),
    documentNo: _extractQrField(rawValue, 'no'),
    issueDate: _parseQrDate(
      _extractQrField(rawValue, 'tarih') ??
          _extractQrField(rawValue, r'tar[^A-Za-z0-9]h'),
    ),
    actualDespatchDate: _parseQrDate(
      _extractQrField(rawValue, 'sevktarihi') ??
          _extractQrField(rawValue, 'sevk_tarihi') ??
          _extractQrField(rawValue, r'sevktar[^A-Za-z0-9]h'),
    ),
    senderTaxNoOrTckn: _extractQrField(rawValue, 'vkntckn'),
    receiverTaxNoOrTckn: _extractQrField(rawValue, 'avkntckn'),
  );
}

String? extractEDespatchEttn(String rawValue) {
  final normalized = rawValue.trim();
  if (normalized.isEmpty) {
    return null;
  }

  final separatedUuidMatch = RegExp(
    r'[0-9a-fA-F]{8}[-*][0-9a-fA-F]{4}[-*][1-5][0-9a-fA-F]{3}[-*]'
    r'[89abAB][0-9a-fA-F]{3}[-*][0-9a-fA-F]{12}',
  ).firstMatch(normalized);
  if (separatedUuidMatch != null) {
    return separatedUuidMatch.group(0)!.replaceAll('*', '-').toLowerCase();
  }

  final compactMatch = RegExp(r'\b[0-9a-fA-F]{32}\b').firstMatch(normalized);
  if (compactMatch == null) {
    return null;
  }

  final compact = compactMatch.group(0)!.toLowerCase();
  return '${compact.substring(0, 8)}-${compact.substring(8, 12)}-'
      '${compact.substring(12, 16)}-${compact.substring(16, 20)}-'
      '${compact.substring(20)}';
}

String? _extractQrField(String rawValue, String fieldName) {
  final match = RegExp(
    '(?:^|[^A-Za-z0-9])$fieldName(?:[^A-Za-z0-9]+)([A-Za-z0-9*._-]+)',
    caseSensitive: false,
  ).firstMatch(rawValue);
  final value = match?.group(1)?.trim();

  if (value == null || value.isEmpty) {
    return null;
  }

  return value;
}

DateTime? _parseQrDate(String? rawValue) {
  final normalized = rawValue
      ?.trim()
      .replaceAll('*', '-')
      .replaceAll('/', '-')
      .replaceAll('.', '-');

  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return DateTime.tryParse(normalized);
}
