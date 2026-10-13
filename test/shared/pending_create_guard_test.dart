import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/pending_create/pending_create_guard.dart';
import 'package:furpa_merkez_terminal/shared/pending_create/pending_create_repository.dart';

import '../support/memory_local_database.dart';

void main() {
  testWidgets('warns at ten pending records and allows explicit continue', (
    tester,
  ) async {
    final repository = LocalPendingCreateRepository(
      database: MemoryLocalDatabase(),
    );
    for (var index = 0; index < pendingCreateWarningThreshold; index++) {
      await repository.save(
        PendingCreateOperation(
          moduleKey: 'test.module',
          userId: 'user-1',
          warehouseNo: '56',
          payload: <String, dynamic>{'clientRequestId': 'request-$index'},
          updatedAt: DateTime(2026, 10, 13, 12, index),
          failureKind: 'uncertain',
        ),
      );
    }

    var allowed = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                allowed = await ensurePendingCreateCapacity(
                  context: context,
                  repository: repository,
                  moduleKey: 'test.module',
                  userId: 'user-1',
                  warehouseNo: '56',
                );
              },
              child: const Text('Yeni Kayit'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Yeni Kayit'));
    await tester.pumpAndSettle();

    expect(find.text('Bekleyen kayitlar var'), findsOneWidget);
    expect(find.textContaining('10 bekleyen guvenli kayit'), findsOneWidget);
    await tester.tap(find.text('Yine de Yeni'));
    await tester.pumpAndSettle();

    expect(allowed, isTrue);
    expect(
      await repository.readAll(
        moduleKey: 'test.module',
        userId: 'user-1',
        warehouseNo: '56',
      ),
      hasLength(10),
    );
  });

  testWidgets('blocks a new operation at the hard safety limit', (
    tester,
  ) async {
    final repository = LocalPendingCreateRepository(
      database: MemoryLocalDatabase(),
    );
    for (var index = 0; index < maxPendingCreateOperationsPerScope; index++) {
      await repository.save(
        PendingCreateOperation(
          moduleKey: 'test.module',
          userId: 'user-1',
          warehouseNo: '56',
          payload: <String, dynamic>{'clientRequestId': 'request-$index'},
          updatedAt: DateTime(2026, 10, 13, 12).add(Duration(minutes: index)),
          failureKind: 'uncertain',
        ),
      );
    }

    var allowed = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                allowed = await ensurePendingCreateCapacity(
                  context: context,
                  repository: repository,
                  moduleKey: 'test.module',
                  userId: 'user-1',
                  warehouseNo: '56',
                );
              },
              child: const Text('Yeni Kayit'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Yeni Kayit'));
    await tester.pumpAndSettle();

    expect(find.text('Yeni kayit durduruldu'), findsOneWidget);
    expect(find.textContaining('50 bekleyen guvenli kayit'), findsOneWidget);
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(allowed, isFalse);
  });
}
