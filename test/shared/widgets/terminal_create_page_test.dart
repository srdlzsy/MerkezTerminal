import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_create_page.dart';

void main() {
  testWidgets('keeps create form open until inline submit succeeds', (
    tester,
  ) async {
    final firstDecision = Completer<bool>();
    var submitCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  unawaited(
                    openTerminalCreatePage<String>(
                      context: context,
                      title: 'Yeni Kayit',
                      builder: (context) => Center(
                        child: FilledButton(
                          onPressed: () => TerminalCreateSubmitScope.submit(
                            context,
                            'istek',
                          ),
                          child: const Text('Kaydet'),
                        ),
                      ),
                      onSubmit: (request) async {
                        submitCount += 1;
                        expect(request, 'istek');
                        if (submitCount == 1) {
                          return firstDecision.future;
                        }
                        return true;
                      },
                    ),
                  );
                },
                child: const Text('Yeni'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Yeni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(submitCount, 1);
    expect(find.text('Kaydet'), findsOneWidget);
    expect(
      find.text(
        'Kayit yapiliyor. Sonuc kesinlesene kadar bu ekran acik kalacak.',
      ),
      findsOneWidget,
    );

    firstDecision.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Kaydet'), findsOneWidget);

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(submitCount, 2);
    expect(find.text('Kaydet'), findsNothing);
    expect(find.text('Yeni'), findsOneWidget);
  });
}
