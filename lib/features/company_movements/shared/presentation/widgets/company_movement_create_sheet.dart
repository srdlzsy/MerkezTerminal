import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/company_movements_repository.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_controller.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/utils/client_request_id.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/utils/terminal_feedback.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class CompanyMovementCreateSheet extends StatefulWidget {
  const CompanyMovementCreateSheet({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.mobileCustomerCatalogRepository,
    required this.title,
    required this.helperText,
    required this.submitLabel,
    this.showDocumentNoField = true,
    this.draft,
    this.draftRepository,
  });

  final CompanyMovementsRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;
  final MobileCustomerCatalogLocalRepository mobileCustomerCatalogRepository;
  final String title;
  final String helperText;
  final String submitLabel;
  final bool showDocumentNoField;
  final CreateDraft? draft;
  final CreateDraftRepository? draftRepository;

  @override
  State<CompanyMovementCreateSheet> createState() =>
      _CompanyMovementCreateSheetState();
}

class _CompanyMovementCreateSheetState extends State<CompanyMovementCreateSheet>
    with CreateFormValidation, WidgetsBindingObserver {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<_MovementLineDraft> _lines = <_MovementLineDraft>[];
  late final TextEditingController _customerController;
  late final TextEditingController _documentNoController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _delivererController;
  late final TextEditingController _receiverController;
  CustomerLookupItem? _selectedCustomer;
  String? _lookupError;
  Timer? _draftSaveTimer;
  Future<void> _draftSaveQueue = Future<void>.value();
  bool _restoringDraft = true;
  bool _submitted = false;
  String? _lastAddedProductKey;

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController();
    _documentNoController = TextEditingController();
    _descriptionController = TextEditingController();
    _delivererController = TextEditingController();
    _receiverController = TextEditingController();
    _restoreDraft();
    _customerController.addListener(_scheduleDraftSave);
    _documentNoController.addListener(_scheduleDraftSave);
    _descriptionController.addListener(_scheduleDraftSave);
    _delivererController.addListener(_scheduleDraftSave);
    _receiverController.addListener(_scheduleDraftSave);
    WidgetsBinding.instance.addObserver(this);
    _restoringDraft = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftSaveTimer?.cancel();
    if (!_submitted) {
      unawaited(_saveDraft());
    }
    _customerController.dispose();
    _documentNoController.dispose();
    _descriptionController.dispose();
    _delivererController.dispose();
    _receiverController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _draftSaveTimer?.cancel();
      unawaited(_saveDraft());
    }
  }

  void _restoreDraft() {
    final payload = widget.draft?.payload;
    if (payload == null || payload.isEmpty) {
      _lines.add(_createLine());
      return;
    }

    _customerController.text = payload['customerText']?.toString() ?? '';
    _documentNoController.text = payload['documentNo']?.toString() ?? '';
    _descriptionController.text = payload['description']?.toString() ?? '';
    _delivererController.text = payload['deliverer']?.toString() ?? '';
    _receiverController.text = payload['receiver']?.toString() ?? '';

    final customerJson = _asJsonMap(payload['selectedCustomer']);
    if (customerJson != null) {
      _selectedCustomer = CustomerLookupItem.fromJson(customerJson);
    }

    final rawLines = payload['lines'];
    if (rawLines is List) {
      for (final rawLine in rawLines) {
        final lineJson = _asJsonMap(rawLine);
        if (lineJson != null) {
          _lines.add(_createLine(lineJson));
        }
      }
    }

    _ensureFreshEntryLine();
  }

  _MovementLineDraft _createLine([Map<String, dynamic>? draft]) {
    return _MovementLineDraft(draft: draft, onChanged: _scheduleDraftSave);
  }

  void _scheduleDraftSave() {
    if (_restoringDraft ||
        widget.draft == null ||
        widget.draftRepository == null) {
      return;
    }

    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 800), () {
      unawaited(_saveDraft());
    });
  }

  Future<void> _saveDraft() {
    final draft = widget.draft;
    final repository = widget.draftRepository;
    if (draft == null || repository == null) {
      return Future<void>.value();
    }

    final meaningful = _hasMeaningfulDraftContent;
    final payload = _draftPayload();
    _draftSaveQueue = _draftSaveQueue.then((_) {
      if (!meaningful) {
        return repository.deleteDraft(draft.id);
      }

      return repository.saveDraft(
        draft.copyWith(
          title: _draftTitle,
          updatedAt: DateTime.now(),
          payload: payload,
        ),
      );
    });
    return _draftSaveQueue;
  }

  String get _draftTitle {
    final customer = _selectedCustomer?.displayName.trim() ?? '';
    if (customer.isEmpty) {
      return widget.title;
    }
    return '${widget.title} - $customer';
  }

  bool get _hasMeaningfulDraftContent {
    return _selectedCustomer != null ||
        _customerController.text.trim().isNotEmpty ||
        _documentNoController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _delivererController.text.trim().isNotEmpty ||
        _receiverController.text.trim().isNotEmpty ||
        _lines.any((line) => line.hasMeaningfulContent);
  }

  Map<String, dynamic> _draftPayload() {
    return <String, dynamic>{
      'customerText': _customerController.text,
      'documentNo': _documentNoController.text,
      'description': _descriptionController.text,
      'deliverer': _delivererController.text,
      'receiver': _receiverController.text,
      'selectedCustomer': _selectedCustomer == null
          ? null
          : _customerToJson(_selectedCustomer!),
      'lines': _lines
          .where((line) => line.hasMeaningfulContent)
          .map((line) => line.toDraftJson())
          .toList(growable: false),
    };
  }

  Future<void> _searchCustomer() async {
    final query = _customerController.text.trim();

    if (query.length < 2) {
      setState(() {
        _lookupError = 'Cari aramak icin en az 2 karakter girilmeli.';
      });
      return;
    }

    List<CustomerLookupItem> customers;
    try {
      customers = await widget.repository.searchCustomers(
        accessToken: widget.accessToken,
        query: query,
      );
    } on ApiException catch (error) {
      final catalogItems = await widget.mobileCustomerCatalogRepository
          .searchCustomers(query: query);
      if (catalogItems.isNotEmpty) {
        customers = catalogItems
            .map((item) => item.toCustomerLookupItem())
            .toList(growable: false);
      } else {
        if (!mounted) {
          return;
        }

        setState(() {
          _lookupError = error
              .toString()
              .replaceFirst('Exception: ', '')
              .trim();
        });
        return;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _lookupError = error.toString().replaceFirst('Exception: ', '').trim();
      });
      return;
    }

    if (!mounted) {
      return;
    }

    final selected = await showModalBottomSheet<CustomerLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        if (customers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: TerminalEmptyState(message: 'Cari bulunamadi.'),
          );
        }

        return FractionallySizedBox(
          heightFactor: 0.82,
          child: ListView.separated(
            itemCount: customers.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = customers[index];
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                isThreeLine: item.lookupDetailParts.length > 3,
                title: Text(
                  item.lookupTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item.lookupDetailLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(context).pop(item),
              );
            },
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedCustomer = selected;
      _customerController.text = selected.displayLabel;
      _lookupError = null;
    });
    _scheduleDraftSave();
    _focusFreshEntryLine();
  }

  Future<void> _searchProduct(_MovementLineDraft line) async {
    final query = line.lookupController.text.trim();

    if (query.length < 2) {
      setState(() {
        line.setLookupStatus(
          'Urun aramak icin en az 2 karakter veya barkod girilmeli.',
          isError: true,
        );
        _lookupError = null;
      });
      _refocusLine(line.lookupFocusNode);
      return;
    }

    List<SearchProductLookupItem> products;
    try {
      setState(() {
        line.setLookupStatus('Urun araniyor: $query', isLoading: true);
        _lookupError = null;
      });

      products = await widget.repository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        query: query,
        customerCode: _selectedCustomer?.customerCode,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        line.setLookupStatus(
          'API hata dondu: ${error.toString().replaceFirst('Exception: ', '').trim()}',
          isError: true,
        );
        _lookupError = null;
      });
      _refocusLine(line.lookupFocusNode);
      return;
    }

    if (!mounted) {
      return;
    }

    if (products.isEmpty) {
      setState(() {
        line.setLookupStatus(
          'API cevap verdi ama urun bulunamadi: $query',
          isError: true,
        );
      });
      _refocusLine(line.lookupFocusNode);
      return;
    }

    SearchProductLookupItem? selected;
    if (products.length == 1) {
      selected = products.single;
    } else {
      setState(() {
        line.setLookupStatus(
          '${products.length} urun bulundu. Listeden secim bekleniyor.',
        );
      });

      selected = await showModalBottomSheet<SearchProductLookupItem>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.82,
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = products[index];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  title: Text(
                    item.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${item.unitName} | ${AppFormatters.currency(item.price)}${item.barcode.isNotEmpty ? ' | ${item.barcode}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(context).pop(item),
                );
              },
            ),
          );
        },
      );
    }

    if (selected == null) {
      if (mounted) {
        setState(() {
          line.clearLookupStatus();
        });
        _refocusLine(line.lookupFocusNode);
      }
      return;
    }
    final pickedProduct = selected;

    if (_increasePendingQuantityIfSameProduct(line, pickedProduct)) {
      _scheduleDraftSave();
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
      _lookupError = null;
    });
    _scheduleDraftSave();
    _refocusLine(entryLine.lookupFocusNode);
  }

  Future<void> _scanProductWithCamera(_MovementLineDraft line) async {
    if (!supportsCameraBarcodeScanning) {
      setState(() {
        _lookupError = 'Bu cihazda kamera ile barkod okutma desteklenmiyor.';
      });
      _refocusLine(line.lookupFocusNode);
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Barkod Kamerasi',
      subtitle: 'Barkodu okutun; bulunan urun secim listesine aktarilacak.',
    );

    if (barcode == null) {
      _refocusLine(line.lookupFocusNode);
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      line.lookupController.text = barcode;
      line.setLookupStatus('Barkod okundu: $barcode. Urun araniyor.');
      _lookupError = null;
    });

    await _searchProduct(line);
  }

  bool _applyProductToLine(
    _MovementLineDraft line,
    SearchProductLookupItem product,
  ) {
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

  _MovementLineDraft? _findMergeTarget(
    _MovementLineDraft line,
    SearchProductLookupItem product,
  ) {
    return productEntryController.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<_MovementLineDraft>(
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

  void _notifySuccessfulProductAdd({
    required SearchProductLookupItem product,
    required bool mergedIntoExisting,
  }) {
    _rememberAddedProduct(product);
    unawaited(TerminalFeedback.success());
  }

  Future<bool> _confirmDuplicateIncrease(
    _MovementLineDraft line,
    SearchProductLookupItem product,
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

  void _rememberAddedProduct(SearchProductLookupItem product) {
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

  void _recycleMergedLine(
    _MovementLineDraft line, {
    required _MovementLineDraft Function() createReplacement,
  }) {
    final lineIndex = _lines.indexOf(line);
    line.dispose();

    if (lineIndex == 0) {
      _lines[lineIndex] = createReplacement();
      return;
    }

    _lines.removeAt(lineIndex);
  }

  void _ensureFreshEntryLine() {
    if (_lines.isEmpty || !_isBlankLine(_lines.first)) {
      _lines.insert(0, _createLine());
    }
  }

  bool _increasePendingQuantityIfSameProduct(
    _MovementLineDraft line,
    SearchProductLookupItem product,
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
        line.quantity + addedQuantity,
      );
      line.lookupController.clear();
      line.setLookupStatus(
        'Ayni barkod okutuldu. +${AppFormatters.quantity(addedQuantity)} eklendi.',
      );
      _lookupError = null;
    });
    unawaited(TerminalFeedback.success());
    return true;
  }

  Future<_MovementLineDraft?> _commitPendingEntryBeforeNextProduct(
    _MovementLineDraft line,
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
    SearchProductLookupItem first,
    SearchProductLookupItem second,
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

  bool get _hasPendingEntryLine =>
      _lines.isNotEmpty && !_isBlankLine(_lines.first);

  Future<void> _commitEntryLine(_MovementLineDraft line) async {
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
      _lookupError = null;
    });
    _scheduleDraftSave();
    _focusFreshEntryLine();
    _notifySuccessfulProductAdd(
      product: product,
      mergedIntoExisting: mergedIntoExisting,
    );
  }

  void _cancelPendingEntryLine(_MovementLineDraft line) {
    setState(() {
      line.clear();
      _lookupError = null;
    });
    _scheduleDraftSave();
    _refocusLine(line.lookupFocusNode);
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

  bool _isBlankLine(_MovementLineDraft line) {
    return line.selectedProduct == null;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;

    if (form == null || !validateCreateForm(_formKey)) {
      return;
    }

    if (_selectedCustomer == null) {
      setState(() {
        _lookupError = 'Cari secimi zorunludur.';
      });
      return;
    }

    if (_hasPendingEntryLine) {
      setState(() {
        _lookupError = 'Secilen urunu once Kaleme Ekle ile listeye alin.';
      });
      return;
    }

    final activeLines = _committedLines();

    if (activeLines.isEmpty) {
      setState(() {
        _lookupError = 'En az bir urun satiri ekleyin.';
      });
      return;
    }

    if (activeLines.any((line) => line.selectedProduct == null)) {
      setState(() {
        _lookupError = 'Tum satirlarda urun secimi tamamlanmali.';
      });
      return;
    }

    final request = CompanyMovementCreateRequest(
      clientRequestId: generateClientRequestId(),
      customerCode: _selectedCustomer!.customerCode,
      movementDate: DateTime.now(),
      documentDate: DateTime.now(),
      documentNo: widget.showDocumentNoField
          ? _documentNoController.text.trim()
          : '',
      description: _descriptionController.text.trim(),
      deliverer: _delivererController.text.trim(),
      receiver: _receiverController.text.trim(),
      lines: activeLines
          .map(
            (line) => CompanyMovementCreateLine(
              stockCode: line.selectedProduct!.stockCode,
              quantity: line.quantity,
              unitPrice: line.unitPrice,
              unitPointer: line.unitPointer,
              description: line.descriptionController.text.trim(),
              partyCode: line.partyCodeController.text.trim(),
              lotNo: line.lotNo,
              projectCode: line.projectCodeController.text.trim(),
              customerResponsibilityCenter: line.customerRcController.text
                  .trim(),
              productResponsibilityCenter: line.productRcController.text.trim(),
            ),
          )
          .toList(growable: false),
    );

    _draftSaveTimer?.cancel();
    await _saveDraft();
    if (!mounted) {
      return;
    }
    _submitted = true;
    Navigator.of(context).pop(request);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      child: Form(
        key: _formKey,
        autovalidateMode: createFormAutovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TerminalSheetHeader(
              title: widget.title,
              badges: <Widget>[
                TerminalLineCountBadge(count: _filledLineIndexes().length),
              ],
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 4),
            TerminalCreateInputDock(
              padding: EdgeInsets.zero,
              children: <Widget>[
                TerminalResponsiveLookupRow(
                  field: TextFormField(
                    controller: _customerController,
                    decoration: const InputDecoration(
                      labelText: 'Cari',
                      hintText: 'Cari adi veya kodu',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    validator: (_) {
                      if (_selectedCustomer == null) {
                        return 'Cari secimi zorunludur.';
                      }

                      return null;
                    },
                  ),
                  action: FilledButton.icon(
                    onPressed: _searchCustomer,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Bul'),
                  ),
                ),
                const SizedBox(height: 4),
                _buildDeliveryInfoRow(),
                const SizedBox(height: 4),
                TerminalSectionToolbar(
                  title: 'Satirlar',
                  actions: const <Widget>[],
                ),
                const SizedBox(height: 4),
                _buildEntryLineCard(),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: CustomScrollView(
                slivers: <Widget>[
                  _buildLazyLineSliver(),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_lookupError != null) ...<Widget>[
                          TerminalMessageBlock.error(message: _lookupError!),
                          const SizedBox(height: 12),
                        ],
                        TerminalFormActionRow(
                          cancel: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Vazgec'),
                          ),
                          submit: FilledButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.save_alt_rounded),
                            label: Text(widget.submitLabel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoRow() {
    final delivererField = TextFormField(
      controller: _delivererController,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Teslim Eden',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
    final receiverField = TextFormField(
      controller: _receiverController,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        labelText: 'Teslim Alan',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300) {
          return Column(
            children: <Widget>[
              delivererField,
              const SizedBox(height: 4),
              receiverField,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: delivererField),
            const SizedBox(width: 8),
            Expanded(child: receiverField),
          ],
        );
      },
    );
  }

  Widget _buildEntryLineCard() {
    if (_lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildLineCard(0);
  }

  Widget _buildLazyLineSliver() {
    final indexes = _filledLineIndexes();
    if (indexes.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, visibleIndex) {
        final index = indexes[visibleIndex];
        return _buildLineCard(index);
      }, childCount: indexes.length),
    );
  }

  List<int> _filledLineIndexes() {
    return <int>[
      for (var index = 0; index < _lines.length; index++)
        if (index != 0 && !_isBlankLine(_lines[index])) index,
    ];
  }

  List<_MovementLineDraft> _committedLines() {
    return <_MovementLineDraft>[
      for (var index = 0; index < _lines.length; index++)
        if (index != 0 && !_isBlankLine(_lines[index])) _lines[index],
    ];
  }

  Widget _buildLineCard(int index) {
    final line = _lines[index];
    final isEntrySlot = index == 0;
    final isFreshEntry = isEntrySlot && _isBlankLine(line);
    final isPendingEntry = isEntrySlot && !_isBlankLine(line);
    final displayLineNo = _lines
        .take(index + 1)
        .where((item) => _lines.indexOf(item) != 0 && !_isBlankLine(item))
        .length;
    final product = line.selectedProduct;

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
        priceLabel: AppFormatters.currency(product.price),
        onConfirm: () => _commitEntryLine(line),
        onCancel: () => _cancelPendingEntryLine(line),
        scanRow: TerminalResponsiveLookupRow(
          field: ProductLookupField(
            controller: line.lookupController,
            focusNode: line.lookupFocusNode,
            enabled: !line.isLookupStatusLoading,
            labelText: 'Barkod okut / urun degistir',
            onSubmit: () => _searchProduct(line),
          ),
          action: FilledButton.icon(
            onPressed: line.isLookupStatusLoading
                ? null
                : () => _searchProduct(line),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Urun'),
          ),
          trailingAction: IconButton.filledTonal(
            onPressed: line.isLookupStatusLoading
                ? null
                : () => _scanProductWithCamera(line),
            tooltip: 'Kamera ile oku',
            icon: const Icon(Icons.photo_camera_back_rounded),
          ),
        ),
        quantityValidator: (_) {
          if (line.quantity <= 0) {
            return 'Miktar > 0 olmali.';
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
        priceLabel: AppFormatters.currency(product.price),
        barcode: product.barcode,
        canDelete: _lines.length > 1,
        onDelete: _lines.length > 1 ? () => _removeLineAt(index) : null,
        onMinimumReached: _lines.length > 1 ? () => _removeLineAt(index) : null,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withAlpha(90),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    isFreshEntry ? 'Giris satiri' : 'Satir $displayLineNo',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isFreshEntry && _lines.length > 1)
                  IconButton(
                    onPressed: () => _removeLineAt(index),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            if (isFreshEntry)
              TerminalResponsiveLookupRow(
                field: ProductLookupField(
                  controller: line.lookupController,
                  focusNode: line.lookupFocusNode,
                  enabled: !line.isLookupStatusLoading,
                  onSubmit: () => _searchProduct(line),
                ),
                action: FilledButton.icon(
                  onPressed: line.isLookupStatusLoading
                      ? null
                      : () => _searchProduct(line),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Urun'),
                ),
                trailingAction: IconButton.filledTonal(
                  onPressed: line.isLookupStatusLoading
                      ? null
                      : () => _scanProductWithCamera(line),
                  tooltip: 'Kamera ile oku',
                  icon: const Icon(Icons.photo_camera_back_rounded),
                ),
              )
            else if (line.selectedProduct != null)
              TerminalPdaInfoGrid(
                minTileWidth: 92,
                items: <TerminalPdaInfo>[
                  TerminalPdaInfo(
                    label: 'Urun',
                    value: line.selectedProduct!.stockName,
                  ),
                  TerminalPdaInfo(
                    label: 'Kod',
                    value: line.selectedProduct!.stockCode,
                  ),
                  TerminalPdaInfo(
                    label: 'Birim',
                    value: line.selectedProduct!.unitName,
                  ),
                  TerminalPdaInfo(
                    label: 'Fiyat',
                    value: AppFormatters.currency(line.selectedProduct!.price),
                  ),
                  if (line.selectedProduct!.barcode.isNotEmpty)
                    TerminalPdaInfo(
                      label: 'Barkod',
                      value: line.selectedProduct!.barcode,
                    ),
                ],
              ),
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
                label: 'Miktar',
                onMinimumReached: _lines.length > 1
                    ? () => _removeLineAt(index)
                    : null,
                validator: (_) {
                  if (line.quantity <= 0) {
                    return 'Miktar > 0 olmali.';
                  }

                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _removeLineAt(int index) {
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
      _ensureFreshEntryLine();
    });
    _scheduleDraftSave();
  }

  void _refocusLine(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focusNode.requestFocus();
      }
    });
  }
}

class _MovementLineDraft {
  _MovementLineDraft({Map<String, dynamic>? draft, this.onChanged})
    : lookupController = TextEditingController(),
      quantityController = TextEditingController(),
      unitPriceController = TextEditingController(text: '0'),
      unitPointerController = TextEditingController(text: '1'),
      descriptionController = TextEditingController(),
      partyCodeController = TextEditingController(),
      lotNoController = TextEditingController(text: '0'),
      projectCodeController = TextEditingController(),
      customerRcController = TextEditingController(),
      productRcController = TextEditingController() {
    if (draft != null) {
      lookupController.text = draft['lookup']?.toString() ?? '';
      quantityController.text = draft['quantity']?.toString() ?? '';
      unitPriceController.text = draft['unitPrice']?.toString() ?? '0';
      unitPointerController.text = draft['unitPointer']?.toString() ?? '1';
      descriptionController.text = draft['description']?.toString() ?? '';
      partyCodeController.text = draft['partyCode']?.toString() ?? '';
      lotNoController.text = draft['lotNo']?.toString() ?? '0';
      projectCodeController.text = draft['projectCode']?.toString() ?? '';
      customerRcController.text = draft['customerRc']?.toString() ?? '';
      productRcController.text = draft['productRc']?.toString() ?? '';
      final productJson = _asJsonMap(draft['selectedProduct']);
      if (productJson != null) {
        selectedProduct = SearchProductLookupItem.fromJson(productJson);
        lookupController.clear();
      }
    }

    for (final controller in _controllers) {
      controller.addListener(_notifyChanged);
    }
  }

  final TextEditingController lookupController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final TextEditingController unitPointerController;
  final TextEditingController descriptionController;
  final TextEditingController partyCodeController;
  final TextEditingController lotNoController;
  final TextEditingController projectCodeController;
  final TextEditingController customerRcController;
  final TextEditingController productRcController;
  final FocusNode lookupFocusNode = FocusNode();
  final VoidCallback? onChanged;

  SearchProductLookupItem? selectedProduct;
  String? lookupStatusMessage;
  bool isLookupStatusLoading = false;
  bool isLookupStatusError = false;

  double get quantity =>
      productEntryController.readQuantity(quantityController.text, fallback: 0);
  double get unitPrice => productEntryController.readQuantity(
    unitPriceController.text,
    fallback: 0,
  );
  int get unitPointer => _readInt(unitPointerController.text, fallback: 1);
  int get lotNo => _readInt(lotNoController.text, fallback: 0);
  bool get hasMeaningfulContent =>
      selectedProduct != null ||
      lookupController.text.trim().isNotEmpty ||
      quantityController.text.trim().isNotEmpty ||
      unitPriceController.text.trim() != '0' ||
      unitPointerController.text.trim() != '1' ||
      descriptionController.text.trim().isNotEmpty ||
      partyCodeController.text.trim().isNotEmpty ||
      (lotNoController.text.trim().isNotEmpty &&
          lotNoController.text.trim() != '0') ||
      projectCodeController.text.trim().isNotEmpty ||
      customerRcController.text.trim().isNotEmpty ||
      productRcController.text.trim().isNotEmpty;

  List<TextEditingController> get _controllers => <TextEditingController>[
    lookupController,
    quantityController,
    unitPriceController,
    unitPointerController,
    descriptionController,
    partyCodeController,
    lotNoController,
    projectCodeController,
    customerRcController,
    productRcController,
  ];

  void applyProduct(SearchProductLookupItem product) {
    selectedProduct = product;
    lookupController.clear();
    if (quantityController.text.trim().isEmpty) {
      quantityController.text = productEntryController.formatQuantity(
        productEntryController.unitMultiplierQuantity(product.unitMultiplier),
      );
    }
    unitPriceController.text = product.price.toString();
  }

  void clear() {
    lookupFocusNode.unfocus();
    lookupController.clear();
    quantityController.clear();
    unitPriceController.text = '0';
    unitPointerController.text = '1';
    descriptionController.clear();
    partyCodeController.clear();
    lotNoController.text = '0';
    projectCodeController.clear();
    customerRcController.clear();
    productRcController.clear();
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

  Map<String, dynamic> toDraftJson() {
    return <String, dynamic>{
      'lookup': lookupController.text,
      'quantity': quantityController.text,
      'unitPrice': unitPriceController.text,
      'unitPointer': unitPointerController.text,
      'description': descriptionController.text,
      'partyCode': partyCodeController.text,
      'lotNo': lotNoController.text,
      'projectCode': projectCodeController.text,
      'customerRc': customerRcController.text,
      'productRc': productRcController.text,
      'selectedProduct': selectedProduct == null
          ? null
          : _productToJson(selectedProduct!),
    };
  }

  void _notifyChanged() {
    onChanged?.call();
  }

  void dispose() {
    lookupFocusNode.dispose();
    lookupController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    unitPointerController.dispose();
    descriptionController.dispose();
    partyCodeController.dispose();
    lotNoController.dispose();
    projectCodeController.dispose();
    customerRcController.dispose();
    productRcController.dispose();
  }
}

int _readInt(String value, {required int fallback}) {
  return int.tryParse(value.trim()) ?? fallback;
}

Map<String, dynamic>? _asJsonMap(Object? value) {
  return switch (value) {
    final Map<String, dynamic> map => Map<String, dynamic>.from(map),
    final Map map => map.map((key, item) => MapEntry(key.toString(), item)),
    _ => null,
  };
}

Map<String, dynamic> _customerToJson(CustomerLookupItem customer) {
  return <String, dynamic>{
    'customerCode': customer.customerCode,
    'customerName': customer.customerName,
    'customerTitle': customer.customerTitle,
    'customerDisplayName': customer.customerDisplayName,
    'taxNumber': customer.taxNumber,
    'representativeCode': customer.representativeCode,
    'representativeName': customer.representativeName,
    'invoiceAddressNo': customer.invoiceAddressNo,
    'shippingAddressNo': customer.shippingAddressNo,
    'isLocked': customer.isLocked,
    'isClosed': customer.isClosed,
    'taxIdentityNo': customer.taxIdentityNo,
    'taxOfficeNo': customer.taxOfficeNo,
    'taxOfficeName': customer.taxOfficeName,
    'mainCustomerCode': customer.mainCustomerCode,
    'regionCode': customer.regionCode,
    'groupCode': customer.groupCode,
    'sectorCode': customer.sectorCode,
    'mobilePhone': customer.mobilePhone,
    'email': customer.email,
    'isEInvoiceCustomer': customer.isEInvoiceCustomer,
    'isEDespatchCustomer': customer.isEDespatchCustomer,
    'sameTaxCustomerCount': customer.sameTaxCustomerCount,
    'selectionLabel': customer.selectionLabel,
  };
}

Map<String, dynamic> _productToJson(SearchProductLookupItem product) {
  return <String, dynamic>{
    'warehouseNo': product.warehouseNo,
    'barcode': product.barcode,
    'stockCode': product.stockCode,
    'stockName': product.stockName,
    'price': product.price,
    'priceTypeCode': product.priceTypeCode,
    'unitName': product.unitName,
    'unitMultiplier': product.unitMultiplier,
    'secondaryUnitName': product.secondaryUnitName,
    'secondaryUnitMultiplier': product.secondaryUnitMultiplier,
    'salesBlockCode': product.salesBlockCode,
    'orderBlockCode': product.orderBlockCode,
    'goodsAcceptanceBlockCode': product.goodsAcceptanceBlockCode,
    'isSalesBlocked': product.isSalesBlocked,
    'isOrderBlocked': product.isOrderBlocked,
    'isGoodsAcceptanceBlocked': product.isGoodsAcceptanceBlocked,
    'productManagerCode': product.productManagerCode,
  };
}
