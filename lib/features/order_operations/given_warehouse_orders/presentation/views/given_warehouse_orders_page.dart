import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_warehouse_orders/data/given_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_warehouse_orders/presentation/widgets/given_warehouse_order_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/presentation/views/warehouse_orders_page.dart';

class GivenWarehouseOrdersPage extends StatelessWidget {
  const GivenWarehouseOrdersPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.canCreate,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
  });

  final GivenWarehouseOrdersRepository repository;
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
      title: 'Verilen Depo Siparisleri',
      subtitle:
          'Liste, detay ve create akisi el terminali kullanimina gore sade tutuldu.',
      createSheetBuilder: (context) {
        return GivenWarehouseOrderCreateSheet(
          repository: repository,
          accessToken: accessToken,
          defaultWarehouseNo: defaultWarehouseNo,
        );
      },
    );
  }
}
