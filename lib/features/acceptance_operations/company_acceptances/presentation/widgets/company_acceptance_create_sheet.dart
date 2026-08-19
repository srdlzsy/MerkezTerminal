import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/models/company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/given_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_session.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/utils/client_request_id.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/utils/e_despatch_qr_parser.dart';
import 'package:furpa_merkez_terminal/shared/utils/terminal_feedback.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

enum _CompanyAcceptanceCreateStep { document, lines }

class CompanyAcceptanceCreateSheet extends StatefulWidget {
  const CompanyAcceptanceCreateSheet({
    super.key,
    required this.repository,
    required this.ordersRepository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.mobileCustomerCatalogRepository,
    required this.mobileProductCatalogRepository,
    this.draft,
    this.draftRepository,
  });

  final CompanyAcceptancesRepository repository;
  final GivenCompanyOrdersRepository ordersRepository;
  final String accessToken;
  final String defaultWarehouseNo;
  final MobileCustomerCatalogLocalRepository mobileCustomerCatalogRepository;
  final MobileProductCatalogLocalRepository mobileProductCatalogRepository;
  final CreateDraft? draft;
  final CreateDraftRepository? draftRepository;

  @override
  State<CompanyAcceptanceCreateSheet> createState() =>
      _CompanyAcceptanceCreateSheetState();
}

class _CompanyAcceptanceCreateSheetState
    extends State<CompanyAcceptanceCreateSheet>
    with CreateFormValidation {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<_AcceptanceLineDraft> _lines = <_AcceptanceLineDraft>[];
  late final TextEditingController _customerController;
  late final TextEditingController _customerCodeController;
  late final TextEditingController _ettnController;
  late final TextEditingController _documentNoController;
  late final TextEditingController _delivererController;
  late final TextEditingController _receiverController;
  late final TextEditingController _descriptionController;
  DateTime _movementDate = DateTime.now();
  DateTime _documentDate = DateTime.now();
  bool _allowOrderOverReceiving = false;
  bool _autoCreateReturnForPartialAcceptance = true;
  bool _isResolvingEDespatch = false;
  String? _lookupError;
  CompanyAcceptanceEDespatchPrefill? _lastEDespatchPrefill;
  _CompanyAcceptanceCreateStep _step = _CompanyAcceptanceCreateStep.document;
  late final CreateDraftSession _draftSession;
  String? _lastAddedProductKey;

  @override
  void initState() {
    super.initState();
    final payload = widget.draft?.payload ?? const <String, dynamic>{};
    _customerController = TextEditingController(
      text: payload['customerText']?.toString() ?? '',
    );
    _customerCodeController = TextEditingController(
      text: payload['customerCode']?.toString() ?? '',
    );
    _ettnController = TextEditingController(
      text: payload['ettn']?.toString() ?? '',
    );
    _documentNoController = TextEditingController(
      text: payload['documentNo']?.toString() ?? '',
    );
    _delivererController = TextEditingController(
      text: payload['deliverer']?.toString() ?? '',
    );
    _receiverController = TextEditingController(
      text: payload['receiver']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: payload['description']?.toString() ?? '',
    );
    _movementDate =
        DateTime.tryParse(payload['movementDate']?.toString() ?? '') ??
        DateTime.now();
    _documentDate =
        DateTime.tryParse(payload['documentDate']?.toString() ?? '') ??
        DateTime.now();
    _allowOrderOverReceiving =
        payload['allowOrderOverReceiving'] == true ||
        payload['allowOrderOverReceiving']?.toString() == 'true';
    _autoCreateReturnForPartialAcceptance =
        payload.containsKey('autoCreateReturnForPartialAcceptance')
        ? payload['autoCreateReturnForPartialAcceptance'] == true ||
              payload['autoCreateReturnForPartialAcceptance']?.toString() ==
                  'true'
        : true;
    _step = payload['activeStep']?.toString() == 'lines'
        ? _CompanyAcceptanceCreateStep.lines
        : _CompanyAcceptanceCreateStep.document;
    _draftSession = CreateDraftSession(
      draft: widget.draft,
      repository: widget.draftRepository,
      hasContent: _hasDraftContent,
      buildPayload: _buildDraftPayload,
      buildTitle: () {
        final customer = _customerController.text.trim();
        return customer.isEmpty
            ? 'Yeni Firma Mal Kabul'
            : 'Mal Kabul - $customer';
      },
    );
    final rawLines = payload['lines'];
    if (rawLines is List) {
      _lines.addAll(
        rawLines
            .map(_acceptanceDraftMap)
            .whereType<Map<String, dynamic>>()
            .map(_createLine),
      );
    }
    _ensureFreshEntryLine();
    _draftSession.listenTo(<TextEditingController>[
      _customerController,
      _customerCodeController,
      _ettnController,
      _documentNoController,
      _delivererController,
      _receiverController,
      _descriptionController,
    ]);
  }

  @override
  void dispose() {
    _draftSession.dispose();
    _customerController.dispose();
    _customerCodeController.dispose();
    _ettnController.dispose();
    _documentNoController.dispose();
    _delivererController.dispose();
    _receiverController.dispose();
    _descriptionController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  _AcceptanceLineDraft _createLine([Map<String, dynamic>? draft]) {
    return _AcceptanceLineDraft(
      draft: draft,
      onChanged: _draftSession.scheduleSave,
    );
  }

  bool _hasDraftContent() {
    return _customerController.text.trim().isNotEmpty ||
        _customerCodeController.text.trim().isNotEmpty ||
        _ettnController.text.trim().isNotEmpty ||
        _documentNoController.text.trim().isNotEmpty ||
        _delivererController.text.trim().isNotEmpty ||
        _receiverController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _allowOrderOverReceiving ||
        !_autoCreateReturnForPartialAcceptance ||
        _lines.any((line) => line.hasContent);
  }

  Map<String, dynamic> _buildDraftPayload() {
    return <String, dynamic>{
      'customerText': _customerController.text,
      'customerCode': _customerCodeController.text,
      'ettn': _ettnController.text,
      'documentNo': _documentNoController.text,
      'deliverer': _delivererController.text,
      'receiver': _receiverController.text,
      'description': _descriptionController.text,
      'movementDate': _movementDate.toIso8601String(),
      'documentDate': _documentDate.toIso8601String(),
      'allowOrderOverReceiving': _allowOrderOverReceiving,
      'autoCreateReturnForPartialAcceptance':
          _autoCreateReturnForPartialAcceptance,
      'activeStep': _step.name,
      'lines': _lines
          .where((line) => line.hasContent)
          .map((line) => line.toDraftJson())
          .toList(growable: false),
    };
  }

  Future<void> _pickDate({required bool movementDate}) async {
    final initialDate = movementDate ? _movementDate : _documentDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      if (movementDate) {
        _movementDate = pickedDate;
      } else {
        _documentDate = pickedDate;
      }
    });
    _draftSession.scheduleSave();
    _focusFreshEntryLine();
  }

  Future<void> _scanEDespatchQr() async {
    if (!supportsCameraBarcodeScanning) {
      setState(() {
        _lookupError =
            'Bu cihazda kamera ile e-belge QR okutma desteklenmiyor.';
      });
      return;
    }

    final qrValue = await openBarcodeCameraScanner(
      context,
      title: 'E-Belge QR',
      subtitle: 'Tedarikci belgesindeki QR kodu okutun.',
      qrOnly: true,
    );

    if (qrValue == null || !mounted) {
      return;
    }

    _ettnController.text = qrValue;
    await _resolveEDespatchFromValue(qrValue);
  }

  Future<void> _resolveEDespatchFromInput() async {
    await _resolveEDespatchFromValue(_ettnController.text);
  }

  Future<void> _resolveEDespatchFromValue(String rawValue) async {
    final qrPayload = parseEDespatchQrPayload(rawValue);
    final ettn = qrPayload.ettn;
    if (ettn == null) {
      setState(() {
        _lookupError = 'Gecerli bir ETTN/UUID bulunamadi.';
      });
      return;
    }

    setState(() {
      _ettnController.text = ettn;
      _applyQrPayloadPrefill(qrPayload);
      _isResolvingEDespatch = true;
      _lookupError = null;
    });
    _draftSession.scheduleSave();

    try {
      final prefill = await widget.repository.resolveEDespatchByEttn(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        ettn: ettn,
      );

      if (!mounted) {
        return;
      }

      if (!prefill.isFound) {
        final documentLabel = prefill.effectiveDocumentLabel;
        setState(() {
          _ettnController.text = ettn;
          _lastEDespatchPrefill = prefill;
          _isResolvingEDespatch = false;
          _lookupError = qrPayload.hasDocumentPrefill
              ? 'Bu ETTN ile gelen $documentLabel bulunamadi; QR belge bilgileri forma aktarildi.'
              : 'Bu ETTN ile gelen $documentLabel bulunamadi: $ettn';
        });
        _draftSession.scheduleSave();
        return;
      }

      setState(() {
        _ettnController.text = prefill.ettn.trim().isEmpty
            ? ettn
            : prefill.ettn.trim();
        _lastEDespatchPrefill = prefill;
        _applyEDespatchPrefill(prefill);
        _isResolvingEDespatch = false;
        _lookupError = null;
      });
      _draftSession.scheduleSave();

      await _fillCustomerFromQrSenderIfNeeded(qrPayload);

      final documentNo = prefill.effectiveDocumentNumber;
      final documentLabel = prefill.effectiveDocumentLabel;
      _showFeedback(
        documentNo.isEmpty
            ? '$documentLabel bilgileri forma aktarildi.'
            : '$documentNo icin $documentLabel bilgileri forma aktarildi.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isResolvingEDespatch = false;
        _lookupError = error.toString().replaceFirst('Exception: ', '');
      });
      _draftSession.scheduleSave();

      await _fillCustomerFromQrSenderIfNeeded(qrPayload);
    }
  }

  Future<void> _fillCustomerFromQrSenderIfNeeded(
    EDespatchQrPayload qrPayload,
  ) async {
    if (_customerCodeController.text.trim().isNotEmpty) {
      return;
    }

    final taxNoOrTckn = qrPayload.senderTaxNoOrTckn?.trim() ?? '';
    if (taxNoOrTckn.length < 6) {
      return;
    }

    try {
      final customers = await _searchCustomersWithFallback(taxNoOrTckn);
      if (!mounted ||
          customers.isEmpty ||
          _customerCodeController.text.trim().isNotEmpty) {
        return;
      }

      final selectedCustomer =
          _findCustomerByTaxNo(customers, taxNoOrTckn) ?? customers.first;
      setState(() {
        _customerController.text = selectedCustomer.displayLabel;
        _customerCodeController.text = selectedCustomer.customerCode;
      });
      _draftSession.scheduleSave();
    } catch (_) {
      // QR belge bilgileri yine de kullanilabilir; cari arama basarisizsa
      // kullanici cari kodunu manuel girebilir.
    }
  }

  void _applyQrPayloadPrefill(EDespatchQrPayload qrPayload) {
    final documentNo = qrPayload.documentNo?.trim() ?? '';
    if (documentNo.isNotEmpty) {
      _documentNoController.text = documentNo;
    }

    final issueDate = qrPayload.issueDate;
    if (issueDate != null) {
      _documentDate = _normalizedDate(issueDate);
    }
  }

  void _applyEDespatchPrefill(CompanyAcceptanceEDespatchPrefill prefill) {
    final documentNumber = prefill.effectiveDocumentNumber;
    if (documentNumber.isNotEmpty) {
      _documentNoController.text = documentNumber;
    }

    final documentDate = prefill.effectiveDocumentDate;
    if (documentDate != null) {
      _documentDate = _normalizedDate(documentDate);
    }

    final suggestedCustomer = _preferredCustomerSuggestion(prefill);
    if (suggestedCustomer != null &&
        suggestedCustomer.customerCode.trim().isNotEmpty) {
      _customerController.text = suggestedCustomer.displayLabel;
      _customerCodeController.text = suggestedCustomer.customerCode.trim();
    } else if (prefill.sender.title.trim().isNotEmpty &&
        _customerController.text.trim().isEmpty) {
      _customerController.text = prefill.sender.title.trim();
    }

    if (_descriptionController.text.trim().isEmpty &&
        prefill.notes.isNotEmpty) {
      _descriptionController.text = prefill.notes.join('\n');
    }
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
      customers = await _searchCustomersWithFallback(query);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _lookupError = error.toString().replaceFirst('Exception: ', '');
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
      _customerController.text = selected.displayLabel;
      _customerCodeController.text = selected.customerCode;
      _lookupError = null;
    });
    _draftSession.scheduleSave();
  }

  Future<void> _searchProduct(_AcceptanceLineDraft line) async {
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

      products = await _searchProductsWithFallback(
        query,
        customerCode: _customerCodeController.text.trim(),
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
                    '${item.unitName} | ${AppFormatters.currency(item.price)}',
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
      _lookupError = null;
    });
    _draftSession.scheduleSave();
    _refocusLine(entryLine.lookupFocusNode);
  }

  Future<void> _scanProductWithCamera(_AcceptanceLineDraft line) async {
    if (!supportsCameraBarcodeScanning) {
      setState(() {
        _lookupError = 'Bu cihazda kamera ile barkod okutma desteklenmiyor.';
      });
      _refocusLine(line.lookupFocusNode);
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Mal Kabul Kamerasi',
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
    _draftSession.scheduleSave();

    await _searchProduct(line);
  }

  bool _increasePendingQuantityIfSameProduct(
    _AcceptanceLineDraft line,
    SearchProductLookupItem product,
  ) {
    final selectedProduct = line.selectedProduct;
    if (selectedProduct == null || !_isSameProduct(selectedProduct, product)) {
      return false;
    }

    final increment = _unitMultiplierQuantity(product.unitMultiplier);
    setState(() {
      line.dispatchQuantityController.text = _formatDraftQuantity(
        line.dispatchQuantity + increment,
      );
      line.acceptedQuantityController.text = _formatDraftQuantity(
        line.acceptedQuantity + increment,
      );
      line.lookupController.clear();
      line.setLookupStatus(
        'Ayni barkod okutuldu. +${AppFormatters.quantity(increment)} eklendi.',
      );
      _lookupError = null;
    });
    unawaited(TerminalFeedback.success());
    return true;
  }

  Future<_AcceptanceLineDraft?> _commitPendingEntryBeforeNextProduct(
    _AcceptanceLineDraft line,
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

  Future<bool> _confirmDuplicateIncrease(
    _AcceptanceLineDraft line,
    SearchProductLookupItem product,
  ) async {
    final existingLine = _findDuplicateLine(
      currentLine: line,
      barcode: product.barcode,
      stockCode: product.stockCode,
    );
    final key = _productIdentity(
      barcode: product.barcode,
      stockCode: product.stockCode,
    );
    if (existingLine == null ||
        _readDouble(
              existingLine.acceptedQuantityController.text,
              fallback: 0,
            ) <=
            0 ||
        key == null ||
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
    final key = _productIdentity(
      barcode: product.barcode,
      stockCode: product.stockCode,
    );
    if (key != null) {
      _lastAddedProductKey = key;
    }
  }

  bool get _hasPendingEntryLine =>
      _lines.isNotEmpty && !_isBlankLine(_lines.first);

  Future<void> _commitEntryLine(_AcceptanceLineDraft line) async {
    final product = line.selectedProduct;
    if (product == null) {
      _refocusLine(line.lookupFocusNode);
      return;
    }

    if (line.dispatchQuantity <= 0 || line.acceptedQuantity < 0) {
      setState(() {
        line.setLookupStatus(
          'Irsaliye miktari sifirdan buyuk, fiili kabul negatif olmamali.',
          isError: true,
        );
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
    _draftSession.scheduleSave();
    _focusFreshEntryLine();
    _rememberAddedProduct(product);
    unawaited(TerminalFeedback.success());
    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  void _cancelPendingEntryLine(_AcceptanceLineDraft line) {
    setState(() {
      line.clear();
      _lookupError = null;
    });
    _draftSession.scheduleSave();
    _refocusLine(line.lookupFocusNode);
  }

  List<_AcceptanceLineDraft> _committedLines() {
    return <_AcceptanceLineDraft>[
      for (var index = 0; index < _lines.length; index++)
        if (index != 0 && !_isBlankLine(_lines[index])) _lines[index],
    ];
  }

  bool _applyProductToLine(
    _AcceptanceLineDraft line,
    SearchProductLookupItem product,
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

    existingLine.dispatchQuantityController.text = _formatQuantity(
      _readDouble(existingLine.dispatchQuantityController.text, fallback: 0) +
          _quantityInputOrUnitMultiplier(
            line.dispatchQuantityController.text,
            product.unitMultiplier,
          ),
    );
    existingLine.acceptedQuantityController.text = _formatQuantity(
      _readDouble(existingLine.acceptedQuantityController.text, fallback: 0) +
          _quantityInputOrUnitMultiplier(
            line.acceptedQuantityController.text,
            product.unitMultiplier,
          ),
    );

    if (_readDouble(existingLine.unitPriceController.text, fallback: 0) <= 0) {
      line.applyProduct(product);
      existingLine.unitPriceController.text = line.unitPriceController.text;
    }

    _recycleMergedLine(line, createReplacement: _createLine);
    return true;
  }

  _AcceptanceLineDraft? _findDuplicateLine({
    required _AcceptanceLineDraft currentLine,
    required String barcode,
    required String stockCode,
  }) {
    if (currentLine.orderGuid != null) {
      return null;
    }

    final targetKey = _productIdentity(barcode: barcode, stockCode: stockCode);
    if (targetKey == null) {
      return null;
    }

    for (final candidate in _lines) {
      if (identical(candidate, currentLine) || candidate.orderGuid != null) {
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
    _AcceptanceLineDraft line, {
    required _AcceptanceLineDraft Function() createReplacement,
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

  bool _isBlankLine(_AcceptanceLineDraft line) {
    return line.selectedProduct == null &&
        line.stockCodeController.text.trim().isEmpty;
  }

  Future<void> _addLinesFromOpenOrders() async {
    final customerCode = _customerCodeController.text.trim();

    if (customerCode.isEmpty) {
      setState(() {
        _lookupError = 'Siparis baglamak icin once cari kodu girilmeli.';
      });
      return;
    }

    List<CompanyOrderListItem> orders;
    try {
      final today = DateTime.now();
      orders = await widget.ordersRepository.fetchOrders(
        accessToken: widget.accessToken,
        filter: CompanyOrderListFilter(
          startDate: DateTime(today.year, today.month, today.day),
          endDate: DateTime.now().add(const Duration(days: 30)),
          warehouseNo: widget.defaultWarehouseNo,
          customerCode: customerCode,
          onlyOpen: true,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _lookupError = error.toString().replaceFirst('Exception: ', '');
      });
      return;
    }

    if (!mounted) {
      return;
    }

    final selectedOrder = await showModalBottomSheet<CompanyOrderListItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        if (orders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: TerminalEmptyState(message: 'Acik siparis bulunamadi.'),
          );
        }

        return FractionallySizedBox(
          heightFactor: 0.82,
          child: ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = orders[index];
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                title: Text(
                  item.documentNoLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${item.customerDisplayName} | Kalan ${AppFormatters.quantity(item.totalRemainingQuantity)}',
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

    if (selectedOrder == null) {
      return;
    }

    CompanyOrderDetail detail;
    try {
      detail = await widget.ordersRepository.fetchOrderDetail(
        accessToken: widget.accessToken,
        documentSerie: selectedOrder.documentSerie,
        documentOrderNo: selectedOrder.documentOrderNo,
        warehouseNo: widget.defaultWarehouseNo,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _lookupError = error.toString().replaceFirst('Exception: ', '');
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      for (final item in detail.items) {
        if (item.remainingQuantity <= 0) {
          continue;
        }

        _lines.add(
          _AcceptanceLineDraft.fromOrderItem(
            item,
            onChanged: _draftSession.scheduleSave,
          ),
        );
      }
      _ensureFreshEntryLine();
      _lookupError = null;
    });
    _draftSession.scheduleSave();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;

    if (form == null || !validateCreateForm(_formKey)) {
      return;
    }

    final customerCode = _customerCodeController.text.trim();
    if (customerCode.isEmpty) {
      _showStepError(
        step: _CompanyAcceptanceCreateStep.document,
        message: 'Cari kodu zorunludur.',
      );
      return;
    }

    if (_isDocumentDateAfterMovementDate()) {
      _showStepError(
        step: _CompanyAcceptanceCreateStep.document,
        message: 'Belge tarihi hareket tarihinden sonra olamaz.',
      );
      return;
    }

    if (_hasPendingEntryLine) {
      _showStepError(
        step: _CompanyAcceptanceCreateStep.lines,
        message: 'Secilen urunu once Kaleme Ekle ile listeye alin.',
      );
      return;
    }

    final activeLines = _committedLines();

    if (activeLines.isEmpty) {
      _showStepError(
        step: _CompanyAcceptanceCreateStep.lines,
        message: 'En az bir urun satiri ekleyin.',
      );
      return;
    }

    final usedOrderGuids = <String>{};
    for (var index = 0; index < activeLines.length; index += 1) {
      final line = activeLines[index];
      if (line.stockCodeController.text.trim().isEmpty) {
        _showStepError(
          step: _CompanyAcceptanceCreateStep.lines,
          message: '${index + 1}. satir icin urun secin.',
        );
        return;
      }

      if (line.dispatchQuantity <= 0) {
        _showStepError(
          step: _CompanyAcceptanceCreateStep.lines,
          message:
              '${index + 1}. satir icin irsaliye miktari sifirdan buyuk olmali.',
        );
        return;
      }

      if (line.acceptedQuantity < 0) {
        _showStepError(
          step: _CompanyAcceptanceCreateStep.lines,
          message:
              '${index + 1}. satir icin fiili kabul miktari negatif olamaz.',
        );
        return;
      }

      if (line.acceptedQuantity > line.dispatchQuantity) {
        _showStepError(
          step: _CompanyAcceptanceCreateStep.lines,
          message:
              '${index + 1}. satirda fiili kabul irsaliye miktarini gecemez.',
        );
        return;
      }

      if (line.unitPointer <= 0 || line.unitPointer > 255) {
        _showStepError(
          step: _CompanyAcceptanceCreateStep.lines,
          message: '${index + 1}. satir icin unitPointer 1-255 olmali.',
        );
        return;
      }

      if (line.lotNo < 0) {
        _showStepError(
          step: _CompanyAcceptanceCreateStep.lines,
          message: '${index + 1}. satir icin lot no negatif olamaz.',
        );
        return;
      }

      final orderGuid = line.orderGuid?.trim() ?? '';
      if (orderGuid.isNotEmpty && !usedOrderGuids.add(orderGuid)) {
        _showStepError(
          step: _CompanyAcceptanceCreateStep.lines,
          message:
              '${index + 1}. satirda ayni siparis satiri tekrar kullanilamaz.',
        );
        return;
      }
    }

    final request = CompanyAcceptanceCreateRequest(
      customerCode: customerCode,
      movementDate: _movementDate,
      documentDate: _documentDate,
      documentNo: _documentNoController.text.trim(),
      clientRequestId: generateClientRequestId(),
      officialDocumentKind: _officialDocumentKindForRequest(),
      officialDocumentNo: _officialDocumentNoForRequest(),
      officialDocumentDate: _officialDocumentDateForRequest(),
      officialDocumentEttn: _officialDocumentEttnForRequest(),
      deliverer: _delivererController.text.trim(),
      receiver: _receiverController.text.trim(),
      description: _descriptionController.text.trim(),
      allowOrderOverReceiving: _allowOrderOverReceiving,
      autoCreateReturnForPartialAcceptance:
          _autoCreateReturnForPartialAcceptance,
      lines: activeLines
          .map(
            (line) => CompanyAcceptanceCreateLine(
              stockCode: line.stockCodeController.text.trim(),
              dispatchQuantity: line.dispatchQuantity,
              acceptedQuantity: line.acceptedQuantity,
              unitPrice: line.unitPrice,
              unitPointer: line.unitPointer,
              lastConsumingDate: line.lastConsumingDate,
              orderGuid: line.orderGuid,
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

    await _draftSession.complete();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(request);
  }

  String? _officialDocumentKindForRequest() {
    final prefill = _lastEDespatchPrefill;
    if (prefill == null || !prefill.isFound) {
      return null;
    }

    final kind = prefill.sourceDocumentKind.trim();
    return kind.isEmpty || kind == 'auto' ? null : kind;
  }

  String? _officialDocumentNoForRequest() {
    final prefill = _lastEDespatchPrefill;
    if (prefill == null || !prefill.isFound) {
      return null;
    }

    final documentNo = prefill.effectiveDocumentNumber.trim();
    return documentNo.isEmpty ? null : documentNo;
  }

  DateTime? _officialDocumentDateForRequest() {
    final prefill = _lastEDespatchPrefill;
    if (prefill == null || !prefill.isFound) {
      return null;
    }

    return prefill.effectiveDocumentDate;
  }

  String? _officialDocumentEttnForRequest() {
    final prefill = _lastEDespatchPrefill;
    if (prefill == null || !prefill.isFound) {
      return null;
    }

    final ettn = prefill.ettn.trim();
    return ettn.isEmpty ? _ettnController.text.trim() : ettn;
  }

  Future<List<CustomerLookupItem>> _searchCustomersWithFallback(
    String query,
  ) async {
    try {
      return await widget.repository.searchCustomers(
        accessToken: widget.accessToken,
        query: query,
      );
    } on ApiException {
      final catalogItems = await widget.mobileCustomerCatalogRepository
          .searchCustomers(query: query);
      if (catalogItems.isNotEmpty) {
        return catalogItems
            .map((item) => item.toCustomerLookupItem())
            .toList(growable: false);
      }
      rethrow;
    }
  }

  Future<List<SearchProductLookupItem>> _searchProductsWithFallback(
    String query, {
    String? customerCode,
  }) async {
    final normalizedCustomerCode = customerCode?.trim();
    try {
      return await widget.repository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        query: query,
        customerCode:
            normalizedCustomerCode == null || normalizedCustomerCode.isEmpty
            ? null
            : normalizedCustomerCode,
      );
    } on ApiException {
      final catalogItems = await widget.mobileProductCatalogRepository
          .searchProducts(warehouseNo: widget.defaultWarehouseNo, query: query);
      if (catalogItems.isNotEmpty) {
        return catalogItems
            .map((item) => item.toSearchProductLookupItem())
            .toList(growable: false);
      }
      rethrow;
    }
  }

  void _goToLinesStep() {
    if (!_validateDocumentStep()) {
      return;
    }

    setState(() {
      _step = _CompanyAcceptanceCreateStep.lines;
      _lookupError = null;
    });
    _draftSession.scheduleSave();
    _focusFreshEntryLine();
  }

  void _goToDocumentStep() {
    setState(() {
      _step = _CompanyAcceptanceCreateStep.document;
      _lookupError = null;
    });
    _draftSession.scheduleSave();
  }

  bool _validateDocumentStep() {
    final form = _formKey.currentState;
    if (form != null && !validateCreateForm(_formKey)) {
      return false;
    }

    final customerCode = _customerCodeController.text.trim();
    if (customerCode.isEmpty) {
      setState(() {
        _step = _CompanyAcceptanceCreateStep.document;
        _lookupError = 'Cari kodu zorunludur.';
      });
      return false;
    }

    if (_isDocumentDateAfterMovementDate()) {
      setState(() {
        _step = _CompanyAcceptanceCreateStep.document;
        _lookupError = 'Belge tarihi hareket tarihinden sonra olamaz.';
      });
      return false;
    }

    return true;
  }

  bool _isDocumentDateAfterMovementDate() {
    return _normalizedDate(
      _documentDate,
    ).isAfter(_normalizedDate(_movementDate));
  }

  void _showStepError({
    required _CompanyAcceptanceCreateStep step,
    required String message,
  }) {
    setState(() {
      _step = step;
      _lookupError = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDocumentStep = _step == _CompanyAcceptanceCreateStep.document;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Form(
        key: _formKey,
        autovalidateMode: createFormAutovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TerminalSheetHeader(
              title: 'Yeni Firma Mal Kabul',
              badges: <Widget>[
                TerminalLineCountBadge(count: _filledLineIndexes().length),
              ],
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 4),
            _buildStepSelector(),
            const SizedBox(height: 5),
            Expanded(
              child: isDocumentStep ? _buildDocumentStep() : _buildLinesStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepSelector() {
    return SizedBox(
      height: 36,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<_CompanyAcceptanceCreateStep>(
          showSelectedIcon: false,
          selected: <_CompanyAcceptanceCreateStep>{_step},
          style: const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(0, 34)),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 8),
            ),
            visualDensity: VisualDensity(horizontal: -3, vertical: -3),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          segments: const <ButtonSegment<_CompanyAcceptanceCreateStep>>[
            ButtonSegment<_CompanyAcceptanceCreateStep>(
              value: _CompanyAcceptanceCreateStep.document,
              icon: Icon(Icons.assignment_outlined, size: 18),
              label: Text('Belge'),
            ),
            ButtonSegment<_CompanyAcceptanceCreateStep>(
              value: _CompanyAcceptanceCreateStep.lines,
              icon: Icon(Icons.playlist_add_check_rounded, size: 18),
              label: Text('Kalemler'),
            ),
          ],
          onSelectionChanged: (selection) {
            final nextStep = selection.first;
            if (nextStep == _CompanyAcceptanceCreateStep.lines) {
              _goToLinesStep();
              return;
            }

            _goToDocumentStep();
          },
        ),
      ),
    );
  }

  Widget _buildDocumentStep() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_lookupError != null) ...<Widget>[
            TerminalMessageBlock.error(message: _lookupError!),
            const SizedBox(height: 6),
          ],
          _buildEDespatchLookupRow(),
          if (_lastEDespatchPrefill != null) ...<Widget>[
            const SizedBox(height: 4),
            TerminalMessageBlock.info(
              message: _eDespatchSummaryMessage(_lastEDespatchPrefill!),
            ),
          ],
          const SizedBox(height: 4),
          _buildCustomerLookupRow(),
          const SizedBox(height: 4),
          _buildCustomerCodeField(),
          const SizedBox(height: 4),
          _buildDocumentDetailsSection(),
          const SizedBox(height: 8),
          _buildDocumentStepActions(),
        ],
      ),
    );
  }

  Widget _buildLinesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TerminalCreateInputDock(
          padding: const EdgeInsets.only(bottom: 4),
          children: <Widget>[
            _buildLineStepSummary(),
            if (_lookupError != null) ...<Widget>[
              const SizedBox(height: 4),
              TerminalMessageBlock.error(message: _lookupError!),
            ],
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
                    const SizedBox(height: 4),
                    _buildLineStepActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerCodeField() {
    return TextFormField(
      controller: _customerCodeController,
      decoration: const InputDecoration(
        labelText: 'Cari Kodu*',
        hintText: 'Internet yoksa elle girin',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onChanged: (_) {
        setState(() {});
        _draftSession.scheduleSave();
      },
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return 'Cari kodu zorunlu';
        }

        return null;
      },
    );
  }

  Widget _buildDocumentStepActions() {
    final cancelButton = OutlinedButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Vazgec'),
    );

    final nextButton = FilledButton.icon(
      onPressed: _goToLinesStep,
      icon: const Icon(Icons.arrow_forward_rounded),
      label: const Text('Kalemlere Gec'),
    );

    return TerminalFormActionRow(cancel: cancelButton, submit: nextButton);
  }

  Widget _buildLineStepActions() {
    final documentButton = OutlinedButton.icon(
      onPressed: _goToDocumentStep,
      icon: const Icon(Icons.assignment_outlined),
      label: const Text('Belge'),
    );

    final submitButton = FilledButton.icon(
      onPressed: _submit,
      icon: const Icon(Icons.save_alt_rounded),
      label: const Text('Mal Kabul Et'),
    );

    return TerminalFormActionRow(cancel: documentButton, submit: submitButton);
  }

  Widget _buildLineStepSummary() {
    final theme = Theme.of(context);
    final customerText = _customerController.text.trim();
    final customerCode = _customerCodeController.text.trim();
    final documentNo = _documentNoController.text.trim();
    final lineCount = _filledLineIndexes().length;
    final dispatchTotal = _totalDispatchQuantity();
    final acceptedTotal = _totalAcceptedQuantity();
    final returnTotal = _totalReturnQuantity();
    final title = customerText.isNotEmpty
        ? customerText
        : customerCode.isNotEmpty
        ? customerCode
        : 'Cari secilmedi';
    final totalsLabel = <String>[
      '$lineCount kalem',
      'Irs ${AppFormatters.quantity(dispatchTotal)}',
      'Kabul ${AppFormatters.quantity(acceptedTotal)}',
      if (returnTotal > 0) 'Fark ${AppFormatters.quantity(returnTotal)}',
      if (documentNo.isNotEmpty) documentNo,
    ].join(' | ');
    final orderButton = IconButton.outlined(
      visualDensity: VisualDensity.compact,
      tooltip: 'Siparis bagla',
      onPressed: _customerCodeController.text.trim().isEmpty
          ? null
          : _addLinesFromOpenOrders,
      icon: const Icon(Icons.link_rounded),
    );
    final documentButton = IconButton.outlined(
      visualDensity: VisualDensity.compact,
      tooltip: 'Belge bilgileri',
      onPressed: _goToDocumentStep,
      icon: const Icon(Icons.edit_note_rounded),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(88),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalsLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: returnTotal > 0
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.onSurface.withAlpha(160),
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              orderButton,
              const SizedBox(width: 4),
              documentButton,
            ],
          ),
        ],
      ),
    );
  }

  double _totalDispatchQuantity() {
    return _committedLines().fold<double>(
      0,
      (total, line) => total + line.dispatchQuantity,
    );
  }

  double _totalAcceptedQuantity() {
    return _committedLines().fold<double>(
      0,
      (total, line) => total + line.acceptedQuantity,
    );
  }

  double _totalReturnQuantity() {
    return _committedLines().fold<double>(
      0,
      (total, line) => total + line.returnQuantity,
    );
  }

  Widget _buildEntryLineCard() {
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

  Widget _buildLineCard(int index) {
    final line = _lines[index];
    final isEntrySlot = index == 0;
    final isFreshEntry = isEntrySlot && _isBlankLine(line);
    final isPendingEntry = isEntrySlot && !_isBlankLine(line);
    final displayLineNo = _lines
        .take(index + 1)
        .where((item) => _lines.indexOf(item) != 0 && !_isBlankLine(item))
        .length;
    final selectedProduct = line.selectedProduct;

    if (isPendingEntry && selectedProduct != null) {
      return ProductDraftEntryPanel(
        stockCode: selectedProduct.stockCode,
        stockName: selectedProduct.stockName,
        quantityController: line.dispatchQuantityController,
        title: 'Secilen urun',
        quantityLabel: 'Irsaliye Miktari*',
        unitLabel: selectedProduct.unitName,
        barcode: selectedProduct.barcode,
        packageLabel: selectedProduct.unitMultiplier > 1
            ? AppFormatters.quantity(selectedProduct.unitMultiplier)
            : null,
        priceLabel: line.unitPrice > 0
            ? AppFormatters.currency(line.unitPrice)
            : null,
        onConfirm: () => _commitEntryLine(line),
        onCancel: () => _cancelPendingEntryLine(line),
        scanRow: _buildProductLookupRow(line),
        quantityValidator: (_) {
          if (line.dispatchQuantity <= 0) {
            return 'Miktar > 0';
          }
          return null;
        },
        onQuantityChanged: (_) => setState(() {}),
        secondaryQuantityController: line.acceptedQuantityController,
        secondaryQuantityLabel: 'Fiili Kabul*',
        secondaryMaximumQuantity: line.dispatchQuantity,
        onSecondaryQuantityChanged: (_) => setState(() {}),
        secondaryQuantityValidator: (_) {
          if (line.acceptedQuantity < 0) {
            return 'Negatif olamaz';
          }
          if (line.acceptedQuantity > line.dispatchQuantity) {
            return 'Irsaliyeyi gecemez';
          }
          return null;
        },
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
                if ((line.orderGuid ?? '').isNotEmpty)
                  const TerminalBadge(label: 'Siparisli'),
                if (!isFreshEntry && _lines.length > 1)
                  IconButton(
                    onPressed: () => _removeLineAt(index),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            if (isFreshEntry)
              _buildProductLookupRow(line)
            else
              TerminalCompactProductLineSummary(
                lineNo: displayLineNo,
                stockCode: line.stockCodeController.text.trim(),
                stockName:
                    line.selectedProduct?.stockName ??
                    line.lookupController.text.trim(),
                unitLabel: line.selectedProduct?.unitName,
                packageLabel:
                    line.selectedProduct != null &&
                        line.selectedProduct!.unitMultiplier > 1
                    ? AppFormatters.quantity(
                        line.selectedProduct!.unitMultiplier,
                      )
                    : null,
                barcode: line.selectedProduct?.barcode,
                priceLabel: line.unitPrice > 0
                    ? AppFormatters.currency(line.unitPrice)
                    : null,
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
              const SizedBox(height: 12),
              _buildQuantityFields(line),
            ],
            if (line.returnQuantity > 0) ...<Widget>[
              const SizedBox(height: 8),
              TerminalMessageBlock.info(
                message:
                    'Iade farki ${AppFormatters.quantity(line.returnQuantity)}. ${_autoCreateReturnForPartialAcceptance ? 'Firma iadesi olusur, e-irsaliye manuel gonderilir.' : 'Otomatik iade kapali; fark manuel iade bekler.'}',
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
    _draftSession.scheduleSave();
  }

  Widget _buildDocumentDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: <Widget>[
            TerminalFilterButton(
              label: 'Hareket Tarihi',
              value: AppFormatters.date(_movementDate),
              onPressed: () => _pickDate(movementDate: true),
            ),
            TerminalFilterButton(
              label: 'Belge Tarihi',
              value: AppFormatters.date(_documentDate),
              onPressed: () => _pickDate(movementDate: false),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final twoColumn = maxWidth >= 300;
            final halfWidth = twoColumn ? (maxWidth - 8) / 2 : maxWidth;

            return Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                SizedBox(
                  width: maxWidth,
                  child: TextFormField(
                    controller: _documentNoController,
                    decoration: const InputDecoration(
                      labelText: 'Belge No / Seri',
                      hintText: 'Bos birakilabilir',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: halfWidth,
                  child: TextFormField(
                    controller: _delivererController,
                    decoration: const InputDecoration(
                      labelText: 'Teslim Eden',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: halfWidth,
                  child: TextFormField(
                    controller: _receiverController,
                    decoration: const InputDecoration(
                      labelText: 'Teslim Alan',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: maxWidth,
                  child: TextFormField(
                    controller: _descriptionController,
                    minLines: 1,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Aciklama',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        _CompactCheckboxTile(
          value: _allowOrderOverReceiving,
          title: 'Siparis kalanindan fazla kabul etmeye izin ver',
          subtitle:
              'Backend fazla miktari siparissiz hareket olarak ayirabilir.',
          onChanged: (value) {
            setState(() {
              _allowOrderOverReceiving = value ?? false;
            });
            _draftSession.scheduleSave();
          },
        ),
        _CompactCheckboxTile(
          value: _autoCreateReturnForPartialAcceptance,
          title: 'Eksik kabul farki icin firma iadesi olustur',
          subtitle:
              'E-irsaliye otomatik gonderilmez; iade evragindan manuel gonderilir.',
          onChanged: (value) {
            setState(() {
              _autoCreateReturnForPartialAcceptance = value ?? true;
            });
            _draftSession.scheduleSave();
          },
        ),
      ],
    );
  }

  Widget _buildEDespatchLookupRow() {
    final lookupField = TerminalSubmitOnTab(
      enabled: !_isResolvingEDespatch,
      onSubmit: _resolveEDespatchFromInput,
      child: TextFormField(
        controller: _ettnController,
        maxLines: 1,
        scrollPadding: EdgeInsets.zero,
        textAlignVertical: TextAlignVertical.center,
        textInputAction: TextInputAction.search,
        onFieldSubmitted: (_) => _resolveEDespatchFromInput(),
        decoration: const InputDecoration(
          labelText: 'ETTN / QR',
          hintText: 'UUID veya QR okut',
          floatingLabelBehavior: FloatingLabelBehavior.never,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
    final fixedLookupField = SizedBox(height: 42, child: lookupField);

    final resolveButton = FilledButton.icon(
      onPressed: _isResolvingEDespatch ? null : _resolveEDespatchFromInput,
      icon: _isResolvingEDespatch
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.fact_check_rounded),
      label: Text(_isResolvingEDespatch ? 'Sorgu' : 'Bul'),
    );

    final scanButton = IconButton.filledTonal(
      onPressed: _isResolvingEDespatch ? null : _scanEDespatchQr,
      tooltip: 'E-belge QR oku',
      icon: const Icon(Icons.qr_code_scanner_rounded),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              fixedLookupField,
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Expanded(child: resolveButton),
                  const SizedBox(width: 8),
                  scanButton,
                ],
              ),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: fixedLookupField),
            const SizedBox(width: 8),
            resolveButton,
            const SizedBox(width: 8),
            scanButton,
          ],
        );
      },
    );
  }

  Widget _buildCustomerLookupRow() {
    final lookupField = TextFormField(
      controller: _customerController,
      decoration: const InputDecoration(
        labelText: 'Cari Arama',
        hintText: 'Cari adi veya kodu',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );

    final searchButton = FilledButton.icon(
      onPressed: _searchCustomer,
      icon: const Icon(Icons.search_rounded),
      label: const Text('Bul'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 330) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              lookupField,
              const SizedBox(height: 6),
              searchButton,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: lookupField),
            const SizedBox(width: 8),
            searchButton,
          ],
        );
      },
    );
  }

  Widget _buildProductLookupRow(_AcceptanceLineDraft line) {
    final lookupField = ProductLookupField(
      controller: line.lookupController,
      focusNode: line.lookupFocusNode,
      enabled: !line.isLookupStatusLoading,
      hintText: 'Arama veya barkod',
      selectTextOnFocus: line.selectedProduct == null,
      onSubmit: () => _searchProduct(line),
      validator: (_) {
        if (_isBlankLine(line)) {
          return null;
        }

        if (line.stockCodeController.text.trim().isEmpty) {
          return 'Urun secin';
        }
        return null;
      },
    );

    final searchButton = FilledButton.icon(
      onPressed: line.isLookupStatusLoading ? null : () => _searchProduct(line),
      icon: const Icon(Icons.search_rounded),
      label: const Text('Urun'),
    );

    final scanButton = IconButton.filledTonal(
      onPressed: line.isLookupStatusLoading
          ? null
          : () => _scanProductWithCamera(line),
      tooltip: 'Kamera ile oku',
      icon: const Icon(Icons.photo_camera_back_rounded),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              lookupField,
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(child: searchButton),
                  const SizedBox(width: 8),
                  scanButton,
                ],
              ),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: lookupField),
            const SizedBox(width: 12),
            searchButton,
            const SizedBox(width: 8),
            scanButton,
          ],
        );
      },
    );
  }

  Widget _buildQuantityFields(_AcceptanceLineDraft line) {
    Widget dispatchField() {
      return TerminalQuantityStepper(
        controller: line.dispatchQuantityController,
        label: 'Irsaliye Miktari*',
        onMinimumReached: () {
          final index = _lines.indexOf(line);
          if (index < 0 || _lines.length <= 1) {
            return;
          }
          setState(() {
            line.dispose();
            _lines.removeAt(index);
          });
          _draftSession.scheduleSave();
        },
        onChanged: (_) => setState(() {}),
        validator: (_) {
          if (line.dispatchQuantity <= 0) {
            return 'Miktar > 0';
          }
          return null;
        },
      );
    }

    Widget acceptedField() {
      return TerminalQuantityStepper(
        controller: line.acceptedQuantityController,
        label: 'Fiili Kabul*',
        maximum: line.dispatchQuantity,
        onChanged: (_) => setState(() {}),
        validator: (_) {
          if (line.acceptedQuantity < 0) {
            return 'Negatif olamaz';
          }
          if (line.acceptedQuantity > line.dispatchQuantity) {
            return 'Irsaliyeyi gecemez';
          }
          return null;
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: <Widget>[
              dispatchField(),
              const SizedBox(height: 10),
              acceptedField(),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: dispatchField()),
            const SizedBox(width: 12),
            Expanded(child: acceptedField()),
          ],
        );
      },
    );
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

  void _refocusLine(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focusNode.requestFocus();
      }
    });
  }

  String _eDespatchSummaryMessage(CompanyAcceptanceEDespatchPrefill prefill) {
    final documentLabel = prefill.effectiveDocumentLabel;
    if (!prefill.isFound) {
      final parts = <String>[
        '$documentLabel bulunamadi',
        'ETTN: ${prefill.ettn}',
        if (prefill.warnings.isNotEmpty)
          'Uyari: ${prefill.warnings.join(' / ')}',
      ];
      return parts.join(' | ');
    }

    final suggestedCustomer = _preferredCustomerSuggestion(prefill);
    final parts = <String>[
      if (prefill.effectiveDocumentNumber.isNotEmpty)
        '$documentLabel: ${prefill.effectiveDocumentNumber}',
      'Belge satiri: ${prefill.totalLineCount}',
      'Kalemler manuel girilecek',
      if (prefill.isInvoice && prefill.invoiceTotal != null)
        'Fatura tutari: ${AppFormatters.currency(prefill.invoiceTotal!)} ${prefill.currencyCode}',
      if (prefill.warnings.isNotEmpty) 'Uyari: ${prefill.warnings.join(' / ')}',
      if (prefill.sender.title.trim().isNotEmpty)
        'Gonderici: ${prefill.sender.title}',
      if (suggestedCustomer != null)
        'Cari onerisi: ${suggestedCustomer.displayLabel}',
    ];

    return parts.join(' | ');
  }

  static CompanyAcceptanceCustomerSuggestion? _preferredCustomerSuggestion(
    CompanyAcceptanceEDespatchPrefill prefill,
  ) {
    final primarySuggestion = prefill.primaryCustomerSuggestion;
    if (primarySuggestion != null &&
        primarySuggestion.customerCode.trim().isNotEmpty) {
      return primarySuggestion;
    }

    for (final suggestion in prefill.suggestedCustomers) {
      if (suggestion.isPrimarySuggestion &&
          suggestion.customerCode.trim().isNotEmpty) {
        return suggestion;
      }
    }

    for (final suggestion in prefill.suggestedCustomers) {
      if (suggestion.customerCode.trim().isNotEmpty) {
        return suggestion;
      }
    }

    return null;
  }

  static CustomerLookupItem? _findCustomerByTaxNo(
    List<CustomerLookupItem> customers,
    String taxNoOrTckn,
  ) {
    final normalizedTaxNo = _onlyDigits(taxNoOrTckn);
    if (normalizedTaxNo.isEmpty) {
      return null;
    }

    for (final customer in customers) {
      if (_onlyDigits(customer.taxNumber) == normalizedTaxNo) {
        return customer;
      }
    }

    return null;
  }

  static String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

double _unitMultiplierQuantity(double unitMultiplier) {
  return unitMultiplier > 0 ? unitMultiplier : 1;
}

double _quantityInputOrUnitMultiplier(String raw, double unitMultiplier) {
  final normalized = raw.trim();
  if (normalized.isEmpty) {
    return _unitMultiplierQuantity(unitMultiplier);
  }

  final parsed = double.tryParse(normalized.replaceAll(',', '.'));
  return parsed != null && parsed > 0
      ? parsed
      : _unitMultiplierQuantity(unitMultiplier);
}

String _formatDraftQuantity(double value) {
  final fixed = value.toStringAsFixed(6);
  final normalized = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  return normalized.replaceAll('.', ',');
}

class _CompactCheckboxTile extends StatelessWidget {
  const _CompactCheckboxTile({
    required this.value,
    required this.title,
    required this.onChanged,
    this.subtitle,
  });

  final bool value;
  final String title;
  final String? subtitle;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 40,
              height: 40,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(150),
                          height: 1.12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcceptanceLineDraft {
  _AcceptanceLineDraft({Map<String, dynamic>? draft, this.onChanged})
    : lookupController = TextEditingController(),
      stockCodeController = TextEditingController(),
      dispatchQuantityController = TextEditingController(),
      acceptedQuantityController = TextEditingController(),
      unitPriceController = TextEditingController(text: '0'),
      descriptionController = TextEditingController(),
      partyCodeController = TextEditingController(),
      lotNoController = TextEditingController(text: '0'),
      projectCodeController = TextEditingController(),
      customerRcController = TextEditingController(),
      productRcController = TextEditingController(),
      lastConsumingDateController = TextEditingController() {
    if (draft != null) {
      lookupController.text = draft['lookup']?.toString() ?? '';
      stockCodeController.text = draft['stockCode']?.toString() ?? '';
      dispatchQuantityController.text =
          draft['dispatchQuantity']?.toString() ?? '';
      acceptedQuantityController.text =
          draft['acceptedQuantity']?.toString() ?? '';
      unitPriceController.text = draft['unitPrice']?.toString() ?? '0';
      descriptionController.text = draft['description']?.toString() ?? '';
      partyCodeController.text = draft['partyCode']?.toString() ?? '';
      lotNoController.text = draft['lotNo']?.toString() ?? '0';
      projectCodeController.text = draft['projectCode']?.toString() ?? '';
      customerRcController.text = draft['customerRc']?.toString() ?? '';
      productRcController.text = draft['productRc']?.toString() ?? '';
      lastConsumingDateController.text =
          draft['lastConsumingDate']?.toString() ?? '';
      orderGuid = draft['orderGuid']?.toString().trim().isEmpty ?? true
          ? null
          : draft['orderGuid']?.toString();
      unitPointer = int.tryParse(draft['unitPointer']?.toString() ?? '') ?? 1;
      final productJson = _acceptanceDraftMap(draft['selectedProduct']);
      if (productJson != null) {
        selectedProduct = SearchProductLookupItem.fromJson(productJson);
        lookupController.clear();
      }
    }
    for (final controller in _controllers) {
      controller.addListener(_notifyChanged);
    }
  }

  _AcceptanceLineDraft.fromOrderItem(
    CompanyOrderDetailItem item, {
    this.onChanged,
  }) : lookupController = TextEditingController(
         text: '${item.stockCode} - ${item.stockName}',
       ),
       stockCodeController = TextEditingController(text: item.stockCode),
       dispatchQuantityController = TextEditingController(
         text: item.remainingQuantity.toString(),
       ),
       acceptedQuantityController = TextEditingController(
         text: item.remainingQuantity.toString(),
       ),
       unitPriceController = TextEditingController(
         text: item.unitPrice.toString(),
       ),
       descriptionController = TextEditingController(text: item.description),
       partyCodeController = TextEditingController(),
       lotNoController = TextEditingController(text: '0'),
       projectCodeController = TextEditingController(text: item.projectCode),
       customerRcController = TextEditingController(),
       productRcController = TextEditingController(),
       lastConsumingDateController = TextEditingController() {
    selectedProduct = SearchProductLookupItem(
      warehouseNo: 0,
      barcode: '',
      stockCode: item.stockCode,
      stockName: item.stockName,
      price: item.unitPrice,
      priceTypeCode: 0,
      unitName: item.unitName,
      unitMultiplier: 1,
      secondaryUnitName: '',
      secondaryUnitMultiplier: 0,
      salesBlockCode: null,
      orderBlockCode: null,
      goodsAcceptanceBlockCode: null,
      isSalesBlocked: false,
      isOrderBlocked: false,
      isGoodsAcceptanceBlocked: false,
      productManagerCode: '',
    );
    orderGuid = item.orderGuid;
    unitPointer = item.unitPointer;
    for (final controller in _controllers) {
      controller.addListener(_notifyChanged);
    }
  }

  final TextEditingController lookupController;
  final TextEditingController stockCodeController;
  final TextEditingController dispatchQuantityController;
  final TextEditingController acceptedQuantityController;
  final TextEditingController unitPriceController;
  final TextEditingController descriptionController;
  final TextEditingController partyCodeController;
  final TextEditingController lotNoController;
  final TextEditingController projectCodeController;
  final TextEditingController customerRcController;
  final TextEditingController productRcController;
  final TextEditingController lastConsumingDateController;
  final FocusNode lookupFocusNode = FocusNode();
  final VoidCallback? onChanged;

  SearchProductLookupItem? selectedProduct;
  String? lookupStatusMessage;
  bool isLookupStatusLoading = false;
  bool isLookupStatusError = false;
  String? orderGuid;
  int unitPointer = 1;

  List<TextEditingController> get _controllers => <TextEditingController>[
    lookupController,
    stockCodeController,
    dispatchQuantityController,
    acceptedQuantityController,
    unitPriceController,
    descriptionController,
    partyCodeController,
    lotNoController,
    projectCodeController,
    customerRcController,
    productRcController,
    lastConsumingDateController,
  ];

  bool get hasContent =>
      selectedProduct != null ||
      orderGuid != null ||
      lookupController.text.trim().isNotEmpty ||
      stockCodeController.text.trim().isNotEmpty ||
      dispatchQuantityController.text.trim().isNotEmpty ||
      acceptedQuantityController.text.trim().isNotEmpty ||
      unitPriceController.text.trim() != '0' ||
      descriptionController.text.trim().isNotEmpty ||
      partyCodeController.text.trim().isNotEmpty ||
      (lotNoController.text.trim().isNotEmpty &&
          lotNoController.text.trim() != '0') ||
      projectCodeController.text.trim().isNotEmpty ||
      customerRcController.text.trim().isNotEmpty ||
      productRcController.text.trim().isNotEmpty ||
      lastConsumingDateController.text.trim().isNotEmpty;

  double get dispatchQuantity =>
      _readDouble(dispatchQuantityController.text, fallback: 0);
  double get acceptedQuantity =>
      _readDouble(acceptedQuantityController.text, fallback: 0);
  double get returnQuantity {
    final value = dispatchQuantity - acceptedQuantity;
    return value > 0 ? value : 0;
  }

  double get unitPrice => _readDouble(unitPriceController.text, fallback: 0);
  int get lotNo => _readInt(lotNoController.text, fallback: 0);
  DateTime? get lastConsumingDate {
    final raw = lastConsumingDateController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  void applyProduct(SearchProductLookupItem product) {
    selectedProduct = product;
    lookupController.clear();
    stockCodeController.text = product.stockCode;
    if (dispatchQuantityController.text.trim().isEmpty) {
      dispatchQuantityController.text = _formatDraftQuantity(
        _unitMultiplierQuantity(product.unitMultiplier),
      );
    }
    if (acceptedQuantityController.text.trim().isEmpty) {
      acceptedQuantityController.text = _formatDraftQuantity(
        _unitMultiplierQuantity(product.unitMultiplier),
      );
    }
    unitPriceController.text = product.price.toString();
    unitPointer = 1;
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

  void clear() {
    lookupController.clear();
    stockCodeController.clear();
    dispatchQuantityController.clear();
    acceptedQuantityController.clear();
    unitPriceController.text = '0';
    descriptionController.clear();
    partyCodeController.clear();
    lotNoController.text = '0';
    projectCodeController.clear();
    customerRcController.clear();
    productRcController.clear();
    lastConsumingDateController.clear();
    selectedProduct = null;
    orderGuid = null;
    unitPointer = 1;
    clearLookupStatus();
  }

  void dispose() {
    lookupFocusNode.dispose();
    lookupController.dispose();
    stockCodeController.dispose();
    dispatchQuantityController.dispose();
    acceptedQuantityController.dispose();
    unitPriceController.dispose();
    descriptionController.dispose();
    partyCodeController.dispose();
    lotNoController.dispose();
    projectCodeController.dispose();
    customerRcController.dispose();
    productRcController.dispose();
    lastConsumingDateController.dispose();
  }

  Map<String, dynamic> toDraftJson() {
    return <String, dynamic>{
      'lookup': lookupController.text,
      'stockCode': stockCodeController.text,
      'dispatchQuantity': dispatchQuantityController.text,
      'acceptedQuantity': acceptedQuantityController.text,
      'unitPrice': unitPriceController.text,
      'unitPointer': unitPointer,
      'description': descriptionController.text,
      'partyCode': partyCodeController.text,
      'lotNo': lotNoController.text,
      'projectCode': projectCodeController.text,
      'customerRc': customerRcController.text,
      'productRc': productRcController.text,
      'lastConsumingDate': lastConsumingDateController.text,
      'orderGuid': orderGuid,
      'selectedProduct': selectedProduct == null
          ? null
          : _acceptanceProductJson(selectedProduct!),
    };
  }

  void _notifyChanged() => onChanged?.call();
}

Map<String, dynamic>? _acceptanceDraftMap(Object? value) {
  return switch (value) {
    final Map<String, dynamic> map => Map<String, dynamic>.from(map),
    final Map map => map.map((key, item) => MapEntry(key.toString(), item)),
    _ => null,
  };
}

Map<String, dynamic> _acceptanceProductJson(SearchProductLookupItem item) {
  return <String, dynamic>{
    'warehouseNo': item.warehouseNo,
    'barcode': item.barcode,
    'stockCode': item.stockCode,
    'stockName': item.stockName,
    'price': item.price,
    'priceTypeCode': item.priceTypeCode,
    'unitName': item.unitName,
    'unitMultiplier': item.unitMultiplier,
    'secondaryUnitName': item.secondaryUnitName,
    'secondaryUnitMultiplier': item.secondaryUnitMultiplier,
    'salesBlockCode': item.salesBlockCode,
    'orderBlockCode': item.orderBlockCode,
    'goodsAcceptanceBlockCode': item.goodsAcceptanceBlockCode,
    'isSalesBlocked': item.isSalesBlocked,
    'isOrderBlocked': item.isOrderBlocked,
    'isGoodsAcceptanceBlocked': item.isGoodsAcceptanceBlocked,
    'productManagerCode': item.productManagerCode,
  };
}

double _readDouble(String value, {required double fallback}) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
}

int _readInt(String value, {required int fallback}) {
  return int.tryParse(value.trim()) ?? fallback;
}
