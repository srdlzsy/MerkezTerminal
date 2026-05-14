import 'package:furpa_merkez_terminal/core/config/app_config.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/core/storage/local_json_database.dart';
import 'package:furpa_merkez_terminal/core/storage/token_storage.dart';
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
import 'package:furpa_merkez_terminal/shared/offline/offline_lookup_cache_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_service.dart';
import 'package:http/http.dart' as http;

class AppDependencies {
  factory AppDependencies.create() {
    final httpClient = http.Client();
    final apiClient = ApiClient(
      baseUrl: AppConfig.baseUrl,
      httpClient: httpClient,
    );
    final tokenStorage = TokenStorage();
    final localDatabase = LocalJsonDatabase();
    final offlineInventoryCountsRepository =
        SharedPrefsOfflineInventoryCountsRepository(database: localDatabase);
    final offlineCompanyAcceptancesRepository =
        SharedPrefsOfflineCompanyAcceptancesRepository(database: localDatabase);
    final offlineLookupCacheRepository = OfflineLookupCacheRepository(
      database: localDatabase,
    );
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
    final receivedCompanyOrdersRepository =
        ApiReceivedCompanyOrdersRepository(apiClient: apiClient);
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
      offlineLookupCacheRepository: offlineLookupCacheRepository,
      offlineSyncService: offlineSyncService,
      legacyToolsRepository: legacyToolsRepository,
    );

    return AppDependencies._(
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
      offlineLookupCacheRepository: offlineLookupCacheRepository,
      offlineSyncService: offlineSyncService,
      legacyToolsRepository: legacyToolsRepository,
    );
  }

  AppDependencies._({
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
    required this.offlineLookupCacheRepository,
    required this.offlineSyncService,
    required this.legacyToolsRepository,
  });

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
  final OfflineLookupCacheRepository offlineLookupCacheRepository;
  final OfflineSyncService offlineSyncService;
  final LegacyToolsRepository legacyToolsRepository;
}
