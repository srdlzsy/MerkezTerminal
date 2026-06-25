import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:furpa_merkez_terminal/shared/utils/client_request_id.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/utils/e_despatch_qr_parser.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

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
  late final CreateDraftSession _draftSession;

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
  }

  Future<void> _scanEDespatchQr() async {
    if (!supportsCameraBarcodeScanning) {
      setState(() {
        _lookupError =
            'Bu cihazda kamera ile e-irsaliye QR okutma desteklenmiyor.';
      });
      return;
    }

    final qrValue = await openBarcodeCameraScanner(
      context,
      title: 'E-Irsaliye QR',
      subtitle: 'Tedarikci irsaliyesindeki QR kodu okutun.',
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
        setState(() {
          _ettnController.text = ettn;
          _lastEDespatchPrefill = prefill;
          _isResolvingEDespatch = false;
          _lookupError = qrPayload.hasDocumentPrefill
              ? 'Bu ETTN ile gelen e-irsaliye bulunamadi; QR belge bilgileri forma aktarildi.'
              : 'Bu ETTN ile gelen e-irsaliye bulunamadi: $ettn';
        });
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

      await _fillCustomerFromQrSenderIfNeeded(qrPayload);

      final documentNo = prefill.despatchNumber.trim();
      _showFeedback(
        documentNo.isEmpty
            ? 'E-irsaliye bilgileri forma aktarildi.'
            : '$documentNo icin e-irsaliye bilgileri forma aktarildi.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isResolvingEDespatch = false;
        _lookupError = error.toString().replaceFirst('Exception: ', '');
      });

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
    final despatchNumber = prefill.despatchNumber.trim();
    if (despatchNumber.isNotEmpty) {
      _documentNoController.text = despatchNumber;
    }

    final issueDate = prefill.issueDate;
    if (issueDate != null) {
      _documentDate = _normalizedDate(issueDate);
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
      showDragHandle: true,
      builder: (context) {
        if (customers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: TerminalEmptyState(message: 'Cari bulunamadi.'),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          itemCount: customers.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = customers[index];
            return ListTile(
              title: Text(item.customerDisplayName),
              subtitle: Text(item.customerCode),
              onTap: () => Navigator.of(context).pop(item),
            );
          },
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
      return;
    }

    List<SearchProductLookupItem> products;
    try {
      setState(() {
        line.setLookupStatus('API araniyor: $query', isLoading: true);
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
      return;
    }

    setState(() {
      line.setLookupStatus(
        '${products.length} urun bulundu. Listeden secim bekleniyor.',
      );
    });

    final selected = await showModalBottomSheet<SearchProductLookupItem>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView.separated(
          shrinkWrap: true,
          itemCount: products.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = products[index];
            return ListTile(
              title: Text(item.displayLabel),
              subtitle: Text(
                '${item.unitName} | ${AppFormatters.currency(item.price)}',
              ),
              onTap: () => Navigator.of(context).pop(item),
            );
          },
        );
      },
    );

    if (selected == null) {
      if (mounted) {
        setState(() {
          line.setLookupStatus(
            '${products.length} sonuc geldi, secim yapilmadi.',
          );
        });
      }
      return;
    }

    var mergedIntoExisting = false;
    setState(() {
      mergedIntoExisting = _applyProductToLine(line, selected);
      if (!mergedIntoExisting) {
        line.setLookupStatus(
          'Secildi: ${selected.stockCode} | ${selected.stockName}',
        );
      }
      _ensureFreshEntryLine();
      _lookupError = null;
    });
    _draftSession.scheduleSave();
    _focusFreshEntryLine();

    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  Future<void> _scanProductWithCamera(_AcceptanceLineDraft line) async {
    if (!supportsCameraBarcodeScanning) {
      setState(() {
        _lookupError = 'Bu cihazda kamera ile barkod okutma desteklenmiyor.';
      });
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Mal Kabul Kamerasi',
      subtitle: 'Barkodu okutun; bulunan urun secim listesine aktarilacak.',
    );

    if (barcode == null || !mounted) {
      return;
    }

    setState(() {
      line.lookupController.text = barcode;
      line.setLookupStatus('Barkod okundu: $barcode. API aramasi basliyor.');
      _lookupError = null;
    });

    await _searchProduct(line);
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
        line.stockCodeController.text.trim().isEmpty &&
        line.lookupController.text.trim().isEmpty;
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
      showDragHandle: true,
      builder: (context) {
        if (orders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: TerminalEmptyState(message: 'Acik siparis bulunamadi.'),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          itemCount: orders.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = orders[index];
            return ListTile(
              title: Text(item.documentNoLabel),
              subtitle: Text(
                '${item.customerDisplayName} | Kalan ${AppFormatters.quantity(item.totalRemainingQuantity)}',
              ),
              onTap: () => Navigator.of(context).pop(item),
            );
          },
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
      setState(() {
        _lookupError = 'Cari kodu zorunludur.';
      });
      return;
    }

    if (_documentDate.isBefore(_movementDate)) {
      setState(() {
        _lookupError = 'Belge tarihi hareket tarihinden once olamaz.';
      });
      return;
    }

    final activeLines = _lines
        .where((line) => !_isBlankLine(line))
        .toList(growable: false);

    if (activeLines.isEmpty) {
      setState(() {
        _lookupError = 'En az bir urun satiri ekleyin.';
      });
      return;
    }

    final usedOrderGuids = <String>{};
    for (var index = 0; index < activeLines.length; index += 1) {
      final line = activeLines[index];
      if (line.stockCodeController.text.trim().isEmpty) {
        setState(() {
          _lookupError = '${index + 1}. satir icin urun secin.';
        });
        return;
      }

      if (line.dispatchQuantity <= 0) {
        setState(() {
          _lookupError =
              '${index + 1}. satir icin irsaliye miktari sifirdan buyuk olmali.';
        });
        return;
      }

      if (line.acceptedQuantity < 0) {
        setState(() {
          _lookupError =
              '${index + 1}. satir icin fiili kabul miktari negatif olamaz.';
        });
        return;
      }

      if (line.acceptedQuantity > line.dispatchQuantity) {
        setState(() {
          _lookupError =
              '${index + 1}. satirda fiili kabul irsaliye miktarini gecemez.';
        });
        return;
      }

      if (line.unitPointer <= 0 || line.unitPointer > 255) {
        setState(() {
          _lookupError = '${index + 1}. satir icin unitPointer 1-255 olmali.';
        });
        return;
      }

      if (line.lotNo < 0) {
        setState(() {
          _lookupError = '${index + 1}. satir icin lot no negatif olamaz.';
        });
        return;
      }

      final orderGuid = line.orderGuid?.trim() ?? '';
      if (orderGuid.isNotEmpty && !usedOrderGuids.add(orderGuid)) {
        setState(() {
          _lookupError =
              '${index + 1}. satirda ayni siparis satiri tekrar kullanilamaz.';
        });
        return;
      }
    }

    final request = CompanyAcceptanceCreateRequest(
      customerCode: customerCode,
      movementDate: _movementDate,
      documentDate: _documentDate,
      documentNo: _documentNoController.text.trim(),
      clientRequestId: generateClientRequestId(),
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

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        autovalidateMode: createFormAutovalidateMode,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            const TerminalSheetHeader(
              title: 'Yeni Firma Mal Kabul',
              subtitle:
                  'Ayni fis icinde siparisli ve siparissiz satirlar bir arada gidebilir. Siparisli satirlarda orderGuid otomatik tasinir.',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            _buildEDespatchLookupRow(),
            if (_lastEDespatchPrefill != null) ...<Widget>[
              const SizedBox(height: 10),
              TerminalMessageBlock.info(
                message: _eDespatchSummaryMessage(_lastEDespatchPrefill!),
              ),
            ],
            const SizedBox(height: 12),
            _buildCustomerLookupRow(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerCodeController,
              decoration: const InputDecoration(
                labelText: 'Cari Kodu*',
                hintText: 'Internet yoksa elle girin',
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
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentNoController,
              decoration: const InputDecoration(
                labelText: 'Belge No / Seri',
                hintText: 'Bos birakilabilir veya ULK gibi seri girilebilir',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    controller: _delivererController,
                    decoration: const InputDecoration(labelText: 'Teslim Eden'),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    controller: _receiverController,
                    decoration: const InputDecoration(labelText: 'Teslim Alan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Aciklama'),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _allowOrderOverReceiving,
              title: const Text(
                'Siparis kalanindan fazla kabul etmeye izin ver',
              ),
              subtitle: const Text(
                'Backend fazla miktari siparissiz hareket olarak ayirabilir.',
              ),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _allowOrderOverReceiving = value ?? false;
                });
                _draftSession.scheduleSave();
              },
            ),
            CheckboxListTile(
              value: _autoCreateReturnForPartialAcceptance,
              title: const Text('Eksik kabul farki icin firma iadesi olustur'),
              subtitle: const Text(
                'E-irsaliye otomatik gonderilmez; iade evragindan manuel gonderilir.',
              ),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _autoCreateReturnForPartialAcceptance = value ?? true;
                });
                _draftSession.scheduleSave();
              },
            ),
            const SizedBox(height: 8),
            _buildLinesToolbar(),
            const SizedBox(height: 10),
            ..._lines.asMap().entries.map((entry) {
              final index = entry.key;
              final line = entry.value;
              final isFreshEntry = index == 0 && _isBlankLine(line);
              final displayLineNo = _lines
                  .take(index + 1)
                  .where((item) => !_isBlankLine(item))
                  .length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withAlpha(90),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              isFreshEntry
                                  ? 'Giris satiri'
                                  : 'Satir $displayLineNo',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (line.orderGuid != null &&
                              line.orderGuid!.isNotEmpty)
                            const TerminalBadge(label: 'Siparisli'),
                          if (!isFreshEntry && _lines.length > 1)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  line.dispose();
                                  _lines.removeAt(index);
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                        ],
                      ),
                      _buildProductLookupRow(line),
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
                      if (line.selectedProduct != null) ...<Widget>[
                        const SizedBox(height: 8),
                        TerminalMessageBlock.info(
                          message:
                              '${line.selectedProduct!.stockCode} | ${line.selectedProduct!.stockName} | ${line.selectedProduct!.unitName} | ${AppFormatters.currency(line.selectedProduct!.price)}',
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildQuantityFields(line),
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
            }),
            if (_lookupError != null) ...<Widget>[
              TerminalMessageBlock.error(message: _lookupError!),
              const SizedBox(height: 12),
            ],
            _buildFormActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildEDespatchLookupRow() {
    final lookupField = TerminalSubmitOnTab(
      enabled: !_isResolvingEDespatch,
      onSubmit: _resolveEDespatchFromInput,
      child: TextFormField(
        controller: _ettnController,
        textInputAction: TextInputAction.search,
        onFieldSubmitted: (_) => _resolveEDespatchFromInput(),
        decoration: const InputDecoration(
          labelText: 'E-Irsaliye ETTN / QR',
          hintText: 'QR okutun veya UUID girin',
          suffixIcon: Icon(Icons.qr_code_2_rounded),
        ),
      ),
    );

    final resolveButton = FilledButton.icon(
      onPressed: _isResolvingEDespatch ? null : _resolveEDespatchFromInput,
      icon: _isResolvingEDespatch
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.fact_check_rounded),
      label: Text(_isResolvingEDespatch ? 'Sorgu' : 'Cozumle'),
    );

    final scanButton = IconButton.filledTonal(
      onPressed: _isResolvingEDespatch ? null : _scanEDespatchQr,
      tooltip: 'E-irsaliye QR oku',
      icon: const Icon(Icons.qr_code_scanner_rounded),
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
            Expanded(child: lookupField),
            const SizedBox(width: 12),
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
      ),
    );

    final searchButton = FilledButton.icon(
      onPressed: _searchCustomer,
      icon: const Icon(Icons.search_rounded),
      label: const Text('Bul'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              lookupField,
              const SizedBox(height: 8),
              searchButton,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: lookupField),
            const SizedBox(width: 12),
            searchButton,
          ],
        );
      },
    );
  }

  Widget _buildLinesToolbar() {
    final title = Text(
      'Satirlar',
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );

    final orderButton = OutlinedButton.icon(
      onPressed: _customerCodeController.text.trim().isEmpty
          ? null
          : _addLinesFromOpenOrders,
      icon: const Icon(Icons.link_rounded),
      label: const Text('Siparis Bagla'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              title,
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: <Widget>[orderButton]),
            ],
          );
        }

        return Row(children: <Widget>[title, const Spacer(), orderButton]);
      },
    );
  }

  Widget _buildFormActions() {
    final cancelButton = OutlinedButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Vazgec'),
    );

    final submitButton = FilledButton.icon(
      onPressed: _submit,
      icon: const Icon(Icons.save_alt_rounded),
      label: const Text('Mal Kabul Et'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              cancelButton,
              const SizedBox(height: 10),
              submitButton,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: cancelButton),
            const SizedBox(width: 12),
            Expanded(child: submitButton),
          ],
        );
      },
    );
  }

  Widget _buildProductLookupRow(_AcceptanceLineDraft line) {
    final lookupField = TerminalSubmitOnTab(
      enabled: !line.isLookupStatusLoading,
      onSubmit: () => _searchProduct(line),
      child: TextFormField(
        controller: line.lookupController,
        focusNode: line.lookupFocusNode,
        textInputAction: TextInputAction.search,
        onFieldSubmitted: (_) => _searchProduct(line),
        decoration: const InputDecoration(
          labelText: 'Barkod / stok kodu / urun adi',
          hintText: 'Arama veya barkod',
        ),
        validator: (_) {
          if (_isBlankLine(line)) {
            return null;
          }

          if (line.stockCodeController.text.trim().isEmpty) {
            return 'Urun secin';
          }
          return null;
        },
      ),
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
      return TextFormField(
        controller: line.dispatchQuantityController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
        ],
        decoration: const InputDecoration(labelText: 'Irsaliye Miktari*'),
        onChanged: (_) => setState(() {}),
        validator: (_) {
          if (_isBlankLine(line)) {
            return null;
          }

          if (line.dispatchQuantity <= 0) {
            return 'Miktar > 0';
          }
          return null;
        },
      );
    }

    Widget acceptedField() {
      return TextFormField(
        controller: line.acceptedQuantityController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
        ],
        decoration: const InputDecoration(labelText: 'Fiili Kabul*'),
        onChanged: (_) => setState(() {}),
        validator: (_) {
          if (_isBlankLine(line)) {
            return null;
          }

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

  String _eDespatchSummaryMessage(CompanyAcceptanceEDespatchPrefill prefill) {
    if (!prefill.isFound) {
      return 'E-irsaliye bulunamadi. ETTN: ${prefill.ettn}';
    }

    final suggestedCustomer = _preferredCustomerSuggestion(prefill);
    final parts = <String>[
      if (prefill.despatchNumber.trim().isNotEmpty)
        'Belge: ${prefill.despatchNumber}',
      'Irsaliye satiri: ${prefill.totalLineCount}',
      'Kalemler manuel girilecek',
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
    lookupController.text = product.displayLabel;
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
