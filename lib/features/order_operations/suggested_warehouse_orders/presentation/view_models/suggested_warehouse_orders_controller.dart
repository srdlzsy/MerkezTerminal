import 'package:flutter/foundation.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/utils/request_epoch.dart';
import 'package:furpa_merkez_terminal/core/utils/safe_change_notifier.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/models/suggested_warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/suggested_warehouse_orders_repository.dart';

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
  List<SuggestedWarehouseOrderListItem> _items =
      const <SuggestedWarehouseOrderListItem>[];
  Set<String> _selectedKeys = <String>{};
  Map<String, double> _quantityByKey = <String, double>{};

  int? get sourceWarehouseNo => _sourceWarehouseNo;
  bool get isLoadingList => _isLoadingList;
  bool get isConverting => _isConverting;
  String? get listError => _listError;
  String? get convertError => _convertError;
  List<SuggestedWarehouseOrderListItem> get items => _items;
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
      final items = await _repository.fetchSuggestions(
        accessToken: _accessToken,
        filter: SuggestedWarehouseOrderFilter(
          sourceWarehouseNo: sourceWarehouseNo,
          targetWarehouseNo: targetWarehouseNo,
          lookbackDays: lookbackDays,
          fallbackRecommendedDay: fallbackRecommendedDay,
          useSourceProducts: useSourceProducts ?? sourceWarehouseNo == 56,
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
      _items = const <SuggestedWarehouseOrderListItem>[];
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

    _isConverting = true;
    _convertError = null;
    notifySafely();

    try {
      final result = await _repository.convertToOrder(
        accessToken: _accessToken,
        request: SuggestedWarehouseOrderConvertRequest(
          sourceWarehouseNo: sourceWarehouseNo,
          targetWarehouseNo: targetWarehouseNo,
          orderDate: _normalizedDate(orderDate),
          deliveryDate: _normalizedDate(deliveryDate),
          description: description,
          lines: lines,
        ),
      );
      _isConverting = false;
      _selectedKeys = <String>{};
      notifySafely();
      return result;
    } on ApiException catch (error) {
      _isConverting = false;
      _convertError = error.message;
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

  static DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
