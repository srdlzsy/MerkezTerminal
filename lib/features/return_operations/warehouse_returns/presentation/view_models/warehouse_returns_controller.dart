import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/core/utils/request_epoch.dart';
import 'package:furpa_merkez_terminal/core/utils/safe_change_notifier.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/warehouse_returns_repository.dart';

class WarehouseReturnsController extends ChangeNotifier
    with SafeChangeNotifier {
  WarehouseReturnsController({
    required WarehouseReturnsRepository repository,
    required String accessToken,
    required String defaultWarehouseNo,
    required WarehouseReturnDirection direction,
  }) : _repository = repository,
       _accessToken = accessToken,
       _defaultWarehouseNo = defaultWarehouseNo,
       _direction = direction;

  final WarehouseReturnsRepository _repository;
  final String _accessToken;
  final String _defaultWarehouseNo;
  final WarehouseReturnDirection _direction;
  final RequestEpoch _listEpoch = RequestEpoch();
  final RequestEpoch _detailEpoch = RequestEpoch();

  DateTime _startDate = defaultFilterStartDate();
  DateTime _endDate = defaultFilterEndDate();
  String _warehouseNo = '';
  bool _isLoadingList = false;
  bool _isLoadingDetail = false;
  bool _isCreating = false;
  bool _isSendingEDespatch = false;
  bool _isLoadingPdf = false;
  String? _listError;
  String? _detailError;
  String? _createError;
  String? _sendEDespatchError;
  String? _pdfError;
  List<WarehouseReturnListItem> _returns = const <WarehouseReturnListItem>[];
  WarehouseReturnListItem? _selectedReturn;
  WarehouseReturnDetail? _selectedReturnDetail;
  EDespatchSendResult? _lastEDespatchResult;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String get warehouseNo => _warehouseNo;
  bool get isLoadingList => _isLoadingList;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isCreating => _isCreating;
  bool get isSendingEDespatch => _isSendingEDespatch;
  bool get isLoadingPdf => _isLoadingPdf;
  String? get listError => _listError;
  String? get detailError => _detailError;
  String? get createError => _createError;
  String? get sendEDespatchError => _sendEDespatchError;
  String? get pdfError => _pdfError;
  List<WarehouseReturnListItem> get returns => _returns;
  WarehouseReturnListItem? get selectedReturn => _selectedReturn;
  WarehouseReturnDetail? get selectedReturnDetail => _selectedReturnDetail;
  EDespatchSendResult? get lastEDespatchResult => _lastEDespatchResult;
  WarehouseReturnDirection get direction => _direction;
  bool get canSendEDespatch =>
      _direction.supportsEDespatch &&
      _lastEDespatchResult == null &&
      (_selectedReturnDetail?.header.canConvertToEDespatch ??
          _selectedReturn?.canConvertToEDespatch ??
          false);
  bool get canViewEDespatchPdf =>
      _direction.supportsEDespatch &&
      (_lastEDespatchResult != null ||
          (_selectedReturnDetail?.header.hasDocumentNo ??
              _selectedReturn?.hasDocumentNo ??
              false));

  void clearSelection() {
    _detailEpoch.invalidate();
    _selectedReturn = null;
    _selectedReturnDetail = null;
    _detailError = null;
    _sendEDespatchError = null;
    _pdfError = null;
    _lastEDespatchResult = null;
    _isLoadingDetail = false;
    notifySafely();
  }

  Future<void> loadReturns({
    String? preferredDocumentSerie,
    int? preferredDocumentOrderNo,
  }) async {
    final listRequestId = _listEpoch.next();
    _detailEpoch.invalidate();
    _isLoadingList = true;
    _listError = null;
    notifySafely();

    try {
      final items = await _repository.fetchReturns(
        accessToken: _accessToken,
        direction: _direction,
        filter: WarehouseReturnListFilter(
          startDate: _startDate,
          endDate: _endDate,
          warehouseNo: _warehouseNo.trim().isEmpty ? null : _warehouseNo,
        ),
      );
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }

      _returns = items;
      _selectedReturn = items.isEmpty
          ? null
          : _findPreferredReturn(
                  items,
                  preferredDocumentSerie: preferredDocumentSerie,
                  preferredDocumentOrderNo: preferredDocumentOrderNo,
                ) ??
                items.first;
      _selectedReturnDetail = null;
      _detailError = null;
      _sendEDespatchError = null;
      _pdfError = null;
      _lastEDespatchResult = null;
      _isLoadingList = false;
      notifySafely();

      if (_selectedReturn case final selectedReturn?) {
        await selectReturn(selectedReturn);
      }
    } on ApiException catch (error) {
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }
      _returns = const <WarehouseReturnListItem>[];
      _selectedReturn = null;
      _selectedReturnDetail = null;
      _lastEDespatchResult = null;
      _isLoadingList = false;
      _listError = error.message;
      notifySafely();
    }
  }

  Future<void> selectReturn(
    WarehouseReturnListItem item, {
    bool preserveEDespatchResult = false,
  }) async {
    final detailRequestId = _detailEpoch.next();
    _selectedReturn = item;
    _selectedReturnDetail = null;
    _detailError = null;
    _sendEDespatchError = null;
    _pdfError = null;
    if (!preserveEDespatchResult) {
      _lastEDespatchResult = null;
    }
    _isLoadingDetail = true;
    notifySafely();

    try {
      final detail = await _repository.fetchReturnDetail(
        accessToken: _accessToken,
        direction: _direction,
        documentSerie: item.documentSerie,
        documentOrderNo: item.documentOrderNo,
        warehouseNo: _effectiveWarehouseNo,
      );
      if (!_detailEpoch.isCurrent(detailRequestId)) {
        return;
      }
      _selectedReturnDetail = detail;
      _isLoadingDetail = false;
      notifySafely();
    } on ApiException catch (error) {
      if (!_detailEpoch.isCurrent(detailRequestId)) {
        return;
      }
      _selectedReturnDetail = null;
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
    await loadReturns();
  }

  Future<WarehouseReturnCreateResult?> createReturn(
    WarehouseReturnCreateRequest request,
  ) async {
    if (_direction != WarehouseReturnDirection.outgoing) {
      _createError = 'Bu ekranda yeni depo iadesi olusturma desteklenmiyor.';
      notifySafely();
      return null;
    }

    _isCreating = true;
    _createError = null;
    notifySafely();

    try {
      final result = await _repository.createReturn(
        accessToken: _accessToken,
        request: request,
      );

      _isCreating = false;
      notifySafely();

      await loadReturns(
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

  Future<EDespatchSendResult?> sendEDespatch(
    EDespatchSendRequest request,
  ) async {
    final currentSelection = _selectedReturn;

    if (currentSelection == null) {
      _sendEDespatchError = 'E-irsaliye icin once bir depo iadesi secilmeli.';
      notifySafely();
      return null;
    }

    _isSendingEDespatch = true;
    _sendEDespatchError = null;
    _pdfError = null;
    notifySafely();

    try {
      final result = await _repository.sendEDespatch(
        accessToken: _accessToken,
        documentSerie: currentSelection.documentSerie,
        documentOrderNo: currentSelection.documentOrderNo,
        warehouseNo: _effectiveWarehouseNo,
        request: request,
      );

      _lastEDespatchResult = result;
      _isSendingEDespatch = false;
      notifySafely();

      await selectReturn(currentSelection, preserveEDespatchResult: true);

      return result;
    } on ApiException catch (error) {
      _isSendingEDespatch = false;
      _sendEDespatchError = error.message;
      notifySafely();
      return null;
    }
  }

  Future<WarehouseReturnPdfDocument?> fetchEDespatchPdf() async {
    final currentSelection = _selectedReturn;

    if (currentSelection == null) {
      _pdfError = 'PDF icin once bir depo iadesi secilmeli.';
      notifySafely();
      return null;
    }

    _isLoadingPdf = true;
    _pdfError = null;
    notifySafely();

    try {
      final document = await _repository.fetchEDespatchPdf(
        accessToken: _accessToken,
        documentSerie: currentSelection.documentSerie,
        documentOrderNo: currentSelection.documentOrderNo,
        warehouseNo: _effectiveWarehouseNo,
      );
      _isLoadingPdf = false;
      notifySafely();
      return document;
    } on ApiException catch (error) {
      _isLoadingPdf = false;
      _pdfError = error.message;
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

  WarehouseReturnListItem? _findPreferredReturn(
    List<WarehouseReturnListItem> items, {
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
