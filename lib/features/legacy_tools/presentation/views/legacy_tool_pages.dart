import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/core/network/api_client.dart';
import 'package:furpa_merkez_terminal/features/legacy_tools/data/legacy_tools_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class ProductLookupToolPage extends StatefulWidget {
  const ProductLookupToolPage({
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
  State<ProductLookupToolPage> createState() => _ProductLookupToolPageState();
}

class _ProductLookupToolPageState extends State<ProductLookupToolPage> {
  final TextEditingController _queryController = TextEditingController();
  bool _isLoading = false;
  bool _hasQuery = false;
  String? _errorMessage;
  List<SearchProductLookupItem> _products = const <SearchProductLookupItem>[];

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
      _products = const <SearchProductLookupItem>[];
      _errorMessage = null;
      _isLoading = false;
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
                  field: TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      labelText: 'Barkod / stok kodu / urun adi',
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                  action: FilledButton.icon(
                    onPressed: _isLoading ? null : _search,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Ara'),
                  ),
                  trailingAction: _hasQuery
                      ? OutlinedButton.icon(
                          onPressed: _isLoading ? null : _clearSearch,
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Temizle'),
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Sonuclar',
            subtitle: _isLoading
                ? 'Araniyor...'
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
              field: TextField(
                controller: _queryController,
                decoration: const InputDecoration(labelText: 'Barkod'),
                onSubmitted: (_) => _search(),
              ),
              action: FilledButton.icon(
                onPressed: _isLoading ? null : _search,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Ara'),
              ),
              trailingAction: _hasQuery
                  ? OutlinedButton.icon(
                      onPressed: _isLoading ? null : _clearSearch,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Temizle'),
                    )
                  : null,
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
        TextField(
          controller: _barcodeController,
          decoration: const InputDecoration(labelText: 'Barkod'),
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
