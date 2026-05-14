import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/core/utils/request_epoch.dart';
import 'package:furpa_merkez_terminal/core/utils/safe_change_notifier.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/models/stock_receipt_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/stock_receipts_repository.dart';

class StockReceiptsController extends ChangeNotifier with SafeChangeNotifier {
  StockReceiptsController({
    required StockReceiptsRepository repository,
    required String accessToken,
    required String defaultWarehouseNo,
    required StockReceiptKind kind,
  }) : _repository = repository,
       _accessToken = accessToken,
       _defaultWarehouseNo = defaultWarehouseNo,
       _kind = kind;

  final StockReceiptsRepository _repository;
  final String _accessToken;
  final String _defaultWarehouseNo;
  final StockReceiptKind _kind;
  final RequestEpoch _listEpoch = RequestEpoch();
  final RequestEpoch _detailEpoch = RequestEpoch();

  DateTime _startDate = defaultFilterStartDate();
  DateTime _endDate = defaultFilterEndDate();
  String _warehouseNo = '';
  bool _isLoadingList = false;
  bool _isLoadingDetail = false;
  bool _isCreating = false;
  String? _listError;
  String? _detailError;
  String? _createError;
  List<StockReceiptListItem> _receipts = const <StockReceiptListItem>[];
  StockReceiptListItem? _selectedReceipt;
  StockReceiptDetail? _selectedReceiptDetail;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String get warehouseNo => _warehouseNo;
  bool get isLoadingList => _isLoadingList;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isCreating => _isCreating;
  String? get listError => _listError;
  String? get detailError => _detailError;
  String? get createError => _createError;
  List<StockReceiptListItem> get receipts => _receipts;
  StockReceiptListItem? get selectedReceipt => _selectedReceipt;
  StockReceiptDetail? get selectedReceiptDetail => _selectedReceiptDetail;

  void clearSelection() {
    _detailEpoch.invalidate();
    _selectedReceipt = null;
    _selectedReceiptDetail = null;
    _detailError = null;
    _isLoadingDetail = false;
    notifySafely();
  }

  Future<void> loadReceipts({
    String? preferredDocumentSerie,
    int? preferredDocumentOrderNo,
  }) async {
    final listRequestId = _listEpoch.next();
    _detailEpoch.invalidate();
    _isLoadingList = true;
    _listError = null;
    notifySafely();

    try {
      final items = await _repository.fetchReceipts(
        accessToken: _accessToken,
        kind: _kind,
        filter: StockReceiptListFilter(
          startDate: _startDate,
          endDate: _endDate,
          warehouseNo: _warehouseNo.trim().isEmpty ? null : _warehouseNo,
        ),
      );
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }

      _receipts = items;
      _selectedReceipt = items.isEmpty
          ? null
          : _findPreferredReceipt(
                  items,
                  preferredDocumentSerie: preferredDocumentSerie,
                  preferredDocumentOrderNo: preferredDocumentOrderNo,
                ) ??
                items.first;
      _selectedReceiptDetail = null;
      _detailError = null;
      _isLoadingList = false;
      notifySafely();

      if (_selectedReceipt case final selectedReceipt?) {
        await selectReceipt(selectedReceipt);
      }
    } on ApiException catch (error) {
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }
      _receipts = const <StockReceiptListItem>[];
      _selectedReceipt = null;
      _selectedReceiptDetail = null;
      _isLoadingList = false;
      _listError = error.message;
      notifySafely();
    }
  }

  Future<void> selectReceipt(StockReceiptListItem item) async {
    final detailRequestId = _detailEpoch.next();
    _selectedReceipt = item;
    _selectedReceiptDetail = null;
    _detailError = null;
    _isLoadingDetail = true;
    notifySafely();

    try {
      final detail = await _repository.fetchReceiptDetail(
        accessToken: _accessToken,
        kind: _kind,
        documentSerie: item.documentSerie,
        documentOrderNo: item.documentOrderNo,
        warehouseNo: _effectiveWarehouseNo,
      );
      if (!_detailEpoch.isCurrent(detailRequestId)) {
        return;
      }
      _selectedReceiptDetail = detail;
      _isLoadingDetail = false;
      notifySafely();
    } on ApiException catch (error) {
      if (!_detailEpoch.isCurrent(detailRequestId)) {
        return;
      }
      _selectedReceiptDetail = null;
      _detailError = error.message;
      _isLoadingDetail = false;
      notifySafely();
    }
  }

  Future<void> updateFilters({
    required DateTime startDate,
    required DateTime endDate,
    required String warehouseNo,
  }) async {
    _startDate = _normalizedDate(startDate);
    _endDate = _normalizedDate(endDate);
    _warehouseNo = warehouseNo.trim();
    await loadReceipts();
  }

  Future<StockReceiptCreateResult?> createReceipt(
    StockReceiptCreateRequest request,
  ) async {
    _isCreating = true;
    _createError = null;
    notifySafely();

    try {
      final result = await _repository.createReceipt(
        accessToken: _accessToken,
        kind: _kind,
        request: request,
      );

      _isCreating = false;
      notifySafely();

      await loadReceipts(
        preferredDocumentSerie: result.documentSerie,
        preferredDocumentOrderNo: result.documentOrderNo,
      );

      return result;
    } on ApiException catch (error) {
      _isCreating = false;
      _createError = error.message;
      notifySafely();
      return null;
    }
  }

  String get _effectiveWarehouseNo {
    if (_warehouseNo.trim().isNotEmpty) {
      return _warehouseNo.trim();
    }

    return _defaultWarehouseNo;
  }

  static DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  StockReceiptListItem? _findPreferredReceipt(
    List<StockReceiptListItem> items, {
    String? preferredDocumentSerie,
    int? preferredDocumentOrderNo,
  }) {
    if (preferredDocumentSerie == null || preferredDocumentOrderNo == null) {
      return null;
    }

    for (final item in items) {
      if (item.documentSerie == preferredDocumentSerie &&
          item.documentOrderNo == preferredDocumentOrderNo) {
        return item;
      }
    }

    return null;
  }
}
