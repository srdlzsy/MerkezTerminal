import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/core/utils/request_epoch.dart';
import 'package:furpa_merkez_terminal/core/utils/safe_change_notifier.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/models/warehouse_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/warehouse_acceptances_repository.dart';

class WarehouseAcceptancesController extends ChangeNotifier
    with SafeChangeNotifier {
  WarehouseAcceptancesController({
    required WarehouseAcceptancesRepository repository,
    required String accessToken,
    required String defaultWarehouseNo,
  }) : _repository = repository,
       _accessToken = accessToken,
       _defaultWarehouseNo = defaultWarehouseNo;

  final WarehouseAcceptancesRepository _repository;
  final String _accessToken;
  final String _defaultWarehouseNo;
  final RequestEpoch _listEpoch = RequestEpoch();
  final RequestEpoch _detailEpoch = RequestEpoch();

  DateTime _startDate = defaultFilterStartDate();
  DateTime _endDate = defaultFilterEndDate();
  String _warehouseNo = '';
  bool _isLoadingList = false;
  bool _isLoadingDetail = false;
  bool _isSubmitting = false;
  String? _listError;
  String? _detailError;
  String? _submitError;
  List<WarehouseAcceptanceListItem> _acceptances =
      const <WarehouseAcceptanceListItem>[];
  WarehouseAcceptanceListItem? _selectedAcceptance;
  WarehouseAcceptanceDetail? _selectedAcceptanceDetail;
  WarehouseAcceptanceResult? _lastAcceptanceResult;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String get warehouseNo => _warehouseNo;
  bool get isLoadingList => _isLoadingList;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isSubmitting => _isSubmitting;
  String? get listError => _listError;
  String? get detailError => _detailError;
  String? get submitError => _submitError;
  List<WarehouseAcceptanceListItem> get acceptances => _acceptances;
  WarehouseAcceptanceListItem? get selectedAcceptance => _selectedAcceptance;
  WarehouseAcceptanceDetail? get selectedAcceptanceDetail =>
      _selectedAcceptanceDetail;
  WarehouseAcceptanceResult? get lastAcceptanceResult => _lastAcceptanceResult;

  void clearSelection() {
    _detailEpoch.invalidate();
    _selectedAcceptance = null;
    _selectedAcceptanceDetail = null;
    _detailError = null;
    _submitError = null;
    _isLoadingDetail = false;
    notifySafely();
  }

  Future<void> loadAcceptances({
    bool preserveLastAcceptanceResult = false,
    String? preferredDocumentSerie,
    int? preferredDocumentOrderNo,
  }) async {
    final listRequestId = _listEpoch.next();
    _detailEpoch.invalidate();
    _isLoadingList = true;
    _listError = null;
    if (!preserveLastAcceptanceResult) {
      _lastAcceptanceResult = null;
    }
    notifySafely();

    try {
      final items = await _repository.fetchAcceptances(
        accessToken: _accessToken,
        filter: WarehouseAcceptanceListFilter(
          startDate: _startDate,
          endDate: _endDate,
          warehouseNo: _warehouseNo.trim().isEmpty ? null : _warehouseNo,
        ),
      );
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }

      _acceptances = items;
      _selectedAcceptance = items.isEmpty
          ? null
          : _findPreferredAcceptance(
                  items,
                  preferredDocumentSerie: preferredDocumentSerie,
                  preferredDocumentOrderNo: preferredDocumentOrderNo,
                ) ??
                items.first;
      _selectedAcceptanceDetail = null;
      _detailError = null;
      _submitError = null;
      _isLoadingList = false;
      notifySafely();

      if (_selectedAcceptance case final selectedAcceptance?) {
        await selectAcceptance(selectedAcceptance);
      }
    } on ApiException catch (error) {
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }
      _acceptances = const <WarehouseAcceptanceListItem>[];
      _selectedAcceptance = null;
      _selectedAcceptanceDetail = null;
      _isLoadingList = false;
      _listError = error.message;
      notifySafely();
    }
  }

  Future<void> selectAcceptance(WarehouseAcceptanceListItem item) async {
    final detailRequestId = _detailEpoch.next();
    _selectedAcceptance = item;
    _selectedAcceptanceDetail = null;
    _detailError = null;
    _submitError = null;
    _isLoadingDetail = true;
    notifySafely();

    try {
      final detail = await _repository.fetchAcceptanceDetail(
        accessToken: _accessToken,
        documentSerie: item.documentSerie,
        documentOrderNo: item.documentOrderNo,
        warehouseNo: _effectiveWarehouseNo,
      );
      if (!_detailEpoch.isCurrent(detailRequestId)) {
        return;
      }
      _selectedAcceptanceDetail = detail;
      _isLoadingDetail = false;
      notifySafely();
    } on ApiException catch (error) {
      if (!_detailEpoch.isCurrent(detailRequestId)) {
        return;
      }
      _selectedAcceptanceDetail = null;
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
    await loadAcceptances();
  }

  Future<WarehouseAcceptanceResult?> acceptShipment(
    WarehouseAcceptanceRequest request,
  ) async {
    final currentSelection = _selectedAcceptance;

    if (currentSelection == null) {
      _submitError = 'Mal kabul icin once bir bekleyen sevk secilmeli.';
      notifySafely();
      return null;
    }

    _isSubmitting = true;
    _submitError = null;
    notifySafely();

    try {
      final result = await _repository.acceptShipment(
        accessToken: _accessToken,
        documentSerie: currentSelection.documentSerie,
        documentOrderNo: currentSelection.documentOrderNo,
        request: request,
      );

      _lastAcceptanceResult = result;
      _isSubmitting = false;
      notifySafely();

      await loadAcceptances(preserveLastAcceptanceResult: true);

      return result;
    } on ApiException catch (error) {
      _isSubmitting = false;
      _submitError = error.message;
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

  WarehouseAcceptanceListItem? _findPreferredAcceptance(
    List<WarehouseAcceptanceListItem> items, {
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
