import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/presentation/view_models/inventory_counts_controller.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/presentation/widgets/inventory_count_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/data/offline_inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/presentation/views/offline_inventory_counts_page.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_lookup_cache_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_service.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class InventoryCountsPage extends StatefulWidget {
  const InventoryCountsPage({
    super.key,
    required this.repository,
    required this.offlineRepository,
    required this.accessToken,
    required this.canCreate,
    required this.lookupCacheRepository,
    required this.offlineSyncService,
    required this.currentUserId,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
  });

  final InventoryCountsRepository repository;
  final OfflineInventoryCountsRepository offlineRepository;
  final String accessToken;
  final bool canCreate;
  final OfflineLookupCacheRepository lookupCacheRepository;
  final OfflineSyncService offlineSyncService;
  final String currentUserId;
  final String defaultWarehouseNo;
  final String userWarehouseName;

  @override
  State<InventoryCountsPage> createState() => _InventoryCountsPageState();
}

class _InventoryCountsPageState extends State<InventoryCountsPage> {
  late final InventoryCountsController _controller;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSubmittingCreate = false;

  @override
  void initState() {
    super.initState();
    _controller = InventoryCountsController(
      repository: widget.repository,
      accessToken: widget.accessToken,
      defaultWarehouseNo: widget.defaultWarehouseNo,
    );
    _startDate = _controller.startDate;
    _endDate = _controller.endDate;
    unawaited(_controller.loadCounts());
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

  Future<void> _openCreateSheet() async {
    final request = await showModalBottomSheet<InventoryCountCreateRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return InventoryCountCreateSheet(
          repository: widget.repository,
          accessToken: widget.accessToken,
          currentUserId: widget.currentUserId,
          defaultWarehouseNo: widget.defaultWarehouseNo,
          lookupCacheRepository: widget.lookupCacheRepository,
        );
      },
    );

    if (request == null || !mounted) {
      return;
    }

    setState(() {
      _isSubmittingCreate = true;
    });

    try {
      final submission = await widget.offlineSyncService.submitInventoryCount(
        accessToken: widget.accessToken,
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        request: request,
      );

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();

      switch (submission.status) {
        case OfflineSubmissionStatus.synced:
        case OfflineSubmissionStatus.recovered:
          final result = submission.onlineResult;
          await _controller.loadCounts(
            preferredDocumentNo: result?.documentNo,
            preferredDocumentDate: result?.documentDate,
          );
          if (!mounted) {
            return;
          }
          if (result == null) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Kayit sunucuda islenmis olarak bulundu.'),
              ),
            );
            return;
          }
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Sayim #${result.documentNo} kaydedildi. '
                '${result.lineCount} satir, toplam ${AppFormatters.quantity(result.totalQuantity)} miktar.',
              ),
            ),
          );
        case OfflineSubmissionStatus.queued:
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Internet olmadigi icin sayim cihaza kaydedildi ve senkron kuyruguna eklendi.',
              ),
            ),
          );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingCreate = false;
        });
      }
    }
  }

  Future<void> _openOfflineDraftsPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return OfflineInventoryCountsPage(
            offlineRepository: widget.offlineRepository,
            onlineRepository: widget.repository,
            accessToken: widget.accessToken,
            offlineSyncService: widget.offlineSyncService,
            currentUserId: widget.currentUserId,
            defaultWarehouseNo: widget.defaultWarehouseNo,
            userWarehouseName: widget.userWarehouseName,
            standalone: true,
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    unawaited(_controller.loadCounts());
  }

  Future<void> _toggleSelection(InventoryCountListItem item) async {
    final selected = _controller.selectedCount;
    final isSameSelection =
        selected?.documentNo == item.documentNo &&
        selected?.documentDate == item.documentDate;

    if (isSameSelection) {
      _controller.clearSelection();
      return;
    }

    await _controller.selectCount(item);
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
              _InventoryCountsAccordionPanel(
                controller: _controller,
                onTap: _toggleSelection,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return TerminalListHeaderCard(
      title: 'Sayim Sonuclari',
      subtitle:
          'Depo bazli sayim gecmisi, detay ve yeni sayim kaydi ayni hizli akis icinde toplandi.',
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Varsayilan depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(label: 'Kayit', value: '${_controller.counts.length}'),
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
            onPressed: _isSubmittingCreate ? null : _openCreateSheet,
            icon: _isSubmittingCreate
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_task_rounded),
            label: Text(_isSubmittingCreate ? 'Kaydediliyor...' : 'Yeni Sayim'),
          ),
        if (widget.canCreate)
          OutlinedButton.icon(
            onPressed: _openOfflineDraftsPage,
            icon: const Icon(Icons.cloud_off_rounded),
            label: const Text('Offline Taslaklar'),
          ),
      ],
    );
  }
}

class _InventoryCountsAccordionPanel extends StatelessWidget {
  const _InventoryCountsAccordionPanel({
    required this.controller,
    required this.onTap,
  });

  final InventoryCountsController controller;
  final ValueChanged<InventoryCountListItem> onTap;

  @override
  Widget build(BuildContext context) {
    if (controller.listError != null && controller.counts.isEmpty) {
      return SectionCard(
        title: 'Sayim Listesi',
        subtitle: 'Listeleme sirasinda hata olustu.',
        child: _ErrorBlock(message: controller.listError!),
      );
    }

    return SectionCard(
      title: 'Sayim Listesi',
      subtitle: controller.isLoadingList
          ? 'Liste yenileniyor...'
          : '${controller.counts.length} kayit bulundu.',
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
          else if (controller.counts.isEmpty)
            const _EmptyState(
              message: 'Secilen tarih araliginda sayim sonucu bulunamadi.',
            )
          else
            Column(
              children: controller.counts
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InventoryCountAccordionCard(
                        item: item,
                        isExpanded:
                            controller.selectedCount?.documentNo ==
                                item.documentNo &&
                            controller.selectedCount?.documentDate ==
                                item.documentDate,
                        detail:
                            controller.selectedCount?.documentNo ==
                                    item.documentNo &&
                                controller.selectedCount?.documentDate ==
                                    item.documentDate
                            ? controller.selectedCountDetail
                            : null,
                        isLoadingDetail:
                            controller.selectedCount?.documentNo ==
                                item.documentNo &&
                            controller.selectedCount?.documentDate ==
                                item.documentDate &&
                            controller.isLoadingDetail,
                        detailError:
                            controller.selectedCount?.documentNo ==
                                    item.documentNo &&
                                controller.selectedCount?.documentDate ==
                                    item.documentDate
                            ? controller.detailError
                            : null,
                        onTap: () => onTap(item),
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

class _InventoryCountAccordionCard extends StatelessWidget {
  const _InventoryCountAccordionCard({
    required this.item,
    required this.isExpanded,
    required this.detail,
    required this.isLoadingDetail,
    required this.detailError,
    required this.onTap,
  });

  final InventoryCountListItem item;
  final bool isExpanded;
  final InventoryCountDetail? detail;
  final bool isLoadingDetail;
  final String? detailError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isExpanded ? const Color(0xFFFFF8F0) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isExpanded
                  ? theme.colorScheme.primary.withAlpha(110)
                  : theme.colorScheme.outlineVariant.withAlpha(88),
              width: isExpanded ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: _InlineField(
                      label: 'Belge No',
                      value: '#${item.documentNo}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _InlineField(
                      label: 'Belge Trh',
                      value: AppFormatters.dateOrDash(item.documentDate),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: _InlineField(
                      label: 'Sayim Adi',
                      value: item.name.isEmpty ? '-' : item.name,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    flex: 4,
                    child: _InlineField(
                      label: 'Olusturma',
                      value: AppFormatters.dateTimeOrDash(item.createdAt),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _InlineField(
                      label: 'Miktar',
                      value: AppFormatters.quantity(item.totalQuantity),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Badge(label: '${item.lineCount} satir'),
                  const SizedBox(width: 2),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _DetailBody(
                          detail: detail,
                          isLoading: isLoadingDetail,
                          errorMessage: detailError,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.detail,
    required this.isLoading,
    required this.errorMessage,
  });

  final InventoryCountDetail? detail;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return _ErrorBlock(message: errorMessage!);
    }

    if (detail == null) {
      return const _EmptyState(message: 'Detay bilgisi yuklenemedi.');
    }

    final currentDetail = detail!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EFE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(86),
        ),
      ),
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
          if (currentDetail.items.isEmpty)
            const _EmptyState(message: 'Bu sayimda kalem bulunamadi.')
          else
            Column(
              children: currentDetail.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CountItemCard(item: item),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _CountItemCard extends StatelessWidget {
  const _CountItemCard({required this.item});

  final InventoryCountLineItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = <String>[
      'Kod ${item.stockCode}',
      'Barkod ${item.barcode.isEmpty ? '-' : item.barcode}',
      'Birim ${item.unitName}/${item.unitPointer}',
      'Toplam ${AppFormatters.quantity(item.totalQuantity)}',
    ].join(' | ');
    final detail = <String>[
      if (item.quantity1 > 0) 'Q1 ${AppFormatters.quantity(item.quantity1)}',
      if (item.quantity2 > 0) 'Q2 ${AppFormatters.quantity(item.quantity2)}',
      if (item.quantity3 > 0) 'Q3 ${AppFormatters.quantity(item.quantity3)}',
      if (item.quantity4 > 0) 'Q4 ${AppFormatters.quantity(item.quantity4)}',
      if (item.quantity5 > 0) 'Q5 ${AppFormatters.quantity(item.quantity5)}',
    ].join(' | ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(82),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
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
              _Badge(label: 'Satir ${item.rowNo}'),
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

class _InlineField extends StatelessWidget {
  const _InlineField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: const Color(0xFF6B5A4A),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: const Color(0xFF231C17),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(14),
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
