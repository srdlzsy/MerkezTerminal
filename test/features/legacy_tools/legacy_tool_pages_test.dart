import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/core/storage/local_database.dart';
import 'package:furpa_merkez_terminal/features/legacy_tools/data/legacy_tools_repository.dart';
import 'package:furpa_merkez_terminal/features/legacy_tools/presentation/views/legacy_tool_pages.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';

void main() {
  testWidgets('fiyat gor uses compact Urun and camera actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductLookupToolPage(
            repository: _FakeLegacyToolsRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            productCatalogRepository: _productCatalogRepository(),
            productCatalogSyncService: _productCatalogSyncService(),
            customerCatalogRepository: _customerCatalogRepository(),
            customerCatalogSyncService: _customerCatalogSyncService(),
            warehouseCatalogRepository: _warehouseCatalogRepository(),
            warehouseCatalogSyncService: _warehouseCatalogSyncService(),
            title: 'Fiyat Gor',
            subtitle: 'Test',
            emptyMessage: 'Bos',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.widgetWithText(FilledButton, 'Urun'), findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_back_rounded), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Ara'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Kamera'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cari bul uses compact Urun and camera actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanyLookupToolPage(
            repository: _FakeLegacyToolsRepository(),
            accessToken: 'token',
            defaultWarehouseNo: '110',
            title: 'Cari Bul',
            subtitle: 'Test',
            emptyMessage: 'Bos',
          ),
        ),
      ),
    );

    expect(find.widgetWithText(FilledButton, 'Urun'), findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_back_rounded), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Ara'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

MobileProductCatalogLocalRepository _productCatalogRepository() {
  return MobileProductCatalogLocalRepository(database: _MemoryLocalDatabase());
}

MobileCustomerCatalogLocalRepository _customerCatalogRepository() {
  return MobileCustomerCatalogLocalRepository(database: _MemoryLocalDatabase());
}

MobileWarehouseCatalogLocalRepository _warehouseCatalogRepository() {
  return MobileWarehouseCatalogLocalRepository(
    database: _MemoryLocalDatabase(),
  );
}

MobileProductCatalogSyncService _productCatalogSyncService() {
  final localRepository = _productCatalogRepository();
  return MobileProductCatalogSyncService(
    remoteDataSource: _NoopProductCatalogRemoteDataSource(),
    localRepository: localRepository,
  );
}

MobileCustomerCatalogSyncService _customerCatalogSyncService() {
  final localRepository = _customerCatalogRepository();
  return MobileCustomerCatalogSyncService(
    remoteDataSource: _NoopCustomerCatalogRemoteDataSource(),
    localRepository: localRepository,
  );
}

MobileWarehouseCatalogSyncService _warehouseCatalogSyncService() {
  final localRepository = _warehouseCatalogRepository();
  return MobileWarehouseCatalogSyncService(
    remoteDataSource: _NoopWarehouseCatalogRemoteDataSource(),
    localRepository: localRepository,
  );
}

class _FakeLegacyToolsRepository implements LegacyToolsRepository {
  @override
  Future<List<SearchProductLookupItem>> searchProducts({
    required String accessToken,
    required String warehouseNo,
    required String query,
  }) async {
    return const <SearchProductLookupItem>[];
  }

  @override
  Future<List<CustomerLookupItem>> searchCustomers({
    required String accessToken,
    required String query,
  }) async {
    return const <CustomerLookupItem>[];
  }

  @override
  Future<List<CustomerLookupItem>> searchCustomersByBarcode({
    required String accessToken,
    required String barcode,
    int? warehouseNo,
  }) async {
    return const <CustomerLookupItem>[];
  }

  @override
  Future<JsonMap> addPackageBarcodeForProduct({
    required String accessToken,
    required String barcode,
    required String productCode,
    required String packageBarcode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<JsonMap> getCurrentProductByBarcode({
    required String accessToken,
    required String barcode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<JsonMap> getPackageBarcodeForProduct({
    required String accessToken,
    required String barcode,
    required String productCode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<JsonMap> updateProductForPiecesInBox({
    required String accessToken,
    required String stockCode,
    required String barcode,
    required int piecesInBox,
  }) {
    throw UnimplementedError();
  }
}

class _NoopProductCatalogRemoteDataSource
    implements MobileProductCatalogRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopCustomerCatalogRemoteDataSource
    implements MobileCustomerCatalogRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopWarehouseCatalogRemoteDataSource
    implements MobileWarehouseCatalogRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryLocalDatabase implements LocalDatabase {
  final Map<String, List<Map<String, dynamic>>> _tables =
      <String, List<Map<String, dynamic>>>{};
  final Map<String, Map<String, dynamic>> _documents =
      <String, Map<String, dynamic>>{};

  @override
  Future<List<Map<String, dynamic>>> readTable(String key) async {
    return List<Map<String, dynamic>>.from(
      _tables[key] ?? const <Map<String, dynamic>>[],
    );
  }

  @override
  Future<void> writeTable(String key, List<Map<String, dynamic>> rows) async {
    _tables[key] = List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<Map<String, dynamic>?> readDocument(String key) async {
    final document = _documents[key];
    return document == null ? null : Map<String, dynamic>.from(document);
  }

  @override
  Future<void> writeDocument(String key, Map<String, dynamic> document) async {
    _documents[key] = Map<String, dynamic>.from(document);
  }

  @override
  Future<void> remove(String key) async {
    _tables.remove(key);
    _documents.remove(key);
  }
}
