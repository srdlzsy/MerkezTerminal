import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

void main() {
  testWidgets('filters passive products and keeps active selection available', (
    tester,
  ) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                selected = await showTerminalProductSelectionSheet<String>(
                  context: context,
                  items: const <String>['Aktif urun', 'Pasif urun'],
                  needsStatusAttention: (item) => item.startsWith('Pasif'),
                  itemBuilder: (context, item, onSelect) =>
                      ListTile(title: Text(item), onTap: onSelect),
                );
              },
              child: const Text('Urun sec'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Urun sec'));
    await tester.pumpAndSettle();

    expect(find.text('Aktif urun'), findsOneWidget);
    expect(find.text('Pasif urun'), findsOneWidget);

    await tester.tap(find.text('Pasif/DLS gizle'));
    await tester.pumpAndSettle();

    expect(find.text('Aktif urun'), findsOneWidget);
    expect(find.text('Pasif urun'), findsNothing);

    await tester.tap(find.text('Aktif urun'));
    await tester.pumpAndSettle();

    expect(selected, 'Aktif urun');
  });
}
