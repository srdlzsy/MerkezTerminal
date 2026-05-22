import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/models/stock_receipt_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/stock_receipts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/presentation/view_models/stock_receipts_controller.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/presentation/widgets/stock_receipt_create_sheet.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
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
  });

  final StockReceiptsRepository repository;
  final StockReceiptKind kind;
  final String accessToken;
  final bool canCreate;
  final String defaultWarehouseNo;
  final String userWarehouseName;

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
    if (_controller.selectedReceipt?.documentNoLabel == item.documentNoLabel) {
      _controller.clearSelection();
      return;
    }

    await _controller.selectReceipt(item);
  }

  Future<void> _openCreateSheet() async {
    final request = await showModalBottomSheet<StockReceiptCreateRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return StockReceiptCreateSheet(
          repository: widget.repository,
          kind: widget.kind,
          accessToken: widget.accessToken,
          defaultWarehouseNo: widget.defaultWarehouseNo,
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
      subtitle:
          'Liste, detay ve yeni fis olusturma akisi ayni ekranda toplandi.',
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
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _toggleSelection(item),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isExpanded
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withAlpha(90),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: TerminalLabeledValue(
                                        label: 'Belge',
                                        value: item.documentNoLabel,
                                      ),
                                    ),
                                    Expanded(
                                      child: TerminalLabeledValue(
                                        label: 'Olusturan',
                                        value: item.creator.isEmpty
                                            ? '-'
                                            : item.creator,
                                      ),
                                    ),
                                    TerminalBadge(
                                      label: '${item.lineCount} satir',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: TerminalLabeledValue(
                                        label: 'Belge Trh',
                                        value: AppFormatters.dateOrDash(
                                          item.documentDate,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TerminalLabeledValue(
                                        label: 'Toplam',
                                        value: AppFormatters.quantity(
                                          item.totalQuantity,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (isExpanded) ...<Widget>[
                                  const SizedBox(height: 12),
                                  if (_controller.isLoadingDetail)
                                    const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  else if (_controller.detailError != null)
                                    TerminalMessageBlock.error(
                                      message: _controller.detailError!,
                                    )
                                  else if (detail == null)
                                    const TerminalEmptyState(
                                      message: 'Detay bilgisi yuklenemedi.',
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        ...detail.items.map((line) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outlineVariant
                                                      .withAlpha(82),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    line.stockName,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Kod ${line.stockCode} | Miktar ${AppFormatters.quantity(line.quantity)} | Birim ${line.unitName}/${line.unitPointer}',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                ],
                              ],
                            ),
                          ),
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
