class ProductEntryLine {
  const ProductEntryLine({
    required this.barcode,
    required this.stockCode,
    required this.quantityText,
  });

  final String barcode;
  final String stockCode;
  final String quantityText;
}

class ProductEntryDuplicateMergePolicy<TLine> {
  const ProductEntryDuplicateMergePolicy({
    required this.currentLine,
    required this.targetBarcode,
    required this.targetStockCode,
    required this.lines,
    required this.lineBarcode,
    required this.lineStockCode,
    this.canMergeLine,
  });

  final TLine currentLine;
  final String targetBarcode;
  final String targetStockCode;
  final Iterable<TLine> lines;
  final String Function(TLine line) lineBarcode;
  final String Function(TLine line) lineStockCode;
  final bool Function(TLine line)? canMergeLine;
}

class ProductEntryController {
  const ProductEntryController();

  String? productIdentity({
    required String barcode,
    required String stockCode,
  }) {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isNotEmpty) {
      return 'b:$normalizedBarcode';
    }

    final normalizedStockCode = stockCode.trim();
    if (normalizedStockCode.isNotEmpty) {
      return 's:$normalizedStockCode';
    }

    return null;
  }

  bool isSameProduct({
    required String firstStockCode,
    required String firstBarcode,
    required String secondStockCode,
    required String secondBarcode,
  }) {
    final normalizedFirstStockCode = firstStockCode.trim().toUpperCase();
    final normalizedSecondStockCode = secondStockCode.trim().toUpperCase();
    if (normalizedFirstStockCode.isNotEmpty &&
        normalizedFirstStockCode == normalizedSecondStockCode) {
      return true;
    }

    final normalizedFirstBarcode = firstBarcode.trim().toUpperCase();
    final normalizedSecondBarcode = secondBarcode.trim().toUpperCase();
    return normalizedFirstBarcode.isNotEmpty &&
        normalizedFirstBarcode == normalizedSecondBarcode;
  }

  String productKey({
    required String stockCode,
    required String barcode,
    String scope = '',
  }) {
    final normalizedScope = scope.trim().toUpperCase();
    final normalizedStockCode = stockCode.trim().toUpperCase();
    final normalizedBarcode = barcode.trim().toUpperCase();

    final identity = normalizedStockCode.isNotEmpty
        ? 'S:$normalizedStockCode'
        : normalizedBarcode.isNotEmpty
        ? 'B:$normalizedBarcode'
        : '';

    if (identity.isEmpty) {
      return '';
    }

    return normalizedScope.isEmpty ? identity : '$normalizedScope|$identity';
  }

  double readQuantity(String value, {required double fallback}) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
  }

  bool isPositiveQuantityText(String value) {
    return readQuantity(value, fallback: 0) > 0;
  }

  double unitMultiplierQuantity(double unitMultiplier) {
    return unitMultiplier > 0 ? unitMultiplier : 1;
  }

  double quantityInputOrUnitMultiplier(String raw, double unitMultiplier) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return unitMultiplierQuantity(unitMultiplier);
    }

    final parsed = double.tryParse(normalized.replaceAll(',', '.'));
    return parsed != null && parsed > 0
        ? parsed
        : unitMultiplierQuantity(unitMultiplier);
  }

  String formatQuantity(double value) {
    final fixed = value.toStringAsFixed(6);
    final normalized = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    return normalized.replaceAll('.', ',');
  }

  String mergedQuantityText({
    required String existingQuantityText,
    required String incomingQuantityText,
    required double unitMultiplier,
  }) {
    return formatQuantity(
      readQuantity(existingQuantityText, fallback: 0) +
          quantityInputOrUnitMultiplier(incomingQuantityText, unitMultiplier),
    );
  }

  bool shouldConfirmDuplicateIncrease({
    required String existingQuantityText,
    required String productKey,
    required String? lastAddedProductKey,
  }) {
    return isPositiveQuantityText(existingQuantityText) &&
        productKey.trim().isNotEmpty &&
        lastAddedProductKey != productKey;
  }

  TLine? findDuplicateLine<TLine>(
    ProductEntryDuplicateMergePolicy<TLine> policy,
  ) {
    final targetIdentity = productIdentity(
      barcode: policy.targetBarcode,
      stockCode: policy.targetStockCode,
    );

    if (targetIdentity == null) {
      return null;
    }

    for (final candidate in policy.lines) {
      if (identical(candidate, policy.currentLine)) {
        continue;
      }

      final canMergeLine = policy.canMergeLine;
      if (canMergeLine != null && !canMergeLine(candidate)) {
        continue;
      }

      final candidateIdentity = productIdentity(
        barcode: policy.lineBarcode(candidate),
        stockCode: policy.lineStockCode(candidate),
      );

      if (candidateIdentity == targetIdentity) {
        return candidate;
      }
    }

    return null;
  }
}

const productEntryController = ProductEntryController();
