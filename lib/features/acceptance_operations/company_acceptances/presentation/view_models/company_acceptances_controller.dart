import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/core/utils/request_epoch.dart';
import 'package:furpa_merkez_terminal/core/utils/safe_change_notifier.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/models/company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';

class CompanyAcceptancesController extends ChangeNotifier
    with SafeChangeNotifier {
  CompanyAcceptancesController({
    required CompanyAcceptancesRepository repository,
    required String accessToken,
    required String defaultWarehouseNo,
  }) : _repository = repository,
       _accessToken = accessToken,
       _defaultWarehouseNo = defaultWarehouseNo;

  final CompanyAcceptancesRepository _repository;
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
  List<CompanyMovementListItem> _acceptances =
      const <CompanyMovementListItem>[];
  CompanyMovementListItem? _selectedAcceptance;
  CompanyMovementDetail? _selectedAcceptanceDetail;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String get warehouseNo => _warehouseNo;
  bool get isLoadingList => _isLoadingList;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isCreating => _isCreating;
  String? get listError => _listError;
  String? get detailError => _detailError;
  String? get createError => _createError;
  List<CompanyMovementListItem> get acceptances => _acceptances;
  CompanyMovementListItem? get selectedAcceptance => _selectedAcceptance;
  CompanyMovementDetail? get selectedAcceptanceDetail =>
      _selectedAcceptanceDetail;

  void clearSelection() {
    _detailEpoch.invalidate();
    _selectedAcceptance = null;
    _selectedAcceptanceDetail = null;
    _detailError = null;
    _isLoadingDetail = false;
    notifySafely();
  }

  Future<void> loadAcceptances({
    String? preferredDocumentSerie,
    int? preferredDocumentOrderNo,
  }) async {
    final listRequestId = _listEpoch.next();
    _detailEpoch.invalidate();
    _isLoadingList = true;
    _listError = null;
    notifySafely();

    try {
      final items = await _repository.fetchAcceptances(
        accessToken: _accessToken,
        filter: CompanyMovementListFilter(
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
      _isLoadingList = false;
      notifySafely();

      if (_selectedAcceptance case final selectedAcceptance?) {
        await selectAcceptance(selectedAcceptance);
      }
    } on ApiException catch (error) {
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }
      _acceptances = const <CompanyMovementListItem>[];
      _selectedAcceptance = null;
      _selectedAcceptanceDetail = null;
      _isLoadingList = false;
      _listError = error.message;
      notifySafely();
    }
  }

  Future<void> selectAcceptance(CompanyMovementListItem item) async {
    final detailRequestId = _detailEpoch.next();
    _selectedAcceptance = item;
    _selectedAcceptanceDetail = null;
    _detailError = null;
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

  Future<CompanyAcceptanceCreateResult?> createAcceptance(
    CompanyAcceptanceCreateRequest request,
  ) async {
    _isCreating = true;
    _createError = null;
    notifySafely();

    try {
      final result = await _repository.createAcceptance(
        accessToken: _accessToken,
        request: request,
      );

      _isCreating = false;
      notifySafely();

      await loadAcceptances(
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

  CompanyMovementListItem? _findPreferredAcceptance(
    List<CompanyMovementListItem> items, {
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
