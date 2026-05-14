import 'package:furpa_merkez_terminal/features/order_operations/given_warehouse_orders/data/given_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/presentation/view_models/warehouse_orders_controller.dart';

class GivenWarehouseOrdersController extends WarehouseOrdersController {
  GivenWarehouseOrdersController({
    required GivenWarehouseOrdersRepository repository,
    required super.accessToken,
    required super.defaultWarehouseNo,
  }) : super(repository: repository);
}
