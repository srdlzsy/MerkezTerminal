import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/presentation/views/company_acceptances_page.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/offline_company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/warehouse_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/presentation/views/warehouse_acceptances_page.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/company_movements_repository.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/presentation/views/company_movements_page.dart';
import 'package:furpa_merkez_terminal/features/legacy_tools/data/legacy_tools_repository.dart';
import 'package:furpa_merkez_terminal/features/legacy_tools/presentation/views/legacy_tool_pages.dart';
import 'package:furpa_merkez_terminal/features/modules/presentation/views/module_placeholder_page.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/given_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/presentation/views/given_company_orders_page.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_warehouse_orders/data/given_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_warehouse_orders/presentation/views/given_warehouse_orders_page.dart';
import 'package:furpa_merkez_terminal/features/order_operations/received_company_orders/data/received_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/received_warehouse_orders/data/received_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/received_warehouse_orders/presentation/views/received_warehouse_orders_page.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/warehouse_returns_repository.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/presentation/views/warehouse_returns_page.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/incoming_warehouse_shipments/data/incoming_warehouse_shipments_repository.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/outgoing_warehouse_shipments_repository.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/presentation/views/outgoing_warehouse_shipments_page.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/presentation/views/inventory_counts_page.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/label_documents/data/label_documents_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/label_documents/presentation/views/label_documents_page.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/label_printing/presentation/views/label_printing_page.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/data/offline_inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/presentation/views/offline_inventory_counts_page.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/models/stock_receipt_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/stock_receipts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/presentation/views/stock_receipts_page.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/virman_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/presentation/views/virman_page.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_lookup_cache_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_service.dart';

typedef ShellModulePageBuilder =
    Widget Function(ShellModuleRouteContext context);

class ShellModuleRouteContext {
  const ShellModuleRouteContext({
    required this.selectedMenu,
    required this.user,
    required this.accessToken,
  });

  final MenuEntry selectedMenu;
  final CurrentUser user;
  final String accessToken;

  String get sessionScopeKey =>
      '${selectedMenu.id}::$accessToken::${user.id}::${user.warehouseNo}';

  ValueKey<String> get pageKey => ValueKey(sessionScopeKey);

  bool get canCreate => selectedMenu.actions.any(
    (action) => action.code == 'create',
  );

  bool get canUpdate => selectedMenu.actions.any(
    (action) => action.code == 'update',
  );
}

class ShellModuleRoute {
  const ShellModuleRoute({
    this.exactRouteKey,
    this.menuCodes = const <String>[],
    this.keywords = const <String>[],
    required this.builder,
  });

  final String? exactRouteKey;
  final List<String> menuCodes;
  final List<String> keywords;
  final ShellModulePageBuilder builder;

  bool matches(MenuEntry menu) {
    final routeKey = '${menu.moduleCode}.${menu.menuCode}'.toLowerCase();
    final displayKey = '${menu.displayModuleName} ${menu.displayMenuName}'
        .toLowerCase();
    final normalizedMenuCode = menu.menuCode.toLowerCase();

    if (exactRouteKey != null && routeKey == exactRouteKey!.toLowerCase()) {
      return true;
    }

    if (menuCodes
        .map((item) => item.toLowerCase())
        .contains(normalizedMenuCode)) {
      return true;
    }

    for (final keyword in keywords) {
      final normalizedKeyword = keyword.toLowerCase();
      if (displayKey.contains(normalizedKeyword) ||
          routeKey.contains(normalizedKeyword.replaceAll(' ', '-')) ||
          routeKey.contains(normalizedKeyword.replaceAll(' ', '')) ||
          routeKey.contains(normalizedKeyword.replaceAll(' ', '_'))) {
        return true;
      }
    }

    return false;
  }
}

class ShellModuleRegistry {
  ShellModuleRegistry({
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

  final GivenCompanyOrdersRepository givenCompanyOrdersRepository;
  final GivenWarehouseOrdersRepository givenWarehouseOrdersRepository;
  final ReceivedCompanyOrdersRepository receivedCompanyOrdersRepository;
  final ReceivedWarehouseOrdersRepository receivedWarehouseOrdersRepository;
  final WarehouseAcceptancesRepository warehouseAcceptancesRepository;
  final WarehouseReturnsRepository warehouseReturnsRepository;
  final IncomingWarehouseShipmentsRepository incomingWarehouseShipmentsRepository;
  final OutgoingWarehouseShipmentsRepository outgoingWarehouseShipmentsRepository;
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

  late final List<ShellModuleRoute> routes = _buildRoutes();

  Widget buildPage({
    required MenuEntry selectedMenu,
    required CurrentUser user,
    required String accessToken,
  }) {
    final context = ShellModuleRouteContext(
      selectedMenu: selectedMenu,
      user: user,
      accessToken: accessToken,
    );

    for (final route in routes) {
      if (route.matches(selectedMenu)) {
        return route.builder(context);
      }
    }

    return ModulePlaceholderPage(
      key: context.pageKey,
      menuEntry: selectedMenu,
    );
  }

  List<ShellModuleRoute> _buildRoutes() {
    return <ShellModuleRoute>[
      ShellModuleRoute(
        exactRouteKey: 'siparis-islemleri.verilen-firma-siparisleri',
        builder: (context) => GivenCompanyOrdersPage(
          key: context.pageKey,
          repository: givenCompanyOrdersRepository,
          accessToken: context.accessToken,
          canCreate: context.canCreate,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
          title: 'Verilen Firma Siparisleri',
          subtitle:
              'Firma siparislerinin liste, detay ve create akisi sade ve hizli kullanim icin tek ekranda toplandi.',
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'siparis-islemleri.alinan-firma-siparisleri',
        builder: (context) => GivenCompanyOrdersPage(
          key: context.pageKey,
          repository: receivedCompanyOrdersRepository,
          accessToken: context.accessToken,
          canCreate: false,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
          title: 'Alinan Firma Siparisleri',
          subtitle:
              'Gelen firma siparisleri salt okunur liste ve detay akisi ile hedef depo perspektifinde gosterilir.',
          emptyListMessage:
              'Secilen tarih araliginda alinan firma siparisi bulunamadi.',
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'siparis-islemleri.verilen-depo-siparisleri',
        builder: (context) => GivenWarehouseOrdersPage(
          key: context.pageKey,
          repository: givenWarehouseOrdersRepository,
          accessToken: context.accessToken,
          canCreate: context.canCreate,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'siparis-islemleri.alinan-depo-siparisleri',
        builder: (context) => ReceivedWarehouseOrdersPage(
          key: context.pageKey,
          repository: receivedWarehouseOrdersRepository,
          accessToken: context.accessToken,
          canCreate: context.canCreate,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'sevk-islemleri.giden-depolar-arasi-sevkler',
        builder: (context) => OutgoingWarehouseShipmentsPage(
          key: context.pageKey,
          repository: outgoingWarehouseShipmentsRepository,
          receivedWarehouseOrdersRepository: receivedWarehouseOrdersRepository,
          accessToken: context.accessToken,
          canCreate: context.canCreate,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
          title: 'Giden Depolar Arasi Sevkler',
          subtitle:
              'Liste, detay ve create akisi dokumandaki giden sevk endpointlerine baglandi.',
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'sevk-islemleri.gelen-depolar-arasi-sevkler',
        builder: (context) => OutgoingWarehouseShipmentsPage(
          key: context.pageKey,
          repository: incomingWarehouseShipmentsRepository,
          receivedWarehouseOrdersRepository: receivedWarehouseOrdersRepository,
          accessToken: context.accessToken,
          canCreate: false,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
          title: 'Gelen Depolar Arasi Sevkler',
          subtitle:
              'Hedef depo perspektifinde gelen sevklerin liste ve detay akisi ayni hizli panelde gosterilir.',
          emptyListMessage:
              'Secilen tarih araliginda gelen depo sevki bulunamadi.',
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'mal-kabul-islemleri.depo-mal-kabulleri',
        builder: (context) => WarehouseAcceptancesPage(
          key: context.pageKey,
          repository: warehouseAcceptancesRepository,
          accessToken: context.accessToken,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
          canSubmit: context.canUpdate,
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'iade-islemleri.giden-depo-iadeleri',
        builder: (context) => WarehouseReturnsPage(
          key: context.pageKey,
          repository: warehouseReturnsRepository,
          accessToken: context.accessToken,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
          direction: WarehouseReturnDirection.outgoing,
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'iade-islemleri.gelen-depo-iadeleri',
        builder: (context) => WarehouseReturnsPage(
          key: context.pageKey,
          repository: warehouseReturnsRepository,
          accessToken: context.accessToken,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
          direction: WarehouseReturnDirection.incoming,
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'stok-islemleri.sayim-sonuclari',
        builder: (context) => InventoryCountsPage(
          key: context.pageKey,
          repository: inventoryCountsRepository,
          offlineRepository: offlineInventoryCountsRepository,
          accessToken: context.accessToken,
          canCreate: context.canCreate,
          lookupCacheRepository: offlineLookupCacheRepository,
          offlineSyncService: offlineSyncService,
          currentUserId: context.user.id,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'stok-islemleri.etiket-belgeleri',
        menuCodes: const <String>['labelDocuments'],
        keywords: const <String>['etiket belgeleri'],
        builder: (context) => LabelDocumentsPage(
          key: context.pageKey,
          repository: labelDocumentsRepository,
          accessToken: context.accessToken,
          canCreate: context.canCreate,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'stok-islemleri.kunye-etiket-yazdirma',
        menuCodes: const <String>['labelPage', 'kunyeEtiketYazdirma'],
        keywords: const <String>[
          'etiket basim',
          'kunye etiket',
          'etiket yazdirma',
        ],
        builder: (context) => LabelPrintingPage(
          key: context.pageKey,
          repository: labelDocumentsRepository,
          accessToken: context.accessToken,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'stok-islemleri.virmanlar',
        builder: (context) => VirmanPage(
          key: context.pageKey,
          repository: virmanRepository,
          accessToken: context.accessToken,
          canCreate: context.canCreate,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'sevk-islemleri.giden-firma-sevkleri',
        builder: (context) => CompanyMovementsPage(
          key: context.pageKey,
          repository: outgoingCompanyShipmentsRepository,
          accessToken: context.accessToken,
          canCreate: context.canCreate,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
          title: 'Giden Firma Sevkleri',
          subtitle:
              'Firma sevklerinin liste, detay, create ve e-irsaliye akisi tek panelde toplandi.',
          createTitle: 'Yeni Firma Sevki',
          createHelperText:
              'Cari secildikten sonra sevk satirlari barkod veya urun arama ile eklenir.',
          createButtonLabel: 'Yeni Firma Sevki',
          emptyListMessage:
              'Secilen tarih araliginda giden firma sevki bulunamadi.',
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'sevk-islemleri.gelen-firma-sevkleri',
        builder: (context) => CompanyMovementsPage(
          key: context.pageKey,
          repository: incomingCompanyShipmentsRepository,
          accessToken: context.accessToken,
          canCreate: false,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
          title: 'Gelen Firma Sevkleri',
          subtitle:
              'Hedef depo perspektifinde gelen firma sevkleri salt okunur liste ve detay akisi ile gosterilir.',
          createTitle: 'Yeni Firma Sevki',
          createHelperText: '',
          createButtonLabel: 'Yeni Firma Sevki',
          emptyListMessage:
              'Secilen tarih araliginda gelen firma sevki bulunamadi.',
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'mal-kabul-islemleri.firma-mal-kabulleri',
        builder: (context) => CompanyAcceptancesPage(
          key: context.pageKey,
          repository: companyAcceptancesRepository,
          offlineRepository: offlineCompanyAcceptancesRepository,
          ordersRepository: givenCompanyOrdersRepository,
          accessToken: context.accessToken,
          canCreate: context.canCreate,
          lookupCacheRepository: offlineLookupCacheRepository,
          offlineSyncService: offlineSyncService,
          currentUserId: context.user.id,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'iade-islemleri.firma-iadeleri',
        builder: (context) => CompanyMovementsPage(
          key: context.pageKey,
          repository: companyReturnsRepository,
          accessToken: context.accessToken,
          canCreate: context.canCreate,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
          title: 'Firma Iadeleri',
          subtitle:
              'Firma iade evraklari liste, detay, create ve e-irsaliye akislariyla birlikte yonetilir.',
          createTitle: 'Yeni Firma Iadesi',
          createHelperText:
              'Cari secildikten sonra iade satirlari manuel eklenir ve e-irsaliye adimi detay ekranindan yonetilir.',
          createButtonLabel: 'Yeni Firma Iadesi',
          emptyListMessage:
              'Secilen tarih araliginda firma iadesi bulunamadi.',
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'stok-islemleri.zayiat-fisleri',
        builder: (context) => StockReceiptsPage(
          key: context.pageKey,
          repository: stockReceiptsRepository,
          kind: StockReceiptKind.outage,
          accessToken: context.accessToken,
          canCreate: context.canCreate,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
        ),
      ),
      ShellModuleRoute(
        exactRouteKey: 'stok-islemleri.masraf-fisleri',
        builder: (context) => StockReceiptsPage(
          key: context.pageKey,
          repository: stockReceiptsRepository,
          kind: StockReceiptKind.expense,
          accessToken: context.accessToken,
          canCreate: context.canCreate,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
        ),
      ),
      ShellModuleRoute(
        menuCodes: const <String>[
          'offlineSayim',
          'sayimOffline',
          'censusEntryOffline',
        ],
        keywords: const <String>['offline sayim'],
        builder: (context) => OfflineInventoryCountsPage(
          key: context.pageKey,
          offlineRepository: offlineInventoryCountsRepository,
          onlineRepository: inventoryCountsRepository,
          accessToken: context.accessToken,
          offlineSyncService: offlineSyncService,
          currentUserId: context.user.id,
          defaultWarehouseNo: context.user.warehouseNo,
          userWarehouseName: context.user.warehouseName,
        ),
      ),
      ShellModuleRoute(
        menuCodes: const <String>['checkPrice'],
        keywords: const <String>['fiyat gor', 'price check'],
        builder: (context) => ProductLookupToolPage(
          key: context.pageKey,
          repository: legacyToolsRepository,
          accessToken: context.accessToken,
          defaultWarehouseNo: context.user.warehouseNo,
          title: 'Fiyat Gor',
          subtitle:
              'Barkod veya stok kodu ile urun fiyatini ve blok durumlarini hizlica gosterir.',
          emptyMessage: 'Aramaya uygun urun bulunamadi.',
        ),
      ),
      ShellModuleRoute(
        menuCodes: const <String>['findCompanies'],
        keywords: const <String>['firma bul'],
        builder: (context) => CompanyLookupToolPage(
          key: context.pageKey,
          repository: legacyToolsRepository,
          accessToken: context.accessToken,
        ),
      ),
      ShellModuleRoute(
        menuCodes: const <String>['packageBarcode'],
        keywords: const <String>['koli barkodu'],
        builder: (context) => PackageBarcodePage(
          key: context.pageKey,
          repository: legacyToolsRepository,
          accessToken: context.accessToken,
        ),
      ),
      ShellModuleRoute(
        menuCodes: const <String>['piecesInBox'],
        keywords: const <String>['koli ici adet'],
        builder: (context) => PiecesInBoxPage(
          key: context.pageKey,
          repository: legacyToolsRepository,
          accessToken: context.accessToken,
        ),
      ),
      ShellModuleRoute(
        menuCodes: const <String>['varyokStoklar'],
        keywords: const <String>['var yok', 'varyok'],
        builder: (context) => ProductLookupToolPage(
          key: context.pageKey,
          repository: legacyToolsRepository,
          accessToken: context.accessToken,
          defaultWarehouseNo: context.user.warehouseNo,
          title: 'Var Yok',
          subtitle:
              'Urunun depoda aranabilir durumda olup olmadigini hizli tarama ekraninda gosterir.',
          emptyMessage: 'Bu aramaya uygun stok bulunamadi.',
        ),
      ),
    ];
  }
}
