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

  double readQuantity(String value, {required double fallback}) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
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
