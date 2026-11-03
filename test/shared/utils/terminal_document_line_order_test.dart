import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/utils/terminal_document_line_order.dart';

void main() {
  test('restores manual lines from newest-first UI order', () {
    expect(oldestEntryFirst(<String>['C', 'B', 'A']), <String>['A', 'B', 'C']);
  });

  test('keeps source lines and appends manual lines in entry order', () {
    const lines = <_Line>[
      _Line('manual-C'),
      _Line('manual-B'),
      _Line('manual-A'),
      _Line('order-1', source: true),
      _Line('order-2', source: true),
    ];

    expect(
      sourceLinesThenOldestManualEntry(
        lines,
        isSourceLine: (line) => line.source,
      ).map((line) => line.value),
      <String>['order-1', 'order-2', 'manual-A', 'manual-B', 'manual-C'],
    );
  });
}

class _Line {
  const _Line(this.value, {this.source = false});

  final String value;
  final bool source;
}
