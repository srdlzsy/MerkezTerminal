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
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_picker.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_service.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_create_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class CompanyAcceptancesPage extends StatefulWidget {
  const CompanyAcceptancesPage({
    super.key,
    required this.repository,
    required this.offlineRepository,
    required this.ordersRepository,
    required this.accessToken,
    required this.canCreate,
    required this.offlineSyncService,
    required this.mobileCustomerCatalogRepository,
    required this.mobileProductCatalogRepository,
    required this.currentUserId,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
    this.draftRepository,
  });

  final CompanyAcceptancesRepository repository;
  final OfflineCompanyAcceptancesRepository offlineRepository;
  final GivenCompanyOrdersRepository ordersRepository;
  final String accessToken;
  final bool canCreate;
  final OfflineSyncService offlineSyncService;
  final MobileCustomerCatalogLocalRepository mobileCustomerCatalogRepository;
  final MobileProductCatalogLocalRepository mobileProductCatalogRepository;
  final String currentUserId;
  final String defaultWarehouseNo;
  final String userWarehouseName;
  final CreateDraftRepository? draftRepository;

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
    await _controller.selectAcceptance(item);
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              final detail = _controller.selectedAcceptanceDetail;

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
                      _CompanyAcceptanceSummaryCard(item: item),
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
                        _CompanyAcceptanceDetailSection(detail: detail),
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
        moduleKey: 'mal-kabul-islemleri.firma-mal-kabulleri',
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        createTitle: 'Yeni Firma Mal Kabul',
      );
      if (launch == null || !mounted) {
        return;
      }
      draft =
          launch.draft ??
          CreateDraft.empty(
            moduleKey: 'mal-kabul-islemleri.firma-mal-kabulleri',
            userId: widget.currentUserId,
            warehouseNo: widget.defaultWarehouseNo,
            title: 'Yeni Firma Mal Kabul',
          );
    }

    final request =
        await openTerminalCreatePage<CompanyAcceptanceCreateRequest>(
          context: context,
          title: 'Yeni Mal Kabul',
          builder: (context) {
            return CompanyAcceptanceCreateSheet(
              repository: widget.repository,
              ordersRepository: widget.ordersRepository,
              accessToken: widget.accessToken,
              defaultWarehouseNo: widget.defaultWarehouseNo,
              mobileCustomerCatalogRepository:
                  widget.mobileCustomerCatalogRepository,
              mobileProductCatalogRepository:
                  widget.mobileProductCatalogRepository,
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
          if (draft != null) {
            await widget.draftRepository?.deleteDraft(draft.id);
          }
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
          if (draft != null) {
            await widget.draftRepository?.deleteDraft(draft.id);
          }
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
            mobileCustomerCatalogRepository:
                widget.mobileCustomerCatalogRepository,
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
      subtitle: 'Gecmis kabulleri listeleyin ve yeni mal kabul baslatin.',
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
                      child: TerminalPdaRecordCard(
                        isSelected: isExpanded,
                        onTap: () => _toggleSelection(item),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            TerminalPdaCardHeader(
                              title: item.documentNoLabel,
                              subtitle: item.customerDisplayName,
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
                                  label: 'Toplam Kabul',
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

class _CompanyAcceptanceSummaryCard extends StatelessWidget {
  const _CompanyAcceptanceSummaryCard({required this.item});

  final CompanyMovementListItem item;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Mal Kabul Detayi',
      subtitle: item.documentNoLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TerminalPdaInfoGrid(
            items: <TerminalPdaInfo>[
              TerminalPdaInfo(label: 'Belge', value: item.documentNoLabel),
              TerminalPdaInfo(label: 'Cari', value: item.customerDisplayName),
              TerminalPdaInfo(
                label: 'Belge Trh',
                value: AppFormatters.dateOrDash(item.documentDate),
              ),
              TerminalPdaInfo(
                label: 'Toplam Kabul',
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

class _CompanyAcceptanceDetailSection extends StatelessWidget {
  const _CompanyAcceptanceDetailSection({required this.detail});

  final CompanyMovementDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.items.isEmpty) {
      return const TerminalEmptyState(
        message: 'Bu mal kabulde satir bulunamadi.',
      );
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
                    if (line.description.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        line.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
