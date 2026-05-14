import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/core/utils/request_epoch.dart';
import 'package:furpa_merkez_terminal/core/utils/safe_change_notifier.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/models/virman_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/virman_repository.dart';

class VirmanController extends ChangeNotifier with SafeChangeNotifier {
  VirmanController({
    required VirmanRepository repository,
    required String accessToken,
    required String defaultWarehouseNo,
  }) : _repository = repository,
       _accessToken = accessToken,
       _defaultWarehouseNo = defaultWarehouseNo;

  final VirmanRepository _repository;
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
  String? _listError;
  String? _detailError;
  String? _createError;
  List<VirmanListItem> _virmans = const <VirmanListItem>[];
  VirmanListItem? _selectedVirman;
  VirmanDetail? _selectedVirmanDetail;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String get warehouseNo => _warehouseNo;
  bool get isLoadingList => _isLoadingList;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isCreating => _isCreating;
  String? get listError => _listError;
  String? get detailError => _detailError;
  String? get createError => _createError;
  List<VirmanListItem> get virmans => _virmans;
  VirmanListItem? get selectedVirman => _selectedVirman;
  VirmanDetail? get selectedVirmanDetail => _selectedVirmanDetail;

  void clearSelection() {
    _detailEpoch.invalidate();
    _selectedVirman = null;
    _selectedVirmanDetail = null;
    _detailError = null;
    _isLoadingDetail = false;
    notifySafely();
  }

  Future<void> loadVirmans({
    String? preferredDocumentSerie,
    int? preferredDocumentOrderNo,
  }) async {
    final listRequestId = _listEpoch.next();
    _detailEpoch.invalidate();
    _isLoadingList = true;
    _listError = null;
    notifySafely();

    try {
      final items = await _repository.fetchVirmans(
        accessToken: _accessToken,
        filter: VirmanListFilter(
          startDate: _startDate,
          endDate: _endDate,
          warehouseNo: _warehouseNo.trim().isEmpty ? null : _warehouseNo,
        ),
      );
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }

      _virmans = items;
      _selectedVirman = items.isEmpty
          ? null
          : _findPreferredVirman(
                  items,
                  preferredDocumentSerie: preferredDocumentSerie,
                  preferredDocumentOrderNo: preferredDocumentOrderNo,
                ) ??
                items.first;
      _selectedVirmanDetail = null;
      _detailError = null;
      _isLoadingList = false;
      notifySafely();

      if (_selectedVirman case final selectedVirman?) {
        await selectVirman(selectedVirman);
      }
    } on ApiException catch (error) {
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }
      _virmans = const <VirmanListItem>[];
      _selectedVirman = null;
      _selectedVirmanDetail = null;
      _isLoadingList = false;
      _listError = error.message;
      notifySafely();
    }
  }

  Future<void> selectVirman(VirmanListItem item) async {
    final detailRequestId = _detailEpoch.next();
    _selectedVirman = item;
    _selectedVirmanDetail = null;
    _detailError = null;
    _isLoadingDetail = true;
    notifySafely();

    try {
      final detail = await _repository.fetchVirmanDetail(
        accessToken: _accessToken,
        documentSerie: item.documentSerie,
        documentOrderNo: item.documentOrderNo,
        warehouseNo: _effectiveWarehouseNo,
      );
      if (!_detailEpoch.isCurrent(detailRequestId)) {
        return;
      }
      _selectedVirmanDetail = detail;
      _isLoadingDetail = false;
      notifySafely();
    } on ApiException catch (error) {
      if (!_detailEpoch.isCurrent(detailRequestId)) {
        return;
      }
      _selectedVirmanDetail = null;
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
    await loadVirmans();
  }

  Future<VirmanCreateResult?> createVirman(VirmanCreateRequest request) async {
    _isCreating = true;
    _createError = null;
    notifySafely();

    try {
      final result = await _repository.createVirman(
        accessToken: _accessToken,
        request: request,
      );

      _isCreating = false;
      notifySafely();

      await loadVirmans(
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

  VirmanListItem? _findPreferredVirman(
    List<VirmanListItem> items, {
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
