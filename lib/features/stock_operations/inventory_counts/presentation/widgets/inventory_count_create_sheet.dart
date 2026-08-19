import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_session.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_controller.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/utils/client_request_id.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/utils/terminal_feedback.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class InventoryCountCreateSheet extends StatefulWidget {
  const InventoryCountCreateSheet({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.mobileProductCatalogRepository,
    this.draft,
    this.draftRepository,
  });

  final InventoryCountsRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;
  final MobileProductCatalogLocalRepository mobileProductCatalogRepository;
  final CreateDraft? draft;
  final CreateDraftRepository? draftRepository;

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
  String? _validationMessage;
  late final CreateDraftSession _draftSession;
  String? _lastAddedProductKey;

  @override
  void initState() {
    super.initState();
    final payload = widget.draft?.payload ?? const <String, dynamic>{};
    _nameController = TextEditingController(
      text: payload['name']?.toString() ?? '',
    );
    _documentDate =
        DateTime.tryParse(payload['documentDate']?.toString() ?? '') ??
        _normalizeDate(DateTime.now());
    _draftSession = CreateDraftSession(
      draft: widget.draft,
      repository: widget.draftRepository,
      hasContent: _hasDraftContent,
      buildPayload: _buildDraftPayload,
      buildTitle: () => _nameController.text.trim().isEmpty
          ? 'Yeni Sayim Sonucu'
          : 'Sayim - ${_nameController.text.trim()}',
    );
    final rawLines = payload['lines'];
    _lines = rawLines is List
        ? rawLines
              .map(_inventoryDraftMap)
              .whereType<Map<String, dynamic>>()
              .map(_createLine)
              .toList(growable: true)
        : <_InventoryLineDraft>[];
    _ensureFreshEntryLine();
    _draftSession.listenTo(<TextEditingController>[_nameController]);
  }

  @override
  void dispose() {
    _draftSession.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  _InventoryLineDraft _createLine([Map<String, dynamic>? draft]) {
    return _InventoryLineDraft(
      draft: draft,
      onChanged: _draftSession.scheduleSave,
    );
  }

  bool _hasDraftContent() {
    return _nameController.text.trim().isNotEmpty ||
        !_isSameDate(_documentDate, _normalizeDate(DateTime.now())) ||
        _lines.any((line) => line.hasContent);
  }

  Map<String, dynamic> _buildDraftPayload() {
    return <String, dynamic>{
      'name': _nameController.text,
      'documentDate': _documentDate.toIso8601String(),
      'lines': _lines
          .where((line) => line.hasContent)
          .map((line) => line.toDraftJson())
          .toList(growable: false),
    };
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
    _draftSession.scheduleSave();
  }

  Future<void> _searchProduct(_InventoryLineDraft line) async {
    final query = line.barcodeController.text.trim();
    if (await _tryResolveBarcode(line, query)) {
      return;
    }

    InventoryCountProductLookupItem? product;
    if (query.length >= 2) {
      try {
        final products = await _searchProductsWithFallback(query);
        if (products.length == 1) {
          product = products.single;
        }
      } catch (_) {
        product = null;
      }
    }

    if (!mounted) {
      return;
    }

    product ??= await showModalBottomSheet<InventoryCountProductLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return _InventoryProductLookupSheet(
          onSearchProducts: _searchProductsWithFallback,
          initialQuery: line.barcodeController.text,
        );
      },
    );

    if (product == null || !mounted) {
      if (mounted) {
        _refocusLine(line.barcodeFocusNode);
      }
      return;
    }
    final pickedProduct = product;

    if (_increasePendingQuantityIfSameProduct(line, pickedProduct)) {
      _draftSession.scheduleSave();
      _refocusLine(line.barcodeFocusNode);
      return;
    }

    final entryLine = await _commitPendingEntryBeforeNextProduct(line);
    if (entryLine == null) {
      return;
    }

    setState(() {
      entryLine.applyProduct(pickedProduct);
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
    _refocusLine(entryLine.barcodeFocusNode);
  }

  Future<bool> _tryResolveBarcode(
    _InventoryLineDraft line,
    String query,
  ) async {
    if (!looksLikeDirectBarcodeInput(query)) {
      return false;
    }

    BarcodeResolutionResult resolution;
    try {
      resolution = await widget.repository.resolveBarcode(
        accessToken: widget.accessToken,
        request: BarcodeResolutionRequest(
          barcode: query,
          warehouseNo: widget.defaultWarehouseNo,
          operationType: 'count',
          screenCode: 'sayim-sonuclari',
        ),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 0) {
        return false;
      }
      if (!mounted) {
        return true;
      }
      final message = error.detail ?? error.title;
      _showFeedback(message);
      unawaited(TerminalFeedback.error());
      _refocusLine(line.barcodeFocusNode);
      return true;
    }

    if (!mounted) {
      return true;
    }

    if (!resolution.isFound || !resolution.isUsableInOperation) {
      final message = resolution.quickErrorMessage;
      setState(() {
        _validationMessage = message;
      });
      _showFeedback(message);
      unawaited(TerminalFeedback.error());
      _refocusLine(line.barcodeFocusNode);
      return true;
    }

    final product = InventoryCountProductLookupItem.fromBarcodeResolution(
      resolution,
    );
    final addedQuantity = resolution.suggestedQuantity;
    if (_increasePendingQuantityIfSameProduct(
      line,
      product,
      addedQuantity: addedQuantity,
    )) {
      _draftSession.scheduleSave();
      _refocusLine(line.barcodeFocusNode);
      return true;
    }

    final entryLine = await _commitPendingEntryBeforeNextProduct(line);
    if (entryLine == null) {
      return true;
    }

    setState(() {
      entryLine.quantityController.text = productEntryController.formatQuantity(
        addedQuantity,
      );
      entryLine.applyProduct(product);
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
    _refocusLine(entryLine.barcodeFocusNode);
    if (resolution.quickWarningMessage.isNotEmpty) {
      unawaited(TerminalFeedback.warning());
      _showFeedback(resolution.quickWarningMessage);
    } else {
      unawaited(TerminalFeedback.success());
    }
    return true;
  }

  Future<List<InventoryCountProductLookupItem>> _searchProductsWithFallback(
    String query,
  ) async {
    try {
      return await widget.repository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        query: query,
      );
    } on ApiException {
      final catalogItems = await widget.mobileProductCatalogRepository
          .searchProducts(warehouseNo: widget.defaultWarehouseNo, query: query);
      if (catalogItems.isNotEmpty) {
        return catalogItems
            .map((item) => item.toInventoryCountProductLookupItem())
            .toList(growable: false);
      }
      rethrow;
    }
  }

  Future<void> _scanProductWithCamera(_InventoryLineDraft line) async {
    if (!supportsCameraBarcodeScanning) {
      _showFeedback('Bu cihazda kamera ile barkod okutma desteklenmiyor.');
      _refocusLine(line.barcodeFocusNode);
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Sayim Barkod Kamerasi',
      subtitle: 'Barkodu okutun; bulunan urun satira eklenecek.',
    );

    if (barcode == null) {
      _refocusLine(line.barcodeFocusNode);
      return;
    }

    if (!mounted) {
      return;
    }

    line.barcodeController.text = barcode;
    await _searchProduct(line);
  }

  bool _applyProductToLine(
    _InventoryLineDraft line,
    InventoryCountProductLookupItem product,
  ) {
    final existingLine = productEntryController.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<_InventoryLineDraft>(
        currentLine: line,
        targetBarcode: product.barcode,
        targetStockCode: product.stockCode,
        lines: _lines,
        lineBarcode: (line) => line.selectedProduct?.barcode ?? '',
        lineStockCode: (line) => line.selectedProduct?.stockCode ?? '',
        canMergeLine: (line) => line.selectedProduct != null,
      ),
    );

    if (existingLine == null) {
      line.applyProduct(product);
      return false;
    }

    existingLine.quantityController.text = productEntryController
        .formatQuantity(
          productEntryController.readQuantity(
                existingLine.quantityController.text,
                fallback: 0,
              ) +
              productEntryController.quantityInputOrUnitMultiplier(
                line.quantityController.text,
                product.unitMultiplier,
              ),
        );
    _recycleMergedLine(line, createReplacement: _createLine);
    return true;
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

  void _ensureFreshEntryLine() {
    if (_lines.isEmpty || !_isBlankLine(_lines.first)) {
      _lines = <_InventoryLineDraft>[_createLine(), ..._lines];
    }
  }

  bool _increasePendingQuantityIfSameProduct(
    _InventoryLineDraft line,
    InventoryCountProductLookupItem product, {
    double? addedQuantity,
  }) {
    final selectedProduct = line.selectedProduct;
    if (selectedProduct == null || !_isSameProduct(selectedProduct, product)) {
      return false;
    }

    final increment =
        addedQuantity ??
        productEntryController.unitMultiplierQuantity(product.unitMultiplier);
    setState(() {
      line.quantityController.text = productEntryController.formatQuantity(
        productEntryController.readQuantity(
              line.quantityController.text,
              fallback: 0,
            ) +
            increment,
      );
      line.barcodeController.clear();
      _validationMessage = null;
    });
    unawaited(TerminalFeedback.success());
    return true;
  }

  Future<_InventoryLineDraft?> _commitPendingEntryBeforeNextProduct(
    _InventoryLineDraft line,
  ) async {
    if (line.selectedProduct == null) {
      return line;
    }

    await _commitEntryLine(line);
    if (!mounted || _lines.isEmpty) {
      return null;
    }

    final entryLine = _lines.first;
    if (identical(entryLine, line) && !_isBlankLine(entryLine)) {
      return null;
    }

    return entryLine;
  }

  bool _isSameProduct(
    InventoryCountProductLookupItem first,
    InventoryCountProductLookupItem second,
  ) {
    final firstStockCode = first.stockCode.trim().toUpperCase();
    final secondStockCode = second.stockCode.trim().toUpperCase();
    if (firstStockCode.isNotEmpty && firstStockCode == secondStockCode) {
      return true;
    }

    final firstBarcode = first.barcode.trim().toUpperCase();
    final secondBarcode = second.barcode.trim().toUpperCase();
    return firstBarcode.isNotEmpty && firstBarcode == secondBarcode;
  }

  Future<bool> _confirmDuplicateIncrease(
    _InventoryLineDraft line,
    InventoryCountProductLookupItem product,
  ) async {
    final existingLine = productEntryController.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<_InventoryLineDraft>(
        currentLine: line,
        targetBarcode: product.barcode,
        targetStockCode: product.stockCode,
        lines: _lines,
        lineBarcode: (line) => line.selectedProduct?.barcode ?? '',
        lineStockCode: (line) => line.selectedProduct?.stockCode ?? '',
        canMergeLine: (line) => line.selectedProduct != null,
      ),
    );
    final key = _productKey(
      stockCode: product.stockCode,
      barcode: product.barcode,
    );
    if (existingLine == null ||
        productEntryController.readQuantity(
              existingLine.quantityController.text,
              fallback: 0,
            ) <=
            0 ||
        key.isEmpty ||
        _lastAddedProductKey == key) {
      return true;
    }

    unawaited(TerminalFeedback.warning());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Urun listede var'),
          content: Text(
            '${product.stockName} daha once eklenmis. Miktar artirilsin mi?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgec'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Artir'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  void _rememberAddedProduct(InventoryCountProductLookupItem product) {
    final key = _productKey(
      stockCode: product.stockCode,
      barcode: product.barcode,
    );
    if (key.isNotEmpty) {
      _lastAddedProductKey = key;
    }
  }

  String _productKey({required String stockCode, required String barcode}) {
    final normalizedStockCode = stockCode.trim().toUpperCase();
    if (normalizedStockCode.isNotEmpty) {
      return 'S:$normalizedStockCode';
    }

    final normalizedBarcode = barcode.trim().toUpperCase();
    if (normalizedBarcode.isNotEmpty) {
      return 'B:$normalizedBarcode';
    }

    return '';
  }

  bool get _hasPendingEntryLine =>
      _lines.isNotEmpty && !_isBlankLine(_lines.first);

  Future<void> _commitEntryLine(_InventoryLineDraft line) async {
    final product = line.selectedProduct;
    if (product == null) {
      _refocusLine(line.barcodeFocusNode);
      return;
    }

    final quantity = productEntryController.readQuantity(
      line.quantityController.text,
      fallback: 0,
    );
    if (quantity <= 0) {
      setState(() {
        _validationMessage = 'Miktar sifirdan buyuk olmali.';
      });
      return;
    }

    if (!await _confirmDuplicateIncrease(line, product)) {
      return;
    }

    var mergedIntoExisting = false;
    setState(() {
      mergedIntoExisting = _applyProductToLine(line, product);
      _ensureFreshEntryLine();
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
    _focusFreshEntryLine();
    _rememberAddedProduct(product);
    unawaited(TerminalFeedback.success());
    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  void _cancelPendingEntryLine(_InventoryLineDraft line) {
    setState(() {
      line.clear();
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
    _refocusLine(line.barcodeFocusNode);
  }

  void _focusFreshEntryLine() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lines.isEmpty) {
        return;
      }

      final firstLine = _lines.first;
      if (_isBlankLine(firstLine)) {
        firstLine.barcodeFocusNode.requestFocus();
      }
    });
  }

  void _refocusLine(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focusNode.requestFocus();
      }
    });
  }

  bool _isBlankLine(_InventoryLineDraft line) {
    return line.selectedProduct == null &&
        line.stockCodeController.text.trim().isEmpty;
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
    _draftSession.scheduleSave();
  }

  Future<void> _submit() async {
    if (!validateCreateForm(_formKey)) {
      setState(() {
        _validationMessage = 'Lutfen zorunlu alanlari duzeltin.';
      });
      return;
    }

    if (_hasPendingEntryLine) {
      setState(() {
        _validationMessage = 'Secilen urunu once Kaleme Ekle ile listeye alin.';
      });
      return;
    }

    final activeLines = _committedLines();

    if (activeLines.isEmpty) {
      setState(() {
        _validationMessage = 'En az bir urun satiri ekleyin.';
      });
      return;
    }

    final requestLines = <InventoryCountCreateLine>[];
    for (var index = 0; index < activeLines.length; index += 1) {
      final line = activeLines[index];
      final stockCode = line.stockCodeController.text.trim();
      final quantity = productEntryController.readQuantity(
        line.quantityController.text,
        fallback: 0,
      );

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
          barcode:
              line.selectedProduct?.barcode ??
              line.barcodeController.text.trim(),
          unitPointer: 1,
        ),
      );
    }

    final request = InventoryCountCreateRequest(
      clientRequestId: generateClientRequestId(),
      name: _nameController.text.trim(),
      documentDate: _documentDate,
      lines: requestLines,
    );

    await _draftSession.complete();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(request);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.97,
          child: Material(
            color: theme.scaffoldBackgroundColor,
            child: Form(
              key: _formKey,
              autovalidateMode: createFormAutovalidateMode,
              child: Column(
                children: <Widget>[
                  TerminalSheetHeader(
                    title: 'Yeni Sayim Sonucu',
                    subtitle: 'Depo: ${widget.defaultWarehouseNo}',
                    badges: <Widget>[
                      TerminalLineCountBadge(
                        count: _filledLineIndexes().length,
                      ),
                    ],
                    elevated: true,
                  ),
                  TerminalCreateInputDock(
                    children: <Widget>[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Sayim Adi*',
                          hintText: 'Nisan 2026 Genel Sayim',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Zorunlu';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 8),
                      TerminalSectionToolbar(
                        title: 'Satirlar',
                        actions: const <Widget>[],
                      ),
                      const SizedBox(height: 6),
                      _buildEntryLineCard(theme),
                    ],
                  ),

                  Expanded(
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: <Widget>[
                        _buildLazyLineSliver(theme),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                if (_validationMessage != null) ...<Widget>[
                                  _ValidationBlock(
                                    message: _validationMessage!,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                TerminalFormActionRow(
                                  submitFlex: 2,
                                  cancel: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Vazgec'),
                                  ),
                                  submit: FilledButton.icon(
                                    onPressed: _submit,
                                    icon: const Icon(Icons.save_rounded),
                                    label: const Text('Sayimi Kaydet'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _buildLineCard({
    required ThemeData theme,
    required int index,
    required _InventoryLineDraft line,
  }) {
    final product = line.selectedProduct;
    final isEntrySlot = index == 0;
    final isFreshEntry = isEntrySlot && _isBlankLine(line);
    final isPendingEntry = isEntrySlot && !_isBlankLine(line);
    final displayLineNo = _lines
        .take(index + 1)
        .where((item) => _lines.indexOf(item) != 0 && !_isBlankLine(item))
        .length;

    if (isPendingEntry && product != null) {
      return ProductDraftEntryPanel(
        stockCode: product.stockCode,
        stockName: product.stockName,
        quantityController: line.quantityController,
        unitLabel: product.unitName,
        packageLabel: product.unitMultiplier > 1
            ? AppFormatters.quantity(product.unitMultiplier)
            : null,
        barcode: product.barcode,
        warningLabel: product.isGoodsAcceptanceBlocked ? 'Bayrak var' : null,
        onConfirm: () => _commitEntryLine(line),
        onCancel: () => _cancelPendingEntryLine(line),
        scanRow: TerminalResponsiveLookupRow(
          breakpoint: 340,
          field: ProductLookupField(
            controller: line.barcodeController,
            focusNode: line.barcodeFocusNode,
            labelText: 'Barkod okut / urun degistir',
            onSubmit: () => _searchProduct(line),
          ),
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () => _searchProduct(line),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Urun'),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => _scanProductWithCamera(line),
                tooltip: 'Kamera ile oku',
                icon: const Icon(Icons.photo_camera_back_rounded),
              ),
            ],
          ),
        ),
        quantityValidator: (value) {
          if (productEntryController.readQuantity(value ?? '', fallback: 0) <=
              0) {
            return 'Zorunlu';
          }

          return null;
        },
      );
    }

    if (!isFreshEntry && product != null) {
      return TerminalCompactProductLineCard(
        lineNo: displayLineNo,
        stockCode: product.stockCode,
        stockName: product.stockName,
        quantityController: line.quantityController,
        unitLabel: product.unitName,
        packageLabel: product.unitMultiplier > 1
            ? AppFormatters.quantity(product.unitMultiplier)
            : null,
        barcode: product.barcode,
        warningLabel: product.isGoodsAcceptanceBlocked ? 'Bayrak var' : null,
        canDelete: _lines.length > 1,
        onDelete: () => _removeLine(line),
        onMinimumReached: _lines.length > 1 ? () => _removeLine(line) : null,
      );
    }

    return TerminalPdaLineCard(
      title: isFreshEntry ? 'Giris satiri' : 'Satir $displayLineNo',
      subtitle:
          product?.stockName ??
          (isFreshEntry ? 'Okutmaya hazir' : 'Urun secilmedi'),
      isEntryLine: isFreshEntry,
      leading: Icon(
        isFreshEntry
            ? Icons.qr_code_scanner_rounded
            : Icons.inventory_2_rounded,
        color: theme.colorScheme.primary,
      ),
      trailing: !isFreshEntry && _lines.length > 1
          ? IconButton(
              onPressed: () => _removeLine(line),
              icon: const Icon(Icons.delete_outline, size: 22),
              tooltip: 'Satiri sil',
            )
          : null,
      child: Column(
        children: <Widget>[
          if (isFreshEntry)
            TerminalResponsiveLookupRow(
              breakpoint: 340,
              field: ProductLookupField(
                controller: line.barcodeController,
                focusNode: line.barcodeFocusNode,
                onSubmit: () => _searchProduct(line),
              ),
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: () => _searchProduct(line),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Urun'),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => _scanProductWithCamera(line),
                    tooltip: 'Kamera ile oku',
                    icon: const Icon(Icons.photo_camera_back_rounded),
                  ),
                ],
              ),
            )
          else if (product != null)
            TerminalPdaInfoGrid(
              minTileWidth: 92,
              items: <TerminalPdaInfo>[
                TerminalPdaInfo(label: 'Kod', value: product.stockCode),
                TerminalPdaInfo(label: 'Birim', value: product.unitName),
                if (product.barcode.isNotEmpty)
                  TerminalPdaInfo(label: 'Barkod', value: product.barcode),
                if (product.isGoodsAcceptanceBlocked)
                  const TerminalPdaInfo(label: 'Uyari', value: 'Bayrak var'),
              ],
            ),
          if (!isFreshEntry) ...<Widget>[
            const SizedBox(height: 10),
            TerminalQuantityStepper(
              controller: line.quantityController,
              onMinimumReached: !isFreshEntry && _lines.length > 1
                  ? () => _removeLine(line)
                  : null,
              validator: (value) {
                if (productEntryController.readQuantity(
                      value ?? '',
                      fallback: 0,
                    ) <=
                    0) {
                  return 'Zorunlu';
                }

                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Widget _buildEntryLineCard(ThemeData theme) {
    return _buildLineCard(theme: theme, index: 0, line: _lines.first);
  }

  Widget _buildLazyLineSliver(ThemeData theme) {
    final indexes = _filledLineIndexes();
    if (indexes.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, visibleIndex) {
          final index = indexes[visibleIndex];
          return _buildLineCard(
            theme: theme,
            index: index,
            line: _lines[index],
          );
        }, childCount: indexes.length),
      ),
    );
  }

  List<int> _filledLineIndexes() {
    return <int>[
      for (var index = 0; index < _lines.length; index++)
        if (index != 0 && !_isBlankLine(_lines[index])) index,
    ];
  }

  List<_InventoryLineDraft> _committedLines() {
    return <_InventoryLineDraft>[
      for (var index = 0; index < _lines.length; index++)
        if (index != 0 && !_isBlankLine(_lines[index])) _lines[index],
    ];
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
  _InventoryLineDraft({Map<String, dynamic>? draft, this.onChanged})
    : barcodeController = TextEditingController(),
      stockCodeController = TextEditingController(),
      quantityController = TextEditingController() {
    if (draft != null) {
      barcodeController.text = draft['barcode']?.toString() ?? '';
      stockCodeController.text = draft['stockCode']?.toString() ?? '';
      quantityController.text = draft['quantity']?.toString() ?? '';
      final productJson = _inventoryDraftMap(draft['selectedProduct']);
      if (productJson != null) {
        selectedProduct = InventoryCountProductLookupItem.fromJson(productJson);
        barcodeController.clear();
      }
    }
    for (final controller in _controllers) {
      controller.addListener(_notifyChanged);
    }
  }

  InventoryCountProductLookupItem? selectedProduct;
  final TextEditingController barcodeController;
  final TextEditingController stockCodeController;
  final TextEditingController quantityController;
  final FocusNode barcodeFocusNode = FocusNode();
  final VoidCallback? onChanged;

  List<TextEditingController> get _controllers => <TextEditingController>[
    barcodeController,
    stockCodeController,
    quantityController,
  ];

  bool get hasContent =>
      selectedProduct != null ||
      barcodeController.text.trim().isNotEmpty ||
      stockCodeController.text.trim().isNotEmpty ||
      quantityController.text.trim().isNotEmpty;

  void applyProduct(InventoryCountProductLookupItem product) {
    selectedProduct = product;
    barcodeController.clear();
    stockCodeController.text = product.stockCode;
    if (quantityController.text.trim().isEmpty) {
      quantityController.text = productEntryController.formatQuantity(
        productEntryController.unitMultiplierQuantity(product.unitMultiplier),
      );
    }
  }

  void clear() {
    selectedProduct = null;
    barcodeController.clear();
    stockCodeController.clear();
    quantityController.clear();
    onChanged?.call();
  }

  void dispose() {
    barcodeFocusNode.dispose();
    barcodeController.dispose();
    stockCodeController.dispose();
    quantityController.dispose();
  }

  Map<String, dynamic> toDraftJson() {
    return <String, dynamic>{
      'barcode': barcodeController.text,
      'stockCode': stockCodeController.text,
      'quantity': quantityController.text,
      'selectedProduct': selectedProduct == null
          ? null
          : _inventoryProductJson(selectedProduct!),
    };
  }

  void _notifyChanged() => onChanged?.call();
}

Map<String, dynamic>? _inventoryDraftMap(Object? value) {
  return switch (value) {
    final Map<String, dynamic> map => Map<String, dynamic>.from(map),
    final Map map => map.map((key, item) => MapEntry(key.toString(), item)),
    _ => null,
  };
}

Map<String, dynamic> _inventoryProductJson(
  InventoryCountProductLookupItem item,
) {
  return <String, dynamic>{
    'warehouseNo': item.warehouseNo,
    'barcode': item.barcode,
    'stockCode': item.stockCode,
    'stockName': item.stockName,
    'unitName': item.unitName,
    'unitMultiplier': item.unitMultiplier,
    'price': item.price,
    'isGoodsAcceptanceBlocked': item.isGoodsAcceptanceBlocked,
  };
}

class _InventoryProductLookupSheet extends StatefulWidget {
  const _InventoryProductLookupSheet({
    required this.onSearchProducts,
    required this.initialQuery,
  });

  final Future<List<InventoryCountProductLookupItem>> Function(String query)
  onSearchProducts;
  final String initialQuery;

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
    _queryController = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
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
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 2,
            ),
            tileColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withAlpha(40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Text(
              item.displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                'Barkod ${item.barcode.isEmpty ? '-' : item.barcode}',
                'Birim ${item.unitName}',
              ].join(' | '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                            child: TerminalLookupSearchField(
                              controller: queryController,
                              onSearch: onSearch,
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
