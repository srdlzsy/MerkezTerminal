import 'package:furpa_merkez_terminal/core/network/api_client.dart';

class CreateLabelDocumentRequest {
  const CreateLabelDocumentRequest({required this.lines});

  final List<CreateLabelDocumentLine> lines;

  JsonMap toJson() {
    return <String, dynamic>{
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class CreateLabelDocumentLine {
  const CreateLabelDocumentLine({required this.productCode});

  final String productCode;

  JsonMap toJson() {
    return <String, dynamic>{'productCode': productCode};
  }
}

class CreateLabelDocumentResult {
  const CreateLabelDocumentResult({
    required this.documentId,
    required this.createDate,
    required this.warehouseNo,
    required this.lineCount,
  });

  final int documentId;
  final DateTime? createDate;
  final int warehouseNo;
  final int lineCount;

  factory CreateLabelDocumentResult.fromJson(JsonMap json) {
    return CreateLabelDocumentResult(
      documentId: _readInt(json['documentId']),
      createDate: _readDate(json['createDate']),
      warehouseNo: _readInt(json['warehouseNo']),
      lineCount: _readInt(json['lineCount']),
    );
  }
}

class LabelDocumentListItem {
  const LabelDocumentListItem({
    required this.documentId,
    required this.createDate,
    required this.warehouseNo,
  });

  final int documentId;
  final DateTime? createDate;
  final int warehouseNo;

  factory LabelDocumentListItem.fromJson(JsonMap json) {
    return LabelDocumentListItem(
      documentId: _readInt(json['documentId']),
      createDate: _readDate(json['createDate']),
      warehouseNo: _readInt(json['warehouseNo']),
    );
  }
}

class LabelDocumentProduct {
  const LabelDocumentProduct({
    required this.package,
    required this.packageFactor,
    required this.lastUpdateDate,
    required this.barcodeContent,
    required this.bulkSaleTaxRate,
    required this.retailSaleTaxRate,
    required this.productCode,
    required this.productName,
    required this.barcode,
    required this.oldPrice,
    required this.price,
    required this.priceChangeDate,
    required this.supplierCode,
    required this.isClosedToSale,
    required this.isClosedToOrder,
    required this.isClosedToReceiving,
    required this.isPassive,
    required this.unitName,
    required this.unitName2,
    required this.typeCode,
    required this.isDomestic,
    required this.origin,
    required this.unitPriceFactor,
    required this.alternativeUnitName,
    required this.pluNo,
    required this.sectorCode,
    required this.shelfLife,
    required this.type,
    required this.orderGuid,
    required this.canBeCalled,
    required this.quantity,
    required this.documentOrderNo,
    required this.categoryCode,
  });

  final String package;
  final String packageFactor;
  final DateTime? lastUpdateDate;
  final String barcodeContent;
  final int bulkSaleTaxRate;
  final int retailSaleTaxRate;
  final String productCode;
  final String productName;
  final String barcode;
  final double oldPrice;
  final double price;
  final String priceChangeDate;
  final String supplierCode;
  final int isClosedToSale;
  final int isClosedToOrder;
  final int isClosedToReceiving;
  final bool isPassive;
  final String unitName;
  final String unitName2;
  final String typeCode;
  final int isDomestic;
  final String origin;
  final double unitPriceFactor;
  final String alternativeUnitName;
  final int pluNo;
  final String sectorCode;
  final int shelfLife;
  final String type;
  final String orderGuid;
  final bool canBeCalled;
  final double quantity;
  final int documentOrderNo;
  final String categoryCode;

  factory LabelDocumentProduct.fromJson(JsonMap json) {
    return LabelDocumentProduct(
      package: _readString(json['package']),
      packageFactor: _readString(json['packageFactor']),
      lastUpdateDate: _readDate(json['lastUpdateDate']),
      barcodeContent: _readString(json['barcodeContent']),
      bulkSaleTaxRate: _readInt(json['bulkSaleTaxRate']),
      retailSaleTaxRate: _readInt(json['retailSaleTaxRate']),
      productCode: _readString(json['productCode']),
      productName: _readString(json['productName']),
      barcode: _readString(json['barcode']),
      oldPrice: _readDouble(json['oldPrice']),
      price: _readDouble(json['price']),
      priceChangeDate: _readString(json['priceChangeDate']),
      supplierCode: _readString(json['supplierCode']),
      isClosedToSale: _readInt(json['isClosedToSale']),
      isClosedToOrder: _readInt(json['isClosedToOrder']),
      isClosedToReceiving: _readInt(json['isClosedToReceiving']),
      isPassive: _readBool(json['isPassive']),
      unitName: _readString(json['unitName']),
      unitName2: _readString(json['unitName2']),
      typeCode: _readString(json['typeCode']),
      isDomestic: _readInt(json['isDomestic']),
      origin: _readString(json['origin']),
      unitPriceFactor: _readDouble(json['unitPriceFactor']),
      alternativeUnitName: _readString(json['alternativeUnitName']),
      pluNo: _readInt(json['pluNo']),
      sectorCode: _readString(json['sectorCode']),
      shelfLife: _readInt(json['shelfLife']),
      type: _readString(json['type']),
      orderGuid: _readString(json['orderGuid']),
      canBeCalled: _readBool(json['canBeCalled']),
      quantity: _readDouble(json['quantity']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      categoryCode: _readString(json['categoryCode']),
    );
  }
}

class LabelPriceChangedProduct {
  const LabelPriceChangedProduct({
    required this.productCode,
    required this.productName,
    required this.pluNo,
    required this.alternativeUnitName,
    required this.barcode,
    required this.isDomestic,
    required this.oldPrice,
    required this.origin,
    required this.price,
    required this.priceChangeDate,
    required this.unitPriceFactor,
    required this.unitName,
  });

  final String productCode;
  final String productName;
  final int pluNo;
  final String alternativeUnitName;
  final String barcode;
  final int isDomestic;
  final double oldPrice;
  final String origin;
  final double price;
  final String priceChangeDate;
  final double unitPriceFactor;
  final String unitName;

  factory LabelPriceChangedProduct.fromJson(JsonMap json) {
    return LabelPriceChangedProduct(
      productCode: _readString(json['productCode']),
      productName: _readString(json['productName']),
      pluNo: _readInt(json['pluNo']),
      alternativeUnitName: _readString(json['alternativeUnitName']),
      barcode: _readString(json['barcode']),
      isDomestic: _readInt(json['isDomestic']),
      oldPrice: _readDouble(json['oldPrice']),
      origin: _readString(json['origin']),
      price: _readDouble(json['price']),
      priceChangeDate: _readString(json['priceChangeDate']),
      unitPriceFactor: _readDouble(json['unitPriceFactor']),
      unitName: _readString(json['unitName']),
    );
  }
}

class LabelTag {
  const LabelTag({
    required this.branchNo,
    required this.branchName,
    required this.productionCity,
    required this.productionDistrict,
    required this.productName,
    required this.goodsType,
    required this.goodsGenus,
    required this.quantity,
    required this.takenTag,
    required this.buyer,
    required this.productionDate,
    required this.buyingPrice,
    required this.shippingDate,
    required this.manufacturer,
  });

  final int branchNo;
  final String branchName;
  final String productionCity;
  final String productionDistrict;
  final String productName;
  final String goodsType;
  final String goodsGenus;
  final double quantity;
  final String takenTag;
  final String buyer;
  final DateTime? productionDate;
  final double buyingPrice;
  final DateTime? shippingDate;
  final String manufacturer;

  factory LabelTag.fromJson(JsonMap json) {
    return LabelTag(
      branchNo: _readInt(json['branchNo']),
      branchName: _readString(json['branchName']),
      productionCity: _readString(json['productionCity']),
      productionDistrict: _readString(json['productionDistrict']),
      productName: _readString(json['productName']),
      goodsType: _readString(json['goodsType']),
      goodsGenus: _readString(json['goodsGenus']),
      quantity: _readDouble(json['quantity']),
      takenTag: _readString(json['takenTag']),
      buyer: _readString(json['buyer']),
      productionDate: _readDate(json['productionDate']),
      buyingPrice: _readDouble(json['buyingPrice']),
      shippingDate: _readDate(json['shippingDate']),
      manufacturer: _readString(json['manufacturer']),
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

DateTime? _readDate(Object? value) {
  final raw = value?.toString().trim();

  if (raw == null || raw.isEmpty) {
    return null;
  }

  return DateTime.tryParse(raw);
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

String _readString(Object? value) {
  return value?.toString() ?? '';
}
