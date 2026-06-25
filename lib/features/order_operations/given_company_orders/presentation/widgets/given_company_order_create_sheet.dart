import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      return;
    }

    setState(() {
      line.setLookupStatus('Urun arama penceresi aciliyor.');
    });

    final product = await showModalBottomSheet<CompanyOrderProductLookupItem>(
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
          line.setLookupStatus('Urun secimi yapilmadi.');
        });
      }
      return;
    }

    var mergedIntoExisting = false;
    setState(() {
      mergedIntoExisting = _applyProductToLine(line, product);
      if (!mergedIntoExisting) {
        line.setLookupStatus(
          'Secildi: ${product.stockCode} | ${product.stockName}',
        );
      }
      _ensureFreshEntryLine();
      _validationMessage = null;
    });
    _focusFreshEntryLine();

    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
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
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Firma Siparisi Kamerasi',
      subtitle: 'Barkodu okutun; secili cari icin urun otomatik bulunacak.',
    );

    if (barcode == null || !mounted) {
      return;
    }

    line.barcodeController.text = barcode;
    setState(() {
      line.setLookupStatus('Barkod okundu: $barcode. API aramasi basliyor.');
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
        line.stockCodeController.text.trim().isEmpty &&
        line.barcodeController.text.trim().isEmpty;
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

    final activeLines = _lines
        .where((line) => !_isBlankLine(line))
        .toList(growable: false);

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
                                'Yeni Verilen Firma Siparisi',
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
                        _buildCustomerSection(theme),
                        const SizedBox(height: 16),

                        TerminalSectionToolbar(
                          title: 'Satirlar',
                          actions: const <Widget>[],
                        ),
                        const SizedBox(height: 10),
                        ..._lines.asMap().entries.map(
                          (entry) => _buildLineCard(
                            theme: theme,
                            index: entry.key,
                            line: entry.value,
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
                            label: const Text('Siparisi Olustur'),
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
                    ' | Vergi No: ${_selectedCustomer!.taxNumber.isEmpty ? '-' : _selectedCustomer!.taxNumber}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLineCard({
    required ThemeData theme,
    required int index,
    required _CompanyOrderLineDraft line,
  }) {
    final product = line.selectedProduct;
    final customerSelected = _selectedCustomer != null;
    final isFreshEntry = index == 0 && _isBlankLine(line);
    final displayLineNo = _lines
        .take(index + 1)
        .where((item) => !_isBlankLine(item))
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(30),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isFreshEntry ? 'Giris' : '#$displayLineNo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product?.stockName ??
                        (isFreshEntry ? 'Okutmaya hazir' : 'Urun secilmedi'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: product != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: product != null
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
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
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ProductLookupField(
                        controller: line.barcodeController,
                        focusNode: line.barcodeFocusNode,
                        enabled:
                            customerSelected && !line.isLookupStatusLoading,
                        onSubmit: () => _searchProduct(line),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: customerSelected && !line.isLookupStatusLoading
                          ? () => _searchProduct(line)
                          : null,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Urun'),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: customerSelected && !line.isLookupStatusLoading
                          ? () => _scanProductWithCamera(line)
                          : null,
                      tooltip: 'Kamera ile oku',
                      icon: const Icon(Icons.photo_camera_back_rounded),
                    ),
                  ],
                ),
                if (!customerSelected) ...<Widget>[
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
                if (line.lookupStatusMessage != null) ...<Widget>[
                  const SizedBox(height: 8),
                  if (line.isLookupStatusLoading)
                    TerminalMessageBlock.loading(
                      message: line.lookupStatusMessage!,
                    )
                  else if (line.isLookupStatusError)
                    TerminalMessageBlock.error(
                      message: line.lookupStatusMessage!,
                    )
                  else
                    TerminalMessageBlock.info(
                      message: line.lookupStatusMessage!,
                    ),
                ],
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
                    if (_isBlankLine(line)) {
                      return null;
                    }

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
                        'Birim: ${product.unitName}',
                        'Varsayilan fiyat: ${AppFormatters.currency(product.price)}',
                        if (product.isOrderBlocked) 'Siparis blokeli',
                        if (product.isSalesBlocked) 'Satis blokeli',
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
    barcodeController.text = product.barcode;
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

  void setLookupStatus(
    String message, {
    bool isLoading = false,
    bool isError = false,
  }) {
    lookupStatusMessage = message;
    isLookupStatusLoading = isLoading;
    isLookupStatusError = isError;
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
                if (item.representativeCode.isNotEmpty)
                  'Temsilci ${item.representativeCode}',
                if (item.taxNumber.isNotEmpty) 'Vergi ${item.taxNumber}',
              ].join(' | '),
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
                'Birim ${item.unitName}',
                'Fiyat ${AppFormatters.currency(item.price)}',
                if (item.isOrderBlocked) 'Siparis blokeli',
                if (item.isSalesBlocked) 'Satis blokeli',
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
