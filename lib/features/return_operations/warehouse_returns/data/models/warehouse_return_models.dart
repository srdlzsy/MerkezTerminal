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

enum WarehouseReturnDirection {
  outgoing,
  incoming,
}

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
      'Liste, detay, e-irsaliye ve PDF akislarini ayni kart yapisinda toplar.',
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
    required this.plaque,
    required this.driverNameSurname,
    required this.driverTckn,
  });

  final String plaque;
  final String driverNameSurname;
  final String driverTckn;

  JsonMap toJson() {
    return <String, dynamic>{
      'plaque': plaque.trim(),
      'driverNameSurname': driverNameSurname.trim(),
      'driverTckn': driverTckn.trim(),
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

  String get documentNoLabel => '$documentSerie.$documentOrderNo';

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
