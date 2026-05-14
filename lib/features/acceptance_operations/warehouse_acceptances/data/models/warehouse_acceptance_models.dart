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

class WarehouseAcceptanceResult {
  const WarehouseAcceptanceResult({
    required this.documentSerie,
    required this.documentOrderNo,
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
      differenceResolutionStatus: _readString(json['differenceResolutionStatus']),
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
