import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

void main() {
  testWidgets('filters passive products and keeps active selection available', (
    tester,
  ) async {
    String? selected;
    final includeDelistedRequests = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                selected = await showTerminalProductSelectionSheet<String>(
                  context: context,
                  items: const <String>['Aktif urun', 'Pasif urun'],
                  reloadItems: ({required bool includeDelisted}) async {
                    includeDelistedRequests.add(includeDelisted);
                    return includeDelisted
                        ? const <String>['Aktif urun', 'Pasif urun']
                        : const <String>['Aktif urun'];
                  },
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
    expect(includeDelistedRequests, <bool>[false]);

    await tester.tap(find.text('Aktif urun'));
    await tester.pumpAndSettle();

    expect(selected, 'Aktif urun');
  });

  testWidgets('shows product source information without blocking selection', (
    tester,
  ) async {
    var selected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TerminalProductLookupTile(
            title: '010416 - DOMATES',
            subtitle: 'ADET | 25,00 TL',
            informationLabels: const <String>[
              'Model 10',
              'MANAV DEPO 56',
              'Firma Urunu',
              'Karisik Kaynak',
            ],
            onTap: () => selected = true,
          ),
        ),
      ),
    );

    expect(find.text('Model 10'), findsOneWidget);
    expect(find.text('MANAV DEPO 56'), findsOneWidget);
    expect(find.text('Firma Urunu'), findsOneWidget);
    expect(find.text('Karisik Kaynak'), findsOneWidget);

    await tester.tap(find.text('010416 - DOMATES'));
    expect(selected, isTrue);
  });
}
