import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/presentation/view_models/warehouse_orders_controller.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_picker.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_create_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

typedef WarehouseOrderCreateSheetBuilder =
    Widget Function(
      BuildContext context,
      CreateDraft? draft,
      CreateDraftRepository? draftRepository,
    );

class WarehouseOrdersPage extends StatefulWidget {
  const WarehouseOrdersPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.canCreate,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
    required this.title,
    required this.subtitle,
    this.emptyListMessage = 'Secilen tarih araliginda siparis bulunamadi.',
    this.createSheetBuilder,
    this.currentUserId = '',
    this.draftModuleKey = '',
    this.draftRepository,
    this.createTitle = 'Yeni Siparis',
  });

  final WarehouseOrdersRepository repository;
  final String accessToken;
  final bool canCreate;
  final String defaultWarehouseNo;
  final String userWarehouseName;
  final String title;
  final String subtitle;
  final String emptyListMessage;
  final WarehouseOrderCreateSheetBuilder? createSheetBuilder;
  final String currentUserId;
  final String draftModuleKey;
  final CreateDraftRepository? draftRepository;
  final String createTitle;

  @override
  State<WarehouseOrdersPage> createState() => _WarehouseOrdersPageState();
}

class _WarehouseOrdersPageState extends State<WarehouseOrdersPage> {
  late final WarehouseOrdersController _controller;
  late DateTime _startDate;
  late DateTime _endDate;

  bool get _canCreate {
    return widget.canCreate &&
        widget.repository.supportsCreate &&
        widget.createSheetBuilder != null;
  }

  @override
  void initState() {
    super.initState();
    _controller = WarehouseOrdersController(
      repository: widget.repository,
      accessToken: widget.accessToken,
      defaultWarehouseNo: widget.defaultWarehouseNo,
    );
    _startDate = _controller.startDate;
    _endDate = _controller.endDate;
    unawaited(_controller.loadOrders());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = DateTime(DateTime.now().year - 3);
    final lastDate = DateTime(DateTime.now().year + 2, 12, 31);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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

  Future<void> _openCreateSheet() async {
    final createSheetBuilder = widget.createSheetBuilder;

    if (createSheetBuilder == null) {
      return;
    }

    CreateDraft? draft;
    if (widget.draftRepository != null && widget.draftModuleKey.isNotEmpty) {
      final launch = await showCreateDraftPicker(
        context: context,
        repository: widget.draftRepository!,
        moduleKey: widget.draftModuleKey,
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        createTitle: widget.createTitle,
      );
      if (launch == null || !mounted) {
        return;
      }
      draft =
          launch.draft ??
          CreateDraft.empty(
            moduleKey: widget.draftModuleKey,
            userId: widget.currentUserId,
            warehouseNo: widget.defaultWarehouseNo,
            title: widget.createTitle,
          );
    }

    final request = await openTerminalCreatePage<WarehouseOrderCreateRequest>(
      context: context,
      title: widget.createTitle,
      builder: (context) =>
          createSheetBuilder(context, draft, widget.draftRepository),
    );

    if (request == null || !mounted) {
      return;
    }

    final result = await _controller.createOrder(request);

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_controller.createError ?? 'Siparis olusturulamadi.'),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.documentNoLabel} olusturuldu. '
          '${result.lineCount} satir, toplam ${AppFormatters.quantity(result.totalQuantity)} miktar.',
        ),
      ),
    );
    if (draft != null) {
      await widget.draftRepository?.deleteDraft(draft.id);
    }
  }

  Future<void> _toggleOrderSelection(WarehouseOrderListItem item) async {
    await _controller.selectOrder(item);
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
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
                      _OrderAccordionCard(
                        item: item,
                        isExpanded: true,
                        detail: _controller.selectedOrderDetail,
                        isLoadingDetail: _controller.isLoadingDetail,
                        detailError: _controller.detailError,
                        onTap: () {},
                      ),
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
              _buildHeader(context),
              const SizedBox(height: 16),
              _OrdersAccordionPanel(
                controller: _controller,
                emptyListMessage: widget.emptyListMessage,
                onOrderTap: _toggleOrderSelection,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return TerminalListHeaderCard(
      title: widget.title,
      subtitle: widget.subtitle,
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Varsayilan depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(label: 'Kayit', value: '${_controller.orders.length}'),
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
        if (_canCreate)
          FilledButton.tonalIcon(
            onPressed: _controller.isCreating ? null : _openCreateSheet,
            icon: _controller.isCreating
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded),
            label: Text(
              _controller.isCreating ? 'Kaydediliyor...' : 'Yeni Siparis',
            ),
          ),
      ],
    );
  }
}

class _OrdersAccordionPanel extends StatelessWidget {
  const _OrdersAccordionPanel({
    required this.controller,
    required this.emptyListMessage,
    required this.onOrderTap,
  });

  final WarehouseOrdersController controller;
  final String emptyListMessage;
  final ValueChanged<WarehouseOrderListItem> onOrderTap;

  @override
  Widget build(BuildContext context) {
    if (controller.listError != null && controller.orders.isEmpty) {
      return SectionCard(
        title: 'Siparis Listesi',
        subtitle: 'Listeleme sirasinda hata olustu.',
        child: _ErrorBlock(message: controller.listError!),
      );
    }

    return SectionCard(
      title: 'Siparis Listesi',
      subtitle: controller.isLoadingList
          ? 'Liste yenileniyor...'
          : '${controller.orders.length} kayit bulundu.',
      child: Column(
        children: <Widget>[
          if (controller.listError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ErrorBlock(message: controller.listError!),
            ),
          if (controller.isLoadingList)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: CircularProgressIndicator(),
            )
          else if (controller.orders.isEmpty)
            _EmptyState(message: emptyListMessage)
          else
            Column(
              children: controller.orders
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _OrderAccordionCard(
                        item: item,
                        isExpanded:
                            controller.selectedOrder?.documentKey ==
                            item.documentKey,
                        detail:
                            controller.selectedOrder?.documentKey ==
                                item.documentKey
                            ? controller.selectedOrderDetail
                            : null,
                        isLoadingDetail:
                            controller.selectedOrder?.documentKey ==
                                item.documentKey &&
                            controller.isLoadingDetail,
                        detailError:
                            controller.selectedOrder?.documentKey ==
                                item.documentKey
                            ? controller.detailError
                            : null,
                        onTap: () => onOrderTap(item),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _OrderAccordionCard extends StatelessWidget {
  const _OrderAccordionCard({
    required this.item,
    required this.isExpanded,
    required this.detail,
    required this.isLoadingDetail,
    required this.detailError,
    required this.onTap,
  });

  final WarehouseOrderListItem item;
  final bool isExpanded;
  final WarehouseOrderDetail? detail;
  final bool isLoadingDetail;
  final String? detailError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TerminalPdaRecordCard(
      isSelected: isExpanded,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TerminalPdaCardHeader(
            title: item.documentNoLabel,
            subtitle: item.relatedWarehouseName,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TerminalBadge(label: '${item.lineCount} satir'),
                const SizedBox(height: 4),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.chevron_right_rounded,
                  size: 26,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TerminalPdaInfoGrid(
            items: <TerminalPdaInfo>[
              TerminalPdaInfo(
                label: 'Belge Trh',
                value: AppFormatters.dateOrDash(item.documentDate),
              ),
              TerminalPdaInfo(
                label: 'Teslim',
                value: AppFormatters.dateOrDash(item.deliveryDate),
              ),
              TerminalPdaInfo(
                label: 'Miktar',
                value: AppFormatters.quantity(item.totalQuantity),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _AccordionDetailBody(
                      detail: detail,
                      isLoading: isLoadingDetail,
                      errorMessage: detailError,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _AccordionDetailBody extends StatelessWidget {
  const _AccordionDetailBody({
    required this.detail,
    required this.isLoading,
    required this.errorMessage,
  });

  final WarehouseOrderDetail? detail;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final currentDetail = detail;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return _ErrorBlock(message: errorMessage!);
    }

    if (currentDetail == null) {
      return const _EmptyState(message: 'Detay bilgisi yuklenemedi.');
    }

    return TerminalPdaDetailPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Kalemler',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _OrderItemsList(items: currentDetail.items),
        ],
      ),
    );
  }
}

class _OrderItemsList extends StatelessWidget {
  const _OrderItemsList({required this.items});

  final List<WarehouseOrderDetailItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(message: 'Bu sipariste kalem bulunamadi.');
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OrderItemCard(item: item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({required this.item});

  final WarehouseOrderDetailItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greenGrocerCase = item.greenGrocerCase;
    final summary = <String>[
      'Kod ${item.stockCode}',
      'Birim ${item.unitName}',
      'Miktar ${AppFormatters.quantity(item.quantity)}',
      'Teslim ${AppFormatters.quantity(item.deliveredQuantity)}',
      'Kalan ${AppFormatters.quantity(item.remainingQuantity)}',
      if (greenGrocerCase != null)
        'Talep ${AppFormatters.quantity(greenGrocerCase.inputQuantity)} '
            '${greenGrocerCase.displayInputMode} ~= '
            '${AppFormatters.quantity(greenGrocerCase.estimatedQuantity)} '
            '${greenGrocerCase.microUnit}',
      if (item.unitPrice > 0) 'Fiyat ${AppFormatters.currency(item.unitPrice)}',
      if (item.lineAmount > 0)
        'Tutar ${AppFormatters.currency(item.lineAmount)}',
    ].join(' | ');
    final detail = <String>[
      if (item.description.trim().isNotEmpty) 'Aciklama ${item.description}',
      if ((greenGrocerCase?.status.trim().isNotEmpty ?? false))
        'Manav ${greenGrocerCase!.status}',
      if (item.isClosed) 'Durum Kapali',
    ].join(' | ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(82),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  item.stockName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF231C17),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _AccentBadge(label: 'Satir ${item.lineNo}'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B5A4A),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detail.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B5A4A),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccentBadge extends StatelessWidget {
  const _AccentBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAA3A3)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF7A1818)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
