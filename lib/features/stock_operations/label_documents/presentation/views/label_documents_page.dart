import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/label_documents/data/label_documents_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/label_documents/data/models/label_document_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_picker.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_session.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_controller.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

enum _LabelDocumentsMode { recent, all }

class LabelDocumentsPage extends StatefulWidget {
  const LabelDocumentsPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.canCreate,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
    required this.currentUserId,
    this.draftRepository,
  });

  final LabelDocumentsRepository repository;
  final String accessToken;
  final bool canCreate;
  final String defaultWarehouseNo;
  final String userWarehouseName;
  final String currentUserId;
  final CreateDraftRepository? draftRepository;

  @override
  State<LabelDocumentsPage> createState() => _LabelDocumentsPageState();
}

class _LabelDocumentsPageState extends State<LabelDocumentsPage> {
  _LabelDocumentsMode _mode = _LabelDocumentsMode.recent;
  bool _isLoading = false;
  bool _isCreating = false;
  String? _errorMessage;
  List<LabelDocumentListItem> _documents = const <LabelDocumentListItem>[];
  List<LabelDocumentProduct> _selectedDocumentProducts =
      const <LabelDocumentProduct>[];
  LabelDocumentListItem? _selectedDocument;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCurrentMode());
  }

  Future<void> _loadCurrentMode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final documents = switch (_mode) {
        _LabelDocumentsMode.recent => widget.repository.fetchRecentDocuments(
          accessToken: widget.accessToken,
          warehouseNo: widget.defaultWarehouseNo,
        ),
        _LabelDocumentsMode.all => widget.repository.fetchAllDocuments(
          accessToken: widget.accessToken,
          warehouseNo: widget.defaultWarehouseNo,
        ),
      };

      final loadedDocuments = await documents;
      final selectedDocument = loadedDocuments.isEmpty
          ? null
          : loadedDocuments.first;
      final selectedProducts = selectedDocument == null
          ? const <LabelDocumentProduct>[]
          : await widget.repository.fetchDocumentProducts(
              accessToken: widget.accessToken,
              documentId: selectedDocument.documentId,
              warehouseNo: widget.defaultWarehouseNo,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = loadedDocuments;
        _selectedDocument = selectedDocument;
        _selectedDocumentProducts = selectedProducts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _selectDocument(LabelDocumentListItem item) async {
    setState(() {
      _selectedDocument = item;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await widget.repository.fetchDocumentProducts(
        accessToken: widget.accessToken,
        documentId: item.documentId,
        warehouseNo: widget.defaultWarehouseNo,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedDocumentProducts = detail;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openCreateSheet() async {
    CreateDraft? draft;
    if (widget.draftRepository != null) {
      final launch = await showCreateDraftPicker(
        context: context,
        repository: widget.draftRepository!,
        moduleKey: 'kasa-islemleri.etiket-belgeleri',
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        createTitle: 'Yeni Etiket Belgesi',
      );
      if (launch == null || !mounted) {
        return;
      }
      draft =
          launch.draft ??
          CreateDraft.empty(
            moduleKey: 'kasa-islemleri.etiket-belgeleri',
            userId: widget.currentUserId,
            warehouseNo: widget.defaultWarehouseNo,
            title: 'Yeni Etiket Belgesi',
          );
    }

    final request = await showModalBottomSheet<CreateLabelDocumentRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return _LabelDocumentCreateSheet(
          repository: widget.repository,
          accessToken: widget.accessToken,
          defaultWarehouseNo: widget.defaultWarehouseNo,
          draft: draft,
          draftRepository: widget.draftRepository,
        );
      },
    );

    if (request == null || !mounted) {
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.repository.createDocument(
        accessToken: widget.accessToken,
        request: request,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isCreating = false;
        _mode = _LabelDocumentsMode.recent;
      });
      await _loadCurrentMode();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Etiket belgesi #${result.documentId} olusturuldu. ${result.lineCount} satir.',
          ),
        ),
      );
      if (draft != null) {
        await widget.draftRepository?.deleteDraft(draft.id);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCreating = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          20 + MediaQuery.paddingOf(context).bottom,
        ),
        children: <Widget>[
          _buildHeader(),
          const SizedBox(height: 16),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return TerminalListHeaderCard(
      title: 'Etiket Belgeleri',
      subtitle:
          'Etiket belgelerini listeleyin, detaylari acin ve yeni belge olusturun.',
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Varsayilan depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(
          label: 'Mod',
          value: switch (_mode) {
            _LabelDocumentsMode.recent => 'Son Belgeler',
            _LabelDocumentsMode.all => 'Tum Gecmis',
          },
        ),
      ],
      filters: <Widget>[
        ChoiceChip(
          label: const Text('Son Belgeler'),
          selected: _mode == _LabelDocumentsMode.recent,
          onSelected: (_) {
            setState(() => _mode = _LabelDocumentsMode.recent);
            unawaited(_loadCurrentMode());
          },
        ),
        ChoiceChip(
          label: const Text('Tum Gecmis'),
          selected: _mode == _LabelDocumentsMode.all,
          onSelected: (_) {
            setState(() => _mode = _LabelDocumentsMode.all);
            unawaited(_loadCurrentMode());
          },
        ),
      ],
      actions: <Widget>[
        FilledButton.icon(
          onPressed: _isLoading ? null : _loadCurrentMode,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Yenile'),
        ),
        if (widget.canCreate)
          FilledButton.tonalIcon(
            onPressed: _isCreating ? null : _openCreateSheet,
            icon: _isCreating
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined),
            label: Text(
              _isCreating ? 'Kaydediliyor...' : 'Yeni Etiket Belgesi',
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return SectionCard(
        title: 'Etiket Belgeleri',
        subtitle: 'Islem sirasinda hata olustu.',
        child: TerminalMessageBlock.error(message: _errorMessage!),
      );
    }

    if (_isLoading) {
      return const SectionCard(
        title: 'Etiket Belgeleri',
        subtitle: 'Yukleniyor...',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return SectionCard(
      title: 'Etiket Belgeleri',
      subtitle: '${_documents.length} belge bulundu.',
      child: _buildDocumentsView(),
    );
  }

  Widget _buildDocumentsView() {
    if (_documents.isEmpty) {
      return const TerminalEmptyState(message: 'Etiket belgesi bulunamadi.');
    }

    return Column(
      children: <Widget>[
        ..._documents.map((item) {
          final isSelected = _selectedDocument?.documentId == item.documentId;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _selectDocument(item),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TerminalLabeledValue(
                              label: 'Belge Id',
                              value: '#${item.documentId}',
                            ),
                          ),
                          Expanded(
                            child: TerminalLabeledValue(
                              label: 'Olusturma',
                              value: AppFormatters.dateTimeOrDash(
                                item.createDate,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isSelected) ...<Widget>[
                        const SizedBox(height: 12),
                        if (_selectedDocumentProducts.isEmpty)
                          const TerminalEmptyState(
                            message: 'Bu belgeye bagli urun bulunamadi.',
                          )
                        else
                          ..._selectedDocumentProducts.map((product) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant.withAlpha(82),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      product.productName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Kod ${product.productCode} | Barkod ${product.barcode.isEmpty ? '-' : product.barcode} | Fiyat ${AppFormatters.currency(product.price)}${product.oldPrice > 0 ? ' | Eski ${AppFormatters.currency(product.oldPrice)}' : ''}',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _LabelDocumentCreateSheet extends StatefulWidget {
  const _LabelDocumentCreateSheet({
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    this.draft,
    this.draftRepository,
  });

  final LabelDocumentsRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;
  final CreateDraft? draft;
  final CreateDraftRepository? draftRepository;

  @override
  State<_LabelDocumentCreateSheet> createState() =>
      _LabelDocumentCreateSheetState();
}

class _LabelDocumentCreateSheetState extends State<_LabelDocumentCreateSheet> {
  late final List<_LabelDocumentLineDraft> _lines;
  String? _errorMessage;
  late final CreateDraftSession _draftSession;

  @override
  void initState() {
    super.initState();
    _draftSession = CreateDraftSession(
      draft: widget.draft,
      repository: widget.draftRepository,
      hasContent: _hasDraftContent,
      buildPayload: _buildDraftPayload,
      buildTitle: () => 'Yeni Etiket Belgesi',
    );
    final rawLines = widget.draft?.payload['lines'];
    _lines = rawLines is List
        ? rawLines
              .map(_labelDraftMap)
              .whereType<Map<String, dynamic>>()
              .map(_createLine)
              .toList(growable: true)
        : <_LabelDocumentLineDraft>[];
    _ensureFreshEntryLine();
  }

  @override
  void dispose() {
    _draftSession.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  _LabelDocumentLineDraft _createLine([Map<String, dynamic>? draft]) {
    return _LabelDocumentLineDraft(
      draft: draft,
      onChanged: _draftSession.scheduleSave,
    );
  }

  bool _hasDraftContent() {
    return _lines.any((line) => line.hasContent);
  }

  Map<String, dynamic> _buildDraftPayload() {
    return <String, dynamic>{
      'lines': _lines
          .where((line) => line.hasContent)
          .map((line) => line.toDraftJson())
          .toList(growable: false),
    };
  }

  Future<void> _searchProduct(_LabelDocumentLineDraft line) async {
    final query = line.lookupController.text.trim();

    if (query.length < 2) {
      setState(() {
        line.setLookupStatus(
          'Urun aramak icin en az 2 karakter veya barkod girilmeli.',
          isError: true,
        );
        _errorMessage =
            'Urun aramak icin en az 2 karakter veya barkod girilmeli.';
      });
      return;
    }

    List<SearchProductLookupItem> products;
    try {
      setState(() {
        line.setLookupStatus('API araniyor: $query', isLoading: true);
        _errorMessage = null;
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
      });
      return;
    }

    if (!mounted) {
      return;
    }

    final selected = await showModalBottomSheet<SearchProductLookupItem>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: TerminalEmptyState(message: 'Urun bulunamadi.'),
          );
        }

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
            products.isEmpty
                ? 'Urun bulunamadi: $query'
                : '${products.length} sonuc geldi, secim yapilmadi.',
            isError: products.isEmpty,
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
      _errorMessage = null;
    });
    _draftSession.scheduleSave();
    _focusFreshEntryLine();

    if (mergedIntoExisting) {
      _showFeedback('Bu urun zaten etiket belgesine ekli.');
    }
  }

  Future<void> _scanProductWithCamera(_LabelDocumentLineDraft line) async {
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
      title: 'Etiket Belgesi Kamerasi',
      subtitle: 'Barkodu okutun; bulunan urun belgeye eklenecek.',
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
    _LabelDocumentLineDraft line,
    SearchProductLookupItem product,
  ) {
    final existingLine = productEntryController.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<_LabelDocumentLineDraft>(
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

    _recycleMergedLine(line, createReplacement: _createLine);
    return true;
  }

  void _recycleMergedLine(
    _LabelDocumentLineDraft line, {
    required _LabelDocumentLineDraft Function() createReplacement,
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

  bool _isBlankLine(_LabelDocumentLineDraft line) {
    return line.selectedProduct == null &&
        line.lookupController.text.trim().isEmpty;
  }

  Future<void> _submit() async {
    final activeLines = _lines
        .where((line) => !_isBlankLine(line))
        .toList(growable: false);

    if (activeLines.isEmpty) {
      setState(() {
        _errorMessage = 'En az bir urun secilmeli.';
      });
      return;
    }

    if (activeLines.any((line) => line.selectedProduct == null)) {
      setState(() {
        _errorMessage = 'Tum satirlarda urun secimi tamamlanmali.';
      });
      return;
    }

    final request = CreateLabelDocumentRequest(
      lines: activeLines
          .map(
            (line) => CreateLabelDocumentLine(
              productCode: line.selectedProduct!.stockCode,
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
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          const TerminalSheetHeader(
            title: 'Yeni Etiket Belgesi',
            subtitle:
                'Belgeye eklenecek her satir yalnizca productCode alanindan olusur.',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          ..._lines.asMap().entries.map((entry) {
            final index = entry.key;
            final line = entry.value;
            final product = line.selectedProduct;
            final isFreshEntry = index == 0 && _isBlankLine(line);
            final displayLineNo = _lines
                .take(index + 1)
                .where((item) => !_isBlankLine(item))
                .length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
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
                        if (!isFreshEntry && _lines.length > 1)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _lines.removeAt(index);
                                line.dispose();
                              });
                              _draftSession.scheduleSave();
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: 'Satiri sil',
                          ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ProductLookupField(
                            controller: line.lookupController,
                            focusNode: line.lookupFocusNode,
                            enabled: !line.isLookupStatusLoading,
                            onSubmit: () => _searchProduct(line),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                    if (product != null) ...<Widget>[
                      const SizedBox(height: 8),
                      TerminalMessageBlock.info(
                        message:
                            '${product.stockCode} | ${product.stockName} | ${product.unitName}${product.barcode.trim().isNotEmpty ? ' | Barkod ${product.barcode}' : ''}',
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          if (_lines.every(_isBlankLine))
            const TerminalEmptyState(
              message: 'Etiket belgesi icin secilen urun yok.',
            ),
          if (_errorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            TerminalMessageBlock.error(message: _errorMessage!),
          ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Vazgec'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('Belge Olustur'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFeedback(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LabelDocumentLineDraft {
  _LabelDocumentLineDraft({Map<String, dynamic>? draft, this.onChanged})
    : lookupController = TextEditingController() {
    if (draft != null) {
      lookupController.text = draft['lookup']?.toString() ?? '';
      final productJson = _labelDraftMap(draft['selectedProduct']);
      if (productJson != null) {
        selectedProduct = SearchProductLookupItem.fromJson(productJson);
      }
      lookupStatusMessage = draft['lookupStatusMessage']?.toString();
    }
    lookupController.addListener(_notifyChanged);
  }

  final TextEditingController lookupController;
  final FocusNode lookupFocusNode = FocusNode();
  final VoidCallback? onChanged;
  SearchProductLookupItem? selectedProduct;
  String? lookupStatusMessage;
  bool isLookupStatusLoading = false;
  bool isLookupStatusError = false;

  bool get hasContent =>
      selectedProduct != null || lookupController.text.trim().isNotEmpty;

  void applyProduct(SearchProductLookupItem product) {
    selectedProduct = product;
    lookupController.text = product.displayLabel;
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
  }

  Map<String, dynamic> toDraftJson() {
    return <String, dynamic>{
      'lookup': lookupController.text,
      'lookupStatusMessage': lookupStatusMessage,
      'selectedProduct': selectedProduct == null
          ? null
          : _searchProductJson(selectedProduct!),
    };
  }

  void _notifyChanged() => onChanged?.call();
}

Map<String, dynamic>? _labelDraftMap(Object? value) {
  return switch (value) {
    final Map<String, dynamic> map => Map<String, dynamic>.from(map),
    final Map map => map.map((key, item) => MapEntry(key.toString(), item)),
    _ => null,
  };
}

Map<String, dynamic> _searchProductJson(SearchProductLookupItem item) {
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
