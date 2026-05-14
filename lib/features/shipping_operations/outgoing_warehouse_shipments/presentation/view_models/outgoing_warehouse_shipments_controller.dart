import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/core/utils/request_epoch.dart';
import 'package:furpa_merkez_terminal/core/utils/safe_change_notifier.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/outgoing_warehouse_shipments_repository.dart';

class OutgoingWarehouseShipmentsController extends ChangeNotifier
    with SafeChangeNotifier {
  OutgoingWarehouseShipmentsController({
    required OutgoingWarehouseShipmentsRepository repository,
    required String accessToken,
    required String defaultWarehouseNo,
  }) : _repository = repository,
       _accessToken = accessToken,
       _defaultWarehouseNo = defaultWarehouseNo;

  final OutgoingWarehouseShipmentsRepository _repository;
  final String _accessToken;
  final String _defaultWarehouseNo;
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
  List<WarehouseShipmentListItem> _shipments =
      const <WarehouseShipmentListItem>[];
  WarehouseShipmentListItem? _selectedShipment;
  WarehouseShipmentDetail? _selectedShipmentDetail;
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
  List<WarehouseShipmentListItem> get shipments => _shipments;
  WarehouseShipmentListItem? get selectedShipment => _selectedShipment;
  WarehouseShipmentDetail? get selectedShipmentDetail =>
      _selectedShipmentDetail;
  EDespatchSendResult? get lastEDespatchResult => _lastEDespatchResult;
  bool get supportsEDespatch => _repository.supportsEDespatch;
  bool get canSendEDespatch =>
      _repository.supportsEDespatch &&
      _lastEDespatchResult == null &&
      (_selectedShipmentDetail?.header.canConvertToEDespatch ??
          _selectedShipment?.canConvertToEDespatch ??
          false);
  bool get canViewEDespatchPdf =>
      _repository.supportsEDespatch &&
      (_lastEDespatchResult != null ||
          (_selectedShipmentDetail?.header.hasDocumentNo ??
              _selectedShipment?.hasDocumentNo ??
              false));

  void clearSelection() {
    _detailEpoch.invalidate();
    _selectedShipment = null;
    _selectedShipmentDetail = null;
    _detailError = null;
    _sendEDespatchError = null;
    _pdfError = null;
    _lastEDespatchResult = null;
    _isLoadingDetail = false;
    _isSendingEDespatch = false;
    _isLoadingPdf = false;
    notifySafely();
  }

  Future<void> loadShipments({
    String? preferredDocumentSerie,
    int? preferredDocumentOrderNo,
  }) async {
    final listRequestId = _listEpoch.next();
    _detailEpoch.invalidate();
    _isLoadingList = true;
    _listError = null;
    notifySafely();

    try {
      final items = await _repository.fetchShipments(
        accessToken: _accessToken,
        filter: WarehouseShipmentListFilter(
          startDate: _startDate,
          endDate: _endDate,
          warehouseNo: _warehouseNo.trim().isEmpty ? null : _warehouseNo,
        ),
      );
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }

      _shipments = items;
      _selectedShipment = items.isEmpty
          ? null
          : _findPreferredShipment(
                  items,
                  preferredDocumentSerie: preferredDocumentSerie,
                  preferredDocumentOrderNo: preferredDocumentOrderNo,
                ) ??
                items.first;
      _selectedShipmentDetail = null;
      _detailError = null;
      _sendEDespatchError = null;
      _pdfError = null;
      _lastEDespatchResult = null;
      _isLoadingList = false;
      _isSendingEDespatch = false;
      _isLoadingPdf = false;
      notifySafely();

      if (_selectedShipment != null) {
        await selectShipment(_selectedShipment!);
      }
    } on ApiException catch (error) {
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }
      _shipments = const <WarehouseShipmentListItem>[];
      _selectedShipment = null;
      _selectedShipmentDetail = null;
      _lastEDespatchResult = null;
      _isLoadingList = false;
      _isSendingEDespatch = false;
      _isLoadingPdf = false;
      _listError = error.message;
      notifySafely();
    }
  }

  Future<void> selectShipment(
    WarehouseShipmentListItem item, {
    bool preserveEDespatchResult = false,
  }) async {
    final detailRequestId = _detailEpoch.next();
    _selectedShipment = item;
    _selectedShipmentDetail = null;
    _detailError = null;
    _sendEDespatchError = null;
    _pdfError = null;
    if (!preserveEDespatchResult) {
      _lastEDespatchResult = null;
    }
    _isLoadingDetail = true;
    notifySafely();

    try {
      final detail = await _repository.fetchShipmentDetail(
        accessToken: _accessToken,
        documentSerie: item.documentSerie,
        documentOrderNo: item.documentOrderNo,
        warehouseNo: _effectiveWarehouseNo,
      );
      if (!_detailEpoch.isCurrent(detailRequestId)) {
        return;
      }
      _selectedShipmentDetail = detail;
      _isLoadingDetail = false;
      notifySafely();
    } on ApiException catch (error) {
      if (!_detailEpoch.isCurrent(detailRequestId)) {
        return;
      }
      _selectedShipmentDetail = null;
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
    await loadShipments();
  }

  Future<WarehouseShipmentCreateResult?> createShipment(
    WarehouseShipmentCreateRequest request,
  ) async {
    _isCreating = true;
    _createError = null;
    notifySafely();

    try {
      final result = await _repository.createShipment(
        accessToken: _accessToken,
        request: request,
      );

      _isCreating = false;
      notifySafely();

      await loadShipments(
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
    final currentSelection = _selectedShipment;

    if (currentSelection == null || !_repository.supportsEDespatch) {
      _sendEDespatchError = 'E-irsaliye icin once uygun bir sevk secilmeli.';
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

      await selectShipment(currentSelection, preserveEDespatchResult: true);
      return result;
    } on ApiException catch (error) {
      _isSendingEDespatch = false;
      _sendEDespatchError = error.message;
      notifySafely();
      return null;
    }
  }

  Future<WarehouseShipmentPdfDocument?> fetchEDespatchPdf() async {
    final currentSelection = _selectedShipment;

    if (currentSelection == null || !_repository.supportsEDespatch) {
      _pdfError = 'PDF icin once uygun bir sevk secilmeli.';
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

  WarehouseShipmentListItem? _findPreferredShipment(
    List<WarehouseShipmentListItem> items, {
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
