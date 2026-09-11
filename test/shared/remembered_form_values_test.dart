import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/form_memory/remembered_form_values.dart';

void main() {
  group('RememberedFormValuesRepository.normalize', () {
    test('removes blanks and case-insensitive duplicates', () {
      final values = RememberedFormValuesRepository.normalize(const <String>[
        '  Ahmet Yilmaz  ',
        '',
        'ahmet yilmaz',
        'Mehmet Kaya',
      ]);

      expect(values, const <String>['Ahmet Yilmaz', 'Mehmet Kaya']);
    });

    test('keeps only the five most recent unique values', () {
      final values = RememberedFormValuesRepository.normalize(const <String>[
        'Bir',
        'Iki',
        'Uc',
        'Dort',
        'Bes',
        'Alti',
      ]);

      expect(values, const <String>['Bir', 'Iki', 'Uc', 'Dort', 'Bes']);
    });
  });

  testWidgets('shows recent values on focus and filters while typing', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RememberedTextFormField(
            warehouseNo: '56',
            field: RememberedFormField.receiver,
            controller: controller,
            repository: _FakeRememberedFormValuesRepository(),
            decoration: const InputDecoration(labelText: 'Teslim Alan'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    expect(find.text('Ahmet Yilmaz'), findsOneWidget);
    expect(find.text('Mehmet Kaya'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'meh');
    await tester.pump();
    expect(find.text('Ahmet Yilmaz'), findsNothing);
    expect(find.text('Mehmet Kaya'), findsOneWidget);

    await tester.tap(find.text('Mehmet Kaya'));
    await tester.pump();
    expect(controller.text, 'Mehmet Kaya');
  });
}

class _FakeRememberedFormValuesRepository
    extends RememberedFormValuesRepository {
  @override
  Future<List<String>> read({
    required String warehouseNo,
    required RememberedFormField field,
  }) async {
    return const <String>['Ahmet Yilmaz', 'Mehmet Kaya'];
  }
}
