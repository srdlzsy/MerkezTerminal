import 'dart:typed_data';

import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';

class WarehouseReturnListFilter extends WarehouseShipmentListFilter {
  const WarehouseReturnListFilter({
    required super.startDate,
    required super.endDate,
    super.warehouseNo,
  });
}

typedef WarehouseReturnListItem = WarehouseShipmentListItem;
typedef WarehouseReturnDetail = WarehouseShipmentDetail;
typedef WarehouseReturnDetailHeader = WarehouseShipmentDetailHeader;
typedef WarehouseReturnDetailItem = WarehouseShipmentDetailItem;
typedef WarehouseReturnCreateRequest = WarehouseShipmentCreateRequest;
typedef WarehouseReturnCreateLine = WarehouseShipmentCreateLine;
typedef WarehouseReturnCreateResult = WarehouseShipmentCreateResult;

class ReturnableWarehouseProductsResult {
  const ReturnableWarehouseProductsResult({
    required this.sourceWarehouseNo,
    required this.sourceWarehouseName,
    required this.totalCount,
    required this.items,
  });

  final int sourceWarehouseNo;
  final String sourceWarehouseName;
  final int totalCount;
  final List<ReturnableWarehouseProduct> items;

  factory ReturnableWarehouseProductsResult.fromJson(JsonMap json) {
    final rawItems = json['items'];
    return ReturnableWarehouseProductsResult(
      sourceWarehouseNo: _readInt(json['sourceWarehouseNo']),
      sourceWarehouseName: _readString(json['sourceWarehouseName']),
      totalCount: _readInt(json['totalCount']),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => ReturnableWarehouseProduct.fromJson(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  ),
                )
                .toList(growable: false)
          : const <ReturnableWarehouseProduct>[],
    );
  }
}

class ReturnableWarehouseProduct {
  const ReturnableWarehouseProduct({
    required this.stockCode,
    required this.stockName,
    required this.barcode,
    required this.caseBarcode,
    required this.modelCode,
    required this.modelName,
    required this.unitName,
    required this.secondaryUnitName,
    required this.unitMultiplier,
    required this.productSourceWarehouseNo,
    required this.productSourceWarehouseName,
    required this.returnWarehouseNo,
    required this.returnWarehouseName,
    required this.currentStockQuantity,
    required this.returnableQuantity,
    required this.procurementType,
    required this.hasPurchaseRequirement,
    required this.isReturnable,
    required this.decision,
    required this.warnings,
  });

  final String stockCode;
  final String stockName;
  final String barcode;
  final String caseBarcode;
  final String modelCode;
  final String modelName;
  final String unitName;
  final String secondaryUnitName;
  final double unitMultiplier;
  final int productSourceWarehouseNo;
  final String productSourceWarehouseName;
  final int returnWarehouseNo;
  final String returnWarehouseName;
  final double currentStockQuantity;
  final double returnableQuantity;
  final String procurementType;
  final bool hasPurchaseRequirement;
  final bool isReturnable;
  final String decision;
  final List<String> warnings;

  String get displayLabel => '$stockCode - $stockName';

  String get routeLabel =>
      '$productSourceWarehouseName $productSourceWarehouseNo -> '
      '$returnWarehouseName $returnWarehouseNo';

  factory ReturnableWarehouseProduct.fromJson(JsonMap json) {
    return ReturnableWarehouseProduct(
      stockCode: _readString(json['stockCode']),
      stockName: _readString(json['stockName']),
      barcode: _readString(json['barcode']),
      caseBarcode: _readString(json['caseBarcode']),
      modelCode: _readString(json['modelCode']),
      modelName: _readString(json['modelName']),
      unitName: _readString(json['unitName']),
      secondaryUnitName: _readString(json['secondaryUnitName']),
      unitMultiplier: _readPositiveDouble(json['unitMultiplier']),
      productSourceWarehouseNo: _readInt(json['productSourceWarehouseNo']),
      productSourceWarehouseName: _readString(
        json['productSourceWarehouseName'],
      ),
      returnWarehouseNo: _readInt(json['returnWarehouseNo']),
      returnWarehouseName: _readString(json['returnWarehouseName']),
      currentStockQuantity: _readDouble(json['currentStockQuantity']),
      returnableQuantity: _readDouble(json['returnableQuantity']),
      procurementType: _readString(json['procurementType']),
      hasPurchaseRequirement: _readBool(json['hasPurchaseRequirement']),
      isReturnable: _readBool(json['isReturnable']),
      decision: _readString(json['decision']),
      warnings: _readStringList(json['warnings']),
    );
  }
}

enum WarehouseReturnDirection { outgoing, incoming }

extension WarehouseReturnDirectionX on WarehouseReturnDirection {
  String get pathSegment => switch (this) {
    WarehouseReturnDirection.outgoing => 'giden',
    WarehouseReturnDirection.incoming => 'gelen',
  };

  String get pageTitle => switch (this) {
    WarehouseReturnDirection.outgoing => 'Giden Depo Iadeleri',
    WarehouseReturnDirection.incoming => 'Gelen Depo Iadeleri',
  };

  String get headerTitle => switch (this) {
    WarehouseReturnDirection.outgoing => 'Kaynak sube iade akisi',
    WarehouseReturnDirection.incoming => 'Hedef sube iade akisi',
  };

  String get pageSubtitle => switch (this) {
    WarehouseReturnDirection.outgoing =>
      'Iade kayitlarini listeleyin, detaylari acin ve e-irsaliye hazirlayin.',
    WarehouseReturnDirection.incoming =>
      'Alici sube perspektifinde sadece liste ve detay akislarini gosterir.',
  };

  String get perspectiveLabel => switch (this) {
    WarehouseReturnDirection.outgoing => 'Kaynak sube',
    WarehouseReturnDirection.incoming => 'Alici sube',
  };

  bool get supportsEDespatch => this == WarehouseReturnDirection.outgoing;
}

class EDespatchSendRequest {
  const EDespatchSendRequest({
    this.driverId,
    required this.plaque,
    required this.driverNameSurname,
    required this.driverTckn,
  });

  final String? driverId;
  final String plaque;
  final String driverNameSurname;
  final String driverTckn;

  JsonMap toJson() {
    final normalizedDriverId = driverId?.trim() ?? '';
    final normalizedPlaque = plaque.trim();
    final normalizedDriverNameSurname = driverNameSurname.trim();
    final normalizedDriverTckn = driverTckn.trim();

    return <String, dynamic>{
      if (normalizedDriverId.isNotEmpty) 'driverId': normalizedDriverId,
      if (normalizedDriverId.isEmpty || normalizedPlaque.isNotEmpty)
        'plaque': normalizedPlaque,
      if (normalizedDriverId.isEmpty || normalizedDriverNameSurname.isNotEmpty)
        'driverNameSurname': normalizedDriverNameSurname,
      if (normalizedDriverId.isEmpty || normalizedDriverTckn.isNotEmpty)
        'driverTckn': normalizedDriverTckn,
    };
  }
}

class EDespatchSendResult {
  const EDespatchSendResult({
    required this.documentType,
    required this.documentSerie,
    required this.documentOrderNo,
    required this.eDespatchDocumentNo,
    required this.eDespatchUuid,
    required this.serviceDocumentId,
    required this.serviceDocumentNumber,
    required this.sentAt,
    required this.endpointUrl,
    this.localMikroMetadataUpdated = true,
    this.warning = '',
  });

  final int documentType;
  final String documentSerie;
  final int documentOrderNo;
  final String eDespatchDocumentNo;
  final String eDespatchUuid;
  final String serviceDocumentId;
  final String serviceDocumentNumber;
  final DateTime? sentAt;
  final String endpointUrl;
  final bool localMikroMetadataUpdated;
  final String warning;

  String get documentNoLabel => '$documentSerie.$documentOrderNo';
  String get serviceDocumentLabel => serviceDocumentNumber.isEmpty
      ? eDespatchDocumentNo
      : serviceDocumentNumber;
  bool get hasWarning =>
      !localMikroMetadataUpdated || warning.trim().isNotEmpty;
  String get warningMessage {
    final explicitWarning = warning.trim();
    if (explicitWarning.isNotEmpty) {
      return explicitWarning;
    }

    if (!localMikroMetadataUpdated) {
      return 'Uyumsoft gonderimi basarili, ancak lokal Mikro metadata isareti tamamlanamadi. Evrak tekrar gonderilmemeli.';
    }

    return '';
  }

  factory EDespatchSendResult.fromJson(JsonMap json) {
    return EDespatchSendResult(
      documentType: _readInt(json['documentType']),
      documentSerie: _readString(json['documentSerie']),
      documentOrderNo: _readInt(json['documentOrderNo']),
      eDespatchDocumentNo: _readString(json['eDespatchDocumentNo']),
      eDespatchUuid: _readString(json['eDespatchUuid']),
      serviceDocumentId: _readString(json['serviceDocumentId']),
      serviceDocumentNumber: _readString(json['serviceDocumentNumber']),
      sentAt: _readDate(json['sentAt']),
      endpointUrl: _readString(json['endpointUrl']),
      localMikroMetadataUpdated: _readBool(
        json['localMikroMetadataUpdated'],
        fallback: true,
      ),
      warning: _readString(json['warning']),
    );
  }
}

class WarehouseReturnPdfDocument {
  const WarehouseReturnPdfDocument({
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final Uint8List bytes;
}

DateTime? _readDate(Object? value) {
  final raw = value?.toString().trim();

  if (raw == null || raw.isEmpty) {
    return null;
  }

  return DateTime.tryParse(raw);
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

bool _readBool(Object? value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }

  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return fallback;
  }

  if (normalized == 'true' || normalized == '1') {
    return true;
  }

  if (normalized == 'false' || normalized == '0') {
    return false;
  }

  return fallback;
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
}

double _readPositiveDouble(Object? value) {
  final parsed = _readDouble(value).abs();
  return parsed > 0 ? parsed : 1;
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
