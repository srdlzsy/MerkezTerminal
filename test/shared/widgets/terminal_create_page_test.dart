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
    expect(find.text('Sunucuya gonderiliyor...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(
      find.textContaining('Mikro sonucu kontrol ediliyor'),
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

  testWidgets('unlocks save after an unexpected submit error', (tester) async {
    var submitCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                unawaited(
                  openTerminalCreatePage<String>(
                    context: context,
                    title: 'Yeni Kayit',
                    builder: (context) => Center(
                      child: FilledButton(
                        onPressed: () =>
                            TerminalCreateSubmitScope.submit(context, 'istek'),
                        child: const Text('Kaydet'),
                      ),
                    ),
                    onSubmit: (_) async {
                      submitCount += 1;
                      if (submitCount == 1) {
                        throw StateError('test error');
                      }
                      return true;
                    },
                  ),
                );
              },
              child: const Text('Yeni'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Yeni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(submitCount, 1);
    expect(find.text('Kaydet'), findsOneWidget);
    expect(find.textContaining('Bilgiler ekranda korunuyor'), findsOneWidget);

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(submitCount, 2);
    expect(find.text('Yeni'), findsOneWidget);
  });

  testWidgets('locks the create page while local data is prepared', (
    tester,
  ) async {
    final preparation = Completer<void>();
    var submitCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
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
                          prepare: () => preparation.future,
                        ),
                        child: const Text('Kaydet'),
                      ),
                    ),
                    onSubmit: (_) async {
                      submitCount += 1;
                      return false;
                    },
                  ),
                );
              },
              child: const Text('Yeni'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Yeni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pump();

    expect(submitCount, 0);
    expect(find.text('Bilgiler hazirlaniyor...'), findsOneWidget);

    preparation.complete();
    await tester.pumpAndSettle();

    expect(submitCount, 1);
    expect(find.text('Kaydet'), findsOneWidget);
  });
}
