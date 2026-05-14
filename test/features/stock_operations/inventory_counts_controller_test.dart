import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/presentation/view_models/inventory_counts_controller.dart';

void main() {
  test('loadCounts selects first record and loads its detail', () async {
    final repository = _FakeInventoryCountsRepository();
    final controller = InventoryCountsController(
      repository: repository,
      accessToken: 'token',
      defaultWarehouseNo: '110',
    );

    await controller.loadCounts();

    expect(controller.counts, hasLength(2));
    expect(controller.selectedCount?.documentNo, 25);
    expect(controller.selectedCountDetail?.items, hasLength(1));
  });

  test('createCount reloads list and selects created document', () async {
    final repository = _FakeInventoryCountsRepository();
    final controller = InventoryCountsController(
      repository: repository,
      accessToken: 'token',
      defaultWarehouseNo: '110',
    );

    final result = await controller.createCount(
      InventoryCountCreateRequest(
        name: 'Yeni Sayim',
        documentDate: DateTime(2026, 4, 23),
        lines: const <InventoryCountCreateLine>[
          InventoryCountCreateLine(
            stockCode: '015792',
            quantity: 12,
            barcode: '8690000000012',
            unitPointer: 1,
          ),
        ],
      ),
    );

    expect(result?.documentNo, 27);
    expect(controller.selectedCount?.documentNo, 27);
    expect(controller.selectedCountDetail?.header.documentNo, 27);
  });

  test(
    'selectCount ignores stale detail response from earlier selection',
    () async {
      final repository = _DelayedInventoryCountsRepository();
      final controller = InventoryCountsController(
        repository: repository,
        accessToken: 'token',
        defaultWarehouseNo: '110',
      );

      final firstItem = InventoryCountListItem(
        documentDate: DateTime(2026, 4, 21),
        createdAt: DateTime(2026, 4, 21, 10, 15),
        documentNo: 25,
        warehouseNo: 110,
        warehouseName: 'KESTEL 1',
        name: 'Nisan 2026 Genel Sayim',
        lineCount: 1,
        totalQuantity: 24,
      );
      final secondItem = InventoryCountListItem(
        documentDate: DateTime(2026, 4, 22),
        createdAt: DateTime(2026, 4, 22, 9, 5),
        documentNo: 26,
        warehouseNo: 110,
        warehouseName: 'KESTEL 1',
        name: 'Aksam Sayimi',
        lineCount: 2,
        totalQuantity: 11,
      );

      final firstFuture = controller.selectCount(firstItem);
      final secondFuture = controller.selectCount(secondItem);

      repository.completeDetail(
        26,
        _buildInventoryCountDetail(
          documentNo: 26,
          documentDate: DateTime(2026, 4, 22),
          name: 'Aksam Sayimi',
          totalQuantity: 11,
        ),
      );
      await secondFuture;

      expect(controller.selectedCount?.documentNo, 26);
      expect(controller.selectedCountDetail?.header.documentNo, 26);

      repository.completeDetail(
        25,
        _buildInventoryCountDetail(
          documentNo: 25,
          documentDate: DateTime(2026, 4, 21),
          name: 'Nisan 2026 Genel Sayim',
          totalQuantity: 24,
        ),
      );
      await firstFuture;

      expect(controller.selectedCount?.documentNo, 26);
      expect(controller.selectedCountDetail?.header.documentNo, 26);
    },
  );
}

class _FakeInventoryCountsRepository implements InventoryCountsRepository {
  final List<InventoryCountListItem> _items = <InventoryCountListItem>[
    InventoryCountListItem(
      documentDate: DateTime(2026, 4, 21),
      createdAt: DateTime(2026, 4, 21, 10, 15),
      documentNo: 25,
      warehouseNo: 110,
      warehouseName: 'KESTEL 1',
      name: 'Nisan 2026 Genel Sayim',
      lineCount: 1,
      totalQuantity: 24,
    ),
    InventoryCountListItem(
      documentDate: DateTime(2026, 4, 22),
      createdAt: DateTime(2026, 4, 22, 9, 5),
      documentNo: 26,
      warehouseNo: 110,
      warehouseName: 'KESTEL 1',
      name: 'Aksam Sayimi',
      lineCount: 2,
      totalQuantity: 11,
    ),
  ];

  @override
  Future<List<InventoryCountListItem>> fetchCounts({
    required String accessToken,
    required InventoryCountListFilter filter,
  }) async {
    return List<InventoryCountListItem>.from(_items);
  }

  @override
  Future<InventoryCountDetail> fetchCountDetail({
    required String accessToken,
    required int documentNo,
    required DateTime documentDate,
    required String warehouseNo,
  }) async {
    final isCreated = documentNo == 27;

    return InventoryCountDetail(
      header: InventoryCountHeader(
        documentDate: isCreated ? DateTime(2026, 4, 23) : DateTime(2026, 4, 21),
        createdAt: isCreated
            ? DateTime(2026, 4, 23, 11, 0)
            : DateTime(2026, 4, 21, 10, 15),
        documentNo: documentNo,
        warehouseNo: 110,
        warehouseName: 'KESTEL 1',
        name: isCreated ? 'Yeni Sayim' : 'Nisan 2026 Genel Sayim',
        lineCount: 1,
        totalQuantity: isCreated ? 12 : 24,
      ),
      items: <InventoryCountLineItem>[
        InventoryCountLineItem(
          rowNo: 0,
          stockCode: '015792',
          stockName: 'Urun',
          barcode: '8690000000012',
          unitName: 'AD',
          unitPointer: 1,
          quantity1: isCreated ? 12 : 24,
          quantity2: 0,
          quantity3: 0,
          quantity4: 0,
          quantity5: 0,
        ),
      ],
    );
  }

  @override
  Future<InventoryCountCreateResult> createCount({
    required String accessToken,
    required InventoryCountCreateRequest request,
  }) async {
    final createdItem = InventoryCountListItem(
      documentDate: DateTime(2026, 4, 23),
      createdAt: DateTime(2026, 4, 23, 11, 0),
      documentNo: 27,
      warehouseNo: 110,
      warehouseName: 'KESTEL 1',
      name: request.name,
      lineCount: request.lines.length,
      totalQuantity: 12,
    );

    _items.insert(0, createdItem);

    return InventoryCountCreateResult(
      documentNo: 27,
      documentDate: DateTime(2026, 4, 23),
      warehouseNo: 110,
      name: request.name,
      lineCount: request.lines.length,
      totalQuantity: 12,
      writeConnectionName: 'testMikroConnection',
    );
  }

  @override
  Future<InventoryCountOfflineSyncStatus> fetchOfflineSyncStatus({
    required String accessToken,
    required String clientRequestId,
  }) async {
    return InventoryCountOfflineSyncStatus(
      clientRequestId: clientRequestId,
      operationCode: 'inventory-count-create',
      status: 'completed',
      createdAtUtc: DateTime(2026, 4, 23, 8, 0),
      completedAtUtc: DateTime(2026, 4, 23, 8, 1),
      errorMessage: null,
      result: null,
    );
  }

  @override
  Future<List<InventoryCountProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  }) async {
    return const <InventoryCountProductLookupItem>[];
  }
}

class _DelayedInventoryCountsRepository extends _FakeInventoryCountsRepository {
  final Map<int, Completer<InventoryCountDetail>> _detailCompleters =
      <int, Completer<InventoryCountDetail>>{};

  @override
  Future<InventoryCountDetail> fetchCountDetail({
    required String accessToken,
    required int documentNo,
    required DateTime documentDate,
    required String warehouseNo,
  }) {
    return (_detailCompleters[documentNo] ??= Completer<InventoryCountDetail>())
        .future;
  }

  void completeDetail(int documentNo, InventoryCountDetail detail) {
    final completer = _detailCompleters[documentNo] ??=
        Completer<InventoryCountDetail>();
    if (!completer.isCompleted) {
      completer.complete(detail);
    }
  }
}

InventoryCountDetail _buildInventoryCountDetail({
  required int documentNo,
  required DateTime documentDate,
  required String name,
  required double totalQuantity,
}) {
  return InventoryCountDetail(
    header: InventoryCountHeader(
      documentDate: documentDate,
      createdAt: documentDate.add(const Duration(hours: 2)),
      documentNo: documentNo,
      warehouseNo: 110,
      warehouseName: 'KESTEL 1',
      name: name,
      lineCount: 1,
      totalQuantity: totalQuantity,
    ),
    items: <InventoryCountLineItem>[
      InventoryCountLineItem(
        rowNo: 0,
        stockCode: '015792',
        stockName: 'Urun',
        barcode: '8690000000012',
        unitName: 'AD',
        unitPointer: 1,
        quantity1: totalQuantity,
        quantity2: 0,
        quantity3: 0,
        quantity4: 0,
        quantity5: 0,
      ),
    ],
  );
}
