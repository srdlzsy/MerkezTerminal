import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/company_orders_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_session.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_controller.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/utils/terminal_feedback.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class GivenCompanyOrderCreateSheet extends StatefulWidget {
  const GivenCompanyOrderCreateSheet({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.mobileCustomerCatalogRepository,
    this.draft,
    this.draftRepository,
  });

  final CompanyOrdersRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;
  final MobileCustomerCatalogLocalRepository mobileCustomerCatalogRepository;
  final CreateDraft? draft;
  final CreateDraftRepository? draftRepository;

  @override
  State<GivenCompanyOrderCreateSheet> createState() =>
      _GivenCompanyOrderCreateSheetState();
}

class _GivenCompanyOrderCreateSheetState
    extends State<GivenCompanyOrderCreateSheet>
    with CreateFormValidation {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _customerCodeController;
  late final TextEditingController _delivererController;
  late final TextEditingController _receiverController;
  late final TextEditingController _description1Controller;
  late final TextEditingController _description2Controller;
  late DateTime _orderDate;
  late DateTime _deliveryDate;
  late List<_CompanyOrderLineDraft> _lines;
  CustomerLookupItem? _selectedCustomer;
  String? _validationMessage;
  late final CreateDraftSession _draftSession;
  String? _lastAddedProductKey;

  @override
  void initState() {
    super.initState();
    final payload = widget.draft?.payload ?? const <String, dynamic>{};
    _customerCodeController = TextEditingController(
      text: payload['customerCode']?.toString() ?? '',
    );
    _delivererController = TextEditingController(
      text: payload['deliverer']?.toString() ?? '',
    );
    _receiverController = TextEditingController(
      text: payload['receiver']?.toString() ?? '',
    );
    _description1Controller = TextEditingController(
      text: payload['description1']?.toString() ?? '',
    );
    _description2Controller = TextEditingController(
      text: payload['description2']?.toString() ?? '',
    );
    _orderDate =
        DateTime.tryParse(payload['orderDate']?.toString() ?? '') ??
        _normalizeDate(DateTime.now());
    _deliveryDate =
        DateTime.tryParse(payload['deliveryDate']?.toString() ?? '') ??
        _normalizeDate(DateTime.now());
    final customerJson = _draftMap(payload['selectedCustomer']);
    if (customerJson != null) {
      _selectedCustomer = CustomerLookupItem.fromJson(customerJson);
    }
    _draftSession = CreateDraftSession(
      draft: widget.draft,
      repository: widget.draftRepository,
      hasContent: _hasDraftContent,
      buildPayload: _buildDraftPayload,
      buildTitle: () => _selectedCustomer == null
          ? 'Yeni Verilen Firma Siparisi'
          : 'Firma Siparisi - ${_selectedCustomer!.customerDisplayName}',
    );
    final rawLines = payload['lines'];
    _lines = rawLines is List
        ? rawLines
              .map(_draftMap)
              .whereType<Map<String, dynamic>>()
              .map(_createLine)
              .toList(growable: true)
        : <_CompanyOrderLineDraft>[];
    _ensureFreshEntryLine();
    _draftSession.listenTo(<TextEditingController>[
      _customerCodeController,
      _delivererController,
      _receiverController,
      _description1Controller,
      _description2Controller,
    ]);
  }

  @override
  void dispose() {
    _draftSession.dispose();
    _scrollController.dispose();
    _customerCodeController.dispose();
    _delivererController.dispose();
    _receiverController.dispose();
    _description1Controller.dispose();
    _description2Controller.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  _CompanyOrderLineDraft _createLine([Map<String, dynamic>? draft]) {
    return _CompanyOrderLineDraft(
      draft: draft,
      onChanged: _draftSession.scheduleSave,
    );
  }

  bool _hasDraftContent() {
    return _selectedCustomer != null ||
        _customerCodeController.text.trim().isNotEmpty ||
        _delivererController.text.trim().isNotEmpty ||
        _receiverController.text.trim().isNotEmpty ||
        _description1Controller.text.trim().isNotEmpty ||
        _description2Controller.text.trim().isNotEmpty ||
        _lines.any((line) => line.hasContent);
  }

  Map<String, dynamic> _buildDraftPayload() {
    return <String, dynamic>{
      'customerCode': _customerCodeController.text,
      'deliverer': _delivererController.text,
      'receiver': _receiverController.text,
      'description1': _description1Controller.text,
      'description2': _description2Controller.text,
      'orderDate': _orderDate.toIso8601String(),
      'deliveryDate': _deliveryDate.toIso8601String(),
      'selectedCustomer': _selectedCustomer == null
          ? null
          : _companyOrderCustomerJson(_selectedCustomer!),
      'lines': _lines
          .where((line) => line.hasContent)
          .map((line) => line.toDraftJson())
          .toList(growable: false),
    };
  }

  Future<void> _searchCustomer() async {
    final customer = await showModalBottomSheet<CustomerLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _CustomerLookupSheet(
        repository: widget.repository,
        accessToken: widget.accessToken,
        mobileCustomerCatalogRepository: widget.mobileCustomerCatalogRepository,
      ),
    );

    if (customer == null || !mounted) {
      return;
    }

    setState(() {
      _selectedCustomer = customer;
      _customerCodeController.text = customer.customerCode;
      _validationMessage = null;
      for (final line in _lines) {
        line.dispose();
      }
      _lines = <_CompanyOrderLineDraft>[_createLine()];
    });
    _draftSession.scheduleSave();
    _focusFreshEntryLine();
  }

  Future<void> _searchProduct(_CompanyOrderLineDraft line) async {
    final customer = _selectedCustomer;
    if (customer == null) {
      setState(() {
        line.setLookupStatus(
          'Urun aramasi icin once cari secilmeli.',
          isError: true,
        );
      });
      _showFeedback('Once bir musteri secin.');
      _refocusLine(line.barcodeFocusNode);
      return;
    }

    setState(() {
      line.setLookupStatus('Urun arama penceresi aciliyor.');
    });

    CompanyOrderProductLookupItem? product;
    final query = line.barcodeController.text.trim();
    if (query.length >= 2) {
      try {
        final products = await widget.repository.searchProducts(
          accessToken: widget.accessToken,
          warehouseNo: widget.defaultWarehouseNo,
          customerCode: customer.customerCode,
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

    product ??= await showModalBottomSheet<CompanyOrderProductLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _CompanyProductLookupSheet(
        repository: widget.repository,
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        customerCode: customer.customerCode,
        initialQuery: line.barcodeController.text,
      ),
    );

    if (product == null || !mounted) {
      if (mounted) {
        setState(() {
          line.clearLookupStatus();
        });
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
      entryLine.setLookupStatus(
        'Secildi: ${pickedProduct.stockCode} | ${pickedProduct.stockName}',
      );
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
    _refocusLine(entryLine.barcodeFocusNode);
  }

  Future<void> _scanProductWithCamera(_CompanyOrderLineDraft line) async {
    final customer = _selectedCustomer;
    if (customer == null) {
      setState(() {
        line.setLookupStatus(
          'Kamera ile okuma icin once cari secilmeli.',
          isError: true,
        );
      });
      _showFeedback('Kamera ile okuma icin once musteri secin.');
      _refocusLine(line.barcodeFocusNode);
      return;
    }

    if (!supportsCameraBarcodeScanning) {
      setState(() {
        line.setLookupStatus(
          'Bu cihazda kamera ile barkod okutma desteklenmiyor.',
          isError: true,
        );
      });
      _showFeedback('Bu cihazda kamera ile barkod okutma desteklenmiyor.');
      _refocusLine(line.barcodeFocusNode);
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Firma Siparisi Kamerasi',
      subtitle: 'Barkodu okutun; secili cari icin urun otomatik bulunacak.',
    );

    if (barcode == null) {
      _refocusLine(line.barcodeFocusNode);
      return;
    }

    if (!mounted) {
      return;
    }

    line.barcodeController.text = barcode;
    setState(() {
      line.setLookupStatus('Barkod okundu: $barcode. Urun araniyor.');
    });
    await _searchProduct(line);
  }

  bool _applyProductToLine(
    _CompanyOrderLineDraft line,
    CompanyOrderProductLookupItem product,
  ) {
    final existingLine = productEntryController.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<_CompanyOrderLineDraft>(
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

    if (productEntryController.readQuantity(
          existingLine.unitPriceController.text,
          fallback: 0,
        ) <=
        0) {
      line.applyProduct(product);
      existingLine.unitPriceController.text = line.unitPriceController.text;
    }

    _recycleMergedLine(line, createReplacement: _createLine);
    return true;
  }

  void _recycleMergedLine(
    _CompanyOrderLineDraft line, {
    required _CompanyOrderLineDraft Function() createReplacement,
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
      _lines = <_CompanyOrderLineDraft>[_createLine(), ..._lines];
    }
  }

  bool _increasePendingQuantityIfSameProduct(
    _CompanyOrderLineDraft line,
    CompanyOrderProductLookupItem product,
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
      line.setLookupStatus(
        'Ayni barkod okutuldu. +${AppFormatters.quantity(addedQuantity)} eklendi.',
      );
      _validationMessage = null;
    });
    unawaited(TerminalFeedback.success());
    return true;
  }

  Future<_CompanyOrderLineDraft?> _commitPendingEntryBeforeNextProduct(
    _CompanyOrderLineDraft line,
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
    CompanyOrderProductLookupItem first,
    CompanyOrderProductLookupItem second,
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
    _CompanyOrderLineDraft line,
    CompanyOrderProductLookupItem product,
  ) async {
    final existingLine = productEntryController.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<_CompanyOrderLineDraft>(
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

  void _rememberAddedProduct(CompanyOrderProductLookupItem product) {
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

  Future<void> _commitEntryLine(_CompanyOrderLineDraft line) async {
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
    _rememberAddedProduct(product);
    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  void _cancelPendingEntryLine(_CompanyOrderLineDraft line) {
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

  bool _isBlankLine(_CompanyOrderLineDraft line) {
    return line.selectedProduct == null &&
        line.stockCodeController.text.trim().isEmpty;
  }

  void _removeLine(_CompanyOrderLineDraft line) {
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

    final customer = _selectedCustomer;
    if (customer == null) {
      setState(() {
        _validationMessage = 'Siparis olusturmak icin musteri secimi zorunlu.';
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
        _validationMessage = 'En az bir satir olusturulmasi gerekiyor.';
      });
      return;
    }

    final requestLines = <CompanyOrderCreateLine>[];
    for (var index = 0; index < activeLines.length; index += 1) {
      final line = activeLines[index];
      final stockCode = line.stockCodeController.text.trim();
      final quantity = productEntryController.readQuantity(
        line.quantityController.text,
        fallback: 0,
      );
      final unitPrice = productEntryController.readQuantity(
        line.unitPriceController.text,
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
        CompanyOrderCreateLine(
          stockCode: stockCode,
          quantity: quantity,
          recommendedQuantity: 0,
          unitPrice: unitPrice,
          unitPointer: 1,
          description1: '',
          description2: '',
          packageCode: '',
          projectCode: '',
          customerResponsibilityCenter: '',
          productResponsibilityCenter: '',
        ),
      );
    }

    final request = CompanyOrderCreateRequest(
      customerCode: customer.customerCode,
      orderDate: _orderDate,
      deliveryDate: _deliveryDate,
      description1: _description1Controller.text.trim(),
      description2: _description2Controller.text.trim(),
      deliverer: _delivererController.text.trim(),
      receiver: _receiverController.text.trim(),
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
                    title: 'Yeni Verilen Firma Siparisi',
                    subtitle: 'Depo: ${widget.defaultWarehouseNo}',
                    badges: <Widget>[
                      TerminalLineCountBadge(count: _activeLineCount()),
                    ],
                    elevated: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildCustomerSection(theme),
                        const SizedBox(height: 12),
                        TerminalSectionToolbar(
                          title: 'Satirlar (${_activeLineCount()})',
                          actions: const <Widget>[],
                        ),
                        const SizedBox(height: 8),
                        _buildEntryLineCard(theme),
                      ],
                    ),
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
                                    label: const Text('Siparisi Olustur'),
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

  Widget _buildCustomerSection(ThemeData theme) {
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
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _customerCodeController,
                    readOnly: true,
                    onTap: _searchCustomer,
                    decoration: const InputDecoration(
                      labelText: 'Musteri Kodu*',
                      hintText: 'Cari secin',
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Zorunlu';
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: _searchCustomer,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.business_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Sec'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_selectedCustomer != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(55),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _selectedCustomer!.displayLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Temsilci: ${_selectedCustomer!.representativeCode.isEmpty ? '-' : _selectedCustomer!.representativeCode}'
                    ' | Vergi No: ${_selectedCustomer!.displayTaxNumber.isEmpty ? '-' : _selectedCustomer!.displayTaxNumber}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
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

  List<_CompanyOrderLineDraft> _committedLines() {
    return <_CompanyOrderLineDraft>[
      for (var index = 0; index < _lines.length; index++)
        if (index != 0 && !_isBlankLine(_lines[index])) _lines[index],
    ];
  }

  Widget _buildLineCard({
    required ThemeData theme,
    required int index,
    required _CompanyOrderLineDraft line,
  }) {
    final product = line.selectedProduct;
    final customerSelected = _selectedCustomer != null;
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
        barcode: product.barcode,
        packageLabel: product.unitMultiplier > 1
            ? AppFormatters.quantity(product.unitMultiplier)
            : null,
        priceLabel: AppFormatters.currency(
          productEntryController.readQuantity(
            line.unitPriceController.text,
            fallback: product.price,
          ),
        ),
        onConfirm: () => _commitEntryLine(line),
        onCancel: () => _cancelPendingEntryLine(line),
        scanRow: TerminalResponsiveLookupRow(
          field: ProductLookupField(
            controller: line.barcodeController,
            focusNode: line.barcodeFocusNode,
            enabled: customerSelected && !line.isLookupStatusLoading,
            labelText: 'Barkod okut / urun degistir',
            onSubmit: () => _searchProduct(line),
          ),
          action: FilledButton.icon(
            onPressed: customerSelected && !line.isLookupStatusLoading
                ? () => _searchProduct(line)
                : null,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Urun'),
          ),
          trailingAction: IconButton.filledTonal(
            onPressed: customerSelected && !line.isLookupStatusLoading
                ? () => _scanProductWithCamera(line)
                : null,
            tooltip: 'Kamera ile oku',
            icon: const Icon(Icons.photo_camera_back_rounded),
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
        priceLabel: AppFormatters.currency(
          productEntryController.readQuantity(
            line.unitPriceController.text,
            fallback: product.price,
          ),
        ),
        barcode: product.barcode,
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
              field: ProductLookupField(
                controller: line.barcodeController,
                focusNode: line.barcodeFocusNode,
                enabled: customerSelected && !line.isLookupStatusLoading,
                onSubmit: () => _searchProduct(line),
              ),
              action: FilledButton.icon(
                onPressed: customerSelected && !line.isLookupStatusLoading
                    ? () => _searchProduct(line)
                    : null,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Urun'),
              ),
              trailingAction: IconButton.filledTonal(
                onPressed: customerSelected && !line.isLookupStatusLoading
                    ? () => _scanProductWithCamera(line)
                    : null,
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
                TerminalPdaInfo(
                  label: 'Fiyat',
                  value: AppFormatters.currency(product.price),
                ),
                if (product.barcode.isNotEmpty)
                  TerminalPdaInfo(label: 'Barkod', value: product.barcode),
              ],
            ),
          if (isFreshEntry && !customerSelected) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6EFE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Bu satirda isleme baslamak icin once cari secin.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5B4738),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (isFreshEntry && line.lookupStatusMessage != null) ...<Widget>[
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

  int _activeLineCount() {
    return _committedLines().length;
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
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

  void _refocusLine(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focusNode.requestFocus();
      }
    });
  }
}

class _CompanyOrderLineDraft {
  _CompanyOrderLineDraft({Map<String, dynamic>? draft, this.onChanged})
    : barcodeController = TextEditingController(),
      stockCodeController = TextEditingController(),
      quantityController = TextEditingController(),
      unitPriceController = TextEditingController(text: '0') {
    if (draft != null) {
      barcodeController.text = draft['barcode']?.toString() ?? '';
      stockCodeController.text = draft['stockCode']?.toString() ?? '';
      quantityController.text = draft['quantity']?.toString() ?? '';
      unitPriceController.text = draft['unitPrice']?.toString() ?? '0';
      final productJson = _draftMap(draft['selectedProduct']);
      if (productJson != null) {
        selectedProduct = CompanyOrderProductLookupItem.fromJson(productJson);
        barcodeController.clear();
      }
    }
    for (final controller in _controllers) {
      controller.addListener(_notifyChanged);
    }
  }

  CompanyOrderProductLookupItem? selectedProduct;
  String? lookupStatusMessage;
  bool isLookupStatusLoading = false;
  bool isLookupStatusError = false;
  final TextEditingController barcodeController;
  final TextEditingController stockCodeController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final FocusNode barcodeFocusNode = FocusNode();
  final VoidCallback? onChanged;

  List<TextEditingController> get _controllers => <TextEditingController>[
    barcodeController,
    stockCodeController,
    quantityController,
    unitPriceController,
  ];

  bool get hasContent =>
      selectedProduct != null ||
      barcodeController.text.trim().isNotEmpty ||
      stockCodeController.text.trim().isNotEmpty ||
      quantityController.text.trim().isNotEmpty ||
      unitPriceController.text.trim() != '0';

  void applyProduct(CompanyOrderProductLookupItem product) {
    selectedProduct = product;
    barcodeController.clear();
    stockCodeController.text = product.stockCode;
    if (quantityController.text.trim().isEmpty) {
      quantityController.text = productEntryController.formatQuantity(
        productEntryController.unitMultiplierQuantity(product.unitMultiplier),
      );
    }
    if (productEntryController.readQuantity(
              unitPriceController.text,
              fallback: 0,
            ) ==
            0 &&
        product.price > 0) {
      unitPriceController.text = _formatNumber(product.price);
    }
  }

  void clearProduct() {
    selectedProduct = null;
    barcodeController.clear();
    stockCodeController.clear();
    unitPriceController.text = '0';
    lookupStatusMessage = null;
    isLookupStatusLoading = false;
    isLookupStatusError = false;
  }

  void clear() {
    clearProduct();
    quantityController.clear();
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

  Map<String, dynamic> toDraftJson() {
    return <String, dynamic>{
      'barcode': barcodeController.text,
      'stockCode': stockCodeController.text,
      'quantity': quantityController.text,
      'unitPrice': unitPriceController.text,
      'selectedProduct': selectedProduct == null
          ? null
          : _companyOrderProductJson(selectedProduct!),
    };
  }

  void _notifyChanged() => onChanged?.call();

  void dispose() {
    barcodeFocusNode.dispose();
    barcodeController.dispose();
    stockCodeController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }

  static String _formatNumber(double value) {
    final raw = value.toStringAsFixed(2);
    if (raw.endsWith('.00')) {
      return raw.substring(0, raw.length - 3);
    }

    return raw.replaceAll('.', ',');
  }
}

Map<String, dynamic>? _draftMap(Object? value) {
  return switch (value) {
    final Map<String, dynamic> map => Map<String, dynamic>.from(map),
    final Map map => map.map((key, item) => MapEntry(key.toString(), item)),
    _ => null,
  };
}

Map<String, dynamic> _companyOrderCustomerJson(CustomerLookupItem item) {
  return <String, dynamic>{
    'customerCode': item.customerCode,
    'customerName': item.customerName,
    'customerTitle': item.customerTitle,
    'customerDisplayName': item.customerDisplayName,
    'taxNumber': item.taxNumber,
    'representativeCode': item.representativeCode,
    'representativeName': item.representativeName,
    'invoiceAddressNo': item.invoiceAddressNo,
    'shippingAddressNo': item.shippingAddressNo,
    'isLocked': item.isLocked,
    'isClosed': item.isClosed,
    'taxIdentityNo': item.taxIdentityNo,
    'taxOfficeNo': item.taxOfficeNo,
    'taxOfficeName': item.taxOfficeName,
    'mainCustomerCode': item.mainCustomerCode,
    'regionCode': item.regionCode,
    'groupCode': item.groupCode,
    'sectorCode': item.sectorCode,
    'mobilePhone': item.mobilePhone,
    'email': item.email,
    'isEInvoiceCustomer': item.isEInvoiceCustomer,
    'isEDespatchCustomer': item.isEDespatchCustomer,
    'sameTaxCustomerCount': item.sameTaxCustomerCount,
    'selectionLabel': item.selectionLabel,
  };
}

Map<String, dynamic> _companyOrderProductJson(
  CompanyOrderProductLookupItem item,
) {
  return <String, dynamic>{
    'warehouseNo': item.warehouseNo,
    'barcode': item.barcode,
    'stockCode': item.stockCode,
    'stockName': item.stockName,
    'price': item.price,
    'unitName': item.unitName,
    'unitMultiplier': item.unitMultiplier,
    'isOrderBlocked': item.isOrderBlocked,
    'isSalesBlocked': item.isSalesBlocked,
  };
}

class _CustomerLookupSheet extends StatefulWidget {
  const _CustomerLookupSheet({
    required this.repository,
    required this.accessToken,
    required this.mobileCustomerCatalogRepository,
  });

  final CompanyOrdersRepository repository;
  final String accessToken;
  final MobileCustomerCatalogLocalRepository mobileCustomerCatalogRepository;

  @override
  State<_CustomerLookupSheet> createState() => _CustomerLookupSheetState();
}

class _CustomerLookupSheetState extends State<_CustomerLookupSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  List<CustomerLookupItem> _items = const <CustomerLookupItem>[];

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
        _items = const <CustomerLookupItem>[];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.repository.searchCustomers(
        accessToken: widget.accessToken,
        query: query,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      final catalogItems = await widget.mobileCustomerCatalogRepository
          .searchCustomers(query: query);
      if (!mounted) {
        return;
      }

      if (catalogItems.isNotEmpty) {
        setState(() {
          _items = catalogItems
              .map((item) => item.toCustomerLookupItem())
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
      title: 'Cari Ara',
      subtitle: 'Kod veya unvan ile arama yapin.',
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
            isThreeLine: item.lookupDetailParts.length > 3,
            title: Text(
              item.lookupTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              item.lookupDetailLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: item.isClosed ? const Icon(Icons.block_rounded) : null,
            onTap: () => Navigator.of(context).pop(item),
          );
        },
      ),
    );
  }
}

class _CompanyProductLookupSheet extends StatefulWidget {
  const _CompanyProductLookupSheet({
    required this.repository,
    required this.accessToken,
    required this.warehouseNo,
    required this.customerCode,
    required this.initialQuery,
  });

  final CompanyOrdersRepository repository;
  final String accessToken;
  final String warehouseNo;
  final String customerCode;
  final String initialQuery;

  @override
  State<_CompanyProductLookupSheet> createState() =>
      _CompanyProductLookupSheetState();
}

class _CompanyProductLookupSheetState
    extends State<_CompanyProductLookupSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  List<CompanyOrderProductLookupItem> _items =
      const <CompanyOrderProductLookupItem>[];

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
        _items = const <CompanyOrderProductLookupItem>[];
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
        customerCode: widget.customerCode,
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
      subtitle:
          'Secili cari: ${widget.customerCode} | Stok kodu, adi veya barkod.',
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
                'Birim ${item.unitName}',
                'Fiyat ${AppFormatters.currency(item.price)}',
                if (item.isOrderBlocked) 'Siparis blokeli',
                if (item.isSalesBlocked) 'Satis blokeli',
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
