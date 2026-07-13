import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/models/stock_receipt_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/stock_receipts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/presentation/view_models/stock_receipts_controller.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/presentation/widgets/stock_receipt_create_sheet.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_picker.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_create_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class StockReceiptsPage extends StatefulWidget {
  const StockReceiptsPage({
    super.key,
    required this.repository,
    required this.kind,
    required this.accessToken,
    required this.canCreate,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
    required this.currentUserId,
    this.draftRepository,
  });

  final StockReceiptsRepository repository;
  final StockReceiptKind kind;
  final String accessToken;
  final bool canCreate;
  final String defaultWarehouseNo;
  final String userWarehouseName;
  final String currentUserId;
  final CreateDraftRepository? draftRepository;

  @override
  State<StockReceiptsPage> createState() => _StockReceiptsPageState();
}

class _StockReceiptsPageState extends State<StockReceiptsPage> {
  late final StockReceiptsController _controller;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _controller = StockReceiptsController(
      repository: widget.repository,
      accessToken: widget.accessToken,
      defaultWarehouseNo: widget.defaultWarehouseNo,
      kind: widget.kind,
    );
    _startDate = _controller.startDate;
    _endDate = _controller.endDate;
    unawaited(_controller.loadReceipts());
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

  Future<void> _toggleSelection(StockReceiptListItem item) async {
    await _controller.selectReceipt(item);
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              final detail = _controller.selectedReceiptDetail;

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
                      _StockReceiptSummaryCard(item: item),
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
                        _StockReceiptDetailSection(detail: detail),
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
    final moduleKey = 'stok-islemleri.${widget.kind.pathSegment}';
    CreateDraft? draft;
    if (widget.draftRepository != null) {
      final launch = await showCreateDraftPicker(
        context: context,
        repository: widget.draftRepository!,
        moduleKey: moduleKey,
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        createTitle: widget.kind.createTitle,
      );
      if (launch == null || !mounted) {
        return;
      }
      draft =
          launch.draft ??
          CreateDraft.empty(
            moduleKey: moduleKey,
            userId: widget.currentUserId,
            warehouseNo: widget.defaultWarehouseNo,
            title: widget.kind.createTitle,
          );
    }

    final request = await openTerminalCreatePage<StockReceiptCreateRequest>(
      context: context,
      title: widget.kind.createTitle,
      builder: (context) {
        return StockReceiptCreateSheet(
          repository: widget.repository,
          kind: widget.kind,
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

    final result = await _controller.createReceipt(request);

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_controller.createError ?? 'Fis kaydedilemedi.'),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.documentNoLabel} kaydedildi. ${result.lineCount} satir, toplam ${AppFormatters.quantity(result.totalQuantity)} miktar.',
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
      title: widget.kind.pageTitle,
      subtitle: 'Fisleri tarih araligina gore listeleyin ve yeni fis acin.',
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Varsayilan depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(
          label: 'Kayit',
          value: '${_controller.receipts.length}',
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
                : const Icon(Icons.add_circle_outline_rounded),
            label: Text(
              _controller.isCreating
                  ? 'Kaydediliyor...'
                  : widget.kind.createButtonLabel,
            ),
          ),
      ],
    );
  }

  Widget _buildListCard() {
    if (_controller.listError != null && _controller.receipts.isEmpty) {
      return SectionCard(
        title: 'Fis Listesi',
        subtitle: 'Listeleme sirasinda hata olustu.',
        child: TerminalMessageBlock.error(message: _controller.listError!),
      );
    }

    return SectionCard(
      title: 'Fis Listesi',
      subtitle: _controller.isLoadingList
          ? 'Liste yenileniyor...'
          : '${_controller.receipts.length} kayit bulundu.',
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
          else if (_controller.receipts.isEmpty)
            TerminalEmptyState(
              message:
                  'Secilen tarih araliginda ${widget.kind == StockReceiptKind.outage ? 'zayiat' : 'masraf'} fisi bulunamadi.',
            )
          else
            Column(
              children: _controller.receipts
                  .map((item) {
                    final isExpanded =
                        _controller.selectedReceipt?.documentNoLabel ==
                        item.documentNoLabel;
                    final detail = isExpanded
                        ? _controller.selectedReceiptDetail
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
                              subtitle: item.creator.isEmpty
                                  ? 'Olusturan -'
                                  : 'Olusturan ${item.creator}',
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

class _StockReceiptSummaryCard extends StatelessWidget {
  const _StockReceiptSummaryCard({required this.item});

  final StockReceiptListItem item;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Fis Detayi',
      subtitle: item.documentNoLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TerminalPdaInfoGrid(
            items: <TerminalPdaInfo>[
              TerminalPdaInfo(label: 'Belge', value: item.documentNoLabel),
              TerminalPdaInfo(
                label: 'Olusturan',
                value: item.creator.isEmpty ? '-' : item.creator,
              ),
              TerminalPdaInfo(
                label: 'Belge Trh',
                value: AppFormatters.dateOrDash(item.documentDate),
              ),
              TerminalPdaInfo(
                label: 'Toplam',
                value: AppFormatters.quantity(item.totalQuantity),
              ),
              TerminalPdaInfo(label: 'Satir', value: '${item.lineCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockReceiptDetailSection extends StatelessWidget {
  const _StockReceiptDetailSection({required this.detail});

  final StockReceiptDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.items.isEmpty) {
      return const TerminalEmptyState(message: 'Bu fis icin satir yok.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: detail.items
          .map((line) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TerminalPdaDetailPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      line.stockName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
