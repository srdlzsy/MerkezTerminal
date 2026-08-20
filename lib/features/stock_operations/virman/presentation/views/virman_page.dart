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
import 'package:furpa_merkez_terminal/shared/utils/client_request_id.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/utils/safe_create_retry.dart';
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
          repository: widget.repository,
          accessToken: widget.accessToken,
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

    await _submitCreateRequest(request, draft);
  }

  Future<void> _submitCreateRequest(
    VirmanCreateRequest request,
    CreateDraft? draft,
  ) async {
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
          action: shouldOfferSafeCreateRetry(_controller.createErrorStatusCode)
              ? SnackBarAction(
                  label: 'Tekrar Dene',
                  onPressed: () {
                    unawaited(_submitCreateRequest(request, draft));
                  },
                )
              : null,
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.documentNoLabel} kaydedildi. ${_formatVirmanFlowSummary(incomingLineCount: result.incomingLineCount, outgoingLineCount: result.outgoingLineCount, incomingQuantity: result.incomingQuantity, outgoingQuantity: result.outgoingQuantity, lineCount: result.lineCount, totalQuantity: result.totalQuantity)}.',
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
                                if (_hasVirmanFlowSummary(
                                  incomingLineCount: item.incomingLineCount,
                                  outgoingLineCount: item.outgoingLineCount,
                                  incomingQuantity: item.incomingQuantity,
                                  outgoingQuantity: item.outgoingQuantity,
                                )) ...<TerminalPdaInfo>[
                                  TerminalPdaInfo(
                                    label: 'Cikis',
                                    value:
                                        '${item.outgoingLineCount} / ${AppFormatters.quantity(item.outgoingQuantity)}',
                                  ),
                                  TerminalPdaInfo(
                                    label: 'Giris',
                                    value:
                                        '${item.incomingLineCount} / ${AppFormatters.quantity(item.incomingQuantity)}',
                                  ),
                                ] else ...<TerminalPdaInfo>[
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
    final outgoingLines = detail.items
        .where((line) => line.movementType == 1)
        .toList(growable: false);
    final incomingLines = detail.items
        .where((line) => line.movementType == 0)
        .toList(growable: false);
    final otherLines = detail.items
        .where((line) => line.movementType != 0 && line.movementType != 1)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (detail.items.isEmpty)
          const TerminalEmptyState(message: 'Bu virmanda satir bulunamadi.')
        else ...<Widget>[
          ..._buildLineGroup(context, 'Cikis Satirlari', outgoingLines),
          ..._buildLineGroup(context, 'Giris Satirlari', incomingLines),
          ..._buildLineGroup(context, 'Diger Satirlar', otherLines),
        ],
      ],
    );
  }

  List<Widget> _buildLineGroup(
    BuildContext context,
    String title,
    List<VirmanLineItem> lines,
  ) {
    if (lines.isEmpty) {
      return const <Widget>[];
    }

    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      ...lines.map((line) {
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TerminalBadge(label: _movementTypeLabel(line.movementType)),
                  ],
                ),
                const SizedBox(height: 6),
                TerminalPdaInfoGrid(
                  items: <TerminalPdaInfo>[
                    TerminalPdaInfo(label: 'Kod', value: line.stockCode),
                    TerminalPdaInfo(
                      label: 'Miktar',
                      value: AppFormatters.quantity(line.quantity),
                    ),
                    TerminalPdaInfo(label: 'Birim', value: line.unitName),
                  ],
                ),
                if (line.description.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'Aciklama ${line.description}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    ];
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
              if (_hasVirmanFlowSummary(
                incomingLineCount: item.incomingLineCount,
                outgoingLineCount: item.outgoingLineCount,
                incomingQuantity: item.incomingQuantity,
                outgoingQuantity: item.outgoingQuantity,
              )) ...<TerminalPdaInfo>[
                TerminalPdaInfo(
                  label: 'Cikis',
                  value:
                      '${item.outgoingLineCount} / ${AppFormatters.quantity(item.outgoingQuantity)}',
                ),
                TerminalPdaInfo(
                  label: 'Giris',
                  value:
                      '${item.incomingLineCount} / ${AppFormatters.quantity(item.incomingQuantity)}',
                ),
              ],
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
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.mobileProductCatalogRepository,
    this.draft,
    this.draftRepository,
  });

  final VirmanRepository repository;
  final String accessToken;
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
  String? _lastAddedProductKey;

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
              .map((draft) => _createLine(draft))
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

  _VirmanDraftLine _createLine([
    Map<String, dynamic>? draft,
    int initialMovementType = 1,
  ]) {
    return _VirmanDraftLine(
      draft: draft,
      initialMovementType: initialMovementType,
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

    List<SearchProductLookupItem> products;
    try {
      products = await widget.repository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        query: query,
      );
    } catch (_) {
      final catalogItems = await widget.mobileProductCatalogRepository
          .searchProducts(warehouseNo: widget.defaultWarehouseNo, query: query);
      products = catalogItems
          .map((item) => item.toSearchProductLookupItem())
          .toList(growable: false);
    }

    if (!mounted) {
      return;
    }

    if (products.isEmpty) {
      setState(() {
        _errorMessage = 'Bu aramaya uygun urun bulunamadi.';
      });
      _refocusLine(line.lookupFocusNode);
      return;
    }

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
      _errorMessage = null;
    });
    _draftSession.scheduleSave();
    _refocusLine(entryLine.lookupFocusNode);
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
        lines: _lines
            .where(
              (item) => item == line || item.movementType == line.movementType,
            )
            .toList(growable: false),
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
      _lines[lineIndex] = _createLine(null, line.movementType);
      return;
    }

    _lines.removeAt(lineIndex);
  }

  void _ensureFreshEntryLine({int initialMovementType = 1}) {
    if (_lines.isEmpty || !_isBlankLine(_lines.first)) {
      _lines.insert(0, _createLine(null, initialMovementType));
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
    return line.stockCodeController.text.trim().isEmpty;
  }

  bool _increasePendingQuantityIfSameProduct(
    _VirmanDraftLine line,
    SearchProductLookupItem product,
  ) {
    final selectedProduct = line.selectedProduct;
    if (selectedProduct == null || !_isSameProduct(selectedProduct, product)) {
      return false;
    }

    final increment = productEntryController.unitMultiplierQuantity(
      product.unitMultiplier,
    );
    setState(() {
      line.quantityController.text = productEntryController.formatQuantity(
        productEntryController.readQuantity(
              line.quantityController.text,
              fallback: 0,
            ) +
            increment,
      );
      line.lookupController.clear();
      _errorMessage = null;
    });
    return true;
  }

  Future<_VirmanDraftLine?> _commitPendingEntryBeforeNextProduct(
    _VirmanDraftLine line,
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

  Future<void> _commitEntryLine(_VirmanDraftLine line) async {
    final product = line.selectedProduct;
    if (product == null) {
      _refocusLine(line.lookupFocusNode);
      return;
    }

    if (productEntryController.readQuantity(
          line.quantityController.text,
          fallback: 0,
        ) <=
        0) {
      setState(() {
        _errorMessage = 'Miktar sifirdan buyuk olmali.';
      });
      return;
    }

    if (!await _confirmDuplicateIncrease(line, product)) {
      return;
    }

    var mergedIntoExisting = false;
    final nextMovementType = line.movementType;
    setState(() {
      mergedIntoExisting = _applyProductToLine(line, product);
      _ensureFreshEntryLine(initialMovementType: nextMovementType);
      _errorMessage = null;
    });
    _draftSession.scheduleSave();
    _focusFreshEntryLine();
    _rememberAddedProduct(product, movementType: nextMovementType);

    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  void _cancelPendingEntryLine(_VirmanDraftLine line) {
    setState(() {
      line.clear();
      _errorMessage = null;
    });
    _draftSession.scheduleSave();
    _refocusLine(line.lookupFocusNode);
  }

  List<_VirmanDraftLine> _committedLines() {
    return <_VirmanDraftLine>[
      for (var index = 0; index < _lines.length; index++)
        if (index != 0 && !_isBlankLine(_lines[index])) _lines[index],
    ];
  }

  Future<bool> _confirmDuplicateIncrease(
    _VirmanDraftLine line,
    SearchProductLookupItem product,
  ) async {
    final existingLine = productEntryController.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<_VirmanDraftLine>(
        currentLine: line,
        targetBarcode: product.barcode,
        targetStockCode: product.stockCode,
        lines: _lines
            .where(
              (item) => item == line || item.movementType == line.movementType,
            )
            .toList(growable: false),
        lineBarcode: (line) => line.barcode,
        lineStockCode: (line) => line.stockCodeController.text,
      ),
    );
    final key = _productKey(
      stockCode: product.stockCode,
      barcode: product.barcode,
      movementType: line.movementType,
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

  void _rememberAddedProduct(
    SearchProductLookupItem product, {
    required int movementType,
  }) {
    final key = _productKey(
      stockCode: product.stockCode,
      barcode: product.barcode,
      movementType: movementType,
    );
    if (key.isNotEmpty) {
      _lastAddedProductKey = key;
    }
  }

  String _productKey({
    required String stockCode,
    required String barcode,
    required int movementType,
  }) {
    final normalizedStockCode = stockCode.trim().toUpperCase();
    if (normalizedStockCode.isNotEmpty) {
      return 'M:$movementType:S:$normalizedStockCode';
    }

    final normalizedBarcode = barcode.trim().toUpperCase();
    if (normalizedBarcode.isNotEmpty) {
      return 'M:$movementType:B:$normalizedBarcode';
    }

    return '';
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

    if (_hasPendingEntryLine) {
      setState(() {
        _errorMessage = 'Secilen urunu once Kaleme Ekle ile listeye alin.';
      });
      return;
    }

    final activeLines = _committedLines();

    if (activeLines.isEmpty) {
      setState(() {
        _errorMessage = 'En az bir urun satiri ekleyin.';
      });
      return;
    }

    for (final line in activeLines) {
      final stockCode = line.stockCodeController.text.trim();
      final movementType = line.movementType;
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

      if (movementType != 0 && movementType != 1) {
        setState(() {
          _errorMessage = 'Her satir tipi Cikis veya Giris olmali.';
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

    final hasOutgoingLine = requestLines.any((line) => line.movementType == 1);
    final hasIncomingLine = requestLines.any((line) => line.movementType == 0);
    if (!hasOutgoingLine || !hasIncomingLine) {
      setState(() {
        _errorMessage =
            'Virman icin en az bir Cikis ve bir Giris satiri ekleyin.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final request = VirmanCreateRequest(
      clientRequestId: generateClientRequestId(),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      child: Form(
        key: _formKey,
        autovalidateMode: createFormAutovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TerminalSheetHeader(
              title: 'Yeni Virman',
              badges: <Widget>[
                TerminalLineCountBadge(count: _filledLineIndexes().length),
                _VirmanFlowBadge(
                  label: 'Cikis ${_movementLineCount(1)}',
                  movementType: 1,
                ),
                _VirmanFlowBadge(
                  label: 'Giris ${_movementLineCount(0)}',
                  movementType: 0,
                ),
              ],
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 4),
            TerminalCreateInputDock(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
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
                const SizedBox(height: 4),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Aciklama',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TerminalSectionToolbar(
                  title: 'Urun Ekle',
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
          ],
        ),
      ),
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

  int _movementLineCount(int movementType) {
    return _filledLineIndexes()
        .where((index) => _lines[index].movementType == movementType)
        .length;
  }

  Widget _buildLineCard(int index) {
    final line = _lines[index];
    final isEntrySlot = index == 0;
    final isFreshEntry = isEntrySlot && _isBlankLine(line);
    final displayLineNo = _lines
        .take(index + 1)
        .where((item) => _lines.indexOf(item) != 0 && !_isBlankLine(item))
        .length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _VirmanDraftLineCard(
        lineNumber: displayLineNo,
        isEntrySlot: isEntrySlot,
        isFreshEntry: isFreshEntry,
        line: line,
        canRemove: !isFreshEntry && _lines.length > 1,
        onPickProduct: () => _searchProduct(line),
        onScanWithCamera: () => _scanProductWithCamera(line),
        onConfirmPending: () => _commitEntryLine(line),
        onCancelPending: () => _cancelPendingEntryLine(line),
        onRemove: () => _removeLine(line),
        onMovementTypeChanged: () {
          setState(() {});
          _draftSession.scheduleSave();
        },
      ),
    );
  }
}

class _VirmanDraftLineCard extends StatelessWidget {
  const _VirmanDraftLineCard({
    required this.lineNumber,
    required this.isEntrySlot,
    required this.isFreshEntry,
    required this.line,
    required this.canRemove,
    required this.onPickProduct,
    required this.onScanWithCamera,
    required this.onConfirmPending,
    required this.onCancelPending,
    required this.onRemove,
    required this.onMovementTypeChanged,
  });

  final int lineNumber;
  final bool isEntrySlot;
  final bool isFreshEntry;
  final _VirmanDraftLine line;
  final bool canRemove;
  final VoidCallback onPickProduct;
  final VoidCallback onScanWithCamera;
  final VoidCallback onConfirmPending;
  final VoidCallback onCancelPending;
  final VoidCallback onRemove;
  final VoidCallback onMovementTypeChanged;

  @override
  Widget build(BuildContext context) {
    final product = line.selectedProduct;
    final movementType = line.movementType;
    final movementTitle = _movementTypeTitle(movementType);
    final movementSubtitle = _movementTypeSubtitle(movementType);
    final movementColor = _movementTypeForegroundColor(movementType, context);
    final packageLabel = product != null
        ? _packageLabelForProduct(product)
        : null;

    if (isEntrySlot && !isFreshEntry && product != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ProductDraftEntryPanel(
            stockCode: product.stockCode,
            stockName: product.stockName,
            quantityController: line.quantityController,
            unitLabel: '${product.unitName} | $movementTitle',
            packageLabel: packageLabel,
            barcode: product.barcode,
            priceLabel: movementSubtitle,
            warningLabel: product.price > 0
                ? AppFormatters.currency(product.price)
                : null,
            onConfirm: onConfirmPending,
            onCancel: onCancelPending,
            scanRow: TerminalResponsiveLookupRow(
              field: ProductLookupField(
                controller: line.lookupController,
                focusNode: line.lookupFocusNode,
                labelText: '$movementTitle urunu degistir',
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
            ),
            quantityValidator: (value) {
              final quantity = double.tryParse(
                (value ?? '').trim().replaceAll(',', '.'),
              );
              if (quantity == null || quantity <= 0) {
                return 'Miktar > 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 6),
          _buildMovementTypeSelector(context),
        ],
      );
    }

    if (!isFreshEntry && product != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TerminalCompactProductLineCard(
            lineNo: lineNumber,
            stockCode: product.stockCode,
            stockName: product.stockName,
            quantityController: line.quantityController,
            unitLabel: '${product.unitName} | $movementTitle',
            packageLabel: packageLabel,
            barcode: product.barcode,
            priceLabel: movementSubtitle,
            canDelete: canRemove,
            onDelete: onRemove,
            onMinimumReached: canRemove ? onRemove : null,
          ),
          _buildMovementTypeSelector(context),
        ],
      );
    }

    return TerminalPdaLineCard(
      title: isFreshEntry ? 'Virman urunu ekle' : 'Satir $lineNumber',
      subtitle: isFreshEntry ? movementSubtitle : product?.stockName,
      leading: Icon(_movementTypeIcon(movementType), color: movementColor),
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
          _buildMovementTypeSelector(context),
          const SizedBox(height: 8),
          if (isFreshEntry)
            TerminalResponsiveLookupRow(
              field: ProductLookupField(
                controller: line.lookupController,
                focusNode: line.lookupFocusNode,
                labelText: '$movementTitle urunu ara',
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

  Widget _buildMovementTypeSelector(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final options = <Widget>[
          _VirmanMovementTypeOption(
            movementType: 1,
            selected: line.movementType == 1,
            onTap: () => _setMovementType(1),
          ),
          _VirmanMovementTypeOption(
            movementType: 0,
            selected: line.movementType == 0,
            onTap: () => _setMovementType(0),
          ),
        ];

        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              options.first,
              const SizedBox(height: 6),
              options.last,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: options.first),
            const SizedBox(width: 8),
            Expanded(child: options.last),
          ],
        );
      },
    );
  }

  void _setMovementType(int movementType) {
    if (line.movementType == movementType) {
      return;
    }

    line.movementTypeController.text = movementType.toString();
    onMovementTypeChanged();
  }
}

class _VirmanFlowBadge extends StatelessWidget {
  const _VirmanFlowBadge({required this.label, required this.movementType});

  final String label;
  final int movementType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = _movementTypeForegroundColor(movementType, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _movementTypeBackgroundColor(movementType, context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foregroundColor.withAlpha(44)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          height: 1,
          color: foregroundColor,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VirmanMovementTypeOption extends StatelessWidget {
  const _VirmanMovementTypeOption({
    required this.movementType,
    required this.selected,
    required this.onTap,
  });

  final int movementType;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = _movementTypeForegroundColor(movementType, context);
    final backgroundColor = _movementTypeBackgroundColor(movementType, context);
    final borderColor = selected
        ? foregroundColor
        : theme.colorScheme.outlineVariant.withAlpha(120);

    return Material(
      color: selected
          ? backgroundColor
          : theme.colorScheme.surfaceContainerHighest.withAlpha(38),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: foregroundColor.withAlpha(selected ? 36 : 20),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  _movementTypeIcon(movementType),
                  size: 17,
                  color: foregroundColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _movementTypeTitle(movementType),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        height: 1.05,
                        color: foregroundColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _movementTypeSubtitle(movementType),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        height: 1.05,
                        color: theme.colorScheme.onSurface.withAlpha(150),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) ...<Widget>[
                const SizedBox(width: 4),
                Icon(
                  Icons.check_circle_rounded,
                  size: 17,
                  color: foregroundColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VirmanDraftLine {
  _VirmanDraftLine({
    Map<String, dynamic>? draft,
    int initialMovementType = 1,
    this.onChanged,
  }) : lookupController = TextEditingController(),
       stockCodeController = TextEditingController(),
       movementTypeController = TextEditingController(
         text: initialMovementType == 0 ? '0' : '1',
       ),
       quantityController = TextEditingController(),
       unitPointerController = TextEditingController(text: '1'),
       descriptionController = TextEditingController(),
       partyCodeController = TextEditingController(),
       lotNoController = TextEditingController(text: '0'),
       projectCodeController = TextEditingController() {
    if (draft != null) {
      lookupController.text = draft['lookup']?.toString() ?? '';
      stockCodeController.text = draft['stockCode']?.toString() ?? '';
      movementTypeController.text = draft['movementType']?.toString() == '0'
          ? '0'
          : '1';
      quantityController.text = draft['quantity']?.toString() ?? '';
      unitPointerController.text = draft['unitPointer']?.toString() ?? '1';
      descriptionController.text = draft['description']?.toString() ?? '';
      partyCodeController.text = draft['partyCode']?.toString() ?? '';
      lotNoController.text = draft['lotNo']?.toString() ?? '0';
      projectCodeController.text = draft['projectCode']?.toString() ?? '';
      final productJson = _virmanDraftMap(draft['selectedProduct']);
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

  int get movementType => movementTypeController.text.trim() == '0' ? 0 : 1;

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
      movementTypeController.text.trim() != '1' ||
      quantityController.text.trim().isNotEmpty ||
      unitPointerController.text.trim() != '1' ||
      descriptionController.text.trim().isNotEmpty ||
      partyCodeController.text.trim().isNotEmpty ||
      (lotNoController.text.trim().isNotEmpty &&
          lotNoController.text.trim() != '0') ||
      projectCodeController.text.trim().isNotEmpty;

  void applyProduct(SearchProductLookupItem product) {
    selectedProduct = product;
    lookupController.clear();
    stockCodeController.text = product.stockCode;
    if (quantityController.text.trim().isEmpty) {
      quantityController.text = productEntryController.formatQuantity(
        productEntryController.unitMultiplierQuantity(product.unitMultiplier),
      );
    }
  }

  void clear() {
    lookupController.clear();
    stockCodeController.clear();
    movementTypeController.text = '1';
    quantityController.clear();
    unitPointerController.text = '1';
    descriptionController.clear();
    partyCodeController.clear();
    lotNoController.text = '0';
    projectCodeController.clear();
    selectedProduct = null;
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

  return movementTypes.map(_movementTypeLabel).join(', ');
}

String _movementTypeLabel(int movementType) {
  return switch (movementType) {
    1 => 'Cikis',
    0 => 'Giris',
    2 => 'Teknik',
    _ => 'Tip $movementType',
  };
}

String _movementTypeTitle(int movementType) {
  return switch (movementType) {
    1 => 'Cikis urunu',
    0 => 'Giris urunu',
    _ => _movementTypeLabel(movementType),
  };
}

String _movementTypeSubtitle(int movementType) {
  return switch (movementType) {
    1 => 'Parcalanacak / stoktan duser',
    0 => 'Olusacak / stoga girer',
    _ => 'Virman satiri',
  };
}

IconData _movementTypeIcon(int movementType) {
  return switch (movementType) {
    1 => Icons.north_east_rounded,
    0 => Icons.south_west_rounded,
    _ => Icons.compare_arrows_rounded,
  };
}

Color _movementTypeForegroundColor(int movementType, BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return switch (movementType) {
    1 => const Color(0xFF9A4D00),
    0 => const Color(0xFF087443),
    _ => colorScheme.primary,
  };
}

Color _movementTypeBackgroundColor(int movementType, BuildContext context) {
  return switch (movementType) {
    1 => const Color(0xFFFFF4E6),
    0 => const Color(0xFFEAF8EF),
    _ => Theme.of(context).colorScheme.primaryContainer.withAlpha(56),
  };
}

String? _packageLabelForProduct(SearchProductLookupItem product) {
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

bool _hasVirmanFlowSummary({
  required int incomingLineCount,
  required int outgoingLineCount,
  required double incomingQuantity,
  required double outgoingQuantity,
}) {
  return incomingLineCount > 0 ||
      outgoingLineCount > 0 ||
      incomingQuantity > 0 ||
      outgoingQuantity > 0;
}

String _formatVirmanFlowSummary({
  required int incomingLineCount,
  required int outgoingLineCount,
  required double incomingQuantity,
  required double outgoingQuantity,
  required int lineCount,
  required double totalQuantity,
}) {
  if (!_hasVirmanFlowSummary(
    incomingLineCount: incomingLineCount,
    outgoingLineCount: outgoingLineCount,
    incomingQuantity: incomingQuantity,
    outgoingQuantity: outgoingQuantity,
  )) {
    return '$lineCount Mikro hareketi, toplam ${AppFormatters.quantity(totalQuantity)} miktar';
  }

  return 'Cikis $outgoingLineCount satir / ${AppFormatters.quantity(outgoingQuantity)}, '
      'Giris $incomingLineCount satir / ${AppFormatters.quantity(incomingQuantity)}';
}
