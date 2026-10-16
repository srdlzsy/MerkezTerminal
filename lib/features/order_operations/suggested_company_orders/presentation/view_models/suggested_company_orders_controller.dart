import 'package:flutter/foundation.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/utils/request_epoch.dart';
import 'package:furpa_merkez_terminal/core/utils/safe_change_notifier.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/data/models/suggested_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/data/suggested_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/shared/utils/safe_create_retry.dart';

class SuggestedCompanyOrdersController extends ChangeNotifier
    with SafeChangeNotifier {
  SuggestedCompanyOrdersController({
    required SuggestedCompanyOrdersRepository repository,
    required String accessToken,
  }) : _repository = repository,
       _accessToken = accessToken;

  final SuggestedCompanyOrdersRepository _repository;
  final String _accessToken;
  final RequestEpoch _listEpoch = RequestEpoch();

  String? _supplierCode;
  bool _isLoadingList = false;
  bool _isConverting = false;
  String? _listError;
  String? _convertError;
  SafeCreateFailureKind _convertFailureKind =
      SafeCreateFailureKind.notRetryable;
  String? _convertRelatedClientRequestId;
  String? _convertErrorCode;
  String? _convertCorrelationId;
  int? _convertRetryAfterSeconds;
  List<SuggestedCompanyOrderListItem> _items =
      const <SuggestedCompanyOrderListItem>[];
  Set<String> _selectedKeys = <String>{};
  Map<String, double> _quantityByKey = <String, double>{};

  String? get supplierCode => _supplierCode;
  bool get isLoadingList => _isLoadingList;
  bool get isConverting => _isConverting;
  String? get listError => _listError;
  String? get convertError => _convertError;
  SafeCreateFailureKind get convertFailureKind => _convertFailureKind;
  String? get convertRelatedClientRequestId => _convertRelatedClientRequestId;
  String? get convertErrorCode => _convertErrorCode;
  String? get convertCorrelationId => _convertCorrelationId;
  int? get convertRetryAfterSeconds => _convertRetryAfterSeconds;
  List<SuggestedCompanyOrderListItem> get items => _items;
  int get selectedCount => _selectedKeys.length;
  bool get hasSelection => _selectedKeys.isNotEmpty;

  double get selectedTotalQuantity {
    var total = 0.0;
    for (final key in _selectedKeys) {
      total += _quantityByKey[key] ?? 0;
    }
    return total;
  }

  double get selectedTotalAmount {
    var total = 0.0;
    for (final item in _items) {
      final key = item.identity;
      if (_selectedKeys.contains(key)) {
        total += item.lineAmount(_quantityByKey[key] ?? 0);
      }
    }
    return total;
  }

  bool isSelected(SuggestedCompanyOrderListItem item) {
    return _selectedKeys.contains(item.identity);
  }

  double quantityFor(SuggestedCompanyOrderListItem item) {
    return _quantityByKey[item.identity] ?? item.defaultOrderQuantity;
  }

  Future<void> loadSuggestions({
    required String supplierCode,
    int? warehouseNo,
    int? lookbackDays,
    int? fallbackRecommendedDay,
  }) async {
    final normalizedSupplierCode = supplierCode.trim();
    if (normalizedSupplierCode.isEmpty) {
      _supplierCode = null;
      _items = const <SuggestedCompanyOrderListItem>[];
      _selectedKeys = <String>{};
      _quantityByKey = <String, double>{};
      _listError = 'Firma/tedarikci secin.';
      notifySafely();
      return;
    }

    final listRequestId = _listEpoch.next();
    _supplierCode = normalizedSupplierCode;
    _isLoadingList = true;
    _listError = null;
    _convertError = null;
    notifySafely();

    try {
      final items = await _repository.fetchSuggestions(
        accessToken: _accessToken,
        filter: SuggestedCompanyOrderFilter(
          supplierCode: normalizedSupplierCode,
          warehouseNo: warehouseNo,
          lookbackDays: lookbackDays,
          fallbackRecommendedDay: fallbackRecommendedDay,
        ),
      );
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }

      _items = items;
      _selectedKeys = <String>{};
      _quantityByKey = <String, double>{
        for (final item in items) item.identity: item.defaultOrderQuantity,
      };
      _isLoadingList = false;
      notifySafely();
    } on ApiException catch (error) {
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }
      _items = const <SuggestedCompanyOrderListItem>[];
      _selectedKeys = <String>{};
      _quantityByKey = <String, double>{};
      _isLoadingList = false;
      _listError = error.message;
      notifySafely();
    } catch (error) {
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }
      _items = const <SuggestedCompanyOrderListItem>[];
      _selectedKeys = <String>{};
      _quantityByKey = <String, double>{};
      _isLoadingList = false;
      _listError = error.toString();
      notifySafely();
    }
  }

  void toggleItem(SuggestedCompanyOrderListItem item) {
    final key = item.identity;
    if (key.isEmpty || !item.canBeSelected) {
      return;
    }

    final nextSelection = Set<String>.from(_selectedKeys);
    if (nextSelection.contains(key)) {
      nextSelection.remove(key);
    } else {
      nextSelection.add(key);
      _quantityByKey[key] = quantityFor(item);
    }
    _selectedKeys = nextSelection;
    _convertError = null;
    notifySafely();
  }

  void selectAllSuggested() {
    _selectedKeys = _items
        .where((item) => item.canBeSelected)
        .map((item) => item.identity)
        .toSet();
    for (final item in _items) {
      _quantityByKey[item.identity] = quantityFor(item);
    }
    _convertError = null;
    notifySafely();
  }

  void clearSelection() {
    _selectedKeys = <String>{};
    _convertError = null;
    notifySafely();
  }

  void updateQuantity(SuggestedCompanyOrderListItem item, String rawValue) {
    final key = item.identity;
    if (key.isEmpty) {
      return;
    }
    _quantityByKey[key] = _readQuantity(rawValue);
    _convertError = null;
    notifySafely();
  }

  Future<CompanyOrderCreateResult?> convertSelected({
    required DateTime orderDate,
    required DateTime deliveryDate,
    required String description1,
    String description2 = '',
    String deliverer = '',
    String receiver = '',
    int? warehouseNo,
    String? clientRequestId,
    bool forceCreateNew = false,
    Future<void> Function(SuggestedCompanyOrderConvertRequest request)?
    onRequestPrepared,
  }) async {
    final supplierCode = _supplierCode?.trim() ?? '';
    if (supplierCode.isEmpty) {
      _convertError = 'Once firma/tedarikci ile onerileri listeleyin.';
      notifySafely();
      return null;
    }

    final lines = _buildSelectedLines();
    if (lines.isEmpty) {
      _convertError = 'Siparise cevirmek icin en az bir satir secin.';
      notifySafely();
      return null;
    }

    final request = SuggestedCompanyOrderConvertRequest(
      supplierCode: supplierCode,
      warehouseNo: warehouseNo,
      orderDate: _normalizedDate(orderDate),
      deliveryDate: _normalizedDate(deliveryDate),
      description1: description1,
      description2: description2,
      deliverer: deliverer,
      receiver: receiver,
      lines: lines,
      clientRequestId: clientRequestId,
      forceCreateNew: forceCreateNew,
    );
    if (onRequestPrepared != null) {
      await onRequestPrepared(request);
    }
    return submitConvertRequest(request);
  }

  Future<CompanyOrderCreateResult?> submitConvertRequest(
    SuggestedCompanyOrderConvertRequest request,
  ) async {
    if (_isConverting) return null;
    _isConverting = true;
    _convertError = null;
    _convertFailureKind = SafeCreateFailureKind.notRetryable;
    _convertRelatedClientRequestId = null;
    _convertErrorCode = null;
    _convertCorrelationId = null;
    _convertRetryAfterSeconds = null;
    notifySafely();

    try {
      final result = await _repository.convertToOrder(
        accessToken: _accessToken,
        request: request,
      );
      _isConverting = false;
      _selectedKeys = <String>{};
      notifySafely();
      return result;
    } on ApiException catch (error) {
      _isConverting = false;
      _convertFailureKind = classifySafeCreateException(error);
      _convertRelatedClientRequestId = error.relatedClientRequestId;
      _convertErrorCode = error.errorCode;
      _convertCorrelationId = error.correlationId;
      _convertRetryAfterSeconds = error.retryAfterSeconds;
      _convertError = safeCreateRetryErrorMessage(error);
      notifySafely();
      return null;
    } catch (error) {
      _isConverting = false;
      _convertError = error.toString();
      notifySafely();
      return null;
    }
  }

  List<SuggestedCompanyOrderConvertLine> _buildSelectedLines() {
    final lines = <SuggestedCompanyOrderConvertLine>[];
    for (final item in _items) {
      final key = item.identity;
      if (!_selectedKeys.contains(key)) {
        continue;
      }

      final quantity = _quantityByKey[key] ?? 0;
      if (quantity <= 0 || item.stockCode.trim().isEmpty) {
        continue;
      }

      lines.add(
        SuggestedCompanyOrderConvertLine(
          stockCode: item.stockCode,
          quantity: quantity,
          recommendedQuantity: item.suggestedOrderQuantity,
          unitPrice: item.purchasePrice,
          unitPointer: 1,
          description1: '',
          description2: '',
          packageCode: '',
          projectCode: '',
          customerResponsibilityCenter: '',
          productResponsibilityCenter: '',
        ),
      );
    }
    return lines;
  }

  static double _readQuantity(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return 0;
    }
    return double.tryParse(normalized) ?? 0;
  }

  static DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
