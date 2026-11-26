import 'dart:async';

import 'package:flutter/material.dart';
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

typedef CustomerDocumentLauncher =
    Future<void> Function(BuildContext context, CustomerLookupItem customer);

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
    this.useStockAvailabilityEndpoint = false,
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
  final bool useStockAvailabilityEndpoint;

  @override
  State<ProductLookupToolPage> createState() => _ProductLookupToolPageState();
}

class _ProductLookupToolPageState extends State<ProductLookupToolPage> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _queryFocusNode = FocusNode();
  int _searchRequestId = 0;
  bool _isLoading = false;
  bool _isSyncingCatalog = false;
  bool _hasQuery = false;
  bool _isUsingOfflineCatalog = false;
  bool _hideDelistedProducts = false;
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
    _focusSearchField();
  }

  @override
  void dispose() {
    _queryController.removeListener(_handleQueryChanged);
    _queryController.dispose();
    _queryFocusNode.dispose();
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
    _searchRequestId++;
    _queryController.clear();
    setState(() {
      _products = const <SearchProductLookupItem>[];
      _errorMessage = null;
      _isUsingOfflineCatalog = false;
      _isLoading = false;
    });
    _focusSearchField();
  }

  void _focusSearchField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _queryFocusNode.requestFocus();
      }
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

    final requestId = ++_searchRequestId;
    final isBarcode = RegExp(r'^\d{7,}$').hasMatch(query);
    if (isBarcode) {
      _queryController.clear();
    }
    _focusSearchField();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = widget.useStockAvailabilityEndpoint
          ? await widget.repository.searchStockAvailability(
              accessToken: widget.accessToken,
              warehouseNo: widget.defaultWarehouseNo,
              query: query,
              includeDelisted: !_hideDelistedProducts,
            )
          : await widget.repository.searchProducts(
              accessToken: widget.accessToken,
              warehouseNo: widget.defaultWarehouseNo,
              query: query,
              includeDelisted: !_hideDelistedProducts,
            );

      if (!mounted || requestId != _searchRequestId) {
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

      if (!mounted || requestId != _searchRequestId) {
        return;
      }

      if (catalogProducts.isNotEmpty) {
        final mappedProducts = catalogProducts
            .map((item) => item.toSearchProductLookupItem())
            .where(
              (item) => !_hideDelistedProducts || !item.needsStatusAttention,
            )
            .toList(growable: false);
        setState(() {
          _products = mappedProducts;
          _isUsingOfflineCatalog = true;
          _catalogStatusMessage =
              'API erisilemedi; son basarili katalog sync verisi gosteriliyor.';
          _isLoading = false;
          _errorMessage = null;
        });
        _focusSearchField();
        return;
      }

      setState(() {
        _isLoading = false;
        _isUsingOfflineCatalog = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
      _focusSearchField();
    } catch (error) {
      if (!mounted || requestId != _searchRequestId) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isUsingOfflineCatalog = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
      _focusSearchField();
    }

    _focusSearchField();
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
    final isCompactWidth = MediaQuery.sizeOf(context).width < 420;
    final showCatalogBelow = _products.isNotEmpty && !_isSyncingCatalog;

    return SafeArea(
      top: false,
      bottom: true,
      child: ListView(
        padding: terminalPdaListPagePadding(context),
        children: <Widget>[
          SectionCard(
            title: widget.title,
            subtitle: isCompactWidth ? null : widget.subtitle,
            dense: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TerminalResponsiveLookupRow(
                  breakpoint: 250,
                  field: ProductLookupField(
                    controller: _queryController,
                    focusNode: _queryFocusNode,
                    autofocus: true,
                    enabled: true,
                    onSubmit: _search,
                    labelText: 'Barkod / urun',
                    suffixIcon: _hasQuery
                        ? IconButton(
                            onPressed: _isLoading ? null : _clearSearch,
                            tooltip: 'Temizle',
                            icon: const Icon(Icons.close_rounded, size: 18),
                          )
                        : null,
                  ),
                  action: FilledButton.icon(
                    onPressed: _isLoading ? null : _search,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Urun'),
                  ),
                  trailingAction: IconButton.filledTonal(
                    onPressed: _isLoading ? null : _scanWithCamera,
                    tooltip: 'Kamera ile oku',
                    icon: const Icon(Icons.photo_camera_back_rounded),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: _isSyncingCatalog ? null : _syncCatalog,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: _isSyncingCatalog
                          ? const SizedBox.square(
                              dimension: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded, size: 17),
                      label: Text(
                        _isSyncingCatalog ? 'Sync...' : 'Mobil Katalog Sync',
                      ),
                    ),
                    FilterChip(
                      selected: _hideDelistedProducts,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onSelected: _isLoading
                          ? null
                          : (selected) {
                              setState(() {
                                _hideDelistedProducts = selected;
                              });
                              if (_queryController.text.trim().isNotEmpty) {
                                unawaited(_search());
                              }
                            },
                      label: const Text('Pasif/DLS gizle'),
                      avatar: Icon(
                        _hideDelistedProducts
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                if (!showCatalogBelow) ...<Widget>[
                  const SizedBox(height: 6),
                  _buildCatalogStatusBlock(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          SectionCard(
            title: 'Sonuclar',
            subtitle: _isLoading
                ? 'Araniyor...'
                : _isUsingOfflineCatalog
                ? '${_products.length} urun local katalogdan bulundu.'
                : '${_products.length} urun bulundu.',
            dense: true,
            framed: _products.isEmpty,
            child: Column(
              children: <Widget>[
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TerminalMessageBlock.error(message: _errorMessage!),
                  ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  )
                else if (_products.isEmpty)
                  TerminalEmptyState(message: widget.emptyMessage)
                else
                  ..._products.map((item) {
                    final blockLabels = <String>[
                      if (item.isPassive) 'Pasif',
                      if (item.isDelisted)
                        item.delistReason.trim().isEmpty
                            ? 'DLS'
                            : 'DLS: ${item.delistReason.trim()}',
                      if (item.isOrderBlocked) 'Siparis',
                      if (item.isSalesBlocked) 'Satis',
                      if (item.isGoodsAcceptanceBlocked) 'Kabul',
                    ];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: TerminalPdaDetailPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    item.stockName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontSize: 13.5,
                                          height: 1.12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                TerminalBadge(
                                  label: _resultBadgeLabel(item),
                                  backgroundColor: _resultBadgeBackground(item),
                                  foregroundColor: _resultBadgeForeground(item),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            TerminalPdaInfoGrid(
                              compact: true,
                              items: <TerminalPdaInfo>[
                                TerminalPdaInfo(
                                  label: widget.useStockAvailabilityEndpoint
                                      ? 'Stok'
                                      : 'Fiyat',
                                  value: widget.useStockAvailabilityEndpoint
                                      ? _stockQuantityLabel(item)
                                      : AppFormatters.currency(item.price),
                                ),
                                TerminalPdaInfo(
                                  label: 'Kod',
                                  value: item.stockCode,
                                ),
                                if (item.barcode.trim().isNotEmpty)
                                  TerminalPdaInfo(
                                    label: 'Barkod',
                                    value: item.barcode,
                                  ),
                                TerminalPdaInfo(
                                  label: 'Birim',
                                  value: item.unitName,
                                ),
                                if (widget.useStockAvailabilityEndpoint)
                                  TerminalPdaInfo(
                                    label: 'Depo',
                                    value: item.warehouseName.isEmpty
                                        ? item.warehouseNo.toString()
                                        : item.warehouseName,
                                  ),
                                if (widget.useStockAvailabilityEndpoint)
                                  TerminalPdaInfo(
                                    label: 'Fiyat',
                                    value: AppFormatters.currency(item.price),
                                  ),
                                if (item.unitMultiplier > 1)
                                  TerminalPdaInfo(
                                    label: 'Koli ici',
                                    value:
                                        '${AppFormatters.quantity(item.unitMultiplier)} ${item.unitName}',
                                  ),
                              ],
                            ),
                            if (widget.useStockAvailabilityEndpoint &&
                                item.isVariableWeightBarcode) ...<Widget>[
                              const SizedBox(height: 4),
                              Text(
                                _variableWeightLabel(item),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (blockLabels.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 4),
                              Text(
                                'Bloklu: ${blockLabels.join(', ')}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          if (showCatalogBelow) ...<Widget>[
            const SizedBox(height: 8),
            _buildCatalogStatusBlock(),
          ],
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

  String _resultBadgeLabel(SearchProductLookupItem item) {
    if (!widget.useStockAvailabilityEndpoint) {
      if (item.needsStatusAttention) {
        return item.statusWarningLabel;
      }
      return item.isSalesBlocked ? 'Bloklu' : 'Bulundu';
    }

    if (item.needsStatusAttention) {
      return item.statusWarningLabel;
    }

    if (item.hasStock == false) {
      return 'Stok Yok';
    }

    if (item.isSalesBlocked ||
        item.isOrderBlocked ||
        item.isGoodsAcceptanceBlocked) {
      return 'Bloklu';
    }

    return 'Stok Var';
  }

  Color _resultBadgeBackground(SearchProductLookupItem item) {
    if (widget.useStockAvailabilityEndpoint && item.hasStock == false) {
      return const Color(0xFFFFF4D6);
    }

    if (item.needsStatusAttention) {
      return const Color(0xFFFFF4D6);
    }

    final isBlocked =
        item.isSalesBlocked ||
        item.isOrderBlocked ||
        item.isGoodsAcceptanceBlocked;
    return isBlocked ? const Color(0xFFFFE5E5) : const Color(0xFFE6F7EE);
  }

  Color _resultBadgeForeground(SearchProductLookupItem item) {
    if (widget.useStockAvailabilityEndpoint && item.hasStock == false) {
      return const Color(0xFF7A4A00);
    }

    if (item.needsStatusAttention) {
      return const Color(0xFF7A4A00);
    }

    final isBlocked =
        item.isSalesBlocked ||
        item.isOrderBlocked ||
        item.isGoodsAcceptanceBlocked;
    return isBlocked ? const Color(0xFF7A1818) : const Color(0xFF1B7A46);
  }

  String _stockQuantityLabel(SearchProductLookupItem item) {
    final quantity = item.currentStockQuantity;
    if (quantity == null) {
      return '-';
    }

    final unit = item.unitName.trim();
    return unit.isEmpty
        ? AppFormatters.quantity(quantity)
        : '${AppFormatters.quantity(quantity)} $unit';
  }

  String _variableWeightLabel(SearchProductLookupItem item) {
    final quantity = item.embeddedQuantity;
    final unit = item.embeddedQuantityUnit.trim().isEmpty
        ? item.unitName
        : item.embeddedQuantityUnit;
    final quantityLabel = quantity == null
        ? '-'
        : '${AppFormatters.quantity(quantity)} $unit';
    final lookupBarcode = item.lookupBarcode.trim().isEmpty
        ? '-'
        : item.lookupBarcode;
    final checkDigitText = switch (item.isBarcodeCheckDigitValid) {
      true => 'dogru',
      false => 'hatali',
      null => 'bilinmiyor',
    };

    return 'Terazi barkodu: $quantityLabel | Aranan: $lookupBarcode | Kontrol: $checkDigitText';
  }
}

class CompanyLookupToolPage extends StatefulWidget {
  const CompanyLookupToolPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.customerCatalogRepository,
    required this.customerCatalogSyncService,
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
    this.onOpenCompanyAcceptance,
    this.onOpenCompanyReturn,
  });

  final LegacyToolsRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;
  final MobileCustomerCatalogLocalRepository customerCatalogRepository;
  final MobileCustomerCatalogSyncService customerCatalogSyncService;
  final String title;
  final String subtitle;
  final String emptyMessage;
  final CustomerDocumentLauncher? onOpenCompanyAcceptance;
  final CustomerDocumentLauncher? onOpenCompanyReturn;

  @override
  State<CompanyLookupToolPage> createState() => _CompanyLookupToolPageState();
}

class _CompanyLookupToolPageState extends State<CompanyLookupToolPage> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _queryFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isSyncingCatalog = false;
  bool _hasQuery = false;
  bool _isUsingOfflineCatalog = false;
  String? _errorMessage;
  String? _catalogStatusMessage;
  MobileCustomerCatalogMetadata? _customerCatalogMetadata;
  List<CustomerLookupItem> _customers = const <CustomerLookupItem>[];

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_handleQueryChanged);
    unawaited(_loadCatalogMetadata());
    _focusSearchField();
  }

  @override
  void dispose() {
    _queryController.removeListener(_handleQueryChanged);
    _queryController.dispose();
    _queryFocusNode.dispose();
    super.dispose();
  }

  void _focusSearchField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _queryFocusNode.requestFocus();
      }
    });
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
      _catalogStatusMessage = null;
      _isUsingOfflineCatalog = false;
      _isLoading = false;
    });
    _focusSearchField();
  }

  Future<void> _loadCatalogMetadata() async {
    final metadata = await widget.customerCatalogRepository.fetchMetadata();
    if (!mounted) {
      return;
    }

    setState(() {
      _customerCatalogMetadata = metadata;
    });
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Cari bulmak icin barkod girilmeli.';
      });
      _focusSearchField();
      return;
    }

    if (RegExp(r'^\d{7,}$').hasMatch(query)) {
      _queryController.clear();
    }
    _focusSearchField();

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
        _isUsingOfflineCatalog = false;
        _catalogStatusMessage = null;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      final catalogCustomers = await widget.customerCatalogRepository
          .searchCustomers(query: query);

      if (!mounted) {
        return;
      }

      if (catalogCustomers.isNotEmpty) {
        setState(() {
          _customers = catalogCustomers
              .map((item) => item.toCustomerLookupItem())
              .toList(growable: false);
          _isUsingOfflineCatalog = true;
          _catalogStatusMessage =
              'API erisilemedi; son basarili cari katalog sync verisi gosteriliyor.';
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

    _focusSearchField();
  }

  Future<void> _syncCatalog() async {
    if (_isSyncingCatalog) {
      return;
    }

    setState(() {
      _isSyncingCatalog = true;
      _errorMessage = null;
      _catalogStatusMessage = 'Cari katalog sync ediliyor...';
    });

    try {
      final result = await widget.customerCatalogSyncService.syncCatalog(
        accessToken: widget.accessToken,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _customerCatalogMetadata = result.metadata;
        _isSyncingCatalog = false;
        _catalogStatusMessage =
            'Cari katalog tamamlandi: ${result.pagesFetched} sayfa / ${result.upsertedCount} kayit / ${result.deletedCount} silinen.';
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
    final isCompactWidth = MediaQuery.sizeOf(context).width < 420;
    final showCatalogBelow = _customers.isNotEmpty && !_isSyncingCatalog;

    return SafeArea(
      top: false,
      bottom: true,
      child: ListView(
        padding: terminalPdaListPagePadding(context),
        children: <Widget>[
          SectionCard(
            title: widget.title,
            subtitle: isCompactWidth ? null : widget.subtitle,
            dense: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TerminalResponsiveLookupRow(
                  breakpoint: 250,
                  field: ProductLookupField(
                    controller: _queryController,
                    focusNode: _queryFocusNode,
                    autofocus: true,
                    enabled: true,
                    onSubmit: _search,
                    labelText: 'Barkod / cari',
                    suffixIcon: _hasQuery
                        ? IconButton(
                            onPressed: _isLoading ? null : _clearSearch,
                            tooltip: 'Temizle',
                            icon: const Icon(Icons.close_rounded, size: 18),
                          )
                        : null,
                  ),
                  action: FilledButton.icon(
                    onPressed: _isLoading ? null : _search,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Cari'),
                  ),
                  trailingAction: IconButton.filledTonal(
                    onPressed: _isLoading ? null : _scanWithCamera,
                    tooltip: 'Kamera ile oku',
                    icon: const Icon(Icons.photo_camera_back_rounded),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: _isSyncingCatalog ? null : _syncCatalog,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: _isSyncingCatalog
                          ? const SizedBox.square(
                              dimension: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded, size: 17),
                      label: Text(
                        _isSyncingCatalog ? 'Sync...' : 'Cari Katalog Sync',
                      ),
                    ),
                  ],
                ),
                if (!showCatalogBelow) ...<Widget>[
                  const SizedBox(height: 6),
                  _buildCustomerCatalogStatusBlock(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          SectionCard(
            title: 'Firmalar',
            subtitle: _isLoading
                ? 'Araniyor...'
                : _isUsingOfflineCatalog
                ? '${_customers.length} firma local katalogdan bulundu.'
                : '${_customers.length} firma bulundu.',
            dense: true,
            framed: _customers.isEmpty,
            child: Column(
              children: <Widget>[
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TerminalMessageBlock.error(message: _errorMessage!),
                  ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  )
                else if (_customers.isEmpty)
                  TerminalEmptyState(message: widget.emptyMessage)
                else
                  ..._customers.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: TerminalPdaDetailPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    item.lookupTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontSize: 13.5,
                                          height: 1.12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                                if (item.isLocked ||
                                    item.isClosed ||
                                    item.isEDespatchCustomer) ...<Widget>[
                                  const SizedBox(width: 6),
                                  Wrap(
                                    spacing: 4,
                                    children: <Widget>[
                                      if (item.isEDespatchCustomer)
                                        const TerminalBadge(label: 'E-Irs.'),
                                      if (item.isLocked)
                                        const TerminalBadge(
                                          label: 'Kilitli',
                                          backgroundColor: Color(0xFFFFE5E5),
                                          foregroundColor: Color(0xFF7A1818),
                                        ),
                                      if (item.isClosed)
                                        const TerminalBadge(
                                          label: 'Kapali',
                                          backgroundColor: Color(0xFFFFE5E5),
                                          foregroundColor: Color(0xFF7A1818),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            if (item.selectionLabel.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.selectionLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(height: 5),
                            TerminalPdaInfoGrid(
                              compact: true,
                              items: <TerminalPdaInfo>[
                                TerminalPdaInfo(
                                  label: 'Kod',
                                  value: item.customerCode,
                                ),
                                if (item.displayTaxNumber.trim().isNotEmpty)
                                  TerminalPdaInfo(
                                    label: 'Vergi',
                                    value: item.displayTaxNumber,
                                  ),
                                if (item.customerTitle.trim().isNotEmpty &&
                                    item.customerTitle.trim() !=
                                        item.lookupTitle.trim())
                                  TerminalPdaInfo(
                                    label: 'Unvan',
                                    value: item.customerTitle,
                                  ),
                                if (item.groupCode.isNotEmpty)
                                  TerminalPdaInfo(
                                    label: 'Grup',
                                    value: item.groupCode,
                                  ),
                                if (item.regionCode.isNotEmpty)
                                  TerminalPdaInfo(
                                    label: 'Bolge',
                                    value: item.regionCode,
                                  ),
                                if (item.sameTaxCustomerCount > 1)
                                  TerminalPdaInfo(
                                    label: 'Ayni Vergi',
                                    value: '${item.sameTaxCustomerCount}',
                                  ),
                                if (item.taxOfficeName.isNotEmpty)
                                  TerminalPdaInfo(
                                    label: 'Vergi D.',
                                    value: item.taxOfficeName,
                                  ),
                                if (item.representativeName.trim().isNotEmpty)
                                  TerminalPdaInfo(
                                    label: 'Temsilci',
                                    value: item.representativeName,
                                  ),
                              ],
                            ),
                            if (widget.onOpenCompanyAcceptance != null ||
                                widget.onOpenCompanyReturn != null) ...<Widget>[
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  if (widget.onOpenCompanyAcceptance != null)
                                    Expanded(
                                      child: FilledButton.tonalIcon(
                                        onPressed:
                                            item.isLocked || item.isClosed
                                            ? null
                                            : () =>
                                                  widget
                                                      .onOpenCompanyAcceptance!(
                                                    context,
                                                    item,
                                                  ),
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size(0, 40),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 0,
                                          ),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.standard,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.inventory_2_rounded,
                                          size: 17,
                                        ),
                                        label: const Text('Mal Kabul'),
                                      ),
                                    ),
                                  if (widget.onOpenCompanyAcceptance != null &&
                                      widget.onOpenCompanyReturn != null)
                                    const SizedBox(width: 8),
                                  if (widget.onOpenCompanyReturn != null)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed:
                                            item.isLocked || item.isClosed
                                            ? null
                                            : () => widget.onOpenCompanyReturn!(
                                                context,
                                                item,
                                              ),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 40),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 0,
                                          ),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.standard,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.undo_rounded,
                                          size: 17,
                                        ),
                                        label: const Text('Firma Iade'),
                                      ),
                                    ),
                                ],
                              ),
                              if (item.isLocked || item.isClosed) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  'Kilitli veya kapali cari ile yeni belge acilamaz.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          if (showCatalogBelow) ...<Widget>[
            const SizedBox(height: 8),
            _buildCustomerCatalogStatusBlock(),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerCatalogStatusBlock() {
    final message = _catalogStatusMessage;
    if (_isSyncingCatalog && message != null) {
      return TerminalMessageBlock.loading(message: message);
    }
    if (message != null) {
      return TerminalMessageBlock.info(message: message);
    }

    final metadata = _customerCatalogMetadata;
    if (metadata == null || metadata.syncToken.trim().isEmpty) {
      return const TerminalMessageBlock.info(
        message:
            'Cari katalogu henuz indirilmedi. Onlineken Cari Katalog Sync ile ilk tam indirmeyi yapin.',
      );
    }

    return TerminalMessageBlock.info(
      message:
          'Cari katalogu: ${AppFormatters.dateTimeOrDash(metadata.lastCompletedAt)} | ${metadata.itemCount} cari',
    );
  }
}
