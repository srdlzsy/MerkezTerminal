import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_lookup_cache_repository.dart';
import 'package:furpa_merkez_terminal/shared/utils/client_request_id.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

enum _InventoryEntryMode { barcode, search, camera }

class InventoryCountCreateSheet extends StatefulWidget {
  const InventoryCountCreateSheet({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.currentUserId,
    required this.defaultWarehouseNo,
    required this.lookupCacheRepository,
  });

  final InventoryCountsRepository repository;
  final String accessToken;
  final String currentUserId;
  final String defaultWarehouseNo;
  final OfflineLookupCacheRepository lookupCacheRepository;

  @override
  State<InventoryCountCreateSheet> createState() =>
      _InventoryCountCreateSheetState();
}

class _InventoryCountCreateSheetState extends State<InventoryCountCreateSheet>
    with CreateFormValidation {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _nameController;
  late DateTime _documentDate;
  late List<_InventoryLineDraft> _lines;
  late _InventoryEntryMode _entryMode;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _documentDate = _normalizeDate(DateTime.now());
    _lines = <_InventoryLineDraft>[_InventoryLineDraft()];
    _entryMode = _InventoryEntryMode.barcode;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _documentDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _documentDate = pickedDate;
    });
  }

  Future<void> _searchProduct(_InventoryLineDraft line) async {
    final product = await showModalBottomSheet<InventoryCountProductLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return _InventoryProductLookupSheet(
          onSearchProducts: _searchProductsWithFallback,
        );
      },
    );

    if (product == null || !mounted) {
      return;
    }

    var mergedIntoExisting = false;
    setState(() {
      mergedIntoExisting = _applyProductToLine(line, product);
      _validationMessage = null;
    });

    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  Future<void> _findProductByBarcode(_InventoryLineDraft line) async {
    final barcode = line.barcodeController.text.trim();
    if (barcode.length < 3) {
      _showFeedback('Barkod alanina gecerli bir deger girin.');
      return;
    }

    try {
      final products = await _searchProductsWithFallback(barcode);

      if (!mounted) {
        return;
      }

      if (products.isEmpty) {
        _showFeedback('Bu barkoda ait urun bulunamadi.');
        return;
      }

      var mergedIntoExisting = false;
      setState(() {
        mergedIntoExisting = _applyProductToLine(line, products.first);
        _validationMessage = null;
      });

      if (mergedIntoExisting) {
        _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showFeedback(error.toString().replaceFirst('Exception: ', '').trim());
    }
  }

  Future<List<InventoryCountProductLookupItem>> _searchProductsWithFallback(
    String query,
  ) async {
    try {
      final items = await widget.repository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        query: query,
      );
      await widget.lookupCacheRepository.cacheInventoryProducts(
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        items: items,
      );
      return items;
    } on ApiException {
      final cached = await widget.lookupCacheRepository.searchInventoryProducts(
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        query: query,
      );
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  Future<void> _scanProductWithCamera(_InventoryLineDraft line) async {
    if (!supportsCameraBarcodeScanning) {
      _showFeedback('Bu cihazda kamera ile barkod okutma desteklenmiyor.');
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Sayim Barkod Kamerasi',
      subtitle: 'Barkodu okutun; bulunan urun satira eklenecek.',
    );

    if (barcode == null || !mounted) {
      return;
    }

    line.barcodeController.text = barcode;
    await _findProductByBarcode(line);
  }

  bool _applyProductToLine(
    _InventoryLineDraft line,
    InventoryCountProductLookupItem product,
  ) {
    final existingLine = _findDuplicateLine(
      currentLine: line,
      barcode: product.barcode,
      stockCode: product.stockCode,
    );

    if (existingLine == null) {
      line.applyProduct(product);
      return false;
    }

    existingLine.quantityController.text = _formatQuantity(
      _parseDouble(existingLine.quantityController.text) +
          _parseDouble(line.quantityController.text),
    );
    _recycleMergedLine(line, createReplacement: _InventoryLineDraft.new);
    return true;
  }

  _InventoryLineDraft? _findDuplicateLine({
    required _InventoryLineDraft currentLine,
    required String barcode,
    required String stockCode,
  }) {
    final targetKey = _productIdentity(barcode: barcode, stockCode: stockCode);
    if (targetKey == null) {
      return null;
    }

    for (final candidate in _lines) {
      if (identical(candidate, currentLine)) {
        continue;
      }

      final selectedProduct = candidate.selectedProduct;
      if (selectedProduct == null) {
        continue;
      }

      final candidateKey = _productIdentity(
        barcode: selectedProduct.barcode,
        stockCode: selectedProduct.stockCode,
      );
      if (candidateKey == targetKey) {
        return candidate;
      }
    }

    return null;
  }

  void _recycleMergedLine(
    _InventoryLineDraft line, {
    required _InventoryLineDraft Function() createReplacement,
  }) {
    final lineIndex = _lines.indexOf(line);
    line.dispose();

    if (lineIndex == 0) {
      _lines[lineIndex] = createReplacement();
      return;
    }

    _lines = _lines.where((item) => item != line).toList(growable: false);
  }

  void _addLine() {
    setState(() {
      _lines = <_InventoryLineDraft>[_InventoryLineDraft(), ..._lines];
      _validationMessage = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeLine(_InventoryLineDraft line) {
    if (_lines.length == 1) {
      return;
    }

    setState(() {
      _lines = _lines.where((item) => item != line).toList(growable: false);
      line.dispose();
      _validationMessage = null;
    });
  }

  void _submit() {
    if (!validateCreateForm(_formKey)) {
      setState(() {
        _validationMessage = 'Lutfen zorunlu alanlari duzeltin.';
      });
      return;
    }

    final requestLines = <InventoryCountCreateLine>[];
    for (var index = 0; index < _lines.length; index += 1) {
      final line = _lines[index];
      final stockCode = line.stockCodeController.text.trim();
      final quantity = _parseDouble(line.quantityController.text);

      if (stockCode.isEmpty) {
        setState(() {
          _validationMessage = '${index + 1}. satir icin urun secin.';
        });
        return;
      }

      if (quantity <= 0) {
        setState(() {
          _validationMessage =
              '${index + 1}. satir icin miktar sifirdan buyuk olmali.';
        });
        return;
      }

      requestLines.add(
        InventoryCountCreateLine(
          stockCode: stockCode,
          quantity: quantity,
          barcode: line.barcodeController.text.trim(),
          unitPointer: 1,
        ),
      );
    }

    Navigator.of(context).pop(
      InventoryCountCreateRequest(
        clientRequestId: generateClientRequestId(),
        name: _nameController.text.trim(),
        documentDate: _documentDate,
        lines: requestLines,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.94,
          child: Material(
            color: theme.scaffoldBackgroundColor,
            child: Form(
              key: _formKey,
              autovalidateMode: createFormAutovalidateMode,
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withAlpha(14),
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Yeni Sayim Sonucu',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Depo: ${widget.defaultWarehouseNo}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 26),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Sayim Adi*',
                            hintText: 'Nisan 2026 Genel Sayim',
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Zorunlu';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text('Belge Tarihi'),
                              Text(
                                AppFormatters.date(_documentDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Text(
                                'Urun girisi:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            _buildModeChip(
                              'Barkod ile',
                              _InventoryEntryMode.barcode,
                            ),
                            _buildModeChip(
                              'Arama ile',
                              _InventoryEntryMode.search,
                            ),
                            _buildModeChip(
                              'Kamera ile',
                              _InventoryEntryMode.camera,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._lines.asMap().entries.map(
                          (entry) => _buildLineCard(
                            theme: theme,
                            index: entry.key,
                            line: entry.value,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _addLine,
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Yeni Satir Ekle'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_validationMessage != null) ...<Widget>[
                          const SizedBox(height: 16),
                          _ValidationBlock(message: _validationMessage!),
                        ],
                        const SizedBox(height: 16),
                        TerminalFormActionRow(
                          submitFlex: 2,
                          cancel: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Vazgec'),
                          ),
                          submit: FilledButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Sayimi Kaydet'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, _InventoryEntryMode mode) {
    final isSelected = _entryMode == mode;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _entryMode = mode;
          _validationMessage = null;
        });
      },
    );
  }

  Widget _buildLineCard({
    required ThemeData theme,
    required int index,
    required _InventoryLineDraft line,
  }) {
    final product = line.selectedProduct;
    final isBarcodeMode = _entryMode == _InventoryEntryMode.barcode;
    final isCameraMode = _entryMode == _InventoryEntryMode.camera;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Satir ${index + 1}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (_lines.length > 1)
                  IconButton(
                    onPressed: () => _removeLine(line),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                if (isBarcodeMode)
                  TerminalResponsiveLookupRow(
                    breakpoint: 340,
                    field: TextField(
                      controller: line.barcodeController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _findProductByBarcode(line),
                      decoration: const InputDecoration(
                        labelText: 'Barkod',
                        hintText: 'Tarat veya yaz',
                        suffixIcon: Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 20,
                        ),
                      ),
                    ),
                    action: FilledButton.tonal(
                      onPressed: () => _findProductByBarcode(line),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Bul'),
                    ),
                  )
                else if (isCameraMode)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _scanProductWithCamera(line),
                      icon: const Icon(
                        Icons.photo_camera_back_rounded,
                        size: 18,
                      ),
                      label: Text(
                        product == null ? 'Kamera ile Oku' : 'Tekrar Kamera Ac',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _searchProduct(line),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: Text(
                        product == null ? 'Urun Sec' : 'Urun Degistir',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: line.quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                  ],
                  decoration: const InputDecoration(labelText: 'Miktar*'),
                  validator: (value) {
                    if (_parseDouble(value ?? '') <= 0) {
                      return 'Zorunlu';
                    }

                    return null;
                  },
                ),
                if (product != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      [
                        'Barkod: ${product.barcode.isEmpty ? '-' : product.barcode}',
                        'Birim: ${product.unitName}',
                        if (product.isGoodsAcceptanceBlocked)
                          'Sayim/tesellum uyari bayragi var',
                      ].join(' | '),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static double _parseDouble(String raw) {
    return double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;
  }

  static String? _productIdentity({
    required String barcode,
    required String stockCode,
  }) {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isNotEmpty) {
      return 'b:$normalizedBarcode';
    }

    final normalizedStockCode = stockCode.trim();
    if (normalizedStockCode.isNotEmpty) {
      return 's:$normalizedStockCode';
    }

    return null;
  }

  static String _formatQuantity(double value) {
    final fixed = value.toStringAsFixed(6);
    final normalized = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    return normalized.replaceAll('.', ',');
  }

  void _showFeedback(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _InventoryLineDraft {
  _InventoryLineDraft()
    : barcodeController = TextEditingController(),
      stockCodeController = TextEditingController(),
      quantityController = TextEditingController(text: '1');

  InventoryCountProductLookupItem? selectedProduct;
  final TextEditingController barcodeController;
  final TextEditingController stockCodeController;
  final TextEditingController quantityController;

  void applyProduct(InventoryCountProductLookupItem product) {
    selectedProduct = product;
    barcodeController.text = product.barcode;
    stockCodeController.text = product.stockCode;
  }

  void dispose() {
    barcodeController.dispose();
    stockCodeController.dispose();
    quantityController.dispose();
  }
}

class _InventoryProductLookupSheet extends StatefulWidget {
  const _InventoryProductLookupSheet({required this.onSearchProducts});

  final Future<List<InventoryCountProductLookupItem>> Function(String query)
  onSearchProducts;

  @override
  State<_InventoryProductLookupSheet> createState() =>
      _InventoryProductLookupSheetState();
}

class _InventoryProductLookupSheetState
    extends State<_InventoryProductLookupSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  List<InventoryCountProductLookupItem> _items =
      const <InventoryCountProductLookupItem>[];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final query = _queryController.text.trim();
    if (query.length < 2) {
      setState(() {
        _errorMessage = 'En az 2 karakter girin.';
        _items = const <InventoryCountProductLookupItem>[];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.onSearchProducts(query);

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _LookupScaffold(
      title: 'Urun Ara',
      subtitle: 'Stok kodu, adi veya barkod ile arama yapin.',
      queryController: _queryController,
      onSearch: _load,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      isEmpty: _items.isEmpty,
      emptyMessage: 'Sonuc bulunamadi.',
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            tileColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withAlpha(40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Text(
              item.displayLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                'Barkod ${item.barcode.isEmpty ? '-' : item.barcode}',
                'Birim ${item.unitName}',
              ].join(' | '),
            ),
            onTap: () => Navigator.of(context).pop(item),
          );
        },
      ),
    );
  }
}

class _LookupScaffold extends StatelessWidget {
  const _LookupScaffold({
    required this.title,
    required this.subtitle,
    required this.queryController,
    required this.onSearch,
    required this.isLoading,
    required this.errorMessage,
    required this.isEmpty,
    required this.emptyMessage,
    required this.child,
  });

  final String title;
  final String subtitle;
  final TextEditingController queryController;
  final VoidCallback onSearch;
  final bool isLoading;
  final String? errorMessage;
  final bool isEmpty;
  final String emptyMessage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: Material(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: queryController,
                              onSubmitted: (_) => onSearch(),
                              decoration: const InputDecoration(
                                hintText: 'Ara...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: isLoading ? null : onSearch,
                            child: const Text('Ara'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                      ? Center(child: Text(errorMessage!))
                      : isEmpty
                      ? Center(child: Text(emptyMessage))
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: child,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ValidationBlock extends StatelessWidget {
  const _ValidationBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
