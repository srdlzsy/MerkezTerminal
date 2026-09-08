import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';

class SearchProductLookupItem {
  const SearchProductLookupItem({
    required this.warehouseNo,
    required this.barcode,
    required this.stockCode,
    required this.stockName,
    required this.price,
    required this.priceTypeCode,
    this.purchasePrice = 0,
    this.purchaseGrossPrice = 0,
    this.purchasePriceSource = '',
    this.purchaseSupplierCode = '',
    this.modelCode = '',
    this.procurementType = '',
    this.sourceWarehouses = const <SearchProductSourceWarehouse>[],
    this.hasPurchaseRequirement = false,
    required this.unitName,
    required this.unitMultiplier,
    required this.secondaryUnitName,
    required this.secondaryUnitMultiplier,
    required this.salesBlockCode,
    required this.orderBlockCode,
    required this.goodsAcceptanceBlockCode,
    required this.isSalesBlocked,
    required this.isOrderBlocked,
    required this.isGoodsAcceptanceBlocked,
    required this.productManagerCode,
    this.warehouseName = '',
    this.currentStockQuantity,
    this.hasStock,
    this.requestedBarcode = '',
    this.lookupBarcode = '',
    this.isVariableWeightBarcode = false,
    this.embeddedQuantity,
    this.embeddedQuantityUnit = '',
    this.isBarcodeCheckDigitValid,
    this.isPassive = false,
    this.isDelisted = false,
    this.delistReason = '',
  });

  final int warehouseNo;
  final String barcode;
  final String stockCode;
  final String stockName;
  final double price;
  final int priceTypeCode;
  final double purchasePrice;
  final double purchaseGrossPrice;
  final String purchasePriceSource;
  final String purchaseSupplierCode;
  final String modelCode;
  final String procurementType;
  final List<SearchProductSourceWarehouse> sourceWarehouses;
  final bool hasPurchaseRequirement;
  final String unitName;
  final double unitMultiplier;
  final String secondaryUnitName;
  final double secondaryUnitMultiplier;
  final int? salesBlockCode;
  final int? orderBlockCode;
  final int? goodsAcceptanceBlockCode;
  final bool isSalesBlocked;
  final bool isOrderBlocked;
  final bool isGoodsAcceptanceBlocked;
  final String productManagerCode;
  final String warehouseName;
  final double? currentStockQuantity;
  final bool? hasStock;
  final String requestedBarcode;
  final String lookupBarcode;
  final bool isVariableWeightBarcode;
  final double? embeddedQuantity;
  final String embeddedQuantityUnit;
  final bool? isBarcodeCheckDigitValid;
  final bool isPassive;
  final bool isDelisted;
  final String delistReason;

  String get displayLabel => '$stockCode - $stockName';

  String get procurementTypeLabel {
    switch (procurementType.trim().toLowerCase()) {
      case 'warehouse':
        return 'Depo Urunu';
      case 'company':
        return 'Firma Urunu';
      case 'mixed':
        return 'Karisik Kaynak';
      case 'unassigned':
        return 'Kaynak Atanmamis';
      default:
        return procurementType.trim();
    }
  }

  List<String> get sourceInformationLabels => <String>[
    if (modelCode.trim().isNotEmpty) 'Model ${modelCode.trim()}',
    for (final warehouse in sourceWarehouses) warehouse.displayLabel,
    if (procurementTypeLabel.isNotEmpty) procurementTypeLabel,
    if (hasPurchaseRequirement) 'Alis Ihtiyaci Var',
  ];

  bool get needsStatusAttention => isPassive || isDelisted;

  String get statusWarningLabel {
    if (isDelisted && isPassive) {
      return 'Pasif / DLS';
    }
    if (isDelisted) {
      return 'DLS';
    }
    if (isPassive) {
      return 'Pasif';
    }
    return '';
  }

  double get companyAcceptanceUnitPrice =>
      purchasePrice > 0 ? purchasePrice : 0;

  factory SearchProductLookupItem.fromJson(JsonMap json) {
    return SearchProductLookupItem(
      warehouseNo: _readInt(json['warehouseNo']),
      barcode: _readString(json['barcode']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      price: _readDouble(json['price']),
      priceTypeCode: _readInt(json['priceTypeCode']),
      purchasePrice: _readDouble(json['purchasePrice']),
      purchaseGrossPrice: _readDouble(json['purchaseGrossPrice']),
      purchasePriceSource: _readString(json['purchasePriceSource']),
      purchaseSupplierCode: _readString(json['purchaseSupplierCode']),
      modelCode: _readString(json['modelCode']),
      procurementType: _readString(json['procurementType']),
      sourceWarehouses: _readSourceWarehouses(json['sourceWarehouses']),
      hasPurchaseRequirement: _readBool(json['hasPurchaseRequirement']),
      unitName: _readString(json['unitName']),
      unitMultiplier: _readProductUnitMultiplier(json),
      secondaryUnitName: _readString(json['secondaryUnitName']),
      secondaryUnitMultiplier: _readPositiveMagnitude(
        json['secondaryUnitMultiplier'],
        fallback: 0,
      ),
      salesBlockCode: _readNullableInt(json['salesBlockCode']),
      orderBlockCode: _readNullableInt(json['orderBlockCode']),
      goodsAcceptanceBlockCode: _readNullableInt(
        json['goodsAcceptanceBlockCode'],
      ),
      isSalesBlocked: _readBool(json['isSalesBlocked']),
      isOrderBlocked: _readBool(json['isOrderBlocked']),
      isGoodsAcceptanceBlocked: _readBool(json['isGoodsAcceptanceBlocked']),
      productManagerCode: _readString(json['productManagerCode']),
      warehouseName: _readString(json['warehouseName']),
      currentStockQuantity: _readNullableDouble(json['currentStockQuantity']),
      hasStock: _readNullableBool(json['hasStock']),
      requestedBarcode: _readString(json['requestedBarcode']),
      lookupBarcode: _readString(json['lookupBarcode']),
      isVariableWeightBarcode: _readBool(json['isVariableWeightBarcode']),
      embeddedQuantity: _readNullableDouble(json['embeddedQuantity']),
      embeddedQuantityUnit: _readString(json['embeddedQuantityUnit']),
      isBarcodeCheckDigitValid: _readNullableBool(
        json['isBarcodeCheckDigitValid'],
      ),
      isPassive: _readBool(json['isPassive']),
      isDelisted: _readBool(json['isDelisted']),
      delistReason: _readString(json['delistReason']),
    );
  }

  factory SearchProductLookupItem.fromBarcodeResolution(
    BarcodeResolutionResult resolution,
  ) {
    return SearchProductLookupItem(
      warehouseNo: resolution.warehouseNo,
      barcode: resolution.effectiveBarcode,
      stockCode: resolution.stockCode,
      stockName: resolution.stockName,
      price: resolution.salesPrice,
      priceTypeCode: resolution.priceTypeCode,
      purchasePrice: resolution.purchasePrice,
      purchaseGrossPrice: resolution.purchaseGrossPrice,
      purchasePriceSource: resolution.purchasePriceSource,
      purchaseSupplierCode: resolution.purchaseSupplierCode,
      modelCode: resolution.productModelCode,
      hasPurchaseRequirement: resolution.hasPurchaseRequirement ?? false,
      unitName: resolution.matchedUnitName,
      unitMultiplier: resolution.matchedUnitMultiplier,
      secondaryUnitName: '',
      secondaryUnitMultiplier: 0,
      salesBlockCode: null,
      orderBlockCode: null,
      goodsAcceptanceBlockCode: null,
      isSalesBlocked: resolution.isSalesBlocked,
      isOrderBlocked: resolution.isOrderBlocked,
      isGoodsAcceptanceBlocked: resolution.isGoodsAcceptanceBlocked,
      productManagerCode: '',
      isPassive: resolution.isPassive,
      isDelisted: resolution.isDelisted,
      delistReason: resolution.delistReason,
    );
  }
}

class SearchProductSourceWarehouse {
  const SearchProductSourceWarehouse({
    required this.warehouseNo,
    required this.warehouseName,
  });

  final int warehouseNo;
  final String warehouseName;

  String get displayLabel {
    final name = warehouseName.trim();
    if (name.isEmpty) {
      return 'Depo $warehouseNo';
    }
    return '$name $warehouseNo';
  }

  factory SearchProductSourceWarehouse.fromJson(JsonMap json) {
    return SearchProductSourceWarehouse(
      warehouseNo: _readInt(json['warehouseNo']),
      warehouseName: _readString(json['warehouseName']),
    );
  }
}

List<SearchProductSourceWarehouse> _readSourceWarehouses(Object? value) {
  if (value is! List) {
    return const <SearchProductSourceWarehouse>[];
  }

  return value
      .whereType<Map>()
      .map(
        (item) => SearchProductSourceWarehouse.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList(growable: false);
}

bool? _readNullableBool(Object? value) {
  if (value == null) {
    return null;
  }

  return _readBool(value);
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final raw = value?.toString().trim().toLowerCase();
  return raw == 'true' || raw == '1';
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double _readPositiveMagnitude(Object? value, {double fallback = 1}) {
  final parsed = _readDouble(value).abs();
  return parsed > 0 ? parsed : fallback;
}

double _readProductUnitMultiplier(JsonMap json) {
  for (final key in const <String>[
    'unitMultiplier',
    'packageFactor',
    'unitsPerCase',
    'matchedUnitsPerCase',
    'packageQuantity',
    'packageQty',
    'unitPerPackage',
    'unitsInPackage',
    'koliIciAdet',
    'koliIciMiktar',
    'koliMiktari',
    'secondaryUnitMultiplier',
  ]) {
    final value = _readDouble(json[key]).abs();
    if (value > 0) {
      return value;
    }
  }

  return 1;
}

double? _readNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

int _readInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readNullableInt(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

String _readString(Object? value) {
  return value?.toString() ?? '';
}
