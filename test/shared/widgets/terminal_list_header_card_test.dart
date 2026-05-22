import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

void main() {
  testWidgets('keeps date filters side by side on terminal width', (
    tester,
  ) async {
    var createTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: TerminalListHeaderCard(
                title: 'Firma Mal Kabulleri',
                subtitle: 'Gecmis fisleri listeler; yeni fis akisini yonetir.',
                infoChips: const <Widget>[
                  TerminalInfoChip(
                    label: 'Varsayilan depo',
                    value: '50 - MERKEZ DEPO',
                  ),
                  TerminalInfoChip(label: 'Kayit', value: '0'),
                ],
                filters: <Widget>[
                  TerminalFilterButton(
                    label: 'Baslangic',
                    value: '14.05.2026',
                    onPressed: () {},
                  ),
                  TerminalFilterButton(
                    label: 'Bitis',
                    value: '14.05.2026',
                    onPressed: () {},
                  ),
                ],
                actions: <Widget>[
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Listele'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Temizle'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      createTapCount += 1;
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Yeni Mal Kabul'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.text('Baslangic')).dy,
      tester.getTopLeft(find.text('Bitis')).dy,
    );
    expect(_buttonTop(tester, 'Listele'), _buttonTop(tester, 'Temizle'));
    expect(_buttonTop(tester, 'Listele'), _buttonTop(tester, 'Yeni Mal Kabul'));

    await tester.tap(find.text('Yeni Mal Kabul'));
    await tester.pump();

    expect(createTapCount, 1);
  });

  testWidgets('balances four header actions without a single-button row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: TerminalListHeaderCard(
                title: 'Firma Mal Kabulleri',
                filters: const <Widget>[],
                actions: <Widget>[
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Listele'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Temizle'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Yeni Mal Kabul'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.cloud_off_rounded),
                    label: const Text('Offline Taslaklar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_buttonTop(tester, 'Listele'), _buttonTop(tester, 'Temizle'));
    expect(
      _buttonTop(tester, 'Yeni Mal Kabul'),
      _buttonTop(tester, 'Offline Taslaklar'),
    );
    expect(
      _buttonTop(tester, 'Listele'),
      isNot(_buttonTop(tester, 'Yeni Mal Kabul')),
    );
  });

  testWidgets('keeps a single header action compact', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: TerminalListHeaderCard(
                title: 'Etiket Belgeleri',
                filters: const <Widget>[],
                actions: <Widget>[
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Yenile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(_buttonFinder('Yenile')).width, lessThan(180));
  });

  testWidgets('stacks form actions on tiny terminal width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: TerminalFormActionRow(
              cancel: OutlinedButton(
                onPressed: () {},
                child: const Text('Vazgec'),
              ),
              submit: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.save_rounded),
                label: const Text('Taslagi Kaydet'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      _buttonTop(tester, 'Vazgec'),
      lessThan(_buttonTop(tester, 'Taslagi Kaydet')),
    );
  });

  testWidgets('stacks lookup rows on tiny terminal width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: TerminalResponsiveLookupRow(
              field: const TextField(
                decoration: InputDecoration(labelText: 'Barkod'),
              ),
              action: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.search_rounded),
                label: const Text('Bul'),
              ),
              trailingAction: IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.photo_camera_back_rounded),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      _buttonTop(tester, 'Bul'),
      greaterThan(tester.getBottomLeft(find.text('Barkod')).dy),
    );
  });
}

double _buttonTop(WidgetTester tester, String label) {
  return tester.getTopLeft(_buttonFinder(label)).dy;
}

Finder _buttonFinder(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate(
      (widget) => widget is FilledButton || widget is OutlinedButton,
    ),
  );
}
