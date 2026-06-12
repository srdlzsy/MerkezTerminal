import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/order_operations/received_warehouse_orders/data/received_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/presentation/views/warehouse_orders_page.dart';

class ReceivedWarehouseOrdersPage extends StatelessWidget {
  const ReceivedWarehouseOrdersPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.canCreate,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
  });

  final ReceivedWarehouseOrdersRepository repository;
  final String accessToken;
  final bool canCreate;
  final String defaultWarehouseNo;
  final String userWarehouseName;

  @override
  Widget build(BuildContext context) {
    return WarehouseOrdersPage(
      repository: repository,
      accessToken: accessToken,
      canCreate: canCreate,
      defaultWarehouseNo: defaultWarehouseNo,
      userWarehouseName: userWarehouseName,
      title: 'Alinan Depo Siparisleri',
      subtitle: 'Gelen depo siparislerini listeleyin ve detaylarini inceleyin.',
    );
  }
}
