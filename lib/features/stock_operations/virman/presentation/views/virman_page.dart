import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/models/virman_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/virman_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/presentation/view_models/virman_controller.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/presentation/widgets/virman_create_sheet.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_picker.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/utils/safe_create_retry.dart';
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
        return VirmanCreateSheet(
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
