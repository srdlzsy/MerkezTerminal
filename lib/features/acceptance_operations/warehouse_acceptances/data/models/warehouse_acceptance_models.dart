import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';

class WarehouseAcceptanceListFilter extends WarehouseShipmentListFilter {
  const WarehouseAcceptanceListFilter({
    required super.startDate,
    required super.endDate,
    super.warehouseNo,
  });
}

typedef WarehouseAcceptanceListItem = WarehouseShipmentListItem;
typedef WarehouseAcceptanceDetail = WarehouseShipmentDetail;
typedef WarehouseAcceptanceDetailHeader = WarehouseShipmentDetailHeader;
typedef WarehouseAcceptanceDetailItem = WarehouseShipmentDetailItem;

class WarehouseAcceptanceRequest {
  const WarehouseAcceptanceRequest({
    required this.allowDiscrepancy,
    required this.lines,
  });

  final bool allowDiscrepancy;
  final List<WarehouseAcceptanceRequestLine> lines;

  JsonMap toJson() {
    return <String, dynamic>{
      'allowDiscrepancy': allowDiscrepancy,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class WarehouseAcceptanceRequestLine {
  const WarehouseAcceptanceRequestLine({
    required this.movementGuid,
    required this.receivedQuantity,
  });

  final String movementGuid;
  final double receivedQuantity;

  JsonMap toJson() {
    return <String, dynamic>{
      'movementGuid': movementGuid,
      'receivedQuantity': receivedQuantity,
    };
  }
}

enum WarehouseAcceptanceDifferenceScope {
  accepted,
  created;

  String get apiValue {
    return switch (this) {
      WarehouseAcceptanceDifferenceScope.accepted => 'accepted',
      WarehouseAcceptanceDifferenceScope.created => 'created',
    };
  }

  String get label {
    return switch (this) {
      WarehouseAcceptanceDifferenceScope.accepted => 'Kabul Ettigim',
      WarehouseAcceptanceDifferenceScope.created => 'Olusturdugum',
    };
  }
}

class WarehouseAcceptanceDifferenceFilter {
  const WarehouseAcceptanceDifferenceFilter({
    required this.startDate,
    required this.endDate,
    required this.scope,
    this.warehouseNo,
  });

  final DateTime startDate;
  final DateTime endDate;
  final WarehouseAcceptanceDifferenceScope scope;
  final String? warehouseNo;

  Map<String, String> toQueryParameters() {
    return <String, String>{
      'StartDate': _toApiDate(startDate),
      'EndDate': _toApiDate(endDate),
      'scope': scope.apiValue,
      if (warehouseNo != null && warehouseNo!.trim().isNotEmpty)
        'WarehouseNo': warehouseNo!.trim(),
    };
  }
}

class WarehouseAcceptanceDifferenceItem {
  const WarehouseAcceptanceDifferenceItem({
    required this.documentDate,
    required this.movementDate,
    required this.documentNo,
    required this.documentSerie,
    required this.documentOrderNo,
    required this.lineNo,
    required this.movementGuid,
    required this.isReturn,
    required this.sourceWarehouseNo,
    required this.sourceWarehouse,
    required this.targetWarehouseNo,
    required this.targetWarehouse,
    required this.productCode,
    required this.productName,
    required this.unitName,
    required this.unitPointer,
    required this.quantity,
    required this.receivedQuantity,
    required this.differenceQuantity,
    required this.differenceType,
    required this.description,
  });

  final DateTime? documentDate;
  final DateTime? movementDate;
  final String documentNo;
  final String documentSerie;
  final int documentOrderNo;
  final int lineNo;
  final String movementGuid;
  final bool isReturn;
  final int sourceWarehouseNo;
  final String sourceWarehouse;
  final int targetWarehouseNo;
  final String targetWarehouse;
  final String productCode;
  final String productName;
  final String unitName;
  final int unitPointer;
  final double quantity;
  final double receivedQuantity;
  final double differenceQuantity;
  final String differenceType;
  final String description;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  String get typeLabel => isReturn ? 'Iade' : 'Sevk';

  String get shortGuid {
    if (movementGuid.length <= 8) {
      return movementGuid;
    }

    return movementGuid.substring(0, 8);
  }

  factory WarehouseAcceptanceDifferenceItem.fromJson(JsonMap json) {
    return WarehouseAcceptanceDifferenceItem(
      documentDate: _readDate(json['documentDate']),
      movementDate: _readDate(json['movementDate']),
      documentNo: _readString(json['documentNo']),
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      lineNo: _readInt(json['lineNo']),
      movementGuid: _readString(json['movementGuid']),
      isReturn: _readBool(json['isReturn']),
      sourceWarehouseNo: _readInt(json['sourceWarehouseNo']),
      sourceWarehouse: _readString(json['sourceWarehouse']),
      targetWarehouseNo: _readInt(json['targetWarehouseNo']),
      targetWarehouse: _readString(json['targetWarehouse']),
      productCode: _readString(json['productCode']),
      productName: _readString(json['productName']),
      unitName: _readString(json['unitName']),
      unitPointer: _readInt(json['unitPointer']),
      quantity: _readDouble(json['quantity']),
      receivedQuantity: _readDouble(json['receivedQuantity']),
      differenceQuantity: _readDouble(json['differenceQuantity']),
      differenceType: _readString(json['differenceType']),
      description: _readString(json['description']),
    );
  }
}

class WarehouseAcceptanceResult {
  const WarehouseAcceptanceResult({
    required this.documentSerie,
    required this.documentOrderNo,
    this.isReturn = false,
    required this.warehouseNo,
    required this.sourceWarehouseNo,
    required this.transitWarehouseNo,
    required this.shippingState,
    required this.lineCount,
    required this.totalShippedQuantity,
    required this.totalReceivedQuantity,
    required this.totalMissingQuantity,
    required this.totalExcessQuantity,
    required this.hasDiscrepancy,
    required this.differenceResolutionStatus,
    required this.writeConnectionName,
    required this.lines,
  });

  final String documentSerie;
  final int documentOrderNo;
  final bool isReturn;
  final int warehouseNo;
  final int sourceWarehouseNo;
  final int transitWarehouseNo;
  final int shippingState;
  final int lineCount;
  final double totalShippedQuantity;
  final double totalReceivedQuantity;
  final double totalMissingQuantity;
  final double totalExcessQuantity;
  final bool hasDiscrepancy;
  final String differenceResolutionStatus;
  final String writeConnectionName;
  final List<WarehouseAcceptanceResultLine> lines;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

  factory WarehouseAcceptanceResult.fromJson(JsonMap json) {
    return WarehouseAcceptanceResult(
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      isReturn: _readBool(json['isReturn']),
      warehouseNo: _readInt(json['warehouseNo']),
      sourceWarehouseNo: _readInt(json['sourceWarehouseNo']),
      transitWarehouseNo: _readInt(json['transitWarehouseNo']),
      shippingState: _readInt(json['shippingState']),
      lineCount: _readInt(json['lineCount']),
      totalShippedQuantity: _readDouble(json['totalShippedQuantity']),
      totalReceivedQuantity: _readDouble(json['totalReceivedQuantity']),
      totalMissingQuantity: _readDouble(json['totalMissingQuantity']),
      totalExcessQuantity: _readDouble(json['totalExcessQuantity']),
      hasDiscrepancy: _readBool(json['hasDiscrepancy']),
      differenceResolutionStatus: _readString(
        json['differenceResolutionStatus'],
      ),
      writeConnectionName: _readString(json['writeConnectionName']),
      lines: (json['lines'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => WarehouseAcceptanceResultLine.fromJson(
              item as JsonMap? ?? <String, dynamic>{},
            ),
          )
          .toList(growable: false),
    );
  }
}

class WarehouseAcceptanceResultLine {
  const WarehouseAcceptanceResultLine({
    required this.movementGuid,
    required this.lineNo,
    required this.stockCode,
    required this.shippedQuantity,
    required this.receivedQuantity,
    required this.differenceQuantity,
    required this.differenceType,
  });

  final String movementGuid;
  final int lineNo;
  final String stockCode;
  final double shippedQuantity;
  final double receivedQuantity;
  final double differenceQuantity;
  final String differenceType;

  factory WarehouseAcceptanceResultLine.fromJson(JsonMap json) {
    return WarehouseAcceptanceResultLine(
      movementGuid: _readString(json['movementGuid']),
      lineNo: _readInt(json['lineNo']),
      stockCode: _readString(json['stockCode']),
      shippedQuantity: _readDouble(json['shippedQuantity']),
      receivedQuantity: _readDouble(json['receivedQuantity']),
      differenceQuantity: _readDouble(json['differenceQuantity']),
      differenceType: _readString(json['differenceType']),
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

  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
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

DateTime? _readDate(Object? value) {
  final raw = value?.toString().trim();

  if (raw == null || raw.isEmpty) {
    return null;
  }

  return DateTime.tryParse(raw);
}

String _toApiDate(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');

  return '${normalized.year}-$month-$day';
}
