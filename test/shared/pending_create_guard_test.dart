import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/pending_create/pending_create_guard.dart';
import 'package:furpa_merkez_terminal/shared/pending_create/pending_create_repository.dart';

void main() {
  testWidgets('pending technical records never block a new document', (
    tester,
  ) async {
    final repository = _ThrowingPendingCreateRepository();
    var allowed = false;
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

    expect(allowed, isTrue);
    expect(find.byType(Dialog), findsNothing);
  });
}

class _ThrowingPendingCreateRepository implements PendingCreateRepository {
  @override
  Future<List<PendingCreateOperation>> readAll({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
  }) => throw StateError('Capacity checks must not read or block.');

  @override
  Future<PendingCreateOperation?> read({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
  }) => throw UnimplementedError();

  @override
  Future<void> save(PendingCreateOperation operation) =>
      throw UnimplementedError();

  @override
  Future<void> complete({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
    required String clientRequestId,
  }) => throw UnimplementedError();

  @override
  Future<void> remove({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
    String? clientRequestId,
  }) => throw UnimplementedError();
}
