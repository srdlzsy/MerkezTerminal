abstract final class AppFormatters {
  static String currency(num value) {
    return '${number(value)} TL';
  }

  static String date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');

    return '$day.$month.${value.year}';
  }

  static String dateOrDash(DateTime? value) {
    if (value == null) {
      return '-';
    }

    return date(value);
  }

  static String dateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '${date(value)} $hour:$minute';
  }

  static String dateTimeOrDash(DateTime? value) {
    if (value == null) {
      return '-';
    }

    return dateTime(value);
  }

  static String number(num value) {
    final normalized = value.toDouble();
    final hasFraction = normalized % 1 != 0;
    final raw = hasFraction
        ? normalized.toStringAsFixed(2)
        : normalized.toStringAsFixed(0);
    final parts = raw.split('.');
    final integerPart = parts.first;
    final buffer = StringBuffer();

    for (var index = 0; index < integerPart.length; index++) {
      final reversedIndex = integerPart.length - index;
      buffer.write(integerPart[index]);
      if (reversedIndex > 1 && reversedIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    if (!hasFraction) {
      return buffer.toString();
    }

    return '${buffer.toString()},${parts.last}';
  }

  static String quantity(num value) {
    return number(value);
  }
}
