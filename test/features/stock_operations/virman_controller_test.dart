import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/models/virman_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/virman_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/presentation/view_models/virman_controller.dart';

void main() {
  test('loadVirmans selects first record and loads detail', () async {
    final repository = _FakeVirmanRepository();
    final controller = VirmanController(
      repository: repository,
      accessToken: 'token',
      defaultWarehouseNo: '110',
    );

    await controller.loadVirmans();

    expect(controller.virmans, hasLength(2));
    expect(controller.selectedVirman?.documentNoLabel, 'F110.15');
    expect(controller.selectedVirmanDetail?.items, hasLength(1));
  });

  test('createVirman reloads list and selects created document', () async {
    final repository = _FakeVirmanRepository();
    final controller = VirmanController(
      repository: repository,
      accessToken: 'token',
      defaultWarehouseNo: '110',
    );

    final result = await controller.createVirman(
      VirmanCreateRequest(
        movementDate: DateTime(2026, 5, 7),
        documentDate: DateTime(2026, 5, 7),
        documentNo: '',
        description: 'Yeni virman',
        lines: const <VirmanCreateLine>[
          VirmanCreateLine(
            stockCode: '015792',
            movementType: 2,
            quantity: 8,
            unitPointer: 1,
            description: '',
            partyCode: '',
            lotNo: 0,
            projectCode: '',
          ),
        ],
      ),
    );

    expect(result?.documentNoLabel, 'F110.17');
    expect(controller.selectedVirman?.documentNoLabel, 'F110.17');
    expect(controller.selectedVirmanDetail?.header.documentNoLabel, 'F110.17');
  });

  test(
    'selectVirman ignores stale detail response from earlier selection',
    () async {
      final repository = _DelayedVirmanRepository();
      final controller = VirmanController(
        repository: repository,
        accessToken: 'token',
        defaultWarehouseNo: '110',
      );

      const firstItem = VirmanListItem(
        documentDate: null,
        movementCreateDate: null,
        movementDate: null,
        documentNo: 'VRM-0001',
        documentSerie: 'F110',
        documentOrderNo: 15,
        warehouseNo: 110,
        warehouseName: 'KESTEL 1',
        documentType: 0,
        movementGenre: 0,
        movementTypes: <int>[2],
        description: 'Ilk belge',
        lineCount: 1,
        totalQuantity: 4,
        totalAmount: 400,
      );
      const secondItem = VirmanListItem(
        documentDate: null,
        movementCreateDate: null,
        movementDate: null,
        documentNo: 'VRM-0002',
        documentSerie: 'F110',
        documentOrderNo: 16,
        warehouseNo: 110,
        warehouseName: 'KESTEL 1',
        documentType: 0,
        movementGenre: 0,
        movementTypes: <int>[2, 3],
        description: 'Ikinci belge',
        lineCount: 2,
        totalQuantity: 10,
        totalAmount: 1200,
      );

      final firstFuture = controller.selectVirman(firstItem);
      final secondFuture = controller.selectVirman(secondItem);

      repository.completeDetail(
        16,
        _buildVirmanDetail(
          documentOrderNo: 16,
          documentNo: 'VRM-0002',
          description: 'Ikinci belge',
          movementTypes: const <int>[2, 3],
          totalQuantity: 10,
        ),
      );
      await secondFuture;

      expect(controller.selectedVirman?.documentNoLabel, 'F110.16');
      expect(
        controller.selectedVirmanDetail?.header.documentNoLabel,
        'F110.16',
      );

      repository.completeDetail(
        15,
        _buildVirmanDetail(
          documentOrderNo: 15,
          documentNo: 'VRM-0001',
          description: 'Ilk belge',
          movementTypes: const <int>[2],
          totalQuantity: 4,
        ),
      );
      await firstFuture;

      expect(controller.selectedVirman?.documentNoLabel, 'F110.16');
      expect(
        controller.selectedVirmanDetail?.header.documentNoLabel,
        'F110.16',
      );
    },
  );
}

class _FakeVirmanRepository implements VirmanRepository {
  final List<VirmanListItem> _items = <VirmanListItem>[
    const VirmanListItem(
      documentDate: null,
      movementCreateDate: null,
      movementDate: null,
      documentNo: 'VRM-0001',
      documentSerie: 'F110',
      documentOrderNo: 15,
      warehouseNo: 110,
      warehouseName: 'KESTEL 1',
      documentType: 0,
      movementGenre: 0,
      movementTypes: <int>[2],
      description: 'Raf duzeltme',
      lineCount: 1,
      totalQuantity: 4,
      totalAmount: 400,
    ),
    const VirmanListItem(
      documentDate: null,
      movementCreateDate: null,
      movementDate: null,
      documentNo: 'VRM-0002',
      documentSerie: 'F110',
      documentOrderNo: 16,
      warehouseNo: 110,
      warehouseName: 'KESTEL 1',
      documentType: 0,
      movementGenre: 0,
      movementTypes: <int>[2, 3],
      description: 'Depo ici aktarim',
      lineCount: 2,
      totalQuantity: 10,
      totalAmount: 1200,
    ),
  ];

  @override
  Future<List<VirmanListItem>> fetchVirmans({
    required String accessToken,
    required VirmanListFilter filter,
  }) async {
    return List<VirmanListItem>.from(_items);
  }

  @override
  Future<VirmanDetail> fetchVirmanDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) async {
    final isCreated = documentOrderNo == 17;

    return _buildVirmanDetail(
      documentOrderNo: documentOrderNo,
      documentNo: isCreated ? 'VRM-0003' : 'VRM-0001',
      description: isCreated ? 'Yeni virman' : 'Raf duzeltme',
      movementTypes: isCreated ? const <int>[2] : const <int>[2],
      totalQuantity: isCreated ? 8 : 4,
    );
  }

  @override
  Future<VirmanCreateResult> createVirman({
    required String accessToken,
    required VirmanCreateRequest request,
  }) async {
    const createdItem = VirmanListItem(
      documentDate: null,
      movementCreateDate: null,
      movementDate: null,
      documentNo: 'VRM-0003',
      documentSerie: 'F110',
      documentOrderNo: 17,
      warehouseNo: 110,
      warehouseName: 'KESTEL 1',
      documentType: 0,
      movementGenre: 0,
      movementTypes: <int>[2],
      description: 'Yeni virman',
      lineCount: 1,
      totalQuantity: 8,
      totalAmount: 800,
    );

    _items.insert(0, createdItem);

    return const VirmanCreateResult(
      documentSerie: 'F110',
      documentOrderNo: 17,
      movementDate: null,
      documentDate: null,
      documentNo: 'VRM-0003',
      warehouseNo: 110,
      movementTypes: <int>[2],
      lineCount: 1,
      totalQuantity: 8,
      totalAmount: 800,
      writeConnectionName: 'testMikroConnection',
    );
  }
}

class _DelayedVirmanRepository extends _FakeVirmanRepository {
  final Map<int, Completer<VirmanDetail>> _detailCompleters =
      <int, Completer<VirmanDetail>>{};

  @override
  Future<VirmanDetail> fetchVirmanDetail({
    required String accessToken,
    required String documentSerie,
    required int documentOrderNo,
    required String warehouseNo,
  }) {
    return (_detailCompleters[documentOrderNo] ??= Completer<VirmanDetail>())
        .future;
  }

  void completeDetail(int documentOrderNo, VirmanDetail detail) {
    final completer = _detailCompleters[documentOrderNo] ??=
        Completer<VirmanDetail>();

    if (!completer.isCompleted) {
      completer.complete(detail);
    }
  }
}

VirmanDetail _buildVirmanDetail({
  required int documentOrderNo,
  required String documentNo,
  required String description,
  required List<int> movementTypes,
  required double totalQuantity,
}) {
  return VirmanDetail(
    header: VirmanHeader(
      documentDate: DateTime(2026, 5, 7),
      movementCreateDate: DateTime(2026, 5, 7, 10, 30),
      movementDate: DateTime(2026, 5, 7),
      documentNo: documentNo,
      documentSerie: 'F110',
      documentOrderNo: documentOrderNo,
      warehouseNo: 110,
      warehouseName: 'KESTEL 1',
      documentType: 0,
      movementGenre: 0,
      movementTypes: movementTypes,
      description: description,
      lineCount: 1,
      totalQuantity: totalQuantity,
      totalAmount: totalQuantity * 100,
    ),
    items: <VirmanLineItem>[
      VirmanLineItem(
        rowNo: 0,
        stockCode: '015792',
        stockName: 'Urun',
        unitName: 'AD',
        unitPointer: 1,
        movementType: movementTypes.first,
        quantity: totalQuantity,
        quantity2: 0,
        unitPrice: 100,
        lineAmount: totalQuantity * 100,
        description: description,
        partyCode: '',
        lotNo: 0,
        projectCode: '',
      ),
    ],
  );
}
