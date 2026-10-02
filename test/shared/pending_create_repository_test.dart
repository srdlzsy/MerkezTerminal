import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/storage/local_database.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';
import 'package:furpa_merkez_terminal/shared/pending_create/pending_create_repository.dart';

void main() {
  test('persists and restores the exact create payload in its scope', () async {
    final repository = LocalPendingCreateRepository(
      database: _MemoryLocalDatabase(),
    );
    final request = WarehouseShipmentCreateRequest(
      clientRequestId: 'request-123',
      targetWarehouseNo: 56,
      transitWarehouseNo: null,
      movementDate: DateTime(2026, 9, 30),
      documentDate: DateTime(2026, 9, 30),
      documentNo: 'TEST-1',
      description: 'Guvenli retry',
      lines: const <WarehouseShipmentCreateLine>[
        WarehouseShipmentCreateLine(
          stockCode: '008748',
          quantity: 12,
          unitPrice: 10.5,
          unitPointer: 1,
          description: '',
          partyCode: '',
          lotNo: 0,
          projectCode: '',
        ),
      ],
    );

    await repository.save(
      PendingCreateOperation(
        moduleKey: 'sevk',
        userId: 'user-1',
        warehouseNo: '120',
        payload: request.toJson(),
        updatedAt: DateTime(2026, 9, 30),
        failureKind: 'processing',
      ),
    );

    final restored = await repository.read(
      moduleKey: 'sevk',
      userId: 'user-1',
      warehouseNo: '120',
    );
    final restoredRequest = WarehouseShipmentCreateRequest.fromJson(
      restored!.payload,
    );

    expect(restored.failureKind, 'processing');
    expect(restoredRequest.clientRequestId, 'request-123');
    expect(restoredRequest.toJson(), request.toJson());
    expect(
      await repository.read(
        moduleKey: 'sevk',
        userId: 'user-1',
        warehouseNo: '145',
      ),
      isNull,
    );
  });

  test('removes only the completed operation scope', () async {
    final repository = LocalPendingCreateRepository(
      database: _MemoryLocalDatabase(),
    );
    for (final warehouseNo in <String>['120', '145']) {
      await repository.save(
        PendingCreateOperation(
          moduleKey: 'iade',
          userId: 'user-1',
          warehouseNo: warehouseNo,
          payload: <String, dynamic>{'clientRequestId': warehouseNo},
          updatedAt: DateTime(2026, 9, 30),
        ),
      );
    }

    await repository.remove(
      moduleKey: 'iade',
      userId: 'user-1',
      warehouseNo: '120',
    );

    expect(
      await repository.read(
        moduleKey: 'iade',
        userId: 'user-1',
        warehouseNo: '120',
      ),
      isNull,
    );
    expect(
      await repository.read(
        moduleKey: 'iade',
        userId: 'user-1',
        warehouseNo: '145',
      ),
      isNotNull,
    );
  });

  test('keeps independent pending creates in the same scope', () async {
    final repository = LocalPendingCreateRepository(
      database: _MemoryLocalDatabase(),
    );
    for (final requestId in <String>['request-old', 'request-new']) {
      await repository.save(
        PendingCreateOperation(
          moduleKey: 'sevk',
          userId: 'user-1',
          warehouseNo: '120',
          payload: <String, dynamic>{'clientRequestId': requestId},
          updatedAt: DateTime(2026, 10, requestId == 'request-old' ? 1 : 2),
        ),
      );
    }

    expect(
      (await repository.readAll(
        moduleKey: 'sevk',
        userId: 'user-1',
        warehouseNo: '120',
      )).map((operation) => operation.clientRequestId),
      <String>['request-new', 'request-old'],
    );

    await repository.remove(
      moduleKey: 'sevk',
      userId: 'user-1',
      warehouseNo: '120',
      clientRequestId: 'request-new',
    );

    expect(
      (await repository.readAll(
        moduleKey: 'sevk',
        userId: 'user-1',
        warehouseNo: '120',
      )).map((operation) => operation.clientRequestId),
      <String>['request-old'],
    );
  });
}

class _MemoryLocalDatabase implements LocalDatabase {
  final Map<String, List<Map<String, dynamic>>> _tables =
      <String, List<Map<String, dynamic>>>{};
  final Map<String, Map<String, dynamic>> _documents =
      <String, Map<String, dynamic>>{};

  @override
  Future<List<Map<String, dynamic>>> readTable(String key) async =>
      (_tables[key] ?? const <Map<String, dynamic>>[])
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);

  @override
  Future<void> writeTable(String key, List<Map<String, dynamic>> rows) async {
    _tables[key] = rows
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> readDocument(String key) async =>
      _documents[key];

  @override
  Future<void> writeDocument(String key, Map<String, dynamic> document) async {
    _documents[key] = Map<String, dynamic>.from(document);
  }

  @override
  Future<void> remove(String key) async {
    _tables.remove(key);
    _documents.remove(key);
  }
}
