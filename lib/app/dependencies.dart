import 'package:furpa_merkez_terminal/core/config/app_config.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/core/storage/local_sqlite_database.dart';
import 'package:furpa_merkez_terminal/core/storage/token_storage.dart';
import 'package:furpa_merkez_terminal/core/update/app_update_service.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/offline_company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/warehouse_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/auth/data/auth_repository.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/company_movements_repository.dart';
import 'package:furpa_merkez_terminal/features/legacy_tools/data/legacy_tools_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/given_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_warehouse_orders/data/given_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/received_company_orders/data/received_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/received_warehouse_orders/data/received_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/warehouse_returns_repository.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/routing/shell_module_registry.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/view_models/app_session_controller.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/incoming_warehouse_shipments/data/incoming_warehouse_shipments_repository.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/outgoing_warehouse_shipments_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/label_documents/data/label_documents_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/data/offline_inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/stock_receipts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/virman_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_service.dart';
import 'package:http/http.dart' as http;

class AppDependencies {
  factory AppDependencies.create() {
    final httpClient = http.Client();
    final apiClient = ApiClient(
      baseUrl: AppConfig.baseUrl,
      httpClient: httpClient,
    );
    final updateService = AppUpdateService(httpClient: httpClient);
    final tokenStorage = TokenStorage();
    final localDatabase = LocalSqliteDatabase();
    final createDraftRepository = LocalCreateDraftRepository(
      database: localDatabase,
    );
    final offlineInventoryCountsRepository =
        LocalOfflineInventoryCountsRepository(database: localDatabase);
    final offlineCompanyAcceptancesRepository =
        LocalOfflineCompanyAcceptancesRepository(database: localDatabase);
    final mobileCustomerCatalogLocalRepository =
        MobileCustomerCatalogLocalRepository(database: localDatabase);
    final mobileWarehouseCatalogLocalRepository =
        MobileWarehouseCatalogLocalRepository(database: localDatabase);
    final mobileProductCatalogLocalRepository =
        MobileProductCatalogLocalRepository(database: localDatabase);
    final authRepository = AuthRepository(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );
    final sessionController = AppSessionController(
      authRepository: authRepository,
    );
    apiClient.configureAuthentication(
      accessTokenProvider: () => sessionController.accessToken,
      unauthorizedRecoveryHandler: sessionController.handleUnauthorized,
    );
    final inventoryCountsRepository = ApiInventoryCountsRepository(
      apiClient: apiClient,
    );
    final companyAcceptancesRepository = ApiCompanyAcceptancesRepository(
      apiClient: apiClient,
    );
    final offlineSyncService = OfflineSyncService(
      inventoryRepository: inventoryCountsRepository,
      companyAcceptanceRepository: companyAcceptancesRepository,
      offlineInventoryRepository: offlineInventoryCountsRepository,
      offlineCompanyAcceptanceRepository: offlineCompanyAcceptancesRepository,
    );
    final givenCompanyOrdersRepository = ApiGivenCompanyOrdersRepository(
      apiClient: apiClient,
    );
    final givenWarehouseOrdersRepository = ApiGivenWarehouseOrdersRepository(
      apiClient: apiClient,
    );
    final receivedCompanyOrdersRepository = ApiReceivedCompanyOrdersRepository(
      apiClient: apiClient,
    );
    final receivedWarehouseOrdersRepository =
        ApiReceivedWarehouseOrdersRepository(apiClient: apiClient);
    final warehouseAcceptancesRepository = ApiWarehouseAcceptancesRepository(
      apiClient: apiClient,
    );
    final warehouseReturnsRepository = ApiWarehouseReturnsRepository(
      apiClient: apiClient,
    );
    final incomingWarehouseShipmentsRepository =
        ApiIncomingWarehouseShipmentsRepository(apiClient: apiClient);
    final outgoingWarehouseShipmentsRepository =
        ApiOutgoingWarehouseShipmentsRepository(apiClient: apiClient);
    final outgoingCompanyShipmentsRepository = ApiCompanyMovementsRepository(
      apiClient: apiClient,
      listPath: '/api/sevk-islemleri/firma-sevkleri/giden',
      detailPathPrefix: '/api/sevk-islemleri/firma-sevkleri/giden',
      supportsCreate: true,
      supportsEDespatch: true,
    );
    final incomingCompanyShipmentsRepository = ApiCompanyMovementsRepository(
      apiClient: apiClient,
      listPath: '/api/sevk-islemleri/firma-sevkleri/gelen',
      detailPathPrefix: '/api/sevk-islemleri/firma-sevkleri/gelen',
      supportsCreate: false,
      supportsEDespatch: false,
    );
    final companyReturnsRepository = ApiCompanyMovementsRepository(
      apiClient: apiClient,
      listPath: '/api/iade-islemleri/firma-iadeleri',
      detailPathPrefix: '/api/iade-islemleri/firma-iadeleri',
      supportsCreate: true,
      supportsEDespatch: true,
    );
    final stockReceiptsRepository = ApiStockReceiptsRepository(
      apiClient: apiClient,
    );
    final labelDocumentsRepository = ApiLabelDocumentsRepository(
      apiClient: apiClient,
    );
    final virmanRepository = ApiVirmanRepository(apiClient: apiClient);
    final legacyToolsRepository = ApiLegacyToolsRepository(
      apiClient: apiClient,
    );
    final mobileProductCatalogSyncService = MobileProductCatalogSyncService(
      remoteDataSource: ApiMobileProductCatalogRemoteDataSource(
        apiClient: apiClient,
      ),
      localRepository: mobileProductCatalogLocalRepository,
    );
    final mobileCustomerCatalogSyncService = MobileCustomerCatalogSyncService(
      remoteDataSource: ApiMobileCustomerCatalogRemoteDataSource(
        apiClient: apiClient,
      ),
      localRepository: mobileCustomerCatalogLocalRepository,
    );
    final mobileWarehouseCatalogSyncService = MobileWarehouseCatalogSyncService(
      remoteDataSource: ApiMobileWarehouseCatalogRemoteDataSource(
        apiClient: apiClient,
      ),
      localRepository: mobileWarehouseCatalogLocalRepository,
    );
    final moduleRegistry = ShellModuleRegistry(
      givenCompanyOrdersRepository: givenCompanyOrdersRepository,
      givenWarehouseOrdersRepository: givenWarehouseOrdersRepository,
      receivedCompanyOrdersRepository: receivedCompanyOrdersRepository,
      receivedWarehouseOrdersRepository: receivedWarehouseOrdersRepository,
      warehouseAcceptancesRepository: warehouseAcceptancesRepository,
      warehouseReturnsRepository: warehouseReturnsRepository,
      incomingWarehouseShipmentsRepository:
          incomingWarehouseShipmentsRepository,
      outgoingWarehouseShipmentsRepository:
          outgoingWarehouseShipmentsRepository,
      inventoryCountsRepository: inventoryCountsRepository,
      outgoingCompanyShipmentsRepository: outgoingCompanyShipmentsRepository,
      incomingCompanyShipmentsRepository: incomingCompanyShipmentsRepository,
      companyReturnsRepository: companyReturnsRepository,
      companyAcceptancesRepository: companyAcceptancesRepository,
      stockReceiptsRepository: stockReceiptsRepository,
      labelDocumentsRepository: labelDocumentsRepository,
      virmanRepository: virmanRepository,
      offlineInventoryCountsRepository: offlineInventoryCountsRepository,
      offlineCompanyAcceptancesRepository: offlineCompanyAcceptancesRepository,
      offlineSyncService: offlineSyncService,
      mobileCustomerCatalogLocalRepository:
          mobileCustomerCatalogLocalRepository,
      mobileCustomerCatalogSyncService: mobileCustomerCatalogSyncService,
      mobileProductCatalogLocalRepository: mobileProductCatalogLocalRepository,
      mobileProductCatalogSyncService: mobileProductCatalogSyncService,
      mobileWarehouseCatalogLocalRepository:
          mobileWarehouseCatalogLocalRepository,
      mobileWarehouseCatalogSyncService: mobileWarehouseCatalogSyncService,
      legacyToolsRepository: legacyToolsRepository,
      createDraftRepository: createDraftRepository,
    );

    return AppDependencies._(
      updateService: updateService,
      sessionController: sessionController,
      moduleRegistry: moduleRegistry,
      givenCompanyOrdersRepository: givenCompanyOrdersRepository,
      givenWarehouseOrdersRepository: givenWarehouseOrdersRepository,
      receivedCompanyOrdersRepository: receivedCompanyOrdersRepository,
      receivedWarehouseOrdersRepository: receivedWarehouseOrdersRepository,
      warehouseAcceptancesRepository: warehouseAcceptancesRepository,
      warehouseReturnsRepository: warehouseReturnsRepository,
      incomingWarehouseShipmentsRepository:
          incomingWarehouseShipmentsRepository,
      outgoingWarehouseShipmentsRepository:
          outgoingWarehouseShipmentsRepository,
      inventoryCountsRepository: inventoryCountsRepository,
      outgoingCompanyShipmentsRepository: outgoingCompanyShipmentsRepository,
      incomingCompanyShipmentsRepository: incomingCompanyShipmentsRepository,
      companyReturnsRepository: companyReturnsRepository,
      companyAcceptancesRepository: companyAcceptancesRepository,
      stockReceiptsRepository: stockReceiptsRepository,
      labelDocumentsRepository: labelDocumentsRepository,
      virmanRepository: virmanRepository,
      offlineInventoryCountsRepository: offlineInventoryCountsRepository,
      offlineCompanyAcceptancesRepository: offlineCompanyAcceptancesRepository,
      offlineSyncService: offlineSyncService,
      mobileCustomerCatalogLocalRepository:
          mobileCustomerCatalogLocalRepository,
      mobileCustomerCatalogSyncService: mobileCustomerCatalogSyncService,
      mobileProductCatalogLocalRepository: mobileProductCatalogLocalRepository,
      mobileProductCatalogSyncService: mobileProductCatalogSyncService,
      mobileWarehouseCatalogLocalRepository:
          mobileWarehouseCatalogLocalRepository,
      mobileWarehouseCatalogSyncService: mobileWarehouseCatalogSyncService,
      legacyToolsRepository: legacyToolsRepository,
      createDraftRepository: createDraftRepository,
    );
  }

  AppDependencies._({
    required this.updateService,
    required this.sessionController,
    required this.moduleRegistry,
    required this.givenCompanyOrdersRepository,
    required this.givenWarehouseOrdersRepository,
    required this.receivedCompanyOrdersRepository,
    required this.receivedWarehouseOrdersRepository,
    required this.warehouseAcceptancesRepository,
    required this.warehouseReturnsRepository,
    required this.incomingWarehouseShipmentsRepository,
    required this.outgoingWarehouseShipmentsRepository,
    required this.inventoryCountsRepository,
    required this.outgoingCompanyShipmentsRepository,
    required this.incomingCompanyShipmentsRepository,
    required this.companyReturnsRepository,
    required this.companyAcceptancesRepository,
    required this.stockReceiptsRepository,
    required this.labelDocumentsRepository,
    required this.virmanRepository,
    required this.offlineInventoryCountsRepository,
    required this.offlineCompanyAcceptancesRepository,
    required this.offlineSyncService,
    required this.mobileCustomerCatalogLocalRepository,
    required this.mobileCustomerCatalogSyncService,
    required this.mobileProductCatalogLocalRepository,
    required this.mobileProductCatalogSyncService,
    required this.mobileWarehouseCatalogLocalRepository,
    required this.mobileWarehouseCatalogSyncService,
    required this.legacyToolsRepository,
    required this.createDraftRepository,
  });

  final AppUpdateService updateService;
  final AppSessionController sessionController;
  final ShellModuleRegistry moduleRegistry;
  final GivenCompanyOrdersRepository givenCompanyOrdersRepository;
  final GivenWarehouseOrdersRepository givenWarehouseOrdersRepository;
  final ReceivedCompanyOrdersRepository receivedCompanyOrdersRepository;
  final ReceivedWarehouseOrdersRepository receivedWarehouseOrdersRepository;
  final WarehouseAcceptancesRepository warehouseAcceptancesRepository;
  final WarehouseReturnsRepository warehouseReturnsRepository;
  final IncomingWarehouseShipmentsRepository
  incomingWarehouseShipmentsRepository;
  final OutgoingWarehouseShipmentsRepository
  outgoingWarehouseShipmentsRepository;
  final InventoryCountsRepository inventoryCountsRepository;
  final CompanyMovementsRepository outgoingCompanyShipmentsRepository;
  final CompanyMovementsRepository incomingCompanyShipmentsRepository;
  final CompanyMovementsRepository companyReturnsRepository;
  final CompanyAcceptancesRepository companyAcceptancesRepository;
  final StockReceiptsRepository stockReceiptsRepository;
  final LabelDocumentsRepository labelDocumentsRepository;
  final VirmanRepository virmanRepository;
  final OfflineInventoryCountsRepository offlineInventoryCountsRepository;
  final OfflineCompanyAcceptancesRepository offlineCompanyAcceptancesRepository;
  final OfflineSyncService offlineSyncService;
  final MobileCustomerCatalogLocalRepository
  mobileCustomerCatalogLocalRepository;
  final MobileCustomerCatalogSyncService mobileCustomerCatalogSyncService;
  final MobileProductCatalogLocalRepository mobileProductCatalogLocalRepository;
  final MobileProductCatalogSyncService mobileProductCatalogSyncService;
  final MobileWarehouseCatalogLocalRepository
  mobileWarehouseCatalogLocalRepository;
  final MobileWarehouseCatalogSyncService mobileWarehouseCatalogSyncService;
  final LegacyToolsRepository legacyToolsRepository;
  final CreateDraftRepository createDraftRepository;
}
