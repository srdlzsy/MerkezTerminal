import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/models/virman_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/virman_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/presentation/view_models/virman_controller.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_picker.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_session.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_controller.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_create_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class VirmanPage extends StatefulWidget {
  const VirmanPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.canCreate,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
    required this.mobileProductCatalogRepository,
    required this.currentUserId,
    this.draftRepository,
  });

  final VirmanRepository repository;
  final String accessToken;
  final bool canCreate;
  final String defaultWarehouseNo;
  final String userWarehouseName;
  final MobileProductCatalogLocalRepository mobileProductCatalogRepository;
  final String currentUserId;
  final CreateDraftRepository? draftRepository;

  @override
  State<VirmanPage> createState() => _VirmanPageState();
}

class _VirmanPageState extends State<VirmanPage> {
  late final VirmanController _controller;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _controller = VirmanController(
      repository: widget.repository,
      accessToken: widget.accessToken,
      defaultWarehouseNo: widget.defaultWarehouseNo,
    );
    _startDate = _controller.startDate;
    _endDate = _controller.endDate;
    unawaited(_controller.loadVirmans());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = pickedDate;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = pickedDate;
        if (_startDate.isAfter(_endDate)) {
          _startDate = _endDate;
        }
      }
    });
  }

  Future<void> _applyFilters() async {
    await _controller.updateFilters(
      startDate: _startDate,
      endDate: _endDate,
      warehouseNo: '',
    );
  }

  void _resetFilters() {
    setState(() {
      _startDate = defaultFilterStartDate();
      _endDate = defaultFilterEndDate();
    });

    unawaited(_applyFilters());
  }

  Future<void> _toggleSelection(VirmanListItem item) async {
    await _controller.selectVirman(item);
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              final detail = _controller.selectedVirmanDetail;

              return Scaffold(
                appBar: AppBar(title: Text(item.documentNoLabel)),
                body: SafeArea(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      20 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: <Widget>[
                      _VirmanSummaryCard(item: item),
                      const SizedBox(height: 12),
                      if (_controller.isLoadingDetail)
                        const Center(child: CircularProgressIndicator())
                      else if (_controller.detailError != null)
                        TerminalMessageBlock.error(
                          message: _controller.detailError!,
                        )
                      else if (detail == null)
                        const TerminalEmptyState(
                          message: 'Detay bilgisi yuklenemedi.',
                        )
                      else
                        _VirmanDetailSection(detail: detail),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );

    if (mounted) {
      _controller.clearSelection();
    }
  }

  Future<void> _openCreateSheet() async {
    CreateDraft? draft;
    if (widget.draftRepository != null) {
      final launch = await showCreateDraftPicker(
        context: context,
        repository: widget.draftRepository!,
        moduleKey: 'stok-islemleri.virmanlar',
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        createTitle: 'Yeni Virman',
      );
      if (launch == null || !mounted) {
        return;
      }
      draft =
          launch.draft ??
          CreateDraft.empty(
            moduleKey: 'stok-islemleri.virmanlar',
            userId: widget.currentUserId,
            warehouseNo: widget.defaultWarehouseNo,
            title: 'Yeni Virman',
          );
    }

    final request = await openTerminalCreatePage<VirmanCreateRequest>(
      context: context,
      title: 'Yeni Virman',
      builder: (context) {
        return _VirmanCreateSheet(
          defaultWarehouseNo: widget.defaultWarehouseNo,
          mobileProductCatalogRepository: widget.mobileProductCatalogRepository,
          draft: draft,
          draftRepository: widget.draftRepository,
        );
      },
    );

    if (request == null || !mounted) {
      return;
    }

    final result = await _controller.createVirman(request);

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_controller.createError ?? 'Virman kaydedilemedi.'),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.documentNoLabel} kaydedildi. ${result.lineCount} Mikro hareketi, toplam ${AppFormatters.quantity(result.totalQuantity)} miktar.',
        ),
      ),
    );
    if (draft != null) {
      await widget.draftRepository?.deleteDraft(draft.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
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
              _buildListCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return TerminalListHeaderCard(
      title: 'Virmanlar',
      subtitle: 'Virman kayitlarini listeleyin ve yeni virman olusturun.',
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Varsayilan depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(
          label: 'Kayit',
          value: '${_controller.virmans.length}',
        ),
      ],
      filters: <Widget>[
        TerminalFilterButton(
          label: 'Baslangic',
          value: AppFormatters.date(_startDate),
          onPressed: () => _pickDate(isStart: true),
        ),
        TerminalFilterButton(
          label: 'Bitis',
          value: AppFormatters.date(_endDate),
          onPressed: () => _pickDate(isStart: false),
        ),
      ],
      actions: <Widget>[
        FilledButton.icon(
          onPressed: _controller.isLoadingList ? null : _applyFilters,
          icon: const Icon(Icons.search_rounded),
          label: const Text('Listele'),
        ),
        OutlinedButton.icon(
          onPressed: _controller.isLoadingList ? null : _resetFilters,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Temizle'),
        ),
        if (widget.canCreate)
          FilledButton.tonalIcon(
            onPressed: _controller.isCreating ? null : _openCreateSheet,
            icon: _controller.isCreating
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.swap_horiz_rounded),
            label: Text(
              _controller.isCreating ? 'Kaydediliyor...' : 'Yeni Virman',
            ),
          ),
      ],
    );
  }

  Widget _buildListCard() {
    if (_controller.listError != null && _controller.virmans.isEmpty) {
      return SectionCard(
        title: 'Virman Listesi',
        subtitle: 'Listeleme sirasinda hata olustu.',
        child: TerminalMessageBlock.error(message: _controller.listError!),
      );
    }

    return SectionCard(
      title: 'Virman Listesi',
      subtitle: _controller.isLoadingList
          ? 'Liste yenileniyor...'
          : '${_controller.virmans.length} kayit bulundu.',
      child: Column(
        children: <Widget>[
          if (_controller.listError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TerminalMessageBlock.error(
                message: _controller.listError!,
              ),
            ),
          if (_controller.isLoadingList)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: CircularProgressIndicator(),
            )
          else if (_controller.virmans.isEmpty)
            const TerminalEmptyState(
              message: 'Secilen tarih araliginda virman kaydi bulunamadi.',
            )
          else
            Column(
              children: _controller.virmans
                  .map((item) {
                    final isExpanded =
                        _controller.selectedVirman?.documentNoLabel ==
                        item.documentNoLabel;
                    final detail = isExpanded
                        ? _controller.selectedVirmanDetail
                        : null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TerminalPdaRecordCard(
                        isSelected: isExpanded,
                        onTap: () => _toggleSelection(item),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            TerminalPdaCardHeader(
                              title: item.documentNoLabel,
                              subtitle: item.description.isEmpty
                                  ? 'Virman'
                                  : item.description,
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  TerminalBadge(
                                    label: '${item.lineCount} satir',
                                  ),
                                  const SizedBox(height: 4),
                                  if (isExpanded && _controller.isLoadingDetail)
                                    const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 28,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            TerminalPdaInfoGrid(
                              items: <TerminalPdaInfo>[
                                TerminalPdaInfo(
                                  label: 'Belge Trh',
                                  value: AppFormatters.dateOrDash(
                                    item.documentDate,
                                  ),
                                ),
                                TerminalPdaInfo(
                                  label: 'Hareket',
                                  value: AppFormatters.dateOrDash(
                                    item.movementDate,
                                  ),
                                ),
                                TerminalPdaInfo(
                                  label: 'Tipler',
                                  value: _formatMovementTypes(
                                    item.movementTypes,
                                  ),
                                ),
                                TerminalPdaInfo(
                                  label: 'Toplam',
                                  value: AppFormatters.quantity(
                                    item.totalQuantity,
                                  ),
                                ),
                              ],
                            ),
                            if (isExpanded &&
                                !_controller.isLoadingDetail &&
                                _controller.detailError != null) ...<Widget>[
                              const SizedBox(height: 8),
                              TerminalMessageBlock.error(
                                message: _controller.detailError!,
                              ),
                            ] else if (isExpanded &&
                                !_controller.isLoadingDetail &&
                                detail == null) ...<Widget>[
                              const SizedBox(height: 8),
                              const TerminalMessageBlock.info(
                                message: 'Detay ayri sayfada aciliyor.',
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _VirmanDetailSection extends StatelessWidget {
  const _VirmanDetailSection({required this.detail});

  final VirmanDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (detail.items.isEmpty)
          const TerminalEmptyState(message: 'Bu virmanda satir bulunamadi.')
        else
          Column(
            children: detail.items
                .map((line) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TerminalPdaDetailPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  line.stockName,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TerminalBadge(label: 'Tip ${line.movementType}'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TerminalPdaInfoGrid(
                            items: <TerminalPdaInfo>[
                              TerminalPdaInfo(
                                label: 'Kod',
                                value: line.stockCode,
                              ),
                              TerminalPdaInfo(
                                label: 'Miktar',
                                value: AppFormatters.quantity(line.quantity),
                              ),
                              TerminalPdaInfo(
                                label: 'Birim',
                                value: line.unitName,
                              ),
                            ],
                          ),
                          if (line.description.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (line.description.isNotEmpty)
                                  'Aciklama ${line.description}',
                              ].join(' | '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _VirmanSummaryCard extends StatelessWidget {
  const _VirmanSummaryCard({required this.item});

  final VirmanListItem item;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Virman Detayi',
      subtitle: item.documentNoLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TerminalPdaInfoGrid(
            items: <TerminalPdaInfo>[
              TerminalPdaInfo(label: 'Belge', value: item.documentNoLabel),
              TerminalPdaInfo(
                label: 'Belge Trh',
                value: AppFormatters.dateOrDash(item.documentDate),
              ),
              TerminalPdaInfo(
                label: 'Hareket',
                value: AppFormatters.dateOrDash(item.movementDate),
              ),
              TerminalPdaInfo(
                label: 'Toplam',
                value: AppFormatters.quantity(item.totalQuantity),
              ),
              TerminalPdaInfo(label: 'Satir', value: '${item.lineCount}'),
            ],
          ),
          if (item.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              item.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _VirmanCreateSheet extends StatefulWidget {
  const _VirmanCreateSheet({
    required this.defaultWarehouseNo,
    required this.mobileProductCatalogRepository,
    this.draft,
    this.draftRepository,
  });

  final String defaultWarehouseNo;
  final MobileProductCatalogLocalRepository mobileProductCatalogRepository;
  final CreateDraft? draft;
  final CreateDraftRepository? draftRepository;

  @override
  State<_VirmanCreateSheet> createState() => _VirmanCreateSheetState();
}

class _VirmanCreateSheetState extends State<_VirmanCreateSheet>
    with CreateFormValidation {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late List<_VirmanDraftLine> _lines;
  late DateTime _movementDate;
  late DateTime _documentDate;
  String? _errorMessage;
  late final CreateDraftSession _draftSession;

  @override
  void initState() {
    super.initState();
    final payload = widget.draft?.payload ?? const <String, dynamic>{};
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
          ? 'Yeni Virman'
          : 'Virman - ${_descriptionController.text.trim()}',
    );
    final rawLines = payload['lines'];
    _lines = rawLines is List
        ? rawLines
              .map(_virmanDraftMap)
              .whereType<Map<String, dynamic>>()
              .map(_createLine)
              .toList(growable: true)
        : <_VirmanDraftLine>[];
    _ensureFreshEntryLine();
    _draftSession.listenTo(<TextEditingController>[_descriptionController]);
  }

  @override
  void dispose() {
    _draftSession.dispose();
    _descriptionController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  _VirmanDraftLine _createLine([Map<String, dynamic>? draft]) {
    return _VirmanDraftLine(
      draft: draft,
      onChanged: _draftSession.scheduleSave,
    );
  }

  bool _hasDraftContent() {
    final today = _normalizeDate(DateTime.now());
    return _descriptionController.text.trim().isNotEmpty ||
        !_isSameDate(_movementDate, today) ||
        !_isSameDate(_documentDate, today) ||
        _lines.any((line) => line.hasContent);
  }

  Map<String, dynamic> _buildDraftPayload() {
    return <String, dynamic>{
      'movementDate': _movementDate.toIso8601String(),
      'documentDate': _documentDate.toIso8601String(),
      'description': _descriptionController.text,
      'lines': _lines
          .where((line) => line.hasContent)
          .map((line) => line.toDraftJson())
          .toList(growable: false),
    };
  }

  Future<void> _pickDate({required bool isMovementDate}) async {
    final initialDate = isMovementDate ? _movementDate : _documentDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      if (isMovementDate) {
        _movementDate = pickedDate;
      } else {
        _documentDate = pickedDate;
      }
    });
    _draftSession.scheduleSave();
  }

  void _removeLine(_VirmanDraftLine line) {
    if (_lines.length == 1) {
      return;
    }

    setState(() {
      _lines.remove(line);
      line.dispose();
    });
    _draftSession.scheduleSave();
  }

  Future<void> _searchProduct(_VirmanDraftLine line) async {
    final query = line.lookupController.text.trim();
    if (query.length < 2) {
      setState(() {
        _errorMessage = 'Urun aramak icin en az 2 karakter veya barkod girin.';
      });
      _refocusLine(line.lookupFocusNode);
      return;
    }

    final catalogItems = await widget.mobileProductCatalogRepository
        .searchProducts(warehouseNo: widget.defaultWarehouseNo, query: query);

    if (!mounted) {
      return;
    }

    if (catalogItems.isEmpty) {
      setState(() {
        _errorMessage = 'Bu aramaya uygun urun katalogda bulunamadi.';
      });
      _refocusLine(line.lookupFocusNode);
      return;
    }

    final products = catalogItems
        .map((item) => item.toSearchProductLookupItem())
        .toList(growable: false);

    SearchProductLookupItem? selected;
    if (products.length == 1) {
      selected = products.single;
    } else {
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
                    '${item.unitName}${item.barcode.isNotEmpty ? ' | ${item.barcode}' : ''}',
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

    if (selected == null || !mounted) {
      if (mounted) {
        _refocusLine(line.lookupFocusNode);
      }
      return;
    }
    final pickedProduct = selected;

    var mergedIntoExisting = false;
    setState(() {
      mergedIntoExisting = _applyProductToLine(line, pickedProduct);
      _ensureFreshEntryLine();
      _errorMessage = null;
    });
    _draftSession.scheduleSave();
    _focusFreshEntryLine();

    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  Future<void> _scanProductWithCamera(_VirmanDraftLine line) async {
    if (!supportsCameraBarcodeScanning) {
      setState(() {
        _errorMessage = 'Bu cihazda kamera ile barkod okutma desteklenmiyor.';
      });
      _refocusLine(line.lookupFocusNode);
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Virman Barkod Kamerasi',
      subtitle: 'Barkodu okutun; bulunan urun satira aktarilacak.',
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

  bool _applyProductToLine(
    _VirmanDraftLine line,
    SearchProductLookupItem product,
  ) {
    final existingLine = productEntryController.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<_VirmanDraftLine>(
        currentLine: line,
        targetBarcode: product.barcode,
        targetStockCode: product.stockCode,
        lines: _lines,
        lineBarcode: (line) => line.barcode,
        lineStockCode: (line) => line.stockCodeController.text,
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
    _recycleMergedLine(line);
    return true;
  }

  void _recycleMergedLine(_VirmanDraftLine line) {
    final lineIndex = _lines.indexOf(line);
    line.dispose();

    if (lineIndex == 0) {
      _lines[lineIndex] = _createLine();
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

  void _refocusLine(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focusNode.requestFocus();
      }
    });
  }

  bool _isBlankLine(_VirmanDraftLine line) {
    return line.lookupController.text.trim().isEmpty &&
        line.stockCodeController.text.trim().isEmpty;
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

  Future<void> _submit() async {
    if (!validateCreateForm(_formKey)) {
      setState(() {
        _errorMessage = 'Lutfen zorunlu alanlari duzeltin.';
      });
      return;
    }

    final requestLines = <VirmanCreateLine>[];

    final activeLines = _lines
        .where((line) => !_isBlankLine(line))
        .toList(growable: false);

    if (activeLines.isEmpty) {
      setState(() {
        _errorMessage = 'En az bir urun satiri ekleyin.';
      });
      return;
    }

    for (final line in activeLines) {
      final stockCode = line.stockCodeController.text.trim();
      final movementType = int.tryParse(
        line.movementTypeController.text.trim(),
      );
      final quantity = double.tryParse(
        line.quantityController.text.trim().replaceAll(',', '.'),
      );
      final unitPointer = int.tryParse(line.unitPointerController.text.trim());
      final lotNo = int.tryParse(line.lotNoController.text.trim()) ?? 0;

      if (stockCode.isEmpty) {
        setState(() {
          _errorMessage = 'Her satirda stok kodu zorunlu.';
        });
        return;
      }

      if (movementType == null || movementType < 0) {
        setState(() {
          _errorMessage = 'Her satirda gecerli bir movementType girilmeli.';
        });
        return;
      }

      if (quantity == null || quantity <= 0) {
        setState(() {
          _errorMessage = 'Her satirda miktar sifirdan buyuk olmali.';
        });
        return;
      }

      if (unitPointer == null || unitPointer <= 0) {
        setState(() {
          _errorMessage = 'Her satirda unitPointer sifirdan buyuk olmali.';
        });
        return;
      }

      requestLines.add(
        VirmanCreateLine(
          stockCode: stockCode,
          movementType: movementType,
          quantity: quantity,
          unitPointer: unitPointer,
          description: line.descriptionController.text.trim(),
          partyCode: line.partyCodeController.text.trim(),
          lotNo: lotNo,
          projectCode: line.projectCodeController.text.trim(),
        ),
      );
    }

    setState(() {
      _errorMessage = null;
    });

    final request = VirmanCreateRequest(
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

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        autovalidateMode: createFormAutovalidateMode,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverList.list(
              children: <Widget>[
                const TerminalSheetHeader(
                  title: 'Yeni Virman',
                  subtitle:
                      'Satirlar movementType=2 ile gonderilir; backend cikis ve giris hareketlerini birlikte olusturur.',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    TerminalFilterButton(
                      label: 'Hareket Tarihi',
                      value: AppFormatters.date(_movementDate),
                      onPressed: () => _pickDate(isMovementDate: true),
                    ),
                    TerminalFilterButton(
                      label: 'Belge Tarihi',
                      value: AppFormatters.date(_documentDate),
                      onPressed: () => _pickDate(isMovementDate: false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Aciklama'),
                ),
                const SizedBox(height: 16),
                TerminalSectionToolbar(
                  title: 'Satirlar',
                  actions: const <Widget>[],
                ),
                const SizedBox(height: 12),
                _buildEntryLineCard(),
              ],
            ),
            _buildLazyLineSliver(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (_errorMessage != null) ...<Widget>[
                    const SizedBox(height: 8),
                    TerminalMessageBlock.error(message: _errorMessage!),
                  ],
                  const SizedBox(height: 12),
                  TerminalFormActionRow(
                    cancel: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Vazgec'),
                    ),
                    submit: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_alt_rounded),
                      label: const Text('Virmani Kaydet'),
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

  Widget _buildEntryLineCard() {
    final entryIndex = _lines.indexWhere(_isBlankLine);
    if (entryIndex == -1) {
      return const SizedBox.shrink();
    }

    return _buildLineCard(entryIndex);
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _VirmanDraftLineCard(
        lineNumber: displayLineNo,
        isFreshEntry: isFreshEntry,
        line: line,
        canRemove: !isFreshEntry && _lines.length > 1,
        onPickProduct: () => _searchProduct(line),
        onScanWithCamera: () => _scanProductWithCamera(line),
        onRemove: () => _removeLine(line),
      ),
    );
  }
}

class _VirmanDraftLineCard extends StatelessWidget {
  const _VirmanDraftLineCard({
    required this.lineNumber,
    required this.isFreshEntry,
    required this.line,
    required this.canRemove,
    required this.onPickProduct,
    required this.onScanWithCamera,
    required this.onRemove,
  });

  final int lineNumber;
  final bool isFreshEntry;
  final _VirmanDraftLine line;
  final bool canRemove;
  final VoidCallback onPickProduct;
  final VoidCallback onScanWithCamera;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final product = line.selectedProduct;

    if (!isFreshEntry && product != null) {
      return TerminalCompactProductLineCard(
        lineNo: lineNumber,
        stockCode: product.stockCode,
        stockName: product.stockName,
        quantityController: line.quantityController,
        unitLabel: product.unitName,
        barcode: product.barcode,
        canDelete: canRemove,
        onDelete: onRemove,
        onMinimumReached: canRemove ? onRemove : null,
      );
    }

    return TerminalPdaLineCard(
      title: isFreshEntry ? 'Giris satiri' : 'Satir $lineNumber',
      subtitle: product?.stockName,
      isEntryLine: isFreshEntry,
      trailing: canRemove
          ? IconButton(
              onPressed: onRemove,
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
                onSubmit: onPickProduct,
              ),
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: onPickProduct,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Urun'),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: onScanWithCamera,
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
                if (product.barcode.trim().isNotEmpty)
                  TerminalPdaInfo(label: 'Barkod', value: product.barcode),
              ],
            ),
          if (!isFreshEntry) ...<Widget>[
            const SizedBox(height: 10),
            TextFormField(
              controller: line.stockCodeController,
              decoration: const InputDecoration(labelText: 'Stok Kodu*'),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Zorunlu';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TerminalQuantityStepper(
              controller: line.quantityController,
              onMinimumReached: canRemove ? onRemove : null,
              validator: (value) {
                final quantity = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                if (quantity == null || quantity <= 0) {
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
}

class _VirmanDraftLine {
  _VirmanDraftLine({Map<String, dynamic>? draft, this.onChanged})
    : lookupController = TextEditingController(),
      stockCodeController = TextEditingController(),
      movementTypeController = TextEditingController(text: '2'),
      quantityController = TextEditingController(),
      unitPointerController = TextEditingController(text: '1'),
      descriptionController = TextEditingController(),
      partyCodeController = TextEditingController(),
      lotNoController = TextEditingController(text: '0'),
      projectCodeController = TextEditingController() {
    if (draft != null) {
      lookupController.text = draft['lookup']?.toString() ?? '';
      stockCodeController.text = draft['stockCode']?.toString() ?? '';
      movementTypeController.text = draft['movementType']?.toString() ?? '2';
      quantityController.text = draft['quantity']?.toString() ?? '';
      unitPointerController.text = draft['unitPointer']?.toString() ?? '1';
      descriptionController.text = draft['description']?.toString() ?? '';
      partyCodeController.text = draft['partyCode']?.toString() ?? '';
      lotNoController.text = draft['lotNo']?.toString() ?? '0';
      projectCodeController.text = draft['projectCode']?.toString() ?? '';
      final productJson = _virmanDraftMap(draft['selectedProduct']);
      if (productJson != null) {
        selectedProduct = SearchProductLookupItem.fromJson(productJson);
      }
    }
    for (final controller in _controllers) {
      controller.addListener(_notifyChanged);
    }
  }

  final TextEditingController lookupController;
  final TextEditingController stockCodeController;
  final TextEditingController movementTypeController;
  final TextEditingController quantityController;
  final TextEditingController unitPointerController;
  final TextEditingController descriptionController;
  final TextEditingController partyCodeController;
  final TextEditingController lotNoController;
  final TextEditingController projectCodeController;
  final FocusNode lookupFocusNode = FocusNode();
  final VoidCallback? onChanged;
  SearchProductLookupItem? selectedProduct;

  String get barcode => selectedProduct?.barcode ?? '';

  List<TextEditingController> get _controllers => <TextEditingController>[
    lookupController,
    stockCodeController,
    movementTypeController,
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
      stockCodeController.text.trim().isNotEmpty ||
      movementTypeController.text.trim() != '2' ||
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
    stockCodeController.text = product.stockCode;
    if (quantityController.text.trim().isEmpty) {
      quantityController.text = productEntryController.formatQuantity(
        productEntryController.unitMultiplierQuantity(product.unitMultiplier),
      );
    }
  }

  void dispose() {
    lookupFocusNode.dispose();
    lookupController.dispose();
    stockCodeController.dispose();
    movementTypeController.dispose();
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
      'stockCode': stockCodeController.text,
      'movementType': movementTypeController.text,
      'quantity': quantityController.text,
      'unitPointer': unitPointerController.text,
      'description': descriptionController.text,
      'partyCode': partyCodeController.text,
      'lotNo': lotNoController.text,
      'projectCode': projectCodeController.text,
      'selectedProduct': selectedProduct == null
          ? null
          : _virmanProductJson(selectedProduct!),
    };
  }

  void _notifyChanged() => onChanged?.call();
}

DateTime _normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

Map<String, dynamic>? _virmanDraftMap(Object? value) {
  return switch (value) {
    final Map<String, dynamic> map => Map<String, dynamic>.from(map),
    final Map map => map.map((key, item) => MapEntry(key.toString(), item)),
    _ => null,
  };
}

Map<String, dynamic> _virmanProductJson(SearchProductLookupItem item) {
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

String _formatMovementTypes(List<int> movementTypes) {
  if (movementTypes.isEmpty) {
    return '-';
  }

  return movementTypes.map((item) => item.toString()).join(', ');
}
