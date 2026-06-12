import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/legacy_tools/data/legacy_tools_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class ProductLookupToolPage extends StatefulWidget {
  const ProductLookupToolPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.productCatalogRepository,
    required this.productCatalogSyncService,
    required this.customerCatalogRepository,
    required this.customerCatalogSyncService,
    required this.warehouseCatalogRepository,
    required this.warehouseCatalogSyncService,
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
  });

  final LegacyToolsRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;
  final MobileProductCatalogLocalRepository productCatalogRepository;
  final MobileProductCatalogSyncService productCatalogSyncService;
  final MobileCustomerCatalogLocalRepository customerCatalogRepository;
  final MobileCustomerCatalogSyncService customerCatalogSyncService;
  final MobileWarehouseCatalogLocalRepository warehouseCatalogRepository;
  final MobileWarehouseCatalogSyncService warehouseCatalogSyncService;
  final String title;
  final String subtitle;
  final String emptyMessage;

  @override
  State<ProductLookupToolPage> createState() => _ProductLookupToolPageState();
}

class _ProductLookupToolPageState extends State<ProductLookupToolPage> {
  final TextEditingController _queryController = TextEditingController();
  bool _isLoading = false;
  bool _isSyncingCatalog = false;
  bool _hasQuery = false;
  bool _isUsingOfflineCatalog = false;
  String? _errorMessage;
  String? _catalogStatusMessage;
  MobileProductCatalogMetadata? _catalogMetadata;
  MobileCustomerCatalogMetadata? _customerCatalogMetadata;
  MobileWarehouseCatalogMetadata? _warehouseCatalogMetadata;
  List<SearchProductLookupItem> _products = const <SearchProductLookupItem>[];

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_handleQueryChanged);
    unawaited(_loadCatalogMetadata());
  }

  @override
  void dispose() {
    _queryController.removeListener(_handleQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    final hasQuery = _queryController.text.trim().isNotEmpty;
    if (hasQuery == _hasQuery) {
      return;
    }

    setState(() {
      _hasQuery = hasQuery;
    });
  }

  void _clearSearch() {
    _queryController.clear();
    setState(() {
      _products = const <SearchProductLookupItem>[];
      _errorMessage = null;
      _isUsingOfflineCatalog = false;
      _isLoading = false;
    });
  }

  Future<void> _loadCatalogMetadata() async {
    final productMetadata = await widget.productCatalogRepository.fetchMetadata(
      warehouseNo: widget.defaultWarehouseNo,
    );
    final customerMetadata = await widget.customerCatalogRepository
        .fetchMetadata();
    final warehouseMetadata = await widget.warehouseCatalogRepository
        .fetchMetadata();

    if (!mounted) {
      return;
    }

    setState(() {
      _catalogMetadata = productMetadata;
      _customerCatalogMetadata = customerMetadata;
      _warehouseCatalogMetadata = warehouseMetadata;
    });
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Arama icin en az 2 karakter veya barkod girilmeli.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await widget.repository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        query: query,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _products = products;
        _isUsingOfflineCatalog = false;
        _catalogStatusMessage = null;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      final catalogProducts = await widget.productCatalogRepository
          .searchProducts(warehouseNo: widget.defaultWarehouseNo, query: query);

      if (!mounted) {
        return;
      }

      if (catalogProducts.isNotEmpty) {
        setState(() {
          _products = catalogProducts
              .map((item) => item.toSearchProductLookupItem())
              .toList(growable: false);
          _isUsingOfflineCatalog = true;
          _catalogStatusMessage =
              'API erisilemedi; son basarili katalog sync verisi gosteriliyor.';
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _isUsingOfflineCatalog = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isUsingOfflineCatalog = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _scanWithCamera() async {
    if (!supportsCameraBarcodeScanning) {
      setState(() {
        _errorMessage = 'Bu cihazda kamera ile barkod okutma desteklenmiyor.';
      });
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: '${widget.title} Kamerasi',
      subtitle: 'Barkodu okutun; fiyat katalogundan veya APIden aranacak.',
    );

    if (barcode == null || !mounted) {
      return;
    }

    _queryController.text = barcode;
    await _search();
  }

  Future<void> _syncCatalog() async {
    if (_isSyncingCatalog) {
      return;
    }

    setState(() {
      _isSyncingCatalog = true;
      _errorMessage = null;
      _catalogStatusMessage = 'Mobil katalog sync basladi...';
    });

    try {
      setState(() {
        _catalogStatusMessage = 'Urun katalogu sync ediliyor...';
      });
      final productResult = await widget.productCatalogSyncService.syncCatalog(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _catalogMetadata = productResult.metadata;
        _catalogStatusMessage =
            'Urun katalogu tamamlandi. Cari katalog sync ediliyor...';
      });

      final customerResult = await widget.customerCatalogSyncService
          .syncCatalog(accessToken: widget.accessToken);

      if (!mounted) {
        return;
      }

      setState(() {
        _customerCatalogMetadata = customerResult.metadata;
        _catalogStatusMessage =
            'Cari katalog tamamlandi. Depo katalog sync ediliyor...';
      });

      final warehouseResult = await widget.warehouseCatalogSyncService
          .syncCatalog(accessToken: widget.accessToken);

      if (!mounted) {
        return;
      }

      setState(() {
        _warehouseCatalogMetadata = warehouseResult.metadata;
        _isSyncingCatalog = false;
        _catalogStatusMessage =
            'Mobil katalog sync tamamlandi: '
            'urun ${productResult.pagesFetched} sayfa / ${productResult.upsertedCount} kayit / ${productResult.deletedCount} silinen, '
            'cari ${customerResult.pagesFetched} sayfa / ${customerResult.upsertedCount} kayit / ${customerResult.deletedCount} silinen, '
            'depo ${warehouseResult.pagesFetched} sayfa / ${warehouseResult.upsertedCount} kayit / ${warehouseResult.deletedCount} silinen.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSyncingCatalog = false;
        _catalogStatusMessage = null;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          20 + MediaQuery.paddingOf(context).bottom,
        ),
        children: <Widget>[
          SectionCard(
            title: widget.title,
            subtitle: widget.subtitle,
            child: Column(
              children: <Widget>[
                TerminalResponsiveLookupRow(
                  breakpoint: 340,
                  field: ProductLookupField(
                    controller: _queryController,
                    enabled: !_isLoading,
                    onSubmit: _search,
                    labelText: 'Arama veya barkod',
                    suffixIcon: _hasQuery
                        ? IconButton(
                            onPressed: _isLoading ? null : _clearSearch,
                            tooltip: 'Temizle',
                            icon: const Icon(Icons.close_rounded),
                          )
                        : null,
                  ),
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _search,
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Urun'),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _isLoading ? null : _scanWithCamera,
                        tooltip: 'Kamera ile oku',
                        icon: const Icon(Icons.photo_camera_back_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: _isSyncingCatalog ? null : _syncCatalog,
                      icon: _isSyncingCatalog
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded),
                      label: Text(
                        _isSyncingCatalog ? 'Sync...' : 'Mobil Katalog Sync',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCatalogStatusBlock(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Sonuclar',
            subtitle: _isLoading
                ? 'Araniyor...'
                : _isUsingOfflineCatalog
                ? '${_products.length} urun local katalogdan bulundu.'
                : '${_products.length} urun bulundu.',
            child: Column(
              children: <Widget>[
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TerminalMessageBlock.error(message: _errorMessage!),
                  ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: CircularProgressIndicator(),
                  )
                else if (_products.isEmpty)
                  TerminalEmptyState(message: widget.emptyMessage)
                else
                  ..._products.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withAlpha(82),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    item.stockName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                TerminalBadge(
                                  label: item.isSalesBlocked
                                      ? 'Bloklu'
                                      : 'Bulundu',
                                  backgroundColor: item.isSalesBlocked
                                      ? const Color(0xFFFFE5E5)
                                      : const Color(0xFFE6F7EE),
                                  foregroundColor: item.isSalesBlocked
                                      ? const Color(0xFF7A1818)
                                      : const Color(0xFF1B7A46),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Kod ${item.stockCode} | Barkod ${item.barcode.isEmpty ? '-' : item.barcode} | Fiyat ${AppFormatters.currency(item.price)} | Birim ${item.unitName}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Siparis blok ${item.isOrderBlocked ? 'evet' : 'hayir'} | Satis blok ${item.isSalesBlocked ? 'evet' : 'hayir'} | Kabul blok ${item.isGoodsAcceptanceBlocked ? 'evet' : 'hayir'}',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogStatusBlock() {
    final message = _catalogStatusMessage;
    if (_isSyncingCatalog && message != null) {
      return TerminalMessageBlock.loading(message: message);
    }
    if (message != null) {
      return TerminalMessageBlock.info(message: message);
    }

    final metadata = _catalogMetadata;
    final customerMetadata = _customerCatalogMetadata;
    final warehouseMetadata = _warehouseCatalogMetadata;
    if ((metadata == null || metadata.syncToken.trim().isEmpty) &&
        (customerMetadata == null ||
            customerMetadata.syncToken.trim().isEmpty) &&
        (warehouseMetadata == null ||
            warehouseMetadata.syncToken.trim().isEmpty)) {
      return const TerminalMessageBlock.info(
        message:
            'Local kataloglar henuz indirilmedi. Onlineken Mobil Katalog Sync ile ilk tam indirmeyi yapin.',
      );
    }

    return TerminalMessageBlock.info(
      message: <String>[
        metadata == null || metadata.syncToken.trim().isEmpty
            ? 'Urun katalogu: henuz yok'
            : 'Urun katalogu: ${AppFormatters.dateTimeOrDash(metadata.lastCompletedAt)} | ${metadata.itemCount} urun | Depo ${metadata.warehouseNo}',
        customerMetadata == null || customerMetadata.syncToken.trim().isEmpty
            ? 'Cari katalogu: henuz yok'
            : 'Cari katalogu: ${AppFormatters.dateTimeOrDash(customerMetadata.lastCompletedAt)} | ${customerMetadata.itemCount} cari',
        warehouseMetadata == null || warehouseMetadata.syncToken.trim().isEmpty
            ? 'Depo katalogu: henuz yok'
            : 'Depo katalogu: ${AppFormatters.dateTimeOrDash(warehouseMetadata.lastCompletedAt)} | ${warehouseMetadata.itemCount} depo',
      ].join('\n'),
    );
  }
}

class CompanyLookupToolPage extends StatefulWidget {
  const CompanyLookupToolPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
  });

  final LegacyToolsRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;
  final String title;
  final String subtitle;
  final String emptyMessage;

  @override
  State<CompanyLookupToolPage> createState() => _CompanyLookupToolPageState();
}

class _CompanyLookupToolPageState extends State<CompanyLookupToolPage> {
  final TextEditingController _queryController = TextEditingController();
  bool _isLoading = false;
  bool _hasQuery = false;
  String? _errorMessage;
  List<CustomerLookupItem> _customers = const <CustomerLookupItem>[];

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _queryController.removeListener(_handleQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    final hasQuery = _queryController.text.trim().isNotEmpty;
    if (hasQuery == _hasQuery) {
      return;
    }

    setState(() {
      _hasQuery = hasQuery;
    });
  }

  void _clearSearch() {
    _queryController.clear();
    setState(() {
      _customers = const <CustomerLookupItem>[];
      _errorMessage = null;
      _isLoading = false;
    });
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Cari bulmak icin barkod girilmeli.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customers = await widget.repository.searchCustomersByBarcode(
        accessToken: widget.accessToken,
        barcode: query,
        warehouseNo: int.tryParse(widget.defaultWarehouseNo),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _scanWithCamera() async {
    if (!supportsCameraBarcodeScanning) {
      setState(() {
        _errorMessage = 'Bu cihazda kamera ile barkod okutma desteklenmiyor.';
      });
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: '${widget.title} Kamerasi',
      subtitle: 'Barkodu okutun; cari onerileri aranacak.',
    );

    if (barcode == null || !mounted) {
      return;
    }

    _queryController.text = barcode;
    await _search();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          20 + MediaQuery.paddingOf(context).bottom,
        ),
        children: <Widget>[
          SectionCard(
            title: widget.title,
            subtitle: widget.subtitle,
            child: TerminalResponsiveLookupRow(
              breakpoint: 340,
              field: ProductLookupField(
                controller: _queryController,
                enabled: !_isLoading,
                onSubmit: _search,
                labelText: 'Arama veya barkod',
                suffixIcon: _hasQuery
                    ? IconButton(
                        onPressed: _isLoading ? null : _clearSearch,
                        tooltip: 'Temizle',
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _search,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Urun'),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _isLoading ? null : _scanWithCamera,
                    tooltip: 'Kamera ile oku',
                    icon: const Icon(Icons.photo_camera_back_rounded),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Firmalar',
            subtitle: _isLoading
                ? 'Araniyor...'
                : '${_customers.length} firma bulundu.',
            child: Column(
              children: <Widget>[
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TerminalMessageBlock.error(message: _errorMessage!),
                  ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: CircularProgressIndicator(),
                  )
                else if (_customers.isEmpty)
                  TerminalEmptyState(message: widget.emptyMessage)
                else
                  ..._customers.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withAlpha(82),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.customerDisplayName,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Kod ${item.customerCode} | Vergi ${item.taxNumber.isEmpty ? '-' : item.taxNumber}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Temsilci ${item.representativeName.isEmpty ? '-' : item.representativeName} | Kilitli ${item.isLocked ? 'evet' : 'hayir'} | Kapali ${item.isClosed ? 'evet' : 'hayir'}',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PackageBarcodePage extends StatefulWidget {
  const PackageBarcodePage({
    super.key,
    required this.repository,
    required this.accessToken,
  });

  final LegacyToolsRepository repository;
  final String accessToken;

  @override
  State<PackageBarcodePage> createState() => _PackageBarcodePageState();
}

class _PackageBarcodePageState extends State<PackageBarcodePage> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _packageBarcodeController =
      TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  JsonMap _result = <String, dynamic>{};

  @override
  void dispose() {
    _barcodeController.dispose();
    _productCodeController.dispose();
    _packageBarcodeController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.repository.getPackageBarcodeForProduct(
        accessToken: widget.accessToken,
        barcode: _barcodeController.text.trim(),
        productCode: _productCodeController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.repository.addPackageBarcodeForProduct(
        accessToken: widget.accessToken,
        barcode: _barcodeController.text.trim(),
        productCode: _productCodeController.text.trim(),
        packageBarcode: _packageBarcodeController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _JsonActionPage(
      title: 'Koli Barkodu',
      subtitle: 'Urun ve koli barkodu eslesmesini okur veya yeni kayit yazar.',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      result: _result,
      formChildren: <Widget>[
        TextField(
          controller: _barcodeController,
          decoration: const InputDecoration(labelText: 'Urun Barkodu'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _productCodeController,
          decoration: const InputDecoration(labelText: 'Urun Kodu'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _packageBarcodeController,
          decoration: const InputDecoration(labelText: 'Koli Barkodu'),
        ),
      ],
      actions: <Widget>[
        FilledButton.icon(
          onPressed: _isLoading ? null : _lookup,
          icon: const Icon(Icons.search_rounded),
          label: const Text('Sorgula'),
        ),
        FilledButton.tonalIcon(
          onPressed: _isLoading ? null : _save,
          icon: const Icon(Icons.save_alt_rounded),
          label: const Text('Kaydet'),
        ),
      ],
    );
  }
}

class PiecesInBoxPage extends StatefulWidget {
  const PiecesInBoxPage({
    super.key,
    required this.repository,
    required this.accessToken,
  });

  final LegacyToolsRepository repository;
  final String accessToken;

  @override
  State<PiecesInBoxPage> createState() => _PiecesInBoxPageState();
}

class _PiecesInBoxPageState extends State<PiecesInBoxPage> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _stockCodeController = TextEditingController();
  final TextEditingController _piecesController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  JsonMap _result = <String, dynamic>{};

  @override
  void dispose() {
    _barcodeController.dispose();
    _stockCodeController.dispose();
    _piecesController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.repository.getCurrentProductByBarcode(
        accessToken: widget.accessToken,
        barcode: _barcodeController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _stockCodeController.text = result['stockCode']?.toString() ?? '';
        if (result['piecesInBox'] != null) {
          _piecesController.text = result['piecesInBox'].toString();
        }
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _update() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.repository.updateProductForPiecesInBox(
        accessToken: widget.accessToken,
        stockCode: _stockCodeController.text.trim(),
        barcode: _barcodeController.text.trim(),
        piecesInBox: int.tryParse(_piecesController.text.trim()) ?? 0,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _JsonActionPage(
      title: 'Koli Ici Adet',
      subtitle:
          'Barkoda bagli guncel urun bilgisini acar ve koli ici adet guncellemesi gonderir.',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      result: _result,
      formChildren: <Widget>[
        TerminalSubmitOnTab(
          enabled: !_isLoading,
          onSubmit: _lookup,
          child: TextField(
            controller: _barcodeController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _lookup(),
            decoration: const InputDecoration(labelText: 'Barkod'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _stockCodeController,
          decoration: const InputDecoration(labelText: 'Stok Kodu'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _piecesController,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(labelText: 'Koli Ici Adet'),
        ),
      ],
      actions: <Widget>[
        FilledButton.icon(
          onPressed: _isLoading ? null : _lookup,
          icon: const Icon(Icons.search_rounded),
          label: const Text('Barkodu Oku'),
        ),
        FilledButton.tonalIcon(
          onPressed: _isLoading ? null : _update,
          icon: const Icon(Icons.save_alt_rounded),
          label: const Text('Guncelle'),
        ),
      ],
    );
  }
}

class _JsonActionPage extends StatelessWidget {
  const _JsonActionPage({
    required this.title,
    required this.subtitle,
    required this.formChildren,
    required this.actions,
    required this.isLoading,
    required this.errorMessage,
    required this.result,
  });

  final String title;
  final String subtitle;
  final List<Widget> formChildren;
  final List<Widget> actions;
  final bool isLoading;
  final String? errorMessage;
  final JsonMap result;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          20 + MediaQuery.paddingOf(context).bottom,
        ),
        children: <Widget>[
          SectionCard(
            title: title,
            subtitle: subtitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ...formChildren,
                const SizedBox(height: 12),
                Wrap(spacing: 12, runSpacing: 12, children: actions),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Yanit',
            subtitle: isLoading ? 'Islem suruyor...' : 'Son donen veri',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TerminalMessageBlock.error(message: errorMessage!),
                  ),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (result.isEmpty)
                  const TerminalEmptyState(
                    message: 'Henuz gosterilecek bir yanit yok.',
                  )
                else
                  ...result.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withAlpha(82),
                          ),
                        ),
                        child: Text('${entry.key}: ${entry.value}'),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
