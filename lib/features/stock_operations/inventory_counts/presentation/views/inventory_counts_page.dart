import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/presentation/view_models/inventory_counts_controller.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/presentation/widgets/inventory_count_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/data/offline_inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/presentation/views/offline_inventory_counts_page.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_picker.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_service.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_create_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class InventoryCountsPage extends StatefulWidget {
  const InventoryCountsPage({
    super.key,
    required this.repository,
    required this.offlineRepository,
    required this.accessToken,
    required this.canCreate,
    required this.offlineSyncService,
    required this.mobileProductCatalogRepository,
    required this.currentUserId,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
    this.draftRepository,
  });

  final InventoryCountsRepository repository;
  final OfflineInventoryCountsRepository offlineRepository;
  final String accessToken;
  final bool canCreate;
  final OfflineSyncService offlineSyncService;
  final MobileProductCatalogLocalRepository mobileProductCatalogRepository;
  final String currentUserId;
  final String defaultWarehouseNo;
  final String userWarehouseName;
  final CreateDraftRepository? draftRepository;

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
    CreateDraft? draft;
    if (widget.draftRepository != null) {
      final launch = await showCreateDraftPicker(
        context: context,
        repository: widget.draftRepository!,
        moduleKey: 'stok-islemleri.sayim-sonuclari',
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        createTitle: 'Yeni Sayim Sonucu',
      );
      if (launch == null || !mounted) {
        return;
      }
      draft =
          launch.draft ??
          CreateDraft.empty(
            moduleKey: 'stok-islemleri.sayim-sonuclari',
            userId: widget.currentUserId,
            warehouseNo: widget.defaultWarehouseNo,
            title: 'Yeni Sayim Sonucu',
          );
    }

    final request = await openTerminalCreatePage<InventoryCountCreateRequest>(
      context: context,
      title: 'Yeni Sayim',
      builder: (context) {
        return InventoryCountCreateSheet(
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
          if (draft != null) {
            await widget.draftRepository?.deleteDraft(draft.id);
          }
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
          if (draft != null) {
            await widget.draftRepository?.deleteDraft(draft.id);
          }
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
            mobileProductCatalogRepository:
                widget.mobileProductCatalogRepository,
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
    await _controller.selectCount(item);
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
                appBar: AppBar(title: Text('#${item.documentNo}')),
                body: SafeArea(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      20 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: <Widget>[
                      _InventoryCountAccordionCard(
                        item: item,
                        isExpanded: true,
                        detail: _controller.selectedCountDetail,
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

    return TerminalPdaRecordCard(
      isSelected: isExpanded,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TerminalPdaCardHeader(
            title: item.name.isEmpty ? '#${item.documentNo}' : item.name,
            subtitle: 'Belge #${item.documentNo}',
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
                label: 'Olusturma',
                value: AppFormatters.dateTimeOrDash(item.createdAt),
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
      'Birim ${item.unitName}',
      'Toplam ${AppFormatters.quantity(item.totalQuantity)}',
    ].join(' | ');
    final detail = <String>[
      if (item.quantity1 > 0)
        'Miktar 1 ${AppFormatters.quantity(item.quantity1)}',
      if (item.quantity2 > 0)
        'Miktar 2 ${AppFormatters.quantity(item.quantity2)}',
      if (item.quantity3 > 0)
        'Miktar 3 ${AppFormatters.quantity(item.quantity3)}',
      if (item.quantity4 > 0)
        'Miktar 4 ${AppFormatters.quantity(item.quantity4)}',
      if (item.quantity5 > 0)
        'Miktar 5 ${AppFormatters.quantity(item.quantity5)}',
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
