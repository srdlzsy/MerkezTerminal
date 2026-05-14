import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/core/utils/request_epoch.dart';
import 'package:furpa_merkez_terminal/core/utils/safe_change_notifier.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';

class InventoryCountsController extends ChangeNotifier with SafeChangeNotifier {
  InventoryCountsController({
    required InventoryCountsRepository repository,
    required String accessToken,
    required String defaultWarehouseNo,
  }) : _repository = repository,
       _accessToken = accessToken,
       _defaultWarehouseNo = defaultWarehouseNo;

  final InventoryCountsRepository _repository;
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
  List<InventoryCountListItem> _counts = const <InventoryCountListItem>[];
  InventoryCountListItem? _selectedCount;
  InventoryCountDetail? _selectedCountDetail;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String get warehouseNo => _warehouseNo;
  bool get isLoadingList => _isLoadingList;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isCreating => _isCreating;
  String? get listError => _listError;
  String? get detailError => _detailError;
  String? get createError => _createError;
  List<InventoryCountListItem> get counts => _counts;
  InventoryCountListItem? get selectedCount => _selectedCount;
  InventoryCountDetail? get selectedCountDetail => _selectedCountDetail;

  void clearSelection() {
    _detailEpoch.invalidate();
    _selectedCount = null;
    _selectedCountDetail = null;
    _detailError = null;
    _isLoadingDetail = false;
    notifySafely();
  }

  Future<void> loadCounts({
    int? preferredDocumentNo,
    DateTime? preferredDocumentDate,
  }) async {
    final listRequestId = _listEpoch.next();
    _detailEpoch.invalidate();
    _isLoadingList = true;
    _listError = null;
    notifySafely();

    try {
      final items = await _repository.fetchCounts(
        accessToken: _accessToken,
        filter: InventoryCountListFilter(
          startDate: _startDate,
          endDate: _endDate,
          warehouseNo: _warehouseNo.trim().isEmpty ? null : _warehouseNo,
        ),
      );
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }

      _counts = items;
      _selectedCount = items.isEmpty
          ? null
          : _findPreferredCount(
                  items,
                  preferredDocumentNo: preferredDocumentNo,
                  preferredDocumentDate: preferredDocumentDate,
                ) ??
                items.first;
      _selectedCountDetail = null;
      _detailError = null;
      _isLoadingList = false;
      notifySafely();

      if (_selectedCount case final selectedCount?) {
        await selectCount(selectedCount);
      }
    } on ApiException catch (error) {
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }
      _counts = const <InventoryCountListItem>[];
      _selectedCount = null;
      _selectedCountDetail = null;
      _isLoadingList = false;
      _listError = error.message;
      notifySafely();
    }
  }

  Future<void> selectCount(InventoryCountListItem item) async {
    final detailRequestId = _detailEpoch.next();

    if (item.documentDate == null) {
      _selectedCount = item;
      _selectedCountDetail = null;
      _detailError = 'Belge tarihi eksik oldugu icin detay acilamadi.';
      _isLoadingDetail = false;
      notifySafely();
      return;
    }

    _selectedCount = item;
    _selectedCountDetail = null;
    _detailError = null;
    _isLoadingDetail = true;
    notifySafely();

    try {
      final detail = await _repository.fetchCountDetail(
        accessToken: _accessToken,
        documentNo: item.documentNo,
        documentDate: item.documentDate!,
        warehouseNo: _effectiveWarehouseNo,
      );
      if (!_detailEpoch.isCurrent(detailRequestId)) {
        return;
      }
      _selectedCountDetail = detail;
      _isLoadingDetail = false;
      notifySafely();
    } on ApiException catch (error) {
      if (!_detailEpoch.isCurrent(detailRequestId)) {
        return;
      }
      _selectedCountDetail = null;
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
    await loadCounts();
  }

  Future<InventoryCountCreateResult?> createCount(
    InventoryCountCreateRequest request,
  ) async {
    _isCreating = true;
    _createError = null;
    notifySafely();

    try {
      final result = await _repository.createCount(
        accessToken: _accessToken,
        request: request,
      );

      _isCreating = false;
      notifySafely();

      await loadCounts(
        preferredDocumentNo: result.documentNo,
        preferredDocumentDate: result.documentDate,
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

  InventoryCountListItem? _findPreferredCount(
    List<InventoryCountListItem> items, {
    int? preferredDocumentNo,
    DateTime? preferredDocumentDate,
  }) {
    if (preferredDocumentNo == null || preferredDocumentDate == null) {
      return null;
    }

    final targetDate = _normalizedDate(preferredDocumentDate);

    for (final item in items) {
      final itemDate = item.documentDate;
      if (item.documentNo == preferredDocumentNo &&
          itemDate != null &&
          _normalizedDate(itemDate) == targetDate) {
        return item;
      }
    }

    return null;
  }
}
