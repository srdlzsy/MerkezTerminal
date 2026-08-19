import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/warehouse_returns_repository.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_session.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_controller.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/utils/client_request_id.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/utils/terminal_feedback.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class WarehouseReturnCreateSheet extends StatefulWidget {
  const WarehouseReturnCreateSheet({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.mobileWarehouseCatalogRepository,
    this.draft,
    this.draftRepository,
  });

  final WarehouseReturnsRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;
  final MobileWarehouseCatalogLocalRepository mobileWarehouseCatalogRepository;
  final CreateDraft? draft;
  final CreateDraftRepository? draftRepository;

  @override
  State<WarehouseReturnCreateSheet> createState() =>
      _WarehouseReturnCreateSheetState();
}

class _WarehouseReturnCreateSheetState extends State<WarehouseReturnCreateSheet>
    with CreateFormValidation {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _targetWarehouseController;
  late final TextEditingController _transitWarehouseController;
  late final TextEditingController _descriptionController;
  late DateTime _movementDate;
  late DateTime _documentDate;
  late List<_ReturnLineDraft> _lines;
  WarehouseLookupItem? _selectedWarehouse;
  String? _validationMessage;
  late final CreateDraftSession _draftSession;
  String? _lastAddedProductKey;

  bool get _hasTargetWarehouse =>
      _selectedWarehouse != null ||
      (int.tryParse(_targetWarehouseController.text.trim()) ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    final payload = widget.draft?.payload ?? const <String, dynamic>{};
    _targetWarehouseController = TextEditingController(
      text: payload['targetWarehouseNo']?.toString() ?? '',
    );
    _transitWarehouseController = TextEditingController(
      text: payload['transitWarehouseNo']?.toString() ?? '60',
    );
    _descriptionController = TextEditingController(
      text: payload['description']?.toString() ?? '',
    );
    _movementDate =
        DateTime.tryParse(payload['movementDate']?.toString() ?? '') ??
        _normalizeDate(DateTime.now());
    _documentDate =
        DateTime.tryParse(payload['documentDate']?.toString() ?? '') ??
        _normalizeDate(DateTime.now());
    final warehouseJson = _returnDraftMap(payload['selectedWarehouse']);
    if (warehouseJson != null) {
      _selectedWarehouse = WarehouseLookupItem.fromJson(warehouseJson);
    }
    _draftSession = CreateDraftSession(
      draft: widget.draft,
      repository: widget.draftRepository,
      hasContent: _hasDraftContent,
      buildPayload: _buildDraftPayload,
      buildTitle: () => _selectedWarehouse == null
          ? 'Yeni Giden Depo Iadesi'
          : 'Depo Iadesi - ${_selectedWarehouse!.warehouseName}',
    );
    final rawLines = payload['lines'];
    _lines = rawLines is List
        ? rawLines
              .map(_returnDraftMap)
              .whereType<Map<String, dynamic>>()
              .map(_createLine)
              .toList(growable: true)
        : <_ReturnLineDraft>[];
    _ensureFreshEntryLine();
    _draftSession.listenTo(<TextEditingController>[
      _targetWarehouseController,
      _transitWarehouseController,
      _descriptionController,
    ]);
  }

  @override
  void dispose() {
    _draftSession.dispose();
    _scrollController.dispose();
    _targetWarehouseController.dispose();
    _transitWarehouseController.dispose();
    _descriptionController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  _ReturnLineDraft _createLine([Map<String, dynamic>? draft]) {
    return _ReturnLineDraft(
      draft: draft,
      onChanged: _draftSession.scheduleSave,
    );
  }

  bool _hasDraftContent() {
    return _selectedWarehouse != null ||
        _targetWarehouseController.text.trim().isNotEmpty ||
        _transitWarehouseController.text.trim() != '60' ||
        _descriptionController.text.trim().isNotEmpty ||
        _lines.any((line) => line.hasContent);
  }

  Map<String, dynamic> _buildDraftPayload() {
    return <String, dynamic>{
      'targetWarehouseNo': _targetWarehouseController.text,
      'transitWarehouseNo': _transitWarehouseController.text,
      'description': _descriptionController.text,
      'movementDate': _movementDate.toIso8601String(),
      'documentDate': _documentDate.toIso8601String(),
      'selectedWarehouse': _selectedWarehouse == null
          ? null
          : _returnWarehouseJson(_selectedWarehouse!),
      'lines': _lines
          .where((line) => line.hasContent)
          .map((line) => line.toDraftJson())
          .toList(growable: false),
    };
  }

  Future<void> _searchWarehouse() async {
    final warehouse = await showModalBottomSheet<WarehouseLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _WarehouseLookupSheet(
        repository: widget.repository,
        accessToken: widget.accessToken,
        mobileWarehouseCatalogRepository:
            widget.mobileWarehouseCatalogRepository,
      ),
    );

    if (warehouse == null || !mounted) {
      return;
    }

    setState(() {
      _selectedWarehouse = warehouse;
      _targetWarehouseController.text = warehouse.warehouseNo.toString();
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
    _focusFreshEntryLine();
  }

  Future<void> _searchProduct(_ReturnLineDraft line) async {
    if (!_hasTargetWarehouse) {
      _showFeedback('Once hedef depoyu secin.');
      _refocusLine(line.lookupFocusNode);
      return;
    }

    final query = line.lookupController.text.trim();
    if (await _tryResolveBarcode(line, query)) {
      return;
    }

    ProductLookupItem? product;
    if (query.length >= 2) {
      try {
        final products = await widget.repository.searchProducts(
          accessToken: widget.accessToken,
          warehouseNo: widget.defaultWarehouseNo,
          query: query,
        );
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

    product ??= await showModalBottomSheet<ProductLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _ProductLookupSheet(
        repository: widget.repository,
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        initialQuery: line.lookupController.text,
      ),
    );

    if (product == null || !mounted) {
      if (mounted) {
        _refocusLine(line.lookupFocusNode);
      }
      return;
    }
    final pickedProduct = product;

    if (_increasePendingQuantityIfSameProduct(line, pickedProduct)) {
      _draftSession.scheduleSave();
      _refocusLine(line.lookupFocusNode);
      return;
    }

    final entryLine = await _commitPendingEntryBeforeNextProduct(line);
    if (entryLine == null) {
      return;
    }

    setState(() {
      entryLine.applyProduct(pickedProduct);
      entryLine.lookupController.clear();
      entryLine.setLookupStatus(
        'Secildi: ${pickedProduct.stockCode} | ${pickedProduct.stockName}',
      );
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
    _refocusLine(entryLine.lookupFocusNode);
  }

  Future<bool> _tryResolveBarcode(_ReturnLineDraft line, String query) async {
    if (!looksLikeDirectBarcodeInput(query)) {
      return false;
    }

    setState(() {
      line.setLookupStatus('Barkod cozumleniyor: $query', isLoading: true);
    });

    BarcodeResolutionResult resolution;
    try {
      resolution = await widget.repository.resolveBarcode(
        accessToken: widget.accessToken,
        request: BarcodeResolutionRequest(
          barcode: query,
          warehouseNo: widget.defaultWarehouseNo,
          operationType: 'return',
          targetWarehouseNo: _targetWarehouseController.text,
          isRefund: true,
          screenCode: 'giden-depo-iadeleri',
        ),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 0 || error.statusCode == 404) {
        if (mounted) {
          setState(line.clearLookupStatus);
        }
        return false;
      }

      if (!mounted) {
        return true;
      }
      final message = error.detail ?? error.title;
      setState(() {
        line.setLookupStatus(message, isError: true);
      });
      _showFeedback(message);
      unawaited(TerminalFeedback.error());
      _refocusLine(line.lookupFocusNode);
      return true;
    }

    if (!mounted) {
      return true;
    }

    if (!resolution.isFound || !resolution.isUsableInOperation) {
      final message = resolution.quickErrorMessage;
      setState(() {
        line.setLookupStatus(message, isError: true);
      });
      _showFeedback(message);
      unawaited(TerminalFeedback.error());
      _refocusLine(line.lookupFocusNode);
      return true;
    }

    final product = ProductLookupItem.fromBarcodeResolution(resolution);
    final addedQuantity = resolution.suggestedQuantity;
    if (_increasePendingQuantityIfSameProduct(
      line,
      product,
      addedQuantity: addedQuantity,
    )) {
      _draftSession.scheduleSave();
      _refocusLine(line.lookupFocusNode);
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
      entryLine.lookupController.clear();
      entryLine.setLookupStatus(_resolvedBarcodeMessage(resolution));
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
    _refocusLine(entryLine.lookupFocusNode);
    if (resolution.quickWarningMessage.isNotEmpty) {
      _rememberAddedProduct(product);
      unawaited(TerminalFeedback.warning());
      _showFeedback(resolution.quickWarningMessage);
    } else {
      unawaited(TerminalFeedback.success());
    }
    return true;
  }

  Future<void> _scanProduct(_ReturnLineDraft line) async {
    if (!_hasTargetWarehouse) {
      _showFeedback('Once hedef depoyu secin.');
      _refocusLine(line.lookupFocusNode);
      return;
    }

    if (!supportsCameraBarcodeScanning) {
      _showFeedback('Bu cihazda kamera ile barkod okutma desteklenmiyor.');
      _refocusLine(line.lookupFocusNode);
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Depo Iadesi Kamerasi',
      subtitle: 'Barkodu okutun; urun ham arama ile secilecek.',
    );

    if (barcode == null) {
      _refocusLine(line.lookupFocusNode);
      return;
    }

    if (!mounted) {
      return;
    }

    line.lookupController.text = barcode;
    await _searchProduct(line);
  }

  void _ensureFreshEntryLine() {
    if (_lines.isEmpty || !_isBlankLine(_lines.first)) {
      _lines = <_ReturnLineDraft>[_createLine(), ..._lines];
    }
  }

  void _focusFreshEntryLine() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lines.isEmpty) {
        return;
      }

      final firstLine = _lines.first;
      if (_isBlankLine(firstLine)) {
        firstLine.lookupFocusNode.requestFocus();
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

  void _notifySuccessfulProductAdd({
    required ProductLookupItem product,
    required bool mergedIntoExisting,
  }) {
    _rememberAddedProduct(product);
    unawaited(TerminalFeedback.success());
  }

  Future<bool> _confirmDuplicateIncrease(
    _ReturnLineDraft line,
    ProductLookupItem product,
  ) async {
    final existingLine = _findMergeTarget(line, product);
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

  void _rememberAddedProduct(ProductLookupItem product) {
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

  String _resolvedBarcodeMessage(BarcodeResolutionResult resolution) {
    if (resolution.isVariableWeightBarcode) {
      return 'Terazi ${AppFormatters.quantity(resolution.suggestedQuantity)} ${resolution.embeddedQuantityUnit}';
    }
    if (resolution.isCaseBarcode) {
      return 'Koli ici ${AppFormatters.quantity(resolution.suggestedQuantity)}';
    }
    return 'Miktar ${AppFormatters.quantity(resolution.suggestedQuantity)}';
  }

  bool _isBlankLine(_ReturnLineDraft line) {
    return line.selectedProduct == null &&
        line.stockCodeController.text.trim().isEmpty;
  }

  bool _increasePendingQuantityIfSameProduct(
    _ReturnLineDraft line,
    ProductLookupItem product, {
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
        line.quantity + increment,
      );
      line.lookupController.clear();
      line.setLookupStatus(
        'Ayni barkod okutuldu. +${AppFormatters.quantity(increment)} eklendi.',
      );
      _validationMessage = null;
    });
    unawaited(TerminalFeedback.success());
    return true;
  }

  Future<_ReturnLineDraft?> _commitPendingEntryBeforeNextProduct(
    _ReturnLineDraft line,
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

  bool _isSameProduct(ProductLookupItem first, ProductLookupItem second) {
    final firstStockCode = first.stockCode.trim().toUpperCase();
    final secondStockCode = second.stockCode.trim().toUpperCase();
    if (firstStockCode.isNotEmpty && firstStockCode == secondStockCode) {
      return true;
    }

    final firstBarcode = first.barcode.trim().toUpperCase();
    final secondBarcode = second.barcode.trim().toUpperCase();
    return firstBarcode.isNotEmpty && firstBarcode == secondBarcode;
  }

  bool get _hasPendingEntryLine =>
      _lines.isNotEmpty && !_isBlankLine(_lines.first);

  Future<void> _commitEntryLine(_ReturnLineDraft line) async {
    final product = line.selectedProduct;
    if (product == null) {
      _refocusLine(line.lookupFocusNode);
      return;
    }

    if (line.quantity <= 0) {
      setState(() {
        line.setLookupStatus('Miktar sifirdan buyuk olmali.', isError: true);
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
    _notifySuccessfulProductAdd(
      product: product,
      mergedIntoExisting: mergedIntoExisting,
    );
  }

  void _cancelPendingEntryLine(_ReturnLineDraft line) {
    setState(() {
      line.clear();
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
    _refocusLine(line.lookupFocusNode);
  }

  List<_ReturnLineDraft> _committedLines() {
    return <_ReturnLineDraft>[
      for (var index = 0; index < _lines.length; index++)
        if (index != 0 && !_isBlankLine(_lines[index])) _lines[index],
    ];
  }

  bool _applyProductToLine(_ReturnLineDraft line, ProductLookupItem product) {
    final existingLine = _findMergeTarget(line, product);

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

  _ReturnLineDraft? _findMergeTarget(
    _ReturnLineDraft line,
    ProductLookupItem product,
  ) {
    return productEntryController.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<_ReturnLineDraft>(
        currentLine: line,
        targetBarcode: product.barcode,
        targetStockCode: product.stockCode,
        lines: _lines,
        lineBarcode: (line) => line.selectedProduct?.barcode ?? '',
        lineStockCode: (line) => line.selectedProduct?.stockCode ?? '',
        canMergeLine: (line) => line.selectedProduct != null,
      ),
    );
  }

  void _recycleMergedLine(
    _ReturnLineDraft line, {
    required _ReturnLineDraft Function() createReplacement,
  }) {
    final lineIndex = _lines.indexOf(line);
    line.dispose();

    if (lineIndex == 0) {
      _lines[lineIndex] = createReplacement();
      return;
    }

    _lines = _lines.where((item) => item != line).toList(growable: false);
  }

  void _removeLine(_ReturnLineDraft line) {
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
        _validationMessage = 'Lutfen zorunlu alanlari kontrol edin.';
      });
      return;
    }

    final targetWarehouseNo = int.tryParse(
      _targetWarehouseController.text.trim(),
    );
    final transitWarehouseNo = int.tryParse(
      _transitWarehouseController.text.trim(),
    );

    if (targetWarehouseNo == null || targetWarehouseNo <= 0) {
      setState(() {
        _validationMessage = 'Gecerli bir hedef depo secin.';
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

    final requestLines = <WarehouseReturnCreateLine>[];
    for (var index = 0; index < activeLines.length; index += 1) {
      final line = activeLines[index];
      final stockCode = line.stockCodeController.text.trim();
      if (stockCode.isEmpty) {
        setState(() {
          _validationMessage = '${index + 1}. satir icin urun secin.';
        });
        return;
      }

      if (line.quantity <= 0) {
        setState(() {
          _validationMessage =
              '${index + 1}. satir icin miktar sifirdan buyuk olmali.';
        });
        return;
      }

      requestLines.add(
        WarehouseReturnCreateLine(
          stockCode: stockCode,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          unitPointer: line.unitPointer,
          description: line.descriptionController.text.trim(),
          partyCode: line.partyCodeController.text.trim(),
          lotNo: line.lotNo,
          projectCode: line.projectCodeController.text.trim(),
        ),
      );
    }

    final request = WarehouseReturnCreateRequest(
      clientRequestId: generateClientRequestId(),
      targetWarehouseNo: targetWarehouseNo,
      transitWarehouseNo: transitWarehouseNo,
      movementDate: _movementDate,
      documentDate: _documentDate,
      documentNo: '',
      description: _descriptionController.text.trim(),
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
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final theme = Theme.of(context);

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
                    title: 'Yeni Giden Depo Iadesi',
                    subtitle: 'Kaynak depo: ${widget.defaultWarehouseNo}',
                    badges: <Widget>[
                      TerminalLineCountBadge(
                        count: _filledLineIndexes().length,
                      ),
                    ],
                    elevated: true,
                  ),
                  TerminalCreateInputDock(
                    children: <Widget>[
                      _buildHeaderSection(theme),
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
                                  cancel: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Vazgec'),
                                  ),
                                  submit: FilledButton.icon(
                                    onPressed: _submit,
                                    icon: const Icon(Icons.save_rounded),
                                    label: const Text('Iadeyi Kaydet'),
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

  Widget _buildHeaderSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _targetWarehouseController,
                  readOnly: true,
                  onTap: _searchWarehouse,
                  decoration: const InputDecoration(
                    labelText: 'Hedef Depo*',
                    hintText: 'Depo secin',
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Zorunlu';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: _searchWarehouse,
                child: const Text('Sec'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
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

  Widget _buildLineCard({
    required ThemeData theme,
    required int index,
    required _ReturnLineDraft line,
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
        priceLabel: product.price > 0
            ? AppFormatters.currency(product.price)
            : null,
        onConfirm: () => _commitEntryLine(line),
        onCancel: () => _cancelPendingEntryLine(line),
        scanRow: TerminalResponsiveLookupRow(
          field: ProductLookupField(
            controller: line.lookupController,
            focusNode: line.lookupFocusNode,
            enabled: _hasTargetWarehouse && !line.isLookupStatusLoading,
            labelText: 'Barkod okut / urun degistir',
            onSubmit: () => _searchProduct(line),
          ),
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _hasTargetWarehouse && !line.isLookupStatusLoading
                    ? () => _searchProduct(line)
                    : null,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Urun'),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _hasTargetWarehouse && !line.isLookupStatusLoading
                    ? () => _scanProduct(line)
                    : null,
                tooltip: 'Kamera ile oku',
                icon: const Icon(Icons.photo_camera_back_rounded),
              ),
            ],
          ),
        ),
        quantityValidator: (_) {
          if (line.quantity <= 0) {
            return 'Miktar > 0';
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
        canDelete: _lines.length > 1,
        onDelete: () => _removeLine(line),
        onMinimumReached: _lines.length > 1 ? () => _removeLine(line) : null,
      );
    }

    return TerminalPdaLineCard(
      title: isFreshEntry ? 'Giris satiri' : 'Satir $displayLineNo',
      subtitle: product?.stockName,
      isEntryLine: isFreshEntry,
      trailing: !isFreshEntry && _lines.length > 1
          ? IconButton(
              onPressed: () => _removeLine(line),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Satiri sil',
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (isFreshEntry)
            TerminalResponsiveLookupRow(
              field: ProductLookupField(
                controller: line.lookupController,
                focusNode: line.lookupFocusNode,
                enabled: _hasTargetWarehouse && !line.isLookupStatusLoading,
                onSubmit: () => _searchProduct(line),
              ),
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed:
                        _hasTargetWarehouse && !line.isLookupStatusLoading
                        ? () => _searchProduct(line)
                        : null,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Urun'),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed:
                        _hasTargetWarehouse && !line.isLookupStatusLoading
                        ? () => _scanProduct(line)
                        : null,
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
              ],
            ),
          if (line.lookupStatusMessage != null) ...<Widget>[
            const SizedBox(height: 8),
            if (line.isLookupStatusLoading)
              TerminalMessageBlock.loading(message: line.lookupStatusMessage!)
            else if (line.isLookupStatusError)
              TerminalMessageBlock.error(message: line.lookupStatusMessage!)
            else
              TerminalMessageBlock.info(message: line.lookupStatusMessage!),
          ],
          if (!isFreshEntry) ...<Widget>[
            const SizedBox(height: 10),
            TerminalQuantityStepper(
              controller: line.quantityController,
              onMinimumReached: !isFreshEntry && _lines.length > 1
                  ? () => _removeLine(line)
                  : null,
              validator: (_) {
                if (line.quantity <= 0) {
                  return 'Miktar > 0';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  static DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

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

class _ReturnLineDraft {
  _ReturnLineDraft({Map<String, dynamic>? draft, this.onChanged})
    : lookupController = TextEditingController(),
      stockCodeController = TextEditingController(),
      quantityController = TextEditingController(),
      unitPriceController = TextEditingController(text: '0'),
      unitPointerController = TextEditingController(text: '1'),
      descriptionController = TextEditingController(),
      partyCodeController = TextEditingController(),
      lotNoController = TextEditingController(text: '0'),
      projectCodeController = TextEditingController() {
    if (draft != null) {
      lookupController.text = draft['lookup']?.toString() ?? '';
      stockCodeController.text = draft['stockCode']?.toString() ?? '';
      quantityController.text = draft['quantity']?.toString() ?? '';
      unitPriceController.text = draft['unitPrice']?.toString() ?? '0';
      unitPointerController.text = draft['unitPointer']?.toString() ?? '1';
      descriptionController.text = draft['description']?.toString() ?? '';
      partyCodeController.text = draft['partyCode']?.toString() ?? '';
      lotNoController.text = draft['lotNo']?.toString() ?? '0';
      projectCodeController.text = draft['projectCode']?.toString() ?? '';
      final productJson = _returnDraftMap(draft['selectedProduct']);
      if (productJson != null) {
        selectedProduct = ProductLookupItem.fromJson(productJson);
        lookupController.clear();
      }
    }
    for (final controller in _controllers) {
      controller.addListener(_notifyChanged);
    }
  }

  final TextEditingController lookupController;
  final TextEditingController stockCodeController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final TextEditingController unitPointerController;
  final TextEditingController descriptionController;
  final TextEditingController partyCodeController;
  final TextEditingController lotNoController;
  final TextEditingController projectCodeController;
  final FocusNode lookupFocusNode = FocusNode();
  final VoidCallback? onChanged;
  ProductLookupItem? selectedProduct;
  String? lookupStatusMessage;
  bool isLookupStatusLoading = false;
  bool isLookupStatusError = false;

  List<TextEditingController> get _controllers => <TextEditingController>[
    lookupController,
    stockCodeController,
    quantityController,
    unitPriceController,
    unitPointerController,
    descriptionController,
    partyCodeController,
    lotNoController,
    projectCodeController,
  ];

  bool get hasContent =>
      selectedProduct != null ||
      lookupController.text.trim().isNotEmpty ||
      stockCodeController.text.trim().isNotEmpty ||
      quantityController.text.trim().isNotEmpty ||
      unitPriceController.text.trim() != '0' ||
      unitPointerController.text.trim() != '1' ||
      descriptionController.text.trim().isNotEmpty ||
      partyCodeController.text.trim().isNotEmpty ||
      (lotNoController.text.trim().isNotEmpty &&
          lotNoController.text.trim() != '0') ||
      projectCodeController.text.trim().isNotEmpty;

  double get quantity =>
      productEntryController.readQuantity(quantityController.text, fallback: 0);
  double get unitPrice => productEntryController.readQuantity(
    unitPriceController.text,
    fallback: 0,
  );
  int get unitPointer => int.tryParse(unitPointerController.text.trim()) ?? 1;
  int get lotNo => int.tryParse(lotNoController.text.trim()) ?? 0;

  void applyProduct(ProductLookupItem product) {
    selectedProduct = product;
    lookupController.clear();
    stockCodeController.text = product.stockCode;
    if (quantityController.text.trim().isEmpty) {
      quantityController.text = productEntryController.formatQuantity(
        productEntryController.unitMultiplierQuantity(product.unitMultiplier),
      );
    }
    if (unitPrice == 0 && product.price > 0) {
      unitPriceController.text = _formatDouble(product.price);
    }
  }

  void clear() {
    lookupFocusNode.unfocus();
    lookupController.clear();
    stockCodeController.clear();
    quantityController.clear();
    unitPriceController.text = '0';
    unitPointerController.text = '1';
    descriptionController.clear();
    partyCodeController.clear();
    lotNoController.text = '0';
    projectCodeController.clear();
    selectedProduct = null;
    lookupStatusMessage = null;
    isLookupStatusLoading = false;
    isLookupStatusError = false;
  }

  void setLookupStatus(
    String message, {
    bool isLoading = false,
    bool isError = false,
  }) {
    lookupStatusMessage = message;
    isLookupStatusLoading = isLoading;
    isLookupStatusError = isError;
  }

  void clearLookupStatus() {
    lookupStatusMessage = null;
    isLookupStatusLoading = false;
    isLookupStatusError = false;
  }

  void dispose() {
    lookupFocusNode.dispose();
    lookupController.dispose();
    stockCodeController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    unitPointerController.dispose();
    descriptionController.dispose();
    partyCodeController.dispose();
    lotNoController.dispose();
    projectCodeController.dispose();
  }

  String _formatDouble(double value) {
    final raw = value.toStringAsFixed(2);
    if (raw.endsWith('.00')) {
      return raw.substring(0, raw.length - 3);
    }
    return raw.replaceAll('.', ',');
  }

  Map<String, dynamic> toDraftJson() {
    return <String, dynamic>{
      'lookup': lookupController.text,
      'stockCode': stockCodeController.text,
      'quantity': quantityController.text,
      'unitPrice': unitPriceController.text,
      'unitPointer': unitPointerController.text,
      'description': descriptionController.text,
      'partyCode': partyCodeController.text,
      'lotNo': lotNoController.text,
      'projectCode': projectCodeController.text,
      'selectedProduct': selectedProduct == null
          ? null
          : _returnProductJson(selectedProduct!),
    };
  }

  void _notifyChanged() => onChanged?.call();
}

Map<String, dynamic>? _returnDraftMap(Object? value) {
  return switch (value) {
    final Map<String, dynamic> map => Map<String, dynamic>.from(map),
    final Map map => map.map((key, item) => MapEntry(key.toString(), item)),
    _ => null,
  };
}

Map<String, dynamic> _returnWarehouseJson(WarehouseLookupItem item) {
  return <String, dynamic>{
    'warehouseNo': item.warehouseNo,
    'warehouseName': item.warehouseName,
    'address': item.address,
    'district': item.district,
    'province': item.province,
  };
}

Map<String, dynamic> _returnProductJson(ProductLookupItem item) {
  return <String, dynamic>{
    'warehouseNo': item.warehouseNo,
    'barcode': item.barcode,
    'stockCode': item.stockCode,
    'stockName': item.stockName,
    'price': item.price,
    'unitName': item.unitName,
    'unitMultiplier': item.unitMultiplier,
    'isOrderBlocked': item.isOrderBlocked,
  };
}

class _WarehouseLookupSheet extends StatefulWidget {
  const _WarehouseLookupSheet({
    required this.repository,
    required this.accessToken,
    required this.mobileWarehouseCatalogRepository,
  });

  final WarehouseReturnsRepository repository;
  final String accessToken;
  final MobileWarehouseCatalogLocalRepository mobileWarehouseCatalogRepository;

  @override
  State<_WarehouseLookupSheet> createState() => _WarehouseLookupSheetState();
}

class _WarehouseLookupSheetState extends State<_WarehouseLookupSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  List<WarehouseLookupItem> _items = const <WarehouseLookupItem>[];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.repository.searchWarehouses(
        accessToken: widget.accessToken,
        query: _queryController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      final catalogItems = await widget.mobileWarehouseCatalogRepository
          .searchWarehouses(query: _queryController.text);
      if (!mounted) {
        return;
      }
      if (catalogItems.isNotEmpty) {
        setState(() {
          _items = catalogItems
              .map((item) => item.toWarehouseLookupItem())
              .toList(growable: false);
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _errorMessage = error.toString();
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
      title: 'Depo Ara',
      subtitle: 'Depo no veya ad ile arama yapin.',
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
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${item.district} ${item.province}'.trim()),
            onTap: () => Navigator.of(context).pop(item),
          );
        },
      ),
    );
  }
}

class _ProductLookupSheet extends StatefulWidget {
  const _ProductLookupSheet({
    required this.repository,
    required this.accessToken,
    required this.warehouseNo,
    required this.initialQuery,
  });

  final WarehouseReturnsRepository repository;
  final String accessToken;
  final String warehouseNo;
  final String initialQuery;

  @override
  State<_ProductLookupSheet> createState() => _ProductLookupSheetState();
}

class _ProductLookupSheetState extends State<_ProductLookupSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  List<ProductLookupItem> _items = const <ProductLookupItem>[];

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
        _items = const <ProductLookupItem>[];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.repository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.warehouseNo,
        query: query,
      );
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
      subtitle: 'Ham arama depo ${widget.warehouseNo} uzerinden yapilir.',
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
              'Birim ${item.unitName} | Fiyat ${AppFormatters.currency(item.price)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: item.isOrderBlocked
                ? const Icon(Icons.warning_amber_rounded)
                : null,
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
  final Future<void> Function() onSearch;
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
      width: double.infinity,
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
