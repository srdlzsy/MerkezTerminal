import 'dart:convert';

class EDespatchQrPayload {
  const EDespatchQrPayload({
    required this.ettn,
    required this.documentNo,
    required this.issueDate,
    required this.actualDespatchDate,
    required this.actualDespatchTime,
    required this.senderTaxNoOrTckn,
    required this.receiverTaxNoOrTckn,
    required this.scenario,
    required this.documentTypeCode,
    required this.carrierTaxNoOrTckn,
    required this.licensePlate,
    required this.currencyCode,
    required this.goodsServicesTotalAmount,
    required this.taxInclusiveAmount,
    required this.payableAmount,
    required this.vatBaseAmounts,
    required this.calculatedVatAmounts,
  });

  final String? ettn;
  final String? documentNo;
  final DateTime? issueDate;
  final DateTime? actualDespatchDate;
  final String? actualDespatchTime;
  final String? senderTaxNoOrTckn;
  final String? receiverTaxNoOrTckn;
  final String? scenario;
  final String? documentTypeCode;
  final String? carrierTaxNoOrTckn;
  final String? licensePlate;
  final String? currencyCode;
  final double? goodsServicesTotalAmount;
  final double? taxInclusiveAmount;
  final double? payableAmount;
  final Map<String, double> vatBaseAmounts;
  final Map<String, double> calculatedVatAmounts;

  bool get hasDocumentPrefill =>
      (documentNo?.trim().isNotEmpty ?? false) || issueDate != null;

  bool get hasShippingInfo =>
      actualDespatchDate != null ||
      (actualDespatchTime?.trim().isNotEmpty ?? false) ||
      (carrierTaxNoOrTckn?.trim().isNotEmpty ?? false) ||
      (licensePlate?.trim().isNotEmpty ?? false);

  bool get hasMonetaryInfo =>
      (currencyCode?.trim().isNotEmpty ?? false) ||
      goodsServicesTotalAmount != null ||
      taxInclusiveAmount != null ||
      payableAmount != null ||
      vatBaseAmounts.isNotEmpty ||
      calculatedVatAmounts.isNotEmpty;
}

EDespatchQrPayload parseEDespatchQrPayload(String rawValue) {
  final jsonFields = _decodeQrJsonFields(rawValue);
  final ettnField = _extractFirstQrField(rawValue, jsonFields, const <String>[
    'ettn',
  ]);
  final actualDespatchTimeField = _extractFirstQrField(
    rawValue,
    jsonFields,
    const <String>['sevkzamani', 'sevk_zamani'],
    fieldPatterns: const <String>[r'sevkzaman[^A-Za-z0-9]*'],
  );

  return EDespatchQrPayload(
    ettn: extractEDespatchEttn(ettnField ?? rawValue),
    documentNo: _extractFirstQrField(rawValue, jsonFields, const <String>[
      'no',
    ]),
    issueDate: _parseQrDate(
      _extractFirstQrField(
        rawValue,
        jsonFields,
        const <String>['tarih'],
        fieldPatterns: const <String>[r'tar[^A-Za-z0-9]*h'],
      ),
    ),
    actualDespatchDate: _parseQrDate(
      _extractFirstQrField(
        rawValue,
        jsonFields,
        const <String>['sevktarihi', 'sevk_tarihi'],
        fieldPatterns: const <String>[r'sevktar[^A-Za-z0-9]*h[^A-Za-z0-9]*'],
      ),
    ),
    actualDespatchTime:
        _parseQrTime(actualDespatchTimeField) ??
        _extractQrTimeValue(rawValue, const <String>[
          'sevkzamani',
          'sevk_zamani',
          r'sevkzaman[^A-Za-z0-9]*',
        ]),
    senderTaxNoOrTckn: _extractFirstQrField(
      rawValue,
      jsonFields,
      const <String>['vkntckn'],
    ),
    receiverTaxNoOrTckn: _extractFirstQrField(
      rawValue,
      jsonFields,
      const <String>['avkntckn'],
    ),
    scenario: _extractFirstQrField(rawValue, jsonFields, const <String>[
      'senaryo',
    ]),
    documentTypeCode: _extractFirstQrField(
      rawValue,
      jsonFields,
      const <String>['tip'],
      fieldPatterns: const <String>[r't[^A-Za-z0-9]*p'],
    ),
    carrierTaxNoOrTckn: _extractFirstQrField(
      rawValue,
      jsonFields,
      const <String>['tasiyicivkn', 'tasiyici_vkn'],
      fieldPatterns: const <String>[
        r'tas[^A-Za-z0-9]*y[^A-Za-z0-9]*c[^A-Za-z0-9]*vkn',
        r'ta[^A-Za-z0-9]*y[^A-Za-z0-9]*c[^A-Za-z0-9]*vkn',
      ],
    ),
    licensePlate: _extractFirstQrField(rawValue, jsonFields, const <String>[
      'plaka',
    ]),
    currencyCode: _extractFirstQrField(rawValue, jsonFields, const <String>[
      'parabirimi',
      'para_birimi',
    ]),
    goodsServicesTotalAmount: _parseQrDecimal(
      _extractFirstQrField(rawValue, jsonFields, const <String>[
        'malhizmettoplam',
        'mal_hizmet_toplam',
      ]),
    ),
    taxInclusiveAmount: _parseQrDecimal(
      _extractFirstQrField(rawValue, jsonFields, const <String>['vergidahil']),
    ),
    payableAmount: _parseQrDecimal(
      _extractFirstQrField(
        rawValue,
        jsonFields,
        const <String>['odenecek'],
        fieldPatterns: const <String>[r'[^A-Za-z0-9]*denecek'],
      ),
    ),
    vatBaseAmounts: _extractRatedAmounts(
      rawValue,
      jsonFields,
      prefix: 'kdvmatrah',
    ),
    calculatedVatAmounts: _extractRatedAmounts(
      rawValue,
      jsonFields,
      prefix: 'hesaplanankdv',
    ),
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

Map<String, String> _decodeQrJsonFields(String rawValue) {
  final trimmed = rawValue.trim();
  if (!trimmed.startsWith('{')) {
    return const <String, String>{};
  }

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is! Map<String, dynamic>) {
      return const <String, String>{};
    }

    return decoded.map((key, value) {
      return MapEntry(_canonicalQrKey(key), value?.toString().trim() ?? '');
    });
  } catch (_) {
    return const <String, String>{};
  }
}

String? _extractFirstQrField(
  String rawValue,
  Map<String, String> jsonFields,
  List<String> fieldNames, {
  List<String> fieldPatterns = const <String>[],
}) {
  for (final fieldName in fieldNames) {
    final value = jsonFields[_canonicalQrKey(fieldName)]?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  for (final fieldName in fieldNames) {
    final value = _extractQrField(rawValue, RegExp.escape(fieldName));
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  for (final fieldPattern in fieldPatterns) {
    final value = _extractQrField(rawValue, fieldPattern);
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  return null;
}

String? _extractQrField(String rawValue, String fieldName) {
  final match = RegExp(
    '(?:^|[^A-Za-z0-9])$fieldName(?:[^A-Za-z0-9]+)([A-Za-z0-9*._:,-]+)',
    caseSensitive: false,
  ).firstMatch(rawValue);
  final value = match?.group(1)?.trim();

  if (value == null || value.isEmpty) {
    return null;
  }

  return value;
}

String? _extractQrTimeValue(String rawValue, List<String> fieldPatterns) {
  for (final fieldPattern in fieldPatterns) {
    final match = RegExp(
      '(?:^|[^A-Za-z0-9])$fieldPattern(?:[^A-Za-z0-9]+)'
      r'([0-9]{1,2})(?:[^0-9]+)([0-9]{1,2})(?:(?:[^0-9]+)([0-9]{1,2}))?',
      caseSensitive: false,
    ).firstMatch(rawValue);
    if (match == null) {
      continue;
    }

    final rawTime = <String>[
      match.group(1) ?? '',
      match.group(2) ?? '',
      match.group(3) ?? '0',
    ].join(':');
    final parsedTime = _parseQrTime(rawTime);
    if (parsedTime != null) {
      return parsedTime;
    }
  }

  return null;
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

String? _parseQrTime(String? rawValue) {
  final matches = RegExp(
    r'\d{1,2}',
  ).allMatches(rawValue?.trim() ?? '').take(3).toList(growable: false);
  if (matches.length < 2) {
    return null;
  }

  final hour = int.tryParse(matches[0].group(0) ?? '');
  final minute = int.tryParse(matches[1].group(0) ?? '');
  final second = matches.length > 2
      ? int.tryParse(matches[2].group(0) ?? '')
      : 0;
  if (hour == null ||
      minute == null ||
      second == null ||
      hour > 23 ||
      minute > 59 ||
      second > 59) {
    return null;
  }

  return '${_twoDigits(hour)}:${_twoDigits(minute)}:${_twoDigits(second)}';
}

double? _parseQrDecimal(String? rawValue) {
  final value = rawValue?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }

  var normalized = value.replaceAll(RegExp(r'[^0-9,.-]'), '');
  if (normalized.isEmpty) {
    return null;
  }

  final lastComma = normalized.lastIndexOf(',');
  final lastDot = normalized.lastIndexOf('.');
  if (lastComma >= 0 && lastDot >= 0) {
    if (lastComma > lastDot) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = normalized.replaceAll(',', '');
    }
  } else if (lastComma >= 0) {
    normalized = normalized.replaceAll(',', '.');
  }

  return double.tryParse(normalized);
}

Map<String, double> _extractRatedAmounts(
  String rawValue,
  Map<String, String> jsonFields, {
  required String prefix,
}) {
  final result = <String, double>{};
  final canonicalPrefix = _canonicalQrKey(prefix);
  final fieldPattern = RegExp(
    '^${RegExp.escape(canonicalPrefix)}\\(([^)]+)\\)',
  );
  for (final entry in jsonFields.entries) {
    final match = fieldPattern.firstMatch(entry.key);
    if (match == null) {
      continue;
    }

    final amount = _parseQrDecimal(entry.value);
    final rate = match.group(1)?.trim();
    if (amount != null && rate != null && rate.isNotEmpty) {
      result[rate] = amount;
    }
  }

  final rawPattern = RegExp(
    '(?:^|[^A-Za-z0-9])${RegExp.escape(prefix)}(?:[^A-Za-z0-9]*)'
    r'\(([^)]+)\)(?:[^A-Za-z0-9]+)([A-Za-z0-9*._:,-]+)',
    caseSensitive: false,
  );
  for (final match in rawPattern.allMatches(rawValue)) {
    final amount = _parseQrDecimal(match.group(2));
    final rate = match.group(1)?.trim();
    if (amount != null && rate != null && rate.isNotEmpty) {
      result.putIfAbsent(rate, () => amount);
    }
  }

  return Map<String, double>.unmodifiable(result);
}

String _canonicalQrKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ş', 's')
      .replaceAll('Ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('Ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('Ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('Ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll('Ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9()]+'), '');
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
