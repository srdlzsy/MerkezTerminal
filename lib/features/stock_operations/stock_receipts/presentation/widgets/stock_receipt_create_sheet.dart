import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/models/stock_receipt_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/stock_receipts_repository.dart';
import 'package:furpa_merkez_terminal/shared/data/barcode_resolution_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_session.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_controller.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/utils/terminal_feedback.dart';
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
      _refocusLine(line.lookupFocusNode);
      return;
    }

    if (await _tryResolveBarcode(line, query)) {
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

    var mergedIntoExisting = false;
    setState(() {
      mergedIntoExisting = _applyProductToLine(line, pickedProduct);
      if (!mergedIntoExisting) {
        line.setLookupStatus(
          'Secildi: ${pickedProduct.stockCode} | ${pickedProduct.stockName}',
        );
      }
      _ensureFreshEntryLine();
      _lookupError = null;
    });
    _draftSession.scheduleSave();
    _focusFreshEntryLine();

    if (mergedIntoExisting) {
      unawaited(TerminalFeedback.success());
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    } else {
      unawaited(TerminalFeedback.success());
    }
  }

  Future<bool> _tryResolveBarcode(
    _StockReceiptLineDraft line,
    String query,
  ) async {
    if (!looksLikeDirectBarcodeInput(query)) {
      return false;
    }

    setState(() {
      line.setLookupStatus('Barkod cozumleniyor: $query', isLoading: true);
      _lookupError = null;
    });

    BarcodeResolutionResult resolution;
    try {
      resolution = await widget.repository.resolveBarcode(
        accessToken: widget.accessToken,
        request: BarcodeResolutionRequest(
          barcode: query,
          warehouseNo: widget.defaultWarehouseNo,
          operationType: 'waste',
          screenCode: widget.kind.pathSegment,
        ),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 0 || error.statusCode == 404) {
        if (mounted) {
          setState(() {
            line.clearLookupStatus();
            _lookupError = null;
          });
        }
        return false;
      }

      if (!mounted) {
        return true;
      }
      final message = error.detail ?? error.title;
      setState(() {
        line.setLookupStatus(message, isError: true);
        _lookupError = null;
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
        _lookupError = null;
      });
      _showFeedback(message);
      unawaited(TerminalFeedback.error());
      _refocusLine(line.lookupFocusNode);
      return true;
    }

    final product = SearchProductLookupItem.fromBarcodeResolution(resolution);
    final addedQuantity = resolution.suggestedQuantity;
    var mergedIntoExisting = false;
    setState(() {
      line.quantityController.text = productEntryController.formatQuantity(
        addedQuantity,
      );
      mergedIntoExisting = _applyProductToLine(line, product);
      if (!mergedIntoExisting) {
        line.setLookupStatus(_resolvedBarcodeMessage(resolution));
      }
      _ensureFreshEntryLine();
      _lookupError = null;
    });
    _draftSession.scheduleSave();
    _focusFreshEntryLine();
    _notifyResolvedBarcodeResult(
      product: product,
      resolution: resolution,
      addedQuantity: addedQuantity,
      mergedIntoExisting: mergedIntoExisting,
      totalQuantity: _lineQuantityFor(product),
    );
    return true;
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
      _refocusLine(line.lookupFocusNode);
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: '${widget.kind.createTitle} Kamerasi',
      subtitle: 'Barkodu okutun; bulunan urun satira eklenecek.',
    );

    if (barcode == null) {
      _refocusLine(line.lookupFocusNode);
      return;
    }

    if (!mounted) {
      return;
    }

    line.lookupController.text = barcode;
    setState(() {
      line.setLookupStatus('Barkod okundu: $barcode. Urun araniyor.');
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
    return line.selectedProduct == null;
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
      padding: EdgeInsets.fromLTRB(12, 6, 12, 12 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        autovalidateMode: createFormAutovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TerminalSheetHeader(
              title: widget.kind.createTitle,
              subtitle:
                  'Creator ve acceptor alanlari evrak notu gibi calisir. Satirlar yalnizca secilen kullanici deposu icin cikis hareketine doner.',
              badges: <Widget>[
                TerminalLineCountBadge(count: _filledLineIndexes().length),
              ],
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            _buildReceiptSetupSection(),
            const SizedBox(height: 6),
            TerminalSectionToolbar(
              title: 'Satirlar',
              actions: const <Widget>[],
            ),
            const SizedBox(height: 6),
            _buildEntryLineCard(),
            const SizedBox(height: 8),
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
                            label: const Text('Kaydet'),
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

  Widget _buildReceiptSetupSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final twoColumn = maxWidth >= 300;
        final fieldWidth = twoColumn ? (maxWidth - 8) / 2 : maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                SizedBox(
                  width: fieldWidth,
                  child: TextFormField(
                    controller: _creatorController,
                    decoration: const InputDecoration(
                      labelText: 'Creator',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: TextFormField(
                    controller: _acceptorController,
                    decoration: const InputDecoration(
                      labelText: 'Acceptor',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
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
          ],
        );
      },
    );
  }

  Widget _buildEntryLineCard() {
    final entryIndex = _lines.indexWhere(_isBlankLine);
    return _buildLineCard(entryIndex == -1 ? 0 : entryIndex);
  }

  Widget _buildLazyLineSliver() {
    final indexes = _filledLineIndexes();
    if (indexes.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, visibleIndex) => _buildLineCard(indexes[visibleIndex]),
        childCount: indexes.length,
      ),
    );
  }

  List<int> _filledLineIndexes() {
    return <int>[
      for (var index = 0; index < _lines.length; index++)
        if (!_isBlankLine(_lines[index])) index,
    ];
  }

  Widget _buildLineCard(int index) {
    final line = _lines[index];
    final isFreshEntry = index == 0 && _isBlankLine(line);
    final displayLineNo = _lines
        .take(index + 1)
        .where((item) => !_isBlankLine(item))
        .length;
    final product = line.selectedProduct;

    if (!isFreshEntry && product != null) {
      return TerminalCompactProductLineCard(
        lineNo: displayLineNo,
        stockCode: product.stockCode,
        stockName: product.stockName,
        quantityController: line.quantityController,
        unitLabel: product.unitName,
        barcode: product.barcode,
        canDelete: _lines.length > 1,
        onDelete: () => _removeLineAt(index),
        onMinimumReached: _lines.length > 1 ? () => _removeLineAt(index) : null,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
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
              )
            else if (line.selectedProduct != null)
              TerminalPdaInfoGrid(
                minTileWidth: 92,
                items: <TerminalPdaInfo>[
                  TerminalPdaInfo(
                    label: 'Kod',
                    value: line.selectedProduct!.stockCode,
                  ),
                  TerminalPdaInfo(
                    label: 'Birim',
                    value: line.selectedProduct!.unitName,
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
                    return 'Miktar > 0';
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
    });
    _draftSession.scheduleSave();
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

  void _notifyResolvedBarcodeResult({
    required SearchProductLookupItem product,
    required BarcodeResolutionResult resolution,
    required double addedQuantity,
    required bool mergedIntoExisting,
    required double totalQuantity,
  }) {
    final warning = resolution.quickWarningMessage;
    if (warning.isNotEmpty) {
      unawaited(TerminalFeedback.warning());
      _showFeedback(warning);
      return;
    }

    unawaited(TerminalFeedback.success());
    final unitName = product.unitName.trim();
    final quantityLabel =
        '${AppFormatters.quantity(addedQuantity)}${unitName.isEmpty ? '' : ' $unitName'}';
    if (mergedIntoExisting) {
      _showFeedback(
        'Urun zaten sepetteydi. +${AppFormatters.quantity(addedQuantity)} '
        'eklendi. Toplam: ${AppFormatters.quantity(totalQuantity)} '
        '${product.unitName}.',
      );
    } else {
      _showFeedback('Eklendi: ${product.stockName}. Miktar: $quantityLabel.');
    }
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

  double _lineQuantityFor(SearchProductLookupItem product) {
    for (final line in _lines) {
      final selected = line.selectedProduct;
      if (selected == null || selected.stockCode != product.stockCode) {
        continue;
      }

      return productEntryController.readQuantity(
        line.quantityController.text,
        fallback: 0,
      );
    }

    return 0;
  }

  void _refocusLine(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focusNode.requestFocus();
      }
    });
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

  void clearLookupStatus() {
    lookupStatusMessage = null;
    isLookupStatusLoading = false;
    isLookupStatusError = false;
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
