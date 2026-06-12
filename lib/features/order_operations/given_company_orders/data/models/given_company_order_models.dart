import 'package:furpa_merkez_terminal/core/network/api_client.dart';

class CompanyOrderListFilter {
  const CompanyOrderListFilter({
    required this.startDate,
    required this.endDate,
    this.warehouseNo,
    this.customerCode,
    this.onlyOpen,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String? warehouseNo;
  final String? customerCode;
  final bool? onlyOpen;

  Map<String, String> toQueryParameters() {
    return <String, String>{
      'StartDate': _toApiDate(startDate),
      'EndDate': _toApiDate(endDate),
      if (warehouseNo != null && warehouseNo!.trim().isNotEmpty)
        'WarehouseNo': warehouseNo!.trim(),
      if (customerCode != null && customerCode!.trim().isNotEmpty)
        'CustomerCode': customerCode!.trim(),
      if (onlyOpen != null) 'OnlyOpen': onlyOpen! ? 'true' : 'false',
    };
  }
}

class CompanyOrderCreateRequest {
  const CompanyOrderCreateRequest({
    required this.customerCode,
    required this.orderDate,
    required this.deliveryDate,
    required this.description1,
    required this.description2,
    required this.deliverer,
    required this.receiver,
    required this.lines,
  });

  final String customerCode;
  final DateTime orderDate;
  final DateTime deliveryDate;
  final String description1;
  final String description2;
  final String deliverer;
  final String receiver;
  final List<CompanyOrderCreateLine> lines;

  JsonMap toJson() {
    return <String, dynamic>{
      'customerCode': customerCode,
      'orderDate': _toApiDate(orderDate),
      'deliveryDate': _toApiDate(deliveryDate),
      'description1': description1,
      'description2': description2,
      'deliverer': deliverer,
      'receiver': receiver,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class CompanyOrderCreateLine {
  const CompanyOrderCreateLine({
    required this.stockCode,
    required this.quantity,
    required this.recommendedQuantity,
    required this.unitPrice,
    required this.unitPointer,
    required this.description1,
    required this.description2,
    required this.packageCode,
    required this.projectCode,
    required this.customerResponsibilityCenter,
    required this.productResponsibilityCenter,
  });

  final String stockCode;
  final double quantity;
  final double recommendedQuantity;
  final double unitPrice;
  final int unitPointer;
  final String description1;
  final String description2;
  final String packageCode;
  final String projectCode;
  final String customerResponsibilityCenter;
  final String productResponsibilityCenter;

  JsonMap toJson() {
    return <String, dynamic>{
      'stockCode': stockCode,
      'quantity': quantity,
      'recommendedQuantity': recommendedQuantity,
      'unitPrice': unitPrice,
      'unitPointer': unitPointer,
      'description1': description1,
      'description2': description2,
      'packageCode': packageCode,
      'projectCode': projectCode,
      'customerResponsibilityCenter': customerResponsibilityCenter,
      'productResponsibilityCenter': productResponsibilityCenter,
    };
  }
}

class CompanyOrderCreateResult {
  const CompanyOrderCreateResult({
    required this.documentSerie,
    required this.documentOrderNo,
    required this.orderDate,
    required this.deliveryDate,
    required this.warehouseNo,
    required this.customerCode,
    required this.lineCount,
    required this.totalQuantity,
    required this.totalAmount,
    required this.writeConnectionName,
  });

  final String documentSerie;
  final int documentOrderNo;
  final DateTime? orderDate;
  final DateTime? deliveryDate;
  final int warehouseNo;
  final String customerCode;
  final int lineCount;
  final double totalQuantity;
  final double totalAmount;
  final String writeConnectionName;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory CompanyOrderCreateResult.fromJson(JsonMap json) {
    return CompanyOrderCreateResult(
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      orderDate: _readDate(json['orderDate']),
      deliveryDate: _readDate(json['deliveryDate']),
      warehouseNo: _readInt(json['warehouseNo']),
      customerCode: _readString(json['customerCode']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
      writeConnectionName: _readString(json['writeConnectionName']),
    );
  }
}

class CustomerLookupItem {
  const CustomerLookupItem({
    required this.customerCode,
    required this.customerName,
    required this.customerTitle,
    required this.customerDisplayName,
    required this.taxNumber,
    required this.representativeCode,
    required this.representativeName,
    required this.invoiceAddressNo,
    required this.shippingAddressNo,
    required this.isLocked,
    required this.isClosed,
  });

  final String customerCode;
  final String customerName;
  final String customerTitle;
  final String customerDisplayName;
  final String taxNumber;
  final String representativeCode;
  final String representativeName;
  final int invoiceAddressNo;
  final int shippingAddressNo;
  final bool isLocked;
  final bool isClosed;

  String get displayLabel => '$customerCode - $customerDisplayName';

  factory CustomerLookupItem.fromJson(JsonMap json) {
    return CustomerLookupItem(
      customerCode: _readString(json['customerCode']),
      customerName: _readString(json['customerName']),
      customerTitle: _readString(json['customerTitle']),
      customerDisplayName: _readString(json['customerDisplayName']),
      taxNumber: _readString(json['taxNumber']),
      representativeCode: _readString(json['representativeCode']),
      representativeName: _readString(json['representativeName']),
      invoiceAddressNo: _readInt(json['invoiceAddressNo']),
      shippingAddressNo: _readInt(json['shippingAddressNo']),
      isLocked: _readBool(json['isLocked']),
      isClosed: _readBool(json['isClosed']),
    );
  }
}

class CompanyOrderProductLookupItem {
  const CompanyOrderProductLookupItem({
    required this.warehouseNo,
    required this.barcode,
    required this.stockCode,
    required this.stockName,
    required this.price,
    required this.unitName,
    this.unitMultiplier = 1,
    required this.isOrderBlocked,
    required this.isSalesBlocked,
  });

  final int warehouseNo;
  final String barcode;
  final String stockCode;
  final String stockName;
  final double price;
  final String unitName;
  final double unitMultiplier;
  final bool isOrderBlocked;
  final bool isSalesBlocked;

  String get displayLabel => '$stockCode - $stockName';

  factory CompanyOrderProductLookupItem.fromJson(JsonMap json) {
    return CompanyOrderProductLookupItem(
      warehouseNo: _readInt(json['warehouseNo']),
      barcode: _readString(json['barcode']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      price: _readDouble(json['price']),
      unitName: _readString(json['unitName']),
      unitMultiplier: _readPositiveDouble(json['unitMultiplier']),
      isOrderBlocked: _readBool(json['isOrderBlocked']),
      isSalesBlocked: _readBool(json['isSalesBlocked']),
    );
  }
}

class CompanyOrderListItem {
  const CompanyOrderListItem({
    required this.documentKey,
    required this.documentDate,
    required this.deliveryDate,
    required this.documentSerie,
    required this.documentOrderNo,
    required this.documentNumber,
    required this.warehouseNo,
    required this.customerCode,
    required this.customerName,
    required this.customerTitle,
    required this.customerDisplayName,
    required this.customerAddress,
    required this.description1,
    required this.description2,
    required this.deliverer,
    required this.receiver,
    required this.canBeCalled,
    required this.customerRepresentativeCode,
    required this.lineCount,
    required this.totalQuantity,
    required this.totalDeliveredQuantity,
    required this.totalRemainingQuantity,
    required this.isClosed,
    required this.totalAmount,
  });

  final String documentKey;
  final DateTime? documentDate;
  final DateTime? deliveryDate;
  final String documentSerie;
  final int documentOrderNo;
  final String documentNumber;
  final int warehouseNo;
  final String customerCode;
  final String customerName;
  final String customerTitle;
  final String customerDisplayName;
  final String customerAddress;
  final String description1;
  final String description2;
  final String deliverer;
  final String receiver;
  final bool canBeCalled;
  final String customerRepresentativeCode;
  final int lineCount;
  final double totalQuantity;
  final double totalDeliveredQuantity;
  final double totalRemainingQuantity;
  final bool isClosed;
  final double totalAmount;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory CompanyOrderListItem.fromJson(JsonMap json) {
    return CompanyOrderListItem(
      documentKey: _readString(json['documentKey']),
      documentDate: _readDate(json['documentDate']),
      deliveryDate: _readDate(json['deliveryDate']),
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      documentNumber: _readString(json['documentNumber']),
      warehouseNo: _readInt(json['warehouseNo']),
      customerCode: _readString(json['customerCode']),
      customerName: _readString(json['customerName']),
      customerTitle: _readString(json['customerTitle']),
      customerDisplayName: _readString(json['customerDisplayName']),
      customerAddress: _readString(json['customerAddress']),
      description1: _readString(json['description1']),
      description2: _readString(json['description2']),
      deliverer: _readString(json['deliverer']),
      receiver: _readString(json['receiver']),
      canBeCalled: _readBool(json['canBeCalled']),
      customerRepresentativeCode: _readString(
        json['customerRepresentativeCode'],
      ),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalDeliveredQuantity: _readDouble(json['totalDeliveredQuantity']),
      totalRemainingQuantity: _readDouble(json['totalRemainingQuantity']),
      isClosed: _readBool(json['isClosed']),
      totalAmount: _readDouble(json['totalAmount']),
    );
  }
}

class CompanyOrderDetail {
  const CompanyOrderDetail({required this.header, required this.items});

  final CompanyOrderDetailHeader header;
  final List<CompanyOrderDetailItem> items;

  factory CompanyOrderDetail.fromJson(JsonMap json) {
    return CompanyOrderDetail(
      header: CompanyOrderDetailHeader.fromJson(
        json['header'] as JsonMap? ?? <String, dynamic>{},
      ),
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => CompanyOrderDetailItem.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
    );
  }
}

class CompanyOrderDetailHeader {
  const CompanyOrderDetailHeader({
    required this.documentKey,
    required this.documentDate,
    required this.deliveryDate,
    required this.documentSerie,
    required this.documentOrderNo,
    required this.documentNumber,
    required this.warehouseNo,
    required this.warehouseName,
    required this.customerCode,
    required this.customerName,
    required this.customerTitle,
    required this.customerDisplayName,
    required this.customerAddress,
    required this.customerRepresentativeCode,
    required this.description1,
    required this.description2,
    required this.deliverer,
    required this.receiver,
    required this.canBeCalled,
    required this.lineCount,
    required this.totalQuantity,
    required this.totalDeliveredQuantity,
    required this.totalRemainingQuantity,
    required this.totalAmount,
    required this.isClosed,
  });

  final String documentKey;
  final DateTime? documentDate;
  final DateTime? deliveryDate;
  final String documentSerie;
  final int documentOrderNo;
  final String documentNumber;
  final int warehouseNo;
  final String warehouseName;
  final String customerCode;
  final String customerName;
  final String customerTitle;
  final String customerDisplayName;
  final String customerAddress;
  final String customerRepresentativeCode;
  final String description1;
  final String description2;
  final String deliverer;
  final String receiver;
  final bool canBeCalled;
  final int lineCount;
  final double totalQuantity;
  final double totalDeliveredQuantity;
  final double totalRemainingQuantity;
  final double totalAmount;
  final bool isClosed;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory CompanyOrderDetailHeader.fromJson(JsonMap json) {
    return CompanyOrderDetailHeader(
      documentKey: _readString(json['documentKey']),
      documentDate: _readDate(json['documentDate']),
      deliveryDate: _readDate(json['deliveryDate']),
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      documentNumber: _readString(json['documentNumber']),
      warehouseNo: _readInt(json['warehouseNo']),
      warehouseName: _readString(json['warehouseName']),
      customerCode: _readString(json['customerCode']),
      customerName: _readString(json['customerName']),
      customerTitle: _readString(json['customerTitle']),
      customerDisplayName: _readString(json['customerDisplayName']),
      customerAddress: _readString(json['customerAddress']),
      customerRepresentativeCode: _readString(
        json['customerRepresentativeCode'],
      ),
      description1: _readString(json['description1']),
      description2: _readString(json['description2']),
      deliverer: _readString(json['deliverer']),
      receiver: _readString(json['receiver']),
      canBeCalled: _readBool(json['canBeCalled']),
      lineCount: _readInt(json['lineCount']),
      totalQuantity: _readDouble(json['totalQuantity']),
      totalDeliveredQuantity: _readDouble(json['totalDeliveredQuantity']),
      totalRemainingQuantity: _readDouble(json['totalRemainingQuantity']),
      totalAmount: _readDouble(json['totalAmount']),
      isClosed: _readBool(json['isClosed']),
    );
  }
}

class CompanyOrderDetailItem {
  const CompanyOrderDetailItem({
    required this.lineNo,
    required this.stockCode,
    required this.stockName,
    required this.unitName,
    required this.unitPointer,
    required this.quantity,
    required this.deliveredQuantity,
    required this.remainingQuantity,
    required this.unitPrice,
    required this.lineAmount,
    required this.isClosed,
    required this.description,
    required this.packageCode,
    required this.projectCode,
    required this.orderGuid,
  });

  final int lineNo;
  final String stockCode;
  final String stockName;
  final String unitName;
  final int unitPointer;
  final double quantity;
  final double deliveredQuantity;
  final double remainingQuantity;
  final double unitPrice;
  final double lineAmount;
  final bool isClosed;
  final String description;
  final String packageCode;
  final String projectCode;
  final String orderGuid;

  factory CompanyOrderDetailItem.fromJson(JsonMap json) {
    return CompanyOrderDetailItem(
      lineNo: _readInt(json['lineNo']),
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      unitName: _readString(json['unitName']),
      unitPointer: _readInt(json['unitPointer']),
      quantity: _readDouble(json['quantity']),
      deliveredQuantity: _readDouble(json['deliveredQuantity']),
      remainingQuantity: _readDouble(json['remainingQuantity']),
      unitPrice: _readDouble(json['unitPrice']),
      lineAmount: _readDouble(json['lineAmount']),
      isClosed: _readBool(json['isClosed']),
      description: _readString(json['description']),
      packageCode: _readString(json['packageCode']),
      projectCode: _readString(json['projectCode']),
      orderGuid: _readString(json['orderGuid']),
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

String _toApiDate(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');

  return '${normalized.year}-$month-$day';
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

double _readPositiveDouble(Object? value, {double fallback = 1}) {
  final parsed = _readDouble(value);
  return parsed > 0 ? parsed : fallback;
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
