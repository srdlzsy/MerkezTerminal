import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/config/app_config.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/green_grocer/product_cases/data/green_grocer_product_cases_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/models/suggested_warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_session.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_controller.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/utils/terminal_feedback.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class GivenWarehouseOrderCreateSheet extends StatefulWidget {
  const GivenWarehouseOrderCreateSheet({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.mobileWarehouseCatalogRepository,
    this.greenGrocerProductCasesRepository,
    this.greenGrocerProductCasesEnabled =
        AppConfig.greenGrocerProductCasesEnabled,
    this.draft,
    this.draftRepository,
  });

  final WarehouseOrdersRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;
  final MobileWarehouseCatalogLocalRepository mobileWarehouseCatalogRepository;
  final GreenGrocerProductCasesRepository? greenGrocerProductCasesRepository;
  final bool greenGrocerProductCasesEnabled;
  final CreateDraft? draft;
  final CreateDraftRepository? draftRepository;

  @override
  State<GivenWarehouseOrderCreateSheet> createState() =>
      _GivenWarehouseOrderCreateSheetState();
}

class _GivenWarehouseOrderCreateSheetState
    extends State<GivenWarehouseOrderCreateSheet>
    with CreateFormValidation {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _outWarehouseNoController;
  late DateTime _orderDate;
  late DateTime _deliveryDate;
  late List<_CreateLineDraft> _lines;
  WarehouseLookupItem? _selectedWarehouse;
  String? _validationMessage;
  bool _isPreparingSubmit = false;
  bool _isGreenGrocerPreviewEnabled = true;
  bool _isLoadingSourceProducts = false;
  final ScrollController _scrollController = ScrollController();
  late final CreateDraftSession _draftSession;
  String? _lastAddedProductKey;

  bool get _hasWarehouseSelection {
    return _selectedWarehouse != null ||
        (int.tryParse(_outWarehouseNoController.text.trim()) ?? 0) > 0;
  }

  int? get _selectedSourceWarehouseNo =>
      int.tryParse(_outWarehouseNoController.text.trim());

  int? get _targetWarehouseNo => int.tryParse(widget.defaultWarehouseNo.trim());

  String get _productLookupWarehouseNo {
    final selectedSourceWarehouseNo = _selectedSourceWarehouseNo;
    if (selectedSourceWarehouseNo != null && selectedSourceWarehouseNo > 0) {
      return selectedSourceWarehouseNo.toString();
    }

    return widget.defaultWarehouseNo;
  }

  SourceWarehouseProductsRepository? get _sourceProductsRepository {
    final repository = widget.repository;
    return repository is SourceWarehouseProductsRepository
        ? repository as SourceWarehouseProductsRepository
        : null;
  }

  bool get _canLoadSourceWarehouseProducts {
    final sourceWarehouseNo = _selectedSourceWarehouseNo;
    return sourceWarehouseNo != null &&
        usesSuggestedWarehouseOrderSourceProducts(sourceWarehouseNo) &&
        _sourceProductsRepository != null;
  }

  bool get _isGreenGrocerOrderFlow {
    return _selectedSourceWarehouseNo == 56 &&
        widget.greenGrocerProductCasesEnabled &&
        widget.greenGrocerProductCasesRepository != null &&
        _isGreenGrocerPreviewEnabled;
  }

  @override
  void initState() {
    super.initState();
    final payload = widget.draft?.payload ?? const <String, dynamic>{};
    _outWarehouseNoController = TextEditingController(
      text: payload['outWarehouseNo']?.toString() ?? '',
    );
    _orderDate =
        DateTime.tryParse(payload['orderDate']?.toString() ?? '') ??
        _normalizeDate(DateTime.now());
    _deliveryDate =
        DateTime.tryParse(payload['deliveryDate']?.toString() ?? '') ??
        _normalizeDate(DateTime.now());
    final warehouseJson = _warehouseOrderDraftMap(payload['selectedWarehouse']);
    if (warehouseJson != null) {
      _selectedWarehouse = WarehouseLookupItem.fromJson(warehouseJson);
    }
    _draftSession = CreateDraftSession(
      draft: widget.draft,
      repository: widget.draftRepository,
      hasContent: _hasDraftContent,
      buildPayload: _buildDraftPayload,
      buildTitle: () => _selectedWarehouse == null
          ? 'Yeni Verilen Depo Siparisi'
          : 'Depo Siparisi - ${_selectedWarehouse!.warehouseName}',
    );
    final rawLines = payload['lines'];
    _lines = rawLines is List
        ? rawLines
              .map(_warehouseOrderDraftMap)
              .whereType<Map<String, dynamic>>()
              .map(_createLine)
              .toList(growable: true)
        : <_CreateLineDraft>[];
    _ensureFreshEntryLine();
    _draftSession.listenTo(<TextEditingController>[_outWarehouseNoController]);
  }

  @override
  void dispose() {
    _draftSession.dispose();
    _outWarehouseNoController.dispose();
    _scrollController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  _CreateLineDraft _createLine([Map<String, dynamic>? draft]) {
    return _CreateLineDraft(
      draft: draft,
      onChanged: _draftSession.scheduleSave,
    );
  }

  bool _hasDraftContent() {
    return _selectedWarehouse != null ||
        _outWarehouseNoController.text.trim().isNotEmpty ||
        _lines.any((line) => line.hasContent);
  }

  Map<String, dynamic> _buildDraftPayload() {
    return <String, dynamic>{
      'outWarehouseNo': _outWarehouseNoController.text,
      'orderDate': _orderDate.toIso8601String(),
      'deliveryDate': _deliveryDate.toIso8601String(),
      'selectedWarehouse': _selectedWarehouse == null
          ? null
          : _warehouseLookupJson(_selectedWarehouse!),
      'lines': _lines
          .where((line) => line.hasContent)
          .map((line) => line.toDraftJson())
          .toList(growable: false),
    };
  }

  Future<void> _searchWarehouse() async {
    final previousWarehouseNo = _selectedSourceWarehouseNo;
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

    final shouldClearLines =
        previousWarehouseNo != null &&
        previousWarehouseNo > 0 &&
        previousWarehouseNo != warehouse.warehouseNo &&
        _lines.any((line) => line.hasContent);
    if (shouldClearLines) {
      final confirmed = await _confirmWarehouseChangeClearsLines(warehouse);
      if (!confirmed || !mounted) {
        return;
      }
    }

    setState(() {
      if (shouldClearLines) {
        _replaceLinesWithFreshEntry();
        _lastAddedProductKey = null;
        _isGreenGrocerPreviewEnabled = true;
      }
      _selectedWarehouse = warehouse;
      _outWarehouseNoController.text = warehouse.warehouseNo.toString();
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
    _focusFreshEntryLine();
  }

  Future<bool> _confirmWarehouseChangeClearsLines(
    WarehouseLookupItem warehouse,
  ) async {
    unawaited(TerminalFeedback.warning());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Depo degissin mi?'),
          content: Text(
            'Mevcut kalemler temizlenecek. Yeni depo: ${warehouse.displayLabel}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgec'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Depoyu Degistir'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  void _replaceLinesWithFreshEntry() {
    for (final line in _lines) {
      line.dispose();
    }
    _lines = <_CreateLineDraft>[_createLine()];
  }

  Future<void> _loadSourceWarehouseProducts() async {
    if (_isLoadingSourceProducts) {
      return;
    }

    if (!_hasWarehouseSelection) {
      _showFeedback('Once karsi depo secin, sonra depo urunlerini getirin.');
      return;
    }

    if (_hasPendingEntryLine) {
      _showFeedback(
        'Once giris satirindaki urunu Kaleme Ekle ile listeye alin.',
      );
      _focusFreshEntryLine();
      return;
    }

    final sourceWarehouseNo = _selectedSourceWarehouseNo;
    final repository = _sourceProductsRepository;
    if (sourceWarehouseNo == null || repository == null) {
      return;
    }

    setState(() {
      _isLoadingSourceProducts = true;
      _validationMessage = null;
    });

    try {
      final products = await repository.fetchSourceWarehouseProducts(
        accessToken: widget.accessToken,
        sourceWarehouseNo: sourceWarehouseNo,
      );
      if (!mounted) {
        return;
      }

      if (products.isEmpty) {
        setState(() => _isLoadingSourceProducts = false);
        _showFeedback('Bu depo icin urun bulunamadi.');
        return;
      }

      final existingKeys = <String>{
        for (final line in _lines)
          if (line.selectedProduct != null)
            _productKey(
              stockCode: line.selectedProduct!.stockCode,
              barcode: line.selectedProduct!.barcode,
            ),
      }..remove('');

      final addedLines = <_CreateLineDraft>[];
      var skippedCount = 0;
      for (final product in products) {
        final key = _productKey(
          stockCode: product.stockCode,
          barcode: product.barcode,
        );
        if (key.isEmpty || existingKeys.contains(key)) {
          skippedCount += 1;
          continue;
        }

        final line = _createLine();
        line.applyProduct(product);
        line.quantityController.clear();
        addedLines.add(line);
        existingKeys.add(key);
      }

      setState(() {
        _lines = <_CreateLineDraft>[
          _lines.first,
          ...addedLines,
          ..._lines.skip(1),
        ];
        _isLoadingSourceProducts = false;
      });
      _draftSession.scheduleSave();
      _focusFreshEntryLine();

      if (addedLines.isEmpty) {
        _showFeedback('Depodaki urunlerin tamami zaten listede.');
      } else {
        final skippedLabel = skippedCount > 0
            ? ' $skippedCount urun zaten vardi.'
            : '';
        _showFeedback(
          '${addedLines.length} urun listeye eklendi.$skippedLabel',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingSourceProducts = false;
        _validationMessage = error.toString();
      });
    }
  }

  Future<void> _searchProduct(_CreateLineDraft line) async {
    if (!_hasWarehouseSelection) {
      _showFeedback('Once karsi depo secin, sonra kalem okutun.');
      _refocusLine(line.barcodeFocusNode);
      return;
    }

    ProductLookupItem? product;
    final query = line.barcodeController.text.trim();
    final productWarehouseNo = _productLookupWarehouseNo;
    if (query.length >= 2) {
      try {
        final products = await widget.repository.searchProducts(
          accessToken: widget.accessToken,
          warehouseNo: productWarehouseNo,
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
        warehouseNo: productWarehouseNo,
        initialQuery: line.barcodeController.text,
      ),
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

    final outWarehouseNo = _selectedSourceWarehouseNo;
    if (outWarehouseNo != null && outWarehouseNo > 0) {
      unawaited(
        _resolveGreenGrocerLineResolution(
          entryLine,
          outWarehouseNo: outWarehouseNo,
          showWarnings: false,
        ),
      );
    }
  }

  Future<void> _scanProductWithCamera(_CreateLineDraft line) async {
    if (!_hasWarehouseSelection) {
      _showFeedback('Once karsi depo secin, sonra kamera ile okutun.');
      _refocusLine(line.barcodeFocusNode);
      return;
    }

    if (!supportsCameraBarcodeScanning) {
      _showFeedback('Bu cihazda kamera ile barkod okutma desteklenmiyor.');
      _refocusLine(line.barcodeFocusNode);
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Depo Siparisi Kamerasi',
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

  void _ensureFreshEntryLine() {
    if (_lines.isEmpty || !_isBlankLine(_lines.first)) {
      _lines = <_CreateLineDraft>[_createLine(), ..._lines];
    }
  }

  bool _increasePendingQuantityIfSameProduct(
    _CreateLineDraft line,
    ProductLookupItem product,
  ) {
    final selectedProduct = line.selectedProduct;
    if (selectedProduct == null || !_isSameProduct(selectedProduct, product)) {
      return false;
    }

    final addedQuantity = productEntryController.unitMultiplierQuantity(
      product.unitMultiplier,
    );
    setState(() {
      line.quantityController.text = productEntryController.formatQuantity(
        productEntryController.readQuantity(
              line.quantityController.text,
              fallback: 0,
            ) +
            addedQuantity,
      );
      line.barcodeController.clear();
      _validationMessage = null;
    });
    unawaited(TerminalFeedback.success());
    return true;
  }

  Future<_CreateLineDraft?> _commitPendingEntryBeforeNextProduct(
    _CreateLineDraft line,
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
    return productEntryController.isSameProduct(
      firstStockCode: first.stockCode,
      firstBarcode: first.barcode,
      secondStockCode: second.stockCode,
      secondBarcode: second.barcode,
    );
  }

  Future<bool> _confirmDuplicateIncrease(
    _CreateLineDraft line,
    ProductLookupItem product,
  ) async {
    final existingLine = productEntryController.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<_CreateLineDraft>(
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
        !productEntryController.shouldConfirmDuplicateIncrease(
          existingQuantityText: existingLine.quantityController.text,
          productKey: key,
          lastAddedProductKey: _lastAddedProductKey,
        )) {
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
    return productEntryController.productKey(
      stockCode: stockCode,
      barcode: barcode,
    );
  }

  bool get _hasPendingEntryLine =>
      _lines.isNotEmpty && !_isBlankLine(_lines.first);

  Future<void> _commitEntryLine(_CreateLineDraft line) async {
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
    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  void _cancelPendingEntryLine(_CreateLineDraft line) {
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

  bool _isBlankLine(_CreateLineDraft line) {
    return line.selectedProduct == null &&
        line.stockCodeController.text.trim().isEmpty;
  }

  bool _isEmptyQuantityLine(_CreateLineDraft line) {
    if (_isBlankLine(line)) {
      return false;
    }

    return productEntryController.readQuantity(
          line.quantityController.text,
          fallback: 0,
        ) <=
        0;
  }

  int get _emptyQuantityLineCount {
    return _lines.skip(1).where(_isEmptyQuantityLine).length;
  }

  bool _applyProductToLine(_CreateLineDraft line, ProductLookupItem product) {
    final existingLine = productEntryController.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<_CreateLineDraft>(
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
        .mergedQuantityText(
          existingQuantityText: existingLine.quantityController.text,
          incomingQuantityText: line.quantityController.text,
          unitMultiplier: product.unitMultiplier,
        );
    _recycleMergedLine(line, createReplacement: _createLine);
    return true;
  }

  void _recycleMergedLine(
    _CreateLineDraft line, {
    required _CreateLineDraft Function() createReplacement,
  }) {
    final lineIndex = _lines.indexOf(line);
    line.dispose();

    if (lineIndex == 0) {
      _lines[lineIndex] = createReplacement();
      return;
    }

    _lines = _lines.where((item) => item != line).toList(growable: false);
  }

  void _removeLine(_CreateLineDraft line) {
    if (_lines.length == 1) {
      return;
    }

    setState(() {
      _lines = _lines.where((item) => item != line).toList(growable: false);
      line.dispose();
    });
    _draftSession.scheduleSave();
  }

  void _removeEmptyQuantityLines() {
    final removableLines = _lines.skip(1).where(_isEmptyQuantityLine).toSet();
    if (removableLines.isEmpty) {
      _showFeedback('Kaldirilacak bos miktarli satir yok.');
      _focusFreshEntryLine();
      return;
    }

    setState(() {
      _lines = <_CreateLineDraft>[
        _lines.first,
        for (final line in _lines.skip(1))
          if (!removableLines.contains(line)) line,
      ];
      _validationMessage = null;
    });

    for (final line in removableLines) {
      line.dispose();
    }
    _draftSession.scheduleSave();
    _focusFreshEntryLine();
    _showFeedback('${removableLines.length} bos miktarli satir kaldirildi.');
  }

  Future<void> _submit() async {
    if (_isPreparingSubmit) {
      return;
    }

    if (!validateCreateForm(_formKey)) {
      setState(() => _validationMessage = 'Lutfen zorunlu alanlari duzeltin.');
      return;
    }

    final outWarehouseNo = int.tryParse(_outWarehouseNoController.text.trim());

    if (outWarehouseNo == null || outWarehouseNo <= 0) {
      setState(
        () => _validationMessage = 'Gecerli bir karsi depo numarasi girin.',
      );
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
      setState(() => _validationMessage = 'En az bir urun satiri ekleyin.');
      return;
    }

    for (var index = 0; index < activeLines.length; index += 1) {
      final line = activeLines[index];
      if (line.stockCodeController.text.trim().isEmpty) {
        setState(
          () => _validationMessage = '${index + 1}. satir icin urun secin.',
        );
        return;
      }

      final quantity = productEntryController.readQuantity(
        line.quantityController.text,
        fallback: 0,
      );
      if (quantity <= 0) {
        setState(
          () => _validationMessage =
              '${index + 1}. satir icin miktar sifirdan buyuk olmali.',
        );
        return;
      }
    }

    setState(() {
      _isPreparingSubmit = true;
      _validationMessage = _isGreenGrocerOrderFlow
          ? 'Manav kasa miktarlari cozumleniyor.'
          : null;
    });

    final resolved = await _resolveGreenGrocerLinesBeforeSubmit(
      activeLines,
      outWarehouseNo: outWarehouseNo,
    );
    if (!resolved || !mounted) {
      if (mounted) {
        setState(() => _isPreparingSubmit = false);
      }
      return;
    }

    final request = WarehouseOrderCreateRequest(
      outWarehouseNo: outWarehouseNo,
      orderDate: _orderDate,
      deliveryDate: _deliveryDate,
      description: '',
      lines: activeLines
          .map(
            (line) => WarehouseOrderCreateLine(
              stockCode: line.stockCodeController.text.trim(),
              quantity: _requestQuantityForLine(line),
              recommendedQuantity: 0,
              unitPrice: 0,
              unitPointer: 1,
              description: '',
              packageCode: '',
              projectCode: '',
              responsibilityCenter: '',
              greenGrocerCase: _greenGrocerCaseForLine(line),
            ),
          )
          .toList(growable: false),
    );

    await _draftSession.complete();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(request);
  }

  Future<bool> _resolveGreenGrocerLinesBeforeSubmit(
    List<_CreateLineDraft> activeLines, {
    required int outWarehouseNo,
  }) async {
    if (!_isGreenGrocerOrderFlow) {
      return true;
    }

    for (var index = 0; index < activeLines.length; index += 1) {
      final line = activeLines[index];
      if (!_shouldResolveGreenGrocerLine(line)) {
        continue;
      }

      final resolved = await _resolveGreenGrocerLineResolution(
        line,
        outWarehouseNo: outWarehouseNo,
        showWarnings: false,
      );
      if (!mounted) {
        return false;
      }

      if (!resolved) {
        setState(() {
          _validationMessage =
              '${index + 1}. satir: ${line.productCaseStatusMessage ?? 'Manav kasa cozumleme tamamlanamadi.'}';
        });
        return false;
      }
    }

    if (mounted &&
        _validationMessage == 'Manav kasa miktarlari cozumleniyor.') {
      setState(() => _validationMessage = null);
    }

    return true;
  }

  Future<bool> _resolveGreenGrocerLineResolution(
    _CreateLineDraft line, {
    required int outWarehouseNo,
    bool showWarnings = true,
  }) async {
    if (!_shouldResolveGreenGrocerLine(line)) {
      return true;
    }

    final repository = widget.greenGrocerProductCasesRepository;
    final sourceWarehouseNo = outWarehouseNo;
    final targetWarehouseNo = _targetWarehouseNo;
    if (repository == null || sourceWarehouseNo <= 0) {
      return true;
    }

    final inputQuantity = productEntryController.readQuantity(
      line.quantityController.text,
      fallback: 0,
    );
    if (inputQuantity <= 0) {
      setState(() {
        line.setProductCaseStatus(
          'Manav kasa miktari sifirdan buyuk olmali.',
          isError: true,
        );
      });
      _showFeedback('Manav kasa miktari sifirdan buyuk olmali.');
      unawaited(TerminalFeedback.error());
      return false;
    }

    setState(() {
      line.setProductCaseStatus('Manav kasa cozumleniyor.', isLoading: true);
    });

    try {
      final result = await repository.resolvePreview(
        accessToken: widget.accessToken,
        request: GreenGrocerProductCaseResolutionRequest(
          stockCode: line.stockCodeController.text.trim(),
          inputQuantity: inputQuantity,
          sourceWarehouseNo: sourceWarehouseNo,
          targetWarehouseNo: targetWarehouseNo,
          orderDate: _orderDate,
        ),
      );
      if (!mounted) {
        return false;
      }

      if (!result.isUsable) {
        final message = result.primaryError;
        setState(() {
          line.setProductCaseStatus(message, isError: true);
        });
        _showFeedback(message);
        unawaited(TerminalFeedback.error());
        return false;
      }

      final warning = result.primaryWarning;
      final message = _greenGrocerResolutionLabel(result);
      setState(() {
        line.setProductCaseResolution(
          result,
          message: warning.isEmpty ? message : '$message | $warning',
          isWarning: warning.isNotEmpty,
        );
        _validationMessage = null;
      });

      if (warning.isNotEmpty) {
        unawaited(TerminalFeedback.warning());
        if (showWarnings) {
          _showFeedback(warning);
        }
      }

      return true;
    } on ApiException catch (error) {
      if (!mounted) {
        return false;
      }

      if (error.statusCode == 409) {
        setState(() {
          _isGreenGrocerPreviewEnabled = false;
          line.clearProductCaseStatus();
        });
        _showFeedback(
          'Manav kasa cozumleme kapali; eski miktar akisi kullaniliyor.',
        );
        return true;
      }

      final message = error.detail ?? error.title;
      setState(() {
        line.setProductCaseStatus(message, isError: true);
      });
      _showFeedback(message);
      unawaited(TerminalFeedback.error());
      return false;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      final message = error.toString();
      setState(() {
        line.setProductCaseStatus(message, isError: true);
      });
      _showFeedback(message);
      unawaited(TerminalFeedback.error());
      return false;
    }
  }

  bool _shouldResolveGreenGrocerLine(_CreateLineDraft line) {
    if (!_isGreenGrocerOrderFlow) {
      return false;
    }

    if (line.stockCodeController.text.trim().isEmpty) {
      return false;
    }

    final modelCode = line.selectedProduct?.modelCode.trim() ?? '';
    if (modelCode.isEmpty) {
      return true;
    }

    return const <String>{'10', '11', '12', '23'}.contains(modelCode);
  }

  double _requestQuantityForLine(_CreateLineDraft line) {
    final resolution = line.productCaseResolution;
    if (resolution != null &&
        resolution.isUsable &&
        _isProductCaseResolutionCurrent(line, resolution)) {
      return resolution.estimatedQuantity;
    }

    return productEntryController.readQuantity(
      line.quantityController.text,
      fallback: 0,
    );
  }

  WarehouseOrderLineGreenGrocerCase? _greenGrocerCaseForLine(
    _CreateLineDraft line,
  ) {
    final resolution = line.productCaseResolution;
    if (resolution == null ||
        !resolution.isUsable ||
        !_isProductCaseResolutionCurrent(line, resolution)) {
      return null;
    }

    return WarehouseOrderLineGreenGrocerCase(
      inputQuantity: resolution.inputQuantity,
      inputMode: resolution.inputMode,
      conversionMode: resolution.conversionMode,
      estimatedQuantity: resolution.estimatedQuantity,
      microUnit: resolution.displayMicroUnit,
      averageKgPerCase: resolution.averageKgPerCase > 0
          ? resolution.averageKgPerCase
          : null,
      unitsPerCase: resolution.unitsPerCase > 0
          ? resolution.unitsPerCase
          : null,
      averageSource: resolution.averageSource,
      averageRecordCount: resolution.averageRecordCount > 0
          ? resolution.averageRecordCount
          : null,
      averageCaseCount: resolution.averageCaseCount > 0
          ? resolution.averageCaseCount
          : null,
      coefficientOfVariation: resolution.coefficientOfVariation > 0
          ? resolution.coefficientOfVariation
          : null,
      confidence: resolution.confidence,
    );
  }

  bool _isProductCaseResolutionCurrent(
    _CreateLineDraft line,
    GreenGrocerProductCaseResolutionResult resolution,
  ) {
    if (line.stockCodeController.text.trim() != resolution.stockCode.trim()) {
      return false;
    }

    final inputQuantity = productEntryController.readQuantity(
      line.quantityController.text,
      fallback: -1,
    );
    return (inputQuantity - resolution.inputQuantity).abs() < 0.000001;
  }

  String _greenGrocerResolutionLabel(
    GreenGrocerProductCaseResolutionResult result,
  ) {
    return '${AppFormatters.quantity(result.inputQuantity)} '
        '${result.displayInputMode} ~= '
        '${AppFormatters.quantity(result.estimatedQuantity)} '
        '${result.displayMicroUnit}';
  }

  String _greenGrocerUnitLabel(
    _CreateLineDraft line,
    ProductLookupItem product,
  ) {
    if (!_shouldResolveGreenGrocerLine(line)) {
      return product.unitName;
    }

    final resolution = line.productCaseResolution;
    if (resolution != null &&
        _isProductCaseResolutionCurrent(line, resolution)) {
      return resolution.displayInputMode;
    }

    return 'kasa/koli';
  }

  String? _productPackageLabel(ProductLookupItem product) {
    if (product.unitMultiplier <= 1) {
      return null;
    }

    final quantity = AppFormatters.quantity(product.unitMultiplier);
    final secondaryUnitName = product.secondaryUnitName.trim();
    if (secondaryUnitName.isEmpty) {
      return quantity;
    }

    return '$quantity $secondaryUnitName';
  }

  String? _greenGrocerMetaLabel(_CreateLineDraft line) {
    if (!_shouldResolveGreenGrocerLine(line)) {
      return null;
    }

    if (line.isProductCaseStatusLoading) {
      return line.productCaseStatusMessage;
    }

    final resolution = line.productCaseResolution;
    if (resolution != null &&
        _isProductCaseResolutionCurrent(line, resolution)) {
      return _greenGrocerResolutionLabel(resolution);
    }

    return 'Kasa/koli girisi';
  }

  String? _greenGrocerWarningLabel(
    _CreateLineDraft line,
    ProductLookupItem product,
  ) {
    final labels = <String>[
      if (product.isOrderBlocked) 'Blokeli',
      if (line.productCaseStatusMessage != null &&
          (line.isProductCaseStatusError || line.isProductCaseStatusWarning))
        line.productCaseStatusMessage!,
    ];

    if (labels.isEmpty) {
      return null;
    }

    return labels.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.zero,
        child: FractionallySizedBox(
          heightFactor: 0.97,
          child: Material(
            color: theme.scaffoldBackgroundColor,
            child: Form(
              key: _formKey,
              autovalidateMode: createFormAutovalidateMode,
              child: Column(
                children: [
                  TerminalSheetHeader(
                    title: 'Yeni Verilen Depo Siparisi',
                    badges: <Widget>[
                      TerminalLineCountBadge(
                        count: _filledLineIndexes().length,
                      ),
                    ],
                    elevated: true,
                  ),

                  TerminalCreateInputDock(
                    children: <Widget>[
                      _buildWarehouseSection(theme),
                      const SizedBox(height: 5),
                      TerminalSectionToolbar(
                        title: 'Satirlar',
                        breakpoint: 430,
                        actions: <Widget>[
                          if (_canLoadSourceWarehouseProducts)
                            FilledButton.tonalIcon(
                              onPressed:
                                  _isLoadingSourceProducts ||
                                      !_hasWarehouseSelection
                                  ? null
                                  : _loadSourceWarehouseProducts,
                              icon: _isLoadingSourceProducts
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.playlist_add_rounded,
                                      size: 18,
                                    ),
                              label: Text(
                                _isLoadingSourceProducts
                                    ? 'Yukleniyor'
                                    : 'Depo urunleri',
                              ),
                            ),
                          if (_emptyQuantityLineCount > 0)
                            FilledButton.tonalIcon(
                              onPressed: _removeEmptyQuantityLines,
                              icon: const Icon(
                                Icons.cleaning_services_rounded,
                                size: 18,
                              ),
                              label: const Text('Boslari sil'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
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
                                if (_validationMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: theme.colorScheme.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _validationMessage!,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onErrorContainer,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Vazgec'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: FilledButton.icon(
                                        onPressed: _isPreparingSubmit
                                            ? null
                                            : _submit,
                                        icon: _isPreparingSubmit
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(Icons.save_rounded),
                                        label: Text(
                                          _isPreparingSubmit
                                              ? 'Hazirlaniyor'
                                              : 'Siparisi Olustur',
                                        ),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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

  Widget _buildWarehouseSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final warehouseField = TextFormField(
                  controller: _outWarehouseNoController,
                  readOnly: true,
                  onTap: _searchWarehouse,
                  decoration: const InputDecoration(
                    labelText: 'Karsi Depo No*',
                    hintText: 'Depo secin',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Zorunlu';
                    }
                    return null;
                  },
                );
                final warehouseButton = FilledButton.tonalIcon(
                  onPressed: _searchWarehouse,
                  icon: const Icon(Icons.warehouse, size: 18),
                  label: const Text('Sec'),
                );

                if (constraints.maxWidth < 280) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      warehouseField,
                      const SizedBox(height: 5),
                      warehouseButton,
                    ],
                  );
                }

                return Row(
                  children: <Widget>[
                    Expanded(child: warehouseField),
                    const SizedBox(width: 8),
                    warehouseButton,
                  ],
                );
              },
            ),
          ),
          if (_selectedWarehouse != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(50),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedWarehouse!.displayLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntryLineCard(ThemeData theme) {
    return _buildLineCard(index: 0, line: _lines.first, theme: theme);
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
            index: index,
            line: _lines[index],
            theme: theme,
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

  List<_CreateLineDraft> _committedLines() {
    return <_CreateLineDraft>[
      for (var index = 0; index < _lines.length; index++)
        if (index != 0 && !_isBlankLine(_lines[index])) _lines[index],
    ];
  }

  Widget _buildLineCard({
    required int index,
    required _CreateLineDraft line,
    required ThemeData theme,
  }) {
    final product = line.selectedProduct;
    final canScan = _hasWarehouseSelection;
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
        unitLabel: _greenGrocerUnitLabel(line, product),
        packageLabel: _productPackageLabel(product),
        barcode: product.barcode,
        priceLabel: _greenGrocerMetaLabel(line),
        warningLabel: _greenGrocerWarningLabel(line, product),
        onConfirm: () => _commitEntryLine(line),
        onCancel: () => _cancelPendingEntryLine(line),
        scanRow: canScan
            ? TerminalResponsiveLookupRow(
                field: ProductLookupField(
                  controller: line.barcodeController,
                  focusNode: line.barcodeFocusNode,
                  enabled: canScan,
                  labelText: 'Barkod okut / urun degistir',
                  onSubmit: () => _searchProduct(line),
                ),
                action: FilledButton.icon(
                  onPressed: canScan ? () => _searchProduct(line) : null,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Urun'),
                ),
                trailingAction: IconButton.filledTonal(
                  onPressed: canScan
                      ? () => _scanProductWithCamera(line)
                      : null,
                  tooltip: 'Kamera ile oku',
                  icon: const Icon(Icons.photo_camera_back_rounded),
                ),
              )
            : null,
        quantityValidator: (value) {
          final parsed = double.tryParse(
            (value ?? '').trim().replaceAll(',', '.'),
          );
          if (parsed == null || parsed <= 0) {
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
        unitLabel: _greenGrocerUnitLabel(line, product),
        packageLabel: _productPackageLabel(product),
        barcode: product.barcode,
        priceLabel: _greenGrocerMetaLabel(line),
        warningLabel: _greenGrocerWarningLabel(line, product),
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
        children: [
          if (isFreshEntry && !canScan)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6EFE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Bu satirda isleme baslamak icin once karsi depo secin.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5B4738),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (isFreshEntry)
            TerminalResponsiveLookupRow(
              field: ProductLookupField(
                controller: line.barcodeController,
                focusNode: line.barcodeFocusNode,
                enabled: canScan,
                onSubmit: () => _searchProduct(line),
              ),
              action: FilledButton.icon(
                onPressed: canScan ? () => _searchProduct(line) : null,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Urun'),
              ),
              trailingAction: IconButton.filledTonal(
                onPressed: canScan ? () => _scanProductWithCamera(line) : null,
                tooltip: 'Kamera ile oku',
                icon: const Icon(Icons.photo_camera_back_rounded),
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
                if (product.isOrderBlocked)
                  const TerminalPdaInfo(label: 'Durum', value: 'Blokeli'),
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
                final parsed = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                if (parsed == null || parsed <= 0) {
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

// ==================== LOOKUP SHEETS (Optimize edildi) ====================

class _WarehouseLookupSheet extends StatefulWidget {
  const _WarehouseLookupSheet({
    required this.repository,
    required this.accessToken,
    required this.mobileWarehouseCatalogRepository,
  });
  final WarehouseOrdersRepository repository;
  final String accessToken;
  final MobileWarehouseCatalogLocalRepository mobileWarehouseCatalogRepository;

  @override
  State<_WarehouseLookupSheet> createState() => _WarehouseLookupSheetState();
}

class _WarehouseLookupSheetState extends State<_WarehouseLookupSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  List<WarehouseLookupItem> _items = [];

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
    return _buildLookupSheet(
      title: 'Depo Ara',
      subtitle: 'Depo no veya ad ile arayin',
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
              '${item.district} ${item.province}'.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.of(context).pop(item),
          );
        },
      ),
    );
  }

  Widget _buildLookupSheet({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: Material(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        children: [
                          Expanded(
                            child: TerminalLookupSearchField(
                              controller: _queryController,
                              onSearch: _load,
                              decoration: const InputDecoration(
                                hintText: 'Ara...',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _isLoading ? null : _load,
                            child: const Text('Ara'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : _items.isEmpty
                      ? const Center(child: Text('Sonuc bulunamadi'))
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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

class _ProductLookupSheet extends StatefulWidget {
  const _ProductLookupSheet({
    required this.repository,
    required this.accessToken,
    required this.warehouseNo,
    required this.initialQuery,
  });

  final WarehouseOrdersRepository repository;
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
  List<ProductLookupItem> _items = [];

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
    if (_queryController.text.trim().length < 2) {
      setState(() {
        _errorMessage = 'En az 2 karakter girin';
        _items = [];
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
        query: _queryController.text,
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: Material(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Urun Ara',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Depo: ${widget.warehouseNo}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TerminalLookupSearchField(
                              controller: _queryController,
                              onSearch: _load,
                              decoration: const InputDecoration(
                                hintText: 'Stok adi, kodu veya barkod',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _isLoading ? null : _load,
                            child: const Text('Ara'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : _items.isEmpty
                      ? const Center(child: Text('Sonuc bulunamadi'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              tileColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withAlpha(40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              title: Text(
                                item.displayLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Birim: ${item.unitName} | Fiyat: ${AppFormatters.currency(item.price)}',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== DATA MODEL ====================

class _CreateLineDraft {
  _CreateLineDraft({Map<String, dynamic>? draft, this.onChanged})
    : stockCodeController = TextEditingController(),
      barcodeController = TextEditingController(),
      quantityController = TextEditingController() {
    if (draft != null) {
      stockCodeController.text = draft['stockCode']?.toString() ?? '';
      barcodeController.text = draft['barcode']?.toString() ?? '';
      quantityController.text = draft['quantity']?.toString() ?? '';
      final productJson = _warehouseOrderDraftMap(draft['selectedProduct']);
      if (productJson != null) {
        selectedProduct = ProductLookupItem.fromJson(productJson);
        barcodeController.clear();
      }
    }
    for (final controller in _controllers) {
      controller.addListener(_notifyChanged);
    }
  }

  final TextEditingController stockCodeController;
  final TextEditingController barcodeController;
  final TextEditingController quantityController;
  final FocusNode barcodeFocusNode = FocusNode();
  final VoidCallback? onChanged;
  ProductLookupItem? selectedProduct;
  GreenGrocerProductCaseResolutionResult? productCaseResolution;
  String? productCaseStatusMessage;
  bool isProductCaseStatusLoading = false;
  bool isProductCaseStatusError = false;
  bool isProductCaseStatusWarning = false;

  List<TextEditingController> get _controllers => <TextEditingController>[
    stockCodeController,
    barcodeController,
    quantityController,
  ];

  bool get hasContent =>
      selectedProduct != null ||
      stockCodeController.text.trim().isNotEmpty ||
      barcodeController.text.trim().isNotEmpty ||
      quantityController.text.trim().isNotEmpty;

  void applyProduct(ProductLookupItem product) {
    selectedProduct = product;
    stockCodeController.text = product.stockCode;
    barcodeController.clear();
    clearProductCaseStatus(notify: false);
    if (quantityController.text.trim().isEmpty) {
      quantityController.text = productEntryController.formatQuantity(
        productEntryController.unitMultiplierQuantity(product.unitMultiplier),
      );
    }
  }

  void setProductCaseResolution(
    GreenGrocerProductCaseResolutionResult result, {
    required String message,
    bool isWarning = false,
  }) {
    productCaseResolution = result;
    productCaseStatusMessage = message;
    isProductCaseStatusLoading = false;
    isProductCaseStatusError = false;
    isProductCaseStatusWarning = isWarning;
    onChanged?.call();
  }

  void setProductCaseStatus(
    String message, {
    bool isLoading = false,
    bool isError = false,
    bool isWarning = false,
  }) {
    productCaseStatusMessage = message;
    isProductCaseStatusLoading = isLoading;
    isProductCaseStatusError = isError;
    isProductCaseStatusWarning = isWarning;
    if (isError) {
      productCaseResolution = null;
    }
    onChanged?.call();
  }

  void clearProductCaseStatus({bool notify = true}) {
    productCaseResolution = null;
    productCaseStatusMessage = null;
    isProductCaseStatusLoading = false;
    isProductCaseStatusError = false;
    isProductCaseStatusWarning = false;
    if (notify) {
      onChanged?.call();
    }
  }

  void clear() {
    selectedProduct = null;
    stockCodeController.clear();
    barcodeController.clear();
    quantityController.clear();
    clearProductCaseStatus(notify: false);
    onChanged?.call();
  }

  void dispose() {
    barcodeFocusNode.dispose();
    stockCodeController.dispose();
    barcodeController.dispose();
    quantityController.dispose();
  }

  Map<String, dynamic> toDraftJson() {
    return <String, dynamic>{
      'stockCode': stockCodeController.text,
      'barcode': barcodeController.text,
      'quantity': quantityController.text,
      'selectedProduct': selectedProduct == null
          ? null
          : _warehouseOrderProductJson(selectedProduct!),
    };
  }

  void _notifyChanged() => onChanged?.call();
}

Map<String, dynamic>? _warehouseOrderDraftMap(Object? value) {
  return switch (value) {
    final Map<String, dynamic> map => Map<String, dynamic>.from(map),
    final Map map => map.map((key, item) => MapEntry(key.toString(), item)),
    _ => null,
  };
}

Map<String, dynamic> _warehouseLookupJson(WarehouseLookupItem item) {
  return <String, dynamic>{
    'warehouseNo': item.warehouseNo,
    'warehouseName': item.warehouseName,
    'address': item.address,
    'district': item.district,
    'province': item.province,
  };
}

Map<String, dynamic> _warehouseOrderProductJson(ProductLookupItem item) {
  return <String, dynamic>{
    'warehouseNo': item.warehouseNo,
    'barcode': item.barcode,
    'stockCode': item.stockCode,
    'stockName': item.stockName,
    'price': item.price,
    'unitName': item.unitName,
    'unitMultiplier': item.unitMultiplier,
    'secondaryUnitName': item.secondaryUnitName,
    'caseBarcode': item.caseBarcode,
    'modelCode': item.modelCode,
    'isOrderBlocked': item.isOrderBlocked,
  };
}
