import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/models/stock_receipt_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/stock_receipts_repository.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_session.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_controller.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class StockReceiptCreateSheet extends StatefulWidget {
  const StockReceiptCreateSheet({
    super.key,
    required this.repository,
    required this.kind,
    required this.accessToken,
    required this.defaultWarehouseNo,
    this.draft,
    this.draftRepository,
  });

  final StockReceiptsRepository repository;
  final StockReceiptKind kind;
  final String accessToken;
  final String defaultWarehouseNo;
  final CreateDraft? draft;
  final CreateDraftRepository? draftRepository;

  @override
  State<StockReceiptCreateSheet> createState() =>
      _StockReceiptCreateSheetState();
}

class _StockReceiptCreateSheetState extends State<StockReceiptCreateSheet>
    with CreateFormValidation {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<_StockReceiptLineDraft> _lines = <_StockReceiptLineDraft>[];
  late final TextEditingController _creatorController;
  late final TextEditingController _acceptorController;
  late final TextEditingController _documentNoController;
  late final TextEditingController _descriptionController;
  late DateTime _movementDate;
  late DateTime _documentDate;
  String? _lookupError;
  late final CreateDraftSession _draftSession;

  bool get _showDocumentNoField => widget.kind != StockReceiptKind.expense;

  @override
  void initState() {
    super.initState();
    final payload = widget.draft?.payload ?? const <String, dynamic>{};
    _creatorController = TextEditingController(
      text: payload['creator']?.toString() ?? '',
    );
    _acceptorController = TextEditingController(
      text: payload['acceptor']?.toString() ?? '',
    );
    _documentNoController = TextEditingController(
      text: payload['documentNo']?.toString() ?? '',
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
    _draftSession = CreateDraftSession(
      draft: widget.draft,
      repository: widget.draftRepository,
      hasContent: _hasDraftContent,
      buildPayload: _buildDraftPayload,
      buildTitle: () => _descriptionController.text.trim().isEmpty
          ? widget.kind.createTitle
          : '${widget.kind.createTitle} - ${_descriptionController.text.trim()}',
    );
    final rawLines = payload['lines'];
    _lines.addAll(
      rawLines is List
          ? rawLines
                .map(_stockReceiptDraftMap)
                .whereType<Map<String, dynamic>>()
                .map(_createLine)
          : const <_StockReceiptLineDraft>[],
    );
    _ensureFreshEntryLine();
    _draftSession.listenTo(<TextEditingController>[
      _creatorController,
      _acceptorController,
      _documentNoController,
      _descriptionController,
    ]);
  }

  @override
  void dispose() {
    _draftSession.dispose();
    _creatorController.dispose();
    _acceptorController.dispose();
    _documentNoController.dispose();
    _descriptionController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  _StockReceiptLineDraft _createLine([Map<String, dynamic>? draft]) {
    return _StockReceiptLineDraft(
      draft: draft,
      onChanged: _draftSession.scheduleSave,
    );
  }

  bool _hasDraftContent() {
    final today = _normalizeDate(DateTime.now());
    return _creatorController.text.trim().isNotEmpty ||
        _acceptorController.text.trim().isNotEmpty ||
        _documentNoController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        !_isSameDate(_movementDate, today) ||
        !_isSameDate(_documentDate, today) ||
        _lines.any((line) => line.hasContent);
  }

  Map<String, dynamic> _buildDraftPayload() {
    return <String, dynamic>{
      'creator': _creatorController.text,
      'acceptor': _acceptorController.text,
      'documentNo': _documentNoController.text,
      'description': _descriptionController.text,
      'movementDate': _movementDate.toIso8601String(),
      'documentDate': _documentDate.toIso8601String(),
      'lines': _lines
          .where((line) => line.hasContent)
          .map((line) => line.toDraftJson())
          .toList(growable: false),
    };
  }

  Future<void> _searchProduct(_StockReceiptLineDraft line) async {
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

      products = await widget.repository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        query: query,
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

  Future<void> _scanProductWithCamera(_StockReceiptLineDraft line) async {
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
      title: '${widget.kind.createTitle} Kamerasi',
      subtitle: 'Barkodu okutun; bulunan urun satira eklenecek.',
    );

    if (barcode == null || !mounted) {
      return;
    }

    line.lookupController.text = barcode;
    setState(() {
      line.setLookupStatus('Barkod okundu: $barcode. API aramasi basliyor.');
    });
    await _searchProduct(line);
  }

  bool _applyProductToLine(
    _StockReceiptLineDraft line,
    SearchProductLookupItem product,
  ) {
    final existingLine = productEntryController.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<_StockReceiptLineDraft>(
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
    _StockReceiptLineDraft line, {
    required _StockReceiptLineDraft Function() createReplacement,
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

  bool _isBlankLine(_StockReceiptLineDraft line) {
    return line.selectedProduct == null &&
        line.lookupController.text.trim().isEmpty;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;

    if (form == null || !validateCreateForm(_formKey)) {
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

    if (activeLines.any((line) => line.selectedProduct == null)) {
      setState(() {
        _lookupError = 'Tum satirlarda urun secimi tamamlanmali.';
      });
      return;
    }

    final request = StockReceiptCreateRequest(
      creator: _creatorController.text.trim(),
      acceptor: _acceptorController.text.trim(),
      movementDate: _movementDate,
      documentDate: _documentDate,
      documentNo: _showDocumentNoField ? _documentNoController.text.trim() : '',
      description: _descriptionController.text.trim(),
      lines: activeLines
          .map(
            (line) => StockReceiptCreateLine(
              stockCode: line.selectedProduct!.stockCode,
              quantity: line.quantity,
              unitPointer: line.unitPointer,
              description: line.descriptionController.text.trim(),
              partyCode: line.partyCodeController.text.trim(),
              lotNo: line.lotNo,
              projectCode: line.projectCodeController.text.trim(),
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
            TerminalSheetHeader(
              title: widget.kind.createTitle,
              subtitle:
                  'Creator ve acceptor alanlari evrak notu gibi calisir. Satirlar yalnizca secilen kullanici deposu icin cikis hareketine doner.',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    controller: _creatorController,
                    decoration: const InputDecoration(labelText: 'Creator'),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    controller: _acceptorController,
                    decoration: const InputDecoration(labelText: 'Acceptor'),
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
            TerminalSectionToolbar(
              title: 'Satirlar',
              actions: const <Widget>[],
            ),
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
                          if (_lines.length > 1)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  line.dispose();
                                  _lines.removeAt(index);
                                });
                                _draftSession.scheduleSave();
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                        ],
                      ),
                      TerminalResponsiveLookupRow(
                        field: ProductLookupField(
                          controller: line.lookupController,
                          focusNode: line.lookupFocusNode,
                          enabled: !line.isLookupStatusLoading,
                          onSubmit: () => _searchProduct(line),
                          validator: (_) {
                            if (_isBlankLine(line)) {
                              return null;
                            }

                            if (line.selectedProduct == null) {
                              return 'Urun secilmeli.';
                            }

                            return null;
                          },
                        ),
                        action: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: line.isLookupStatusLoading
                                  ? null
                                  : () => _searchProduct(line),
                              icon: const Icon(Icons.search_rounded),
                              label: const Text('Urun'),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: line.isLookupStatusLoading
                                  ? null
                                  : () => _scanProductWithCamera(line),
                              tooltip: 'Kamera ile oku',
                              icon: const Icon(Icons.photo_camera_back_rounded),
                            ),
                          ],
                        ),
                      ),
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
                              '${line.selectedProduct!.stockCode} | ${line.selectedProduct!.stockName} | ${line.selectedProduct!.unitName}',
                        ),
                      ],
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: line.quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9,\.]'),
                          ),
                        ],
                        decoration: const InputDecoration(labelText: 'Miktar'),
                        validator: (_) {
                          if (_isBlankLine(line)) {
                            return null;
                          }

                          if (line.quantity <= 0) {
                            return 'Miktar > 0';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
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
                label: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
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

class _StockReceiptLineDraft {
  _StockReceiptLineDraft({Map<String, dynamic>? draft, this.onChanged})
    : lookupController = TextEditingController(),
      quantityController = TextEditingController(),
      unitPointerController = TextEditingController(text: '1'),
      descriptionController = TextEditingController(),
      partyCodeController = TextEditingController(),
      lotNoController = TextEditingController(text: '0'),
      projectCodeController = TextEditingController() {
    if (draft != null) {
      lookupController.text = draft['lookup']?.toString() ?? '';
      quantityController.text = draft['quantity']?.toString() ?? '';
      unitPointerController.text = draft['unitPointer']?.toString() ?? '1';
      descriptionController.text = draft['description']?.toString() ?? '';
      partyCodeController.text = draft['partyCode']?.toString() ?? '';
      lotNoController.text = draft['lotNo']?.toString() ?? '0';
      projectCodeController.text = draft['projectCode']?.toString() ?? '';
      lookupStatusMessage = draft['lookupStatusMessage']?.toString();
      final productJson = _stockReceiptDraftMap(draft['selectedProduct']);
      if (productJson != null) {
        selectedProduct = SearchProductLookupItem.fromJson(productJson);
      }
    }
    for (final controller in _controllers) {
      controller.addListener(_notifyChanged);
    }
  }

  final TextEditingController lookupController;
  final TextEditingController quantityController;
  final TextEditingController unitPointerController;
  final TextEditingController descriptionController;
  final TextEditingController partyCodeController;
  final TextEditingController lotNoController;
  final TextEditingController projectCodeController;
  final FocusNode lookupFocusNode = FocusNode();
  final VoidCallback? onChanged;

  SearchProductLookupItem? selectedProduct;
  String? lookupStatusMessage;
  bool isLookupStatusLoading = false;
  bool isLookupStatusError = false;

  double get quantity =>
      productEntryController.readQuantity(quantityController.text, fallback: 0);
  int get unitPointer => _readInt(unitPointerController.text, fallback: 1);
  int get lotNo => _readInt(lotNoController.text, fallback: 0);

  List<TextEditingController> get _controllers => <TextEditingController>[
    lookupController,
    quantityController,
    unitPointerController,
    descriptionController,
    partyCodeController,
    lotNoController,
    projectCodeController,
  ];

  bool get hasContent =>
      selectedProduct != null ||
      lookupController.text.trim().isNotEmpty ||
      quantityController.text.trim().isNotEmpty ||
      unitPointerController.text.trim() != '1' ||
      descriptionController.text.trim().isNotEmpty ||
      partyCodeController.text.trim().isNotEmpty ||
      (lotNoController.text.trim().isNotEmpty &&
          lotNoController.text.trim() != '0') ||
      projectCodeController.text.trim().isNotEmpty;

  void applyProduct(SearchProductLookupItem product) {
    selectedProduct = product;
    lookupController.text = product.displayLabel;
    if (quantityController.text.trim().isEmpty) {
      quantityController.text = productEntryController.formatQuantity(
        productEntryController.unitMultiplierQuantity(product.unitMultiplier),
      );
    }
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
    quantityController.dispose();
    unitPointerController.dispose();
    descriptionController.dispose();
    partyCodeController.dispose();
    lotNoController.dispose();
    projectCodeController.dispose();
  }

  Map<String, dynamic> toDraftJson() {
    return <String, dynamic>{
      'lookup': lookupController.text,
      'quantity': quantityController.text,
      'unitPointer': unitPointerController.text,
      'description': descriptionController.text,
      'partyCode': partyCodeController.text,
      'lotNo': lotNoController.text,
      'projectCode': projectCodeController.text,
      'lookupStatusMessage': lookupStatusMessage,
      'selectedProduct': selectedProduct == null
          ? null
          : _stockReceiptProductJson(selectedProduct!),
    };
  }

  void _notifyChanged() => onChanged?.call();
}

int _readInt(String value, {required int fallback}) {
  return int.tryParse(value.trim()) ?? fallback;
}

DateTime _normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

Map<String, dynamic>? _stockReceiptDraftMap(Object? value) {
  return switch (value) {
    final Map<String, dynamic> map => Map<String, dynamic>.from(map),
    final Map map => map.map((key, item) => MapEntry(key.toString(), item)),
    _ => null,
  };
}

Map<String, dynamic> _stockReceiptProductJson(SearchProductLookupItem item) {
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
