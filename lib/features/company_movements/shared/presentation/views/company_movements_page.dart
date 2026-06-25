import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/company_movements_repository.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/presentation/view_models/company_movements_controller.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/presentation/widgets/company_movement_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/presentation/views/warehouse_return_pdf_preview_page.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/presentation/widgets/warehouse_return_e_despatch_sheet.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_picker.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class CompanyMovementsPage extends StatefulWidget {
  const CompanyMovementsPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.canCreate,
    this.currentUserId = '',
    this.draftModuleKey = '',
    this.draftRepository,
    required this.defaultWarehouseNo,
    required this.mobileCustomerCatalogRepository,
    required this.userWarehouseName,
    required this.title,
    required this.subtitle,
    required this.createTitle,
    required this.createHelperText,
    required this.createButtonLabel,
    this.emptyListMessage = 'Secilen tarih araliginda kayit bulunamadi.',
    this.showCreateDocumentNoField = true,
  });

  final CompanyMovementsRepository repository;
  final String accessToken;
  final bool canCreate;
  final String currentUserId;
  final String draftModuleKey;
  final CreateDraftRepository? draftRepository;
  final String defaultWarehouseNo;
  final MobileCustomerCatalogLocalRepository mobileCustomerCatalogRepository;
  final String userWarehouseName;
  final String title;
  final String subtitle;
  final String createTitle;
  final String createHelperText;
  final String createButtonLabel;
  final String emptyListMessage;
  final bool showCreateDocumentNoField;

  @override
  State<CompanyMovementsPage> createState() => _CompanyMovementsPageState();
}

class _CompanyMovementsPageState extends State<CompanyMovementsPage> {
  late final CompanyMovementsController _controller;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _controller = CompanyMovementsController(
      repository: widget.repository,
      accessToken: widget.accessToken,
      defaultWarehouseNo: widget.defaultWarehouseNo,
    );
    _startDate = _controller.startDate;
    _endDate = _controller.endDate;
    unawaited(_controller.loadMovements());
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
    if (_controller.selectedMovement?.documentNoLabel == item.documentNoLabel) {
      _controller.clearSelection();
      return;
    }

    await _controller.selectMovement(item);
  }

  Future<void> _openCreateSheet() async {
    CreateDraft? draft;
    final draftRepository = widget.draftRepository;
    if (draftRepository != null && widget.draftModuleKey.isNotEmpty) {
      final launch = await showCreateDraftPicker(
        context: context,
        repository: draftRepository,
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

    final request = await showModalBottomSheet<CompanyMovementCreateRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return CompanyMovementCreateSheet(
          repository: widget.repository,
          accessToken: widget.accessToken,
          defaultWarehouseNo: widget.defaultWarehouseNo,
          mobileCustomerCatalogRepository:
              widget.mobileCustomerCatalogRepository,
          title: widget.createTitle,
          helperText: widget.createHelperText,
          submitLabel: widget.createButtonLabel,
          showDocumentNoField: widget.showCreateDocumentNoField,
          draft: draft,
          draftRepository: draftRepository,
        );
      },
    );

    if (request == null || !mounted) {
      return;
    }

    final result = await _controller.createMovement(request);

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_controller.createError ?? 'Evrak olusturulamadi.'),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.documentNoLabel} olusturuldu. ${result.lineCount} satir, toplam ${AppFormatters.quantity(result.totalQuantity)} miktar.',
        ),
      ),
    );

    if (draft != null) {
      await draftRepository?.deleteDraft(draft.id);
    }
  }

  Future<void> _openEDespatchSheet() async {
    final currentMovement = _controller.selectedMovement;

    if (currentMovement == null || !_controller.canSendEDespatch) {
      return;
    }

    final request = await showModalBottomSheet<EDespatchSendRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return WarehouseReturnEDespatchSheet(
          documentNoLabel: currentMovement.documentNoLabel,
        );
      },
    );

    if (request == null || !mounted) {
      return;
    }

    final result = await _controller.sendEDespatch(request);

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _controller.sendEDespatchError ?? 'E-irsaliye gonderilemedi.',
          ),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.documentNoLabel} icin e-irsaliye gonderildi. Belge: ${result.serviceDocumentNumber.isEmpty ? result.eDespatchDocumentNo : result.serviceDocumentNumber}',
        ),
      ),
    );
  }

  Future<void> _openPdfPreview() async {
    final currentMovement = _controller.selectedMovement;

    if (currentMovement == null || !_controller.canViewEDespatchPdf) {
      return;
    }

    final document = await _controller.fetchEDespatchPdf();

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (document == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(_controller.pdfError ?? 'PDF gosterilemedi.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return WarehouseReturnPdfPreviewPage(
            documentNoLabel: currentMovement.documentNoLabel,
            document: WarehouseReturnPdfDocument(
              fileName: document.fileName,
              bytes: document.bytes,
            ),
          );
        },
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
      title: widget.title,
      subtitle: widget.subtitle,
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Varsayilan depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(
          label: 'Kayit',
          value: '${_controller.movements.length}',
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
        if (widget.canCreate && _controller.canCreate)
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
              _controller.isCreating
                  ? 'Kaydediliyor...'
                  : widget.createButtonLabel,
            ),
          ),
      ],
    );
  }

  Widget _buildListCard() {
    if (_controller.listError != null && _controller.movements.isEmpty) {
      return SectionCard(
        title: 'Evrak Listesi',
        subtitle: 'Listeleme sirasinda hata olustu.',
        child: TerminalMessageBlock.error(message: _controller.listError!),
      );
    }

    return SectionCard(
      title: 'Evrak Listesi',
      subtitle: _controller.isLoadingList
          ? 'Liste yenileniyor...'
          : '${_controller.movements.length} kayit bulundu.',
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
          else if (_controller.movements.isEmpty)
            TerminalEmptyState(message: widget.emptyListMessage)
          else
            Column(
              children: _controller.movements
                  .map((item) {
                    final isExpanded =
                        _controller.selectedMovement?.documentNoLabel ==
                        item.documentNoLabel;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MovementCard(
                        item: item,
                        detail: isExpanded
                            ? _controller.selectedMovementDetail
                            : null,
                        isExpanded: isExpanded,
                        isLoadingDetail:
                            isExpanded && _controller.isLoadingDetail,
                        detailError: isExpanded
                            ? _controller.detailError
                            : null,
                        canSendEDespatch: _controller.canSendEDespatch,
                        canViewEDespatchPdf: _controller.canViewEDespatchPdf,
                        isSendingEDespatch:
                            isExpanded && _controller.isSendingEDespatch,
                        isLoadingPdf: isExpanded && _controller.isLoadingPdf,
                        lastEDespatchResult: isExpanded
                            ? _controller.lastEDespatchResult
                            : null,
                        onSendEDespatch: _openEDespatchSheet,
                        onShowPdf: _openPdfPreview,
                        onTap: () => _toggleSelection(item),
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

class _MovementCard extends StatelessWidget {
  const _MovementCard({
    required this.item,
    required this.detail,
    required this.isExpanded,
    required this.isLoadingDetail,
    required this.detailError,
    required this.canSendEDespatch,
    required this.canViewEDespatchPdf,
    required this.isSendingEDespatch,
    required this.isLoadingPdf,
    required this.lastEDespatchResult,
    required this.onSendEDespatch,
    required this.onShowPdf,
    required this.onTap,
  });

  final CompanyMovementListItem item;
  final CompanyMovementDetail? detail;
  final bool isExpanded;
  final bool isLoadingDetail;
  final String? detailError;
  final bool canSendEDespatch;
  final bool canViewEDespatchPdf;
  final bool isSendingEDespatch;
  final bool isLoadingPdf;
  final EDespatchSendResult? lastEDespatchResult;
  final VoidCallback onSendEDespatch;
  final VoidCallback onShowPdf;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
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
                children: <Widget>[
                  Expanded(
                    child: TerminalLabeledValue(
                      label: 'Belge',
                      value: item.documentNoLabel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TerminalLabeledValue(
                      label: 'Belge Trh',
                      value: AppFormatters.dateOrDash(item.documentDate),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TerminalLabeledValue(
                      label: 'Cari',
                      value: item.customerDisplayName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TerminalLabeledValue(
                      label: 'Hareket',
                      value: AppFormatters.dateOrDash(item.movementDate),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TerminalLabeledValue(
                      label: 'Miktar',
                      value: AppFormatters.quantity(item.totalQuantity),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TerminalBadge(label: '${item.lineCount} satir'),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
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
                        child: _MovementDetailBody(
                          detail: detail,
                          isLoading: isLoadingDetail,
                          errorMessage: detailError,
                          canSendEDespatch: canSendEDespatch,
                          canViewEDespatchPdf: canViewEDespatchPdf,
                          isSendingEDespatch: isSendingEDespatch,
                          isLoadingPdf: isLoadingPdf,
                          lastEDespatchResult: lastEDespatchResult,
                          onSendEDespatch: onSendEDespatch,
                          onShowPdf: onShowPdf,
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

class _MovementDetailBody extends StatelessWidget {
  const _MovementDetailBody({
    required this.detail,
    required this.isLoading,
    required this.errorMessage,
    required this.canSendEDespatch,
    required this.canViewEDespatchPdf,
    required this.isSendingEDespatch,
    required this.isLoadingPdf,
    required this.lastEDespatchResult,
    required this.onSendEDespatch,
    required this.onShowPdf,
  });

  final CompanyMovementDetail? detail;
  final bool isLoading;
  final String? errorMessage;
  final bool canSendEDespatch;
  final bool canViewEDespatchPdf;
  final bool isSendingEDespatch;
  final bool isLoadingPdf;
  final EDespatchSendResult? lastEDespatchResult;
  final VoidCallback onSendEDespatch;
  final VoidCallback onShowPdf;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return TerminalMessageBlock.error(message: errorMessage!);
    }

    if (detail == null) {
      return const TerminalEmptyState(message: 'Detay bilgisi yuklenemedi.');
    }

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
          if (canSendEDespatch || canViewEDespatchPdf) ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF1F4369), Color(0xFF315D8D)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    'E-Irsaliye',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (canSendEDespatch)
                    FilledButton.icon(
                      onPressed: isSendingEDespatch || isLoadingPdf
                          ? null
                          : onSendEDespatch,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF7C948),
                        foregroundColor: const Color(0xFF1E2C3A),
                      ),
                      icon: isSendingEDespatch
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        isSendingEDespatch
                            ? 'Gonderiliyor...'
                            : 'E-Irsaliyeye Cevir',
                      ),
                    ),
                  if (canViewEDespatchPdf)
                    OutlinedButton.icon(
                      onPressed: isSendingEDespatch || isLoadingPdf
                          ? null
                          : onShowPdf,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withAlpha(82)),
                      ),
                      icon: isLoadingPdf
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(
                        isLoadingPdf ? 'Hazirlaniyor...' : 'PDF Goster',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (lastEDespatchResult != null) ...<Widget>[
            const SizedBox(height: 12),
            TerminalMessageBlock.info(
              message:
                  'Son e-irsaliye: ${lastEDespatchResult!.documentNoLabel} | ${lastEDespatchResult!.serviceDocumentNumber.isEmpty ? lastEDespatchResult!.eDespatchDocumentNo : lastEDespatchResult!.serviceDocumentNumber}',
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Kalemler',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (detail!.items.isEmpty)
            const TerminalEmptyState(message: 'Bu evrakta kalem bulunamadi.')
          else
            Column(
              children: detail!.items
                  .map((item) {
                    final extra = <String>[
                      'Kod ${item.stockCode}',
                      'Birim ${item.unitName}/${item.unitPointer}',
                      'Miktar ${AppFormatters.quantity(item.quantity)}',
                      if (item.unitPrice > 0)
                        'Fiyat ${AppFormatters.currency(item.unitPrice)}',
                      if (item.lineAmount > 0)
                        'Tutar ${AppFormatters.currency(item.lineAmount)}',
                      if (item.orderGuid.isNotEmpty)
                        'Siparis ${item.orderGuid}',
                    ].join(' | ');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withAlpha(82),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                TerminalBadge(label: 'Satir ${item.lineNo}'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              extra,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
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
