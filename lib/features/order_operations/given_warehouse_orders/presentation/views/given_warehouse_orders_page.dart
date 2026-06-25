import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_warehouse_orders/data/given_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_warehouse_orders/presentation/widgets/given_warehouse_order_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/presentation/views/warehouse_orders_page.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';

class GivenWarehouseOrdersPage extends StatelessWidget {
  const GivenWarehouseOrdersPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.canCreate,
    required this.defaultWarehouseNo,
    required this.mobileWarehouseCatalogRepository,
    required this.userWarehouseName,
    this.currentUserId = '',
    this.draftRepository,
  });

  final GivenWarehouseOrdersRepository repository;
  final String accessToken;
  final bool canCreate;
  final String defaultWarehouseNo;
  final MobileWarehouseCatalogLocalRepository mobileWarehouseCatalogRepository;
  final String userWarehouseName;
  final String currentUserId;
  final CreateDraftRepository? draftRepository;

  @override
  Widget build(BuildContext context) {
    return WarehouseOrdersPage(
      repository: repository,
      accessToken: accessToken,
      canCreate: canCreate,
      defaultWarehouseNo: defaultWarehouseNo,
      userWarehouseName: userWarehouseName,
      title: 'Verilen Depo Siparisleri',
      subtitle: 'Depo siparislerini listeleyin ve yeni siparis olusturun.',
      currentUserId: currentUserId,
      draftModuleKey: 'siparis-islemleri.verilen-depo-siparisleri',
      draftRepository: draftRepository,
      createTitle: 'Yeni Verilen Depo Siparisi',
      createSheetBuilder: (context, draft, draftRepository) {
        return GivenWarehouseOrderCreateSheet(
          repository: repository,
          accessToken: accessToken,
          defaultWarehouseNo: defaultWarehouseNo,
          mobileWarehouseCatalogRepository: mobileWarehouseCatalogRepository,
          draft: draft,
          draftRepository: draftRepository,
        );
      },
    );
  }
}
