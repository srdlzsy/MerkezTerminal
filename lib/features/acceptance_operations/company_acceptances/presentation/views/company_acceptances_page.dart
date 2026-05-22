import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/models/company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/presentation/view_models/company_acceptances_controller.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/presentation/widgets/company_acceptance_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/offline_company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/presentation/views/offline_company_acceptances_page.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/given_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_lookup_cache_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_service.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class CompanyAcceptancesPage extends StatefulWidget {
  const CompanyAcceptancesPage({
    super.key,
    required this.repository,
    required this.offlineRepository,
    required this.ordersRepository,
    required this.accessToken,
    required this.canCreate,
    required this.lookupCacheRepository,
    required this.offlineSyncService,
    required this.currentUserId,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
  });

  final CompanyAcceptancesRepository repository;
  final OfflineCompanyAcceptancesRepository offlineRepository;
  final GivenCompanyOrdersRepository ordersRepository;
  final String accessToken;
  final bool canCreate;
  final OfflineLookupCacheRepository lookupCacheRepository;
  final OfflineSyncService offlineSyncService;
  final String currentUserId;
  final String defaultWarehouseNo;
  final String userWarehouseName;

  @override
  State<CompanyAcceptancesPage> createState() => _CompanyAcceptancesPageState();
}

class _CompanyAcceptancesPageState extends State<CompanyAcceptancesPage> {
  late final CompanyAcceptancesController _controller;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSubmittingCreate = false;

  @override
  void initState() {
    super.initState();
    _controller = CompanyAcceptancesController(
      repository: widget.repository,
      accessToken: widget.accessToken,
      defaultWarehouseNo: widget.defaultWarehouseNo,
    );
    _startDate = _controller.startDate;
    _endDate = _controller.endDate;
    unawaited(_controller.loadAcceptances());
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

  Future<void> _toggleSelection(CompanyMovementListItem item) async {
    if (_controller.selectedAcceptance?.documentNoLabel ==
        item.documentNoLabel) {
      _controller.clearSelection();
      return;
    }

    await _controller.selectAcceptance(item);
  }

  Future<void> _openCreateSheet() async {
    final request = await showModalBottomSheet<CompanyAcceptanceCreateRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return CompanyAcceptanceCreateSheet(
          repository: widget.repository,
          ordersRepository: widget.ordersRepository,
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
      final submission = await widget.offlineSyncService
          .submitCompanyAcceptance(
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
          await _controller.loadAcceptances(
            preferredDocumentSerie: result?.documentSerie,
            preferredDocumentOrderNo: result?.documentOrderNo,
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
          final returnDocumentLabel = result.autoCreatedReturnDocumentNoLabel;
          final returnInfo = result.totalReturnedQuantity > 0
              ? ' Net kabul ${AppFormatters.quantity(result.totalNetAcceptedQuantity)}, iade ${AppFormatters.quantity(result.totalReturnedQuantity)}${returnDocumentLabel == null ? '' : ' ($returnDocumentLabel ${result.returnEDespatchStatus})'}.'
              : ' Net kabul ${AppFormatters.quantity(result.totalNetAcceptedQuantity)}.';
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                '${result.documentNoLabel} kaydedildi. ${result.lineCount} satir, irsaliye ${AppFormatters.quantity(result.totalDispatchQuantity)}.$returnInfo',
              ),
            ),
          );
        case OfflineSubmissionStatus.queued:
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Internet olmadigi icin mal kabul cihaza kaydedildi ve senkron kuyruguna eklendi.',
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
          return OfflineCompanyAcceptancesPage(
            offlineRepository: widget.offlineRepository,
            onlineRepository: widget.repository,
            ordersRepository: widget.ordersRepository,
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

    unawaited(_controller.loadAcceptances());
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
      title: 'Firma Mal Kabulleri',
      subtitle:
          'Gecmis fisleri listeler; yeni fiste siparisli ve siparissiz satirlar ayni kabul evraginda birlesebilir.',
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Varsayilan depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(
          label: 'Kayit',
          value: '${_controller.acceptances.length}',
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
            onPressed: _isSubmittingCreate ? null : _openCreateSheet,
            icon: _isSubmittingCreate
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_task_rounded),
            label: Text(
              _isSubmittingCreate ? 'Kaydediliyor...' : 'Yeni Mal Kabul',
            ),
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

  Widget _buildListCard() {
    if (_controller.listError != null && _controller.acceptances.isEmpty) {
      return SectionCard(
        title: 'Mal Kabul Listesi',
        subtitle: 'Listeleme sirasinda hata olustu.',
        child: TerminalMessageBlock.error(message: _controller.listError!),
      );
    }

    return SectionCard(
      title: 'Mal Kabul Listesi',
      subtitle: _controller.isLoadingList
          ? 'Liste yenileniyor...'
          : '${_controller.acceptances.length} kayit bulundu.',
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
          else if (_controller.acceptances.isEmpty)
            const TerminalEmptyState(
              message:
                  'Secilen tarih araliginda firma mal kabul kaydi bulunamadi.',
            )
          else
            Column(
              children: _controller.acceptances
                  .map((item) {
                    final isExpanded =
                        _controller.selectedAcceptance?.documentNoLabel ==
                        item.documentNoLabel;
                    final detail = isExpanded
                        ? _controller.selectedAcceptanceDetail
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
                                        label: 'Cari',
                                        value: item.customerDisplayName,
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
                                        label: 'Toplam Kabul',
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
                                                    'Kod ${line.stockCode} | Miktar ${AppFormatters.quantity(line.quantity)} | Birim ${line.unitName}/${line.unitPointer}${line.orderGuid.isNotEmpty ? ' | Siparis ${line.orderGuid}' : ''}',
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
