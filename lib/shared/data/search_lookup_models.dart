import 'package:furpa_merkez_terminal/core/network/api_client.dart';

class SearchProductLookupItem {
  const SearchProductLookupItem({
    required this.warehouseNo,
    required this.barcode,
    required this.stockCode,
    required this.stockName,
    required this.price,
    required this.priceTypeCode,
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
  });

  final int warehouseNo;
  final String barcode;
  final String stockCode;
  final String stockName;
  final double price;
  final int priceTypeCode;
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

  String get displayLabel => '$stockCode - $stockName';

  factory SearchProductLookupItem.fromJson(JsonMap json) {
    return SearchProductLookupItem(
      warehouseNo: _readInt(json['warehouseNo']),
      barcode: _readString(json['barcode']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      price: _readDouble(json['price']),
      priceTypeCode: _readInt(json['priceTypeCode']),
      unitName: _readString(json['unitName']),
      unitMultiplier: _readDouble(json['unitMultiplier']),
      secondaryUnitName: _readString(json['secondaryUnitName']),
      secondaryUnitMultiplier: _readDouble(json['secondaryUnitMultiplier']),
      salesBlockCode: _readNullableInt(json['salesBlockCode']),
      orderBlockCode: _readNullableInt(json['orderBlockCode']),
      goodsAcceptanceBlockCode: _readNullableInt(
        json['goodsAcceptanceBlockCode'],
      ),
      isSalesBlocked: _readBool(json['isSalesBlocked']),
      isOrderBlocked: _readBool(json['isOrderBlocked']),
      isGoodsAcceptanceBlocked: _readBool(json['isGoodsAcceptanceBlocked']),
      productManagerCode: _readString(json['productManagerCode']),
    );
  }
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
