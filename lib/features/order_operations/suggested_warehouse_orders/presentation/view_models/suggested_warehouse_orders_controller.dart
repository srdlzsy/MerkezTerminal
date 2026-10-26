import 'package:flutter/foundation.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/utils/request_epoch.dart';
import 'package:furpa_merkez_terminal/core/utils/safe_change_notifier.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/models/suggested_warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/suggested_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/shared/utils/safe_create_retry.dart';

class SuggestedWarehouseOrdersController extends ChangeNotifier
    with SafeChangeNotifier {
  SuggestedWarehouseOrdersController({
    required SuggestedWarehouseOrdersRepository repository,
    required String accessToken,
  }) : _repository = repository,
       _accessToken = accessToken;

  final SuggestedWarehouseOrdersRepository _repository;
  final String _accessToken;
  final RequestEpoch _listEpoch = RequestEpoch();

  int? _sourceWarehouseNo;
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
  List<SuggestedWarehouseOrderListItem> _items =
      const <SuggestedWarehouseOrderListItem>[];
  SuggestedWarehouseOrderAnalysis? _analysis;
  Set<String> _selectedKeys = <String>{};
  Map<String, double> _quantityByKey = <String, double>{};

  int? get sourceWarehouseNo => _sourceWarehouseNo;
  bool get isLoadingList => _isLoadingList;
  bool get isConverting => _isConverting;
  String? get listError => _listError;
  String? get convertError => _convertError;
  SafeCreateFailureKind get convertFailureKind => _convertFailureKind;
  String? get convertRelatedClientRequestId => _convertRelatedClientRequestId;
  String? get convertErrorCode => _convertErrorCode;
  String? get convertCorrelationId => _convertCorrelationId;
  int? get convertRetryAfterSeconds => _convertRetryAfterSeconds;
  List<SuggestedWarehouseOrderListItem> get items => _items;
  SuggestedWarehouseOrderAnalysis? get analysis => _analysis;
  int get selectedCount => _selectedKeys.length;
  bool get hasSelection => _selectedKeys.isNotEmpty;

  double get selectedTotalQuantity {
    var total = 0.0;
    for (final key in _selectedKeys) {
      total += _quantityByKey[key] ?? 0;
    }
    return total;
  }

  bool isSelected(SuggestedWarehouseOrderListItem item) {
    return _selectedKeys.contains(item.identity);
  }

  double quantityFor(SuggestedWarehouseOrderListItem item) {
    return _quantityByKey[item.identity] ?? item.defaultOrderQuantity;
  }

  Future<void> loadSuggestions({
    required int sourceWarehouseNo,
    int? targetWarehouseNo,
    int? lookbackDays,
    int? fallbackRecommendedDay,
    bool? useSourceProducts,
  }) async {
    if (sourceWarehouseNo <= 0) {
      _sourceWarehouseNo = null;
      _items = const <SuggestedWarehouseOrderListItem>[];
      _analysis = null;
      _selectedKeys = <String>{};
      _quantityByKey = <String, double>{};
      _listError = 'Kaynak depo secin.';
      notifySafely();
      return;
    }

    final listRequestId = _listEpoch.next();
    _sourceWarehouseNo = sourceWarehouseNo;
    _isLoadingList = true;
    _listError = null;
    _convertError = null;
    notifySafely();

    try {
      final filter = SuggestedWarehouseOrderFilter(
        sourceWarehouseNo: sourceWarehouseNo,
        targetWarehouseNo: targetWarehouseNo,
        lookbackDays: lookbackDays,
        fallbackRecommendedDay: fallbackRecommendedDay,
        useSourceProducts:
            useSourceProducts ??
            usesSuggestedWarehouseOrderSourceProducts(sourceWarehouseNo),
      );
      final analysisRepository =
          _repository is SuggestedWarehouseOrderAnalysisRepository
          ? _repository as SuggestedWarehouseOrderAnalysisRepository
          : null;
      final analysis = !filter.useSourceProducts && analysisRepository != null
          ? await analysisRepository.fetchSuggestionAnalysis(
              accessToken: _accessToken,
              filter: filter,
            )
          : null;
      final items =
          analysis?.items ??
          await _repository.fetchSuggestions(
            accessToken: _accessToken,
            filter: filter,
          );
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }

      _items = items;
      _analysis = analysis;
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
      _items = const <SuggestedWarehouseOrderListItem>[];
      _analysis = null;
      _selectedKeys = <String>{};
      _quantityByKey = <String, double>{};
      _isLoadingList = false;
      _listError = error.message;
      notifySafely();
    } catch (error) {
      if (!_listEpoch.isCurrent(listRequestId)) {
        return;
      }
      _items = const <SuggestedWarehouseOrderListItem>[];
      _analysis = null;
      _selectedKeys = <String>{};
      _quantityByKey = <String, double>{};
      _isLoadingList = false;
      _listError = error.toString();
      notifySafely();
    }
  }

  void toggleItem(SuggestedWarehouseOrderListItem item) {
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
        .where((item) => item.canBeAutoSelected)
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

  void updateQuantity(SuggestedWarehouseOrderListItem item, String rawValue) {
    final key = item.identity;
    if (key.isEmpty) {
      return;
    }
    _quantityByKey[key] = _readQuantity(rawValue);
    _convertError = null;
    notifySafely();
  }

  Future<WarehouseOrderCreateResult?> convertSelected({
    required DateTime orderDate,
    required DateTime deliveryDate,
    required String description,
    int? targetWarehouseNo,
    String? clientRequestId,
    bool forceCreateNew = false,
    Future<void> Function(SuggestedWarehouseOrderConvertRequest request)?
    onRequestPrepared,
  }) async {
    final sourceWarehouseNo = _sourceWarehouseNo;
    if (sourceWarehouseNo == null || sourceWarehouseNo <= 0) {
      _convertError = 'Once kaynak depo ile onerileri listeleyin.';
      notifySafely();
      return null;
    }

    if (_selectedKeys.isEmpty) {
      _convertError = 'Siparise cevirmek icin en az bir satir secin.';
      notifySafely();
      return null;
    }

    final quantityError = _validateSelectedQuantities();
    if (quantityError != null) {
      _convertError = quantityError;
      notifySafely();
      return null;
    }

    final lines = _buildSelectedLines();
    if (lines.isEmpty) {
      _convertError = 'Siparise cevirmek icin en az bir gecerli satir secin.';
      notifySafely();
      return null;
    }

    final request = SuggestedWarehouseOrderConvertRequest(
      sourceWarehouseNo: sourceWarehouseNo,
      targetWarehouseNo: targetWarehouseNo,
      orderDate: _normalizedDate(orderDate),
      deliveryDate: _normalizedDate(deliveryDate),
      description: description,
      lines: lines,
      clientRequestId: clientRequestId,
      forceCreateNew: forceCreateNew,
    );
    if (onRequestPrepared != null) {
      await onRequestPrepared(request);
    }
    return submitConvertRequest(request);
  }

  Future<WarehouseOrderCreateResult?> submitConvertRequest(
    SuggestedWarehouseOrderConvertRequest request,
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

  List<SuggestedWarehouseOrderConvertLine> _buildSelectedLines() {
    final lines = <SuggestedWarehouseOrderConvertLine>[];
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
        SuggestedWarehouseOrderConvertLine(
          stockCode: item.stockCode,
          quantity: quantity,
          recommendedQuantity: item.recommendedQuantity > 0
              ? item.recommendedQuantity
              : item.suggestedOrderQuantity,
          unitPrice: item.unitPrice,
          unitPointer: item.unitPointer,
          description: '',
          packageCode: '',
          projectCode: '',
          responsibilityCenter: '',
        ),
      );
    }
    return lines;
  }

  String? _validateSelectedQuantities() {
    for (final item in _items) {
      final key = item.identity;
      if (!_selectedKeys.contains(key)) {
        continue;
      }

      final quantity = _quantityByKey[key] ?? 0;
      if (quantity <= 0) {
        return '${item.stockCode} icin siparis miktari sifirdan buyuk olmali.';
      }
      if (item.sourceOnHand > 0 && quantity > item.sourceOnHand) {
        return '${item.stockCode} icin siparis miktari kaynak stoktan buyuk olamaz.';
      }
      if (_sourceWarehouseNo == 50) {
        final factor = item.packageFactor.abs();
        final ratio = factor > 1 ? quantity / factor : 0;
        if (factor > 1 && (ratio - ratio.roundToDouble()).abs() >= 0.000001) {
          final lower = ratio.floorToDouble() * factor;
          final upper = ratio.ceilToDouble() * factor;
          final validQuantities = lower > 0
              ? '${_formatQuantity(lower)} veya ${_formatQuantity(upper)}'
              : _formatQuantity(upper);
          return '${item.stockCode} icin miktar ${_formatQuantity(factor)} '
              'koli katinda olmali. En yakin gecerli miktar: '
              '$validQuantities.';
        }
      }
    }
    return null;
  }

  static double _readQuantity(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return 0;
    }
    return double.tryParse(normalized) ?? 0;
  }

  static String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
