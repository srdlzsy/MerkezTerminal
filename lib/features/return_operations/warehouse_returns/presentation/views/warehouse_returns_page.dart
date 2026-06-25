import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/warehouse_returns_repository.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/presentation/view_models/warehouse_returns_controller.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/presentation/views/warehouse_return_pdf_preview_page.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/presentation/widgets/warehouse_return_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/presentation/widgets/warehouse_return_e_despatch_sheet.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_picker.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class WarehouseReturnsPage extends StatefulWidget {
  const WarehouseReturnsPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.mobileWarehouseCatalogRepository,
    required this.userWarehouseName,
    required this.direction,
    this.currentUserId = '',
    this.draftRepository,
  });

  final WarehouseReturnsRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;
  final MobileWarehouseCatalogLocalRepository mobileWarehouseCatalogRepository;
  final String userWarehouseName;
  final WarehouseReturnDirection direction;
  final String currentUserId;
  final CreateDraftRepository? draftRepository;

  @override
  State<WarehouseReturnsPage> createState() => _WarehouseReturnsPageState();
}

class _WarehouseReturnsPageState extends State<WarehouseReturnsPage> {
  late final WarehouseReturnsController _controller;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _controller = WarehouseReturnsController(
      repository: widget.repository,
      accessToken: widget.accessToken,
      defaultWarehouseNo: widget.defaultWarehouseNo,
      direction: widget.direction,
    );
    _startDate = _controller.startDate;
    _endDate = _controller.endDate;
    unawaited(_controller.loadReturns());
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

  Future<void> _toggleSelection(WarehouseReturnListItem item) async {
    if (_controller.selectedReturn?.documentNoLabel == item.documentNoLabel) {
      _controller.clearSelection();
      return;
    }

    await _controller.selectReturn(item);
  }

  Future<void> _openEDespatchSheet() async {
    final currentReturn = _controller.selectedReturn;
    final currentDetail = _controller.selectedReturnDetail;

    if (currentReturn == null || !_controller.canSendEDespatch) {
      return;
    }

    final header = currentDetail?.header;
    final request = await showModalBottomSheet<EDespatchSendRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return WarehouseReturnEDespatchSheet(
          documentNoLabel: currentReturn.documentNoLabel,
          initialPlaque: header?.plaque ?? '',
          initialDriverNameSurname: header?.driverNameSurname ?? '',
          initialDriverTckn: header?.driverTckn ?? '',
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

    final serviceInfo = result.serviceDocumentNumber.isNotEmpty
        ? result.serviceDocumentNumber
        : result.eDespatchDocumentNo;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.documentNoLabel} icin e-irsaliye gonderildi. Belge: $serviceInfo',
        ),
      ),
    );
  }

  Future<void> _openPdfPreview() async {
    final currentReturn = _controller.selectedReturn;

    if (currentReturn == null || !_controller.canViewEDespatchPdf) {
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
            documentNoLabel: currentReturn.documentNoLabel,
            document: document,
          );
        },
      ),
    );
  }

  Future<void> _openCreateSheet() async {
    if (widget.direction != WarehouseReturnDirection.outgoing) {
      return;
    }

    CreateDraft? draft;
    if (widget.draftRepository != null) {
      final launch = await showCreateDraftPicker(
        context: context,
        repository: widget.draftRepository!,
        moduleKey: 'iade-islemleri.giden-depo-iadeleri',
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        createTitle: 'Yeni Giden Depo Iadesi',
      );
      if (launch == null || !mounted) {
        return;
      }
      draft =
          launch.draft ??
          CreateDraft.empty(
            moduleKey: 'iade-islemleri.giden-depo-iadeleri',
            userId: widget.currentUserId,
            warehouseNo: widget.defaultWarehouseNo,
            title: 'Yeni Giden Depo Iadesi',
          );
    }

    final request = await showModalBottomSheet<WarehouseReturnCreateRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return WarehouseReturnCreateSheet(
          repository: widget.repository,
          accessToken: widget.accessToken,
          defaultWarehouseNo: widget.defaultWarehouseNo,
          mobileWarehouseCatalogRepository:
              widget.mobileWarehouseCatalogRepository,
          draft: draft,
          draftRepository: widget.draftRepository,
        );
      },
    );

    if (request == null || !mounted) {
      return;
    }

    final result = await _controller.createReturn(request);

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _controller.createError ?? 'Depo iadesi kaydedilemedi.',
          ),
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
              _ReturnsAccordionPanel(
                controller: _controller,
                direction: widget.direction,
                onTap: _toggleSelection,
                onSendEDespatch: _openEDespatchSheet,
                onShowPdf: _openPdfPreview,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return TerminalListHeaderCard(
      title: widget.direction.pageTitle,
      subtitle: widget.direction.pageSubtitle,
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Varsayilan depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),

        TerminalInfoChip(
          label: 'Kayit',
          value: '${_controller.returns.length}',
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
        if (widget.direction == WarehouseReturnDirection.outgoing)
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
              _controller.isCreating ? 'Kaydediliyor...' : 'Yeni Iade',
            ),
          ),
      ],
    );
  }
}

class _ReturnsAccordionPanel extends StatelessWidget {
  const _ReturnsAccordionPanel({
    required this.controller,
    required this.direction,
    required this.onTap,
    required this.onSendEDespatch,
    required this.onShowPdf,
  });

  final WarehouseReturnsController controller;
  final WarehouseReturnDirection direction;
  final ValueChanged<WarehouseReturnListItem> onTap;
  final VoidCallback onSendEDespatch;
  final VoidCallback onShowPdf;

  @override
  Widget build(BuildContext context) {
    if (controller.listError != null && controller.returns.isEmpty) {
      return SectionCard(
        title: 'Depo Iadesi Listesi',
        subtitle: 'Listeleme sirasinda hata olustu.',
        child: _ErrorBlock(message: controller.listError!),
      );
    }

    return SectionCard(
      title: 'Depo Iadesi Listesi',
      subtitle: controller.isLoadingList
          ? 'Liste yenileniyor...'
          : '${controller.returns.length} kayit bulundu.',
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
          else if (controller.returns.isEmpty)
            const _EmptyState(
              message: 'Secilen tarih araliginda depo iadesi bulunamadi.',
            )
          else
            Column(
              children: controller.returns
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ReturnAccordionCard(
                        item: item,
                        direction: direction,
                        isExpanded:
                            controller.selectedReturn?.documentNoLabel ==
                            item.documentNoLabel,
                        detail:
                            controller.selectedReturn?.documentNoLabel ==
                                item.documentNoLabel
                            ? controller.selectedReturnDetail
                            : null,
                        isLoadingDetail:
                            controller.selectedReturn?.documentNoLabel ==
                                item.documentNoLabel &&
                            controller.isLoadingDetail,
                        detailError:
                            controller.selectedReturn?.documentNoLabel ==
                                item.documentNoLabel
                            ? controller.detailError
                            : null,
                        lastEDespatchResult:
                            controller.selectedReturn?.documentNoLabel ==
                                item.documentNoLabel
                            ? controller.lastEDespatchResult
                            : null,
                        isSendingEDespatch:
                            controller.selectedReturn?.documentNoLabel ==
                                item.documentNoLabel &&
                            controller.isSendingEDespatch,
                        isLoadingPdf:
                            controller.selectedReturn?.documentNoLabel ==
                                item.documentNoLabel &&
                            controller.isLoadingPdf,
                        canSendEDespatch:
                            controller.selectedReturn?.documentNoLabel ==
                                item.documentNoLabel &&
                            controller.canSendEDespatch,
                        canViewEDespatchPdf:
                            controller.selectedReturn?.documentNoLabel ==
                                item.documentNoLabel &&
                            controller.canViewEDespatchPdf,
                        onSendEDespatch: onSendEDespatch,
                        onShowPdf: onShowPdf,
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

class _ReturnAccordionCard extends StatelessWidget {
  const _ReturnAccordionCard({
    required this.item,
    required this.direction,
    required this.isExpanded,
    required this.detail,
    required this.isLoadingDetail,
    required this.detailError,
    required this.lastEDespatchResult,
    required this.isSendingEDespatch,
    required this.isLoadingPdf,
    required this.canSendEDespatch,
    required this.canViewEDespatchPdf,
    required this.onSendEDespatch,
    required this.onShowPdf,
    required this.onTap,
  });

  final WarehouseReturnListItem item;
  final WarehouseReturnDirection direction;
  final bool isExpanded;
  final WarehouseReturnDetail? detail;
  final bool isLoadingDetail;
  final String? detailError;
  final EDespatchSendResult? lastEDespatchResult;
  final bool isSendingEDespatch;
  final bool isLoadingPdf;
  final bool canSendEDespatch;
  final bool canViewEDespatchPdf;
  final VoidCallback onSendEDespatch;
  final VoidCallback onShowPdf;
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
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withAlpha(isExpanded ? 10 : 5),
                blurRadius: isExpanded ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.documentNoLabel,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1F1A16),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${item.sourceWarehouse} -> ${item.targetWarehouse}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3A2B20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      _StateBadge(state: item.shippingState),
                      const SizedBox(height: 10),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 30,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _TileInfoPill(
                    label: 'Belge tarihi',
                    value: AppFormatters.dateOrDash(item.documentDate),
                  ),
                  _TileInfoPill(
                    label: 'Iade tarihi',
                    value: AppFormatters.dateOrDash(item.movementDate),
                  ),
                  _TileInfoPill(
                    label: direction == WarehouseReturnDirection.outgoing
                        ? 'Hedef depo'
                        : 'Kaynak depo',
                    value: direction == WarehouseReturnDirection.outgoing
                        ? '${item.targetWarehouseNo}'
                        : '${item.sourceWarehouseNo}',
                  ),
                  _TileInfoPill(label: 'Satir', value: '${item.lineCount}'),
                  _TileInfoPill(
                    label: 'Toplam miktar',
                    value: AppFormatters.quantity(item.totalQuantity),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: _ReturnDetailBody(
                          direction: direction,
                          detail: detail,
                          isLoading: isLoadingDetail,
                          errorMessage: detailError,
                          lastEDespatchResult: lastEDespatchResult,
                          isSendingEDespatch: isSendingEDespatch,
                          isLoadingPdf: isLoadingPdf,
                          canSendEDespatch: canSendEDespatch,
                          canViewEDespatchPdf: canViewEDespatchPdf,
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

class _ReturnDetailBody extends StatelessWidget {
  const _ReturnDetailBody({
    required this.direction,
    required this.detail,
    required this.isLoading,
    required this.errorMessage,
    required this.lastEDespatchResult,
    required this.isSendingEDespatch,
    required this.isLoadingPdf,
    required this.canSendEDespatch,
    required this.canViewEDespatchPdf,
    required this.onSendEDespatch,
    required this.onShowPdf,
  });

  final WarehouseReturnDirection direction;
  final WarehouseReturnDetail? detail;
  final bool isLoading;
  final String? errorMessage;
  final EDespatchSendResult? lastEDespatchResult;
  final bool isSendingEDespatch;
  final bool isLoadingPdf;
  final bool canSendEDespatch;
  final bool canViewEDespatchPdf;
  final VoidCallback onSendEDespatch;
  final VoidCallback onShowPdf;

  @override
  Widget build(BuildContext context) {
    final currentErrorMessage = errorMessage;
    final currentDetail = detail;
    final currentEDespatchResult = lastEDespatchResult;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentErrorMessage case final message?) {
      return _ErrorBlock(message: message);
    }

    if (currentDetail == null) {
      return const _EmptyState(message: 'Detay bilgisi yuklenemedi.');
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
          if (direction.supportsEDespatch &&
              (canSendEDespatch || canViewEDespatchPdf)) ...<Widget>[
            _ReturnActionStrip(
              isSendingEDespatch: isSendingEDespatch,
              isLoadingPdf: isLoadingPdf,
              canSendEDespatch: canSendEDespatch,
              canViewEDespatchPdf: canViewEDespatchPdf,
              onSendEDespatch: onSendEDespatch,
              onShowPdf: onShowPdf,
            ),
            const SizedBox(height: 18),
          ],
          if (currentEDespatchResult case final result?) ...<Widget>[
            const SizedBox(height: 18),
            _EDespatchResultCard(result: result),
          ],
          const SizedBox(height: 18),
          Text(
            'Kalemler',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _ReturnItemsList(items: currentDetail.items),
        ],
      ),
    );
  }
}

class _ReturnActionStrip extends StatelessWidget {
  const _ReturnActionStrip({
    required this.isSendingEDespatch,
    required this.isLoadingPdf,
    required this.canSendEDespatch,
    required this.canViewEDespatchPdf,
    required this.onSendEDespatch,
    required this.onShowPdf,
  });

  final bool isSendingEDespatch;
  final bool isLoadingPdf;
  final bool canSendEDespatch;
  final bool canViewEDespatchPdf;
  final VoidCallback onSendEDespatch;
  final VoidCallback onShowPdf;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'E-Irsaliye Islemleri',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Plaka, sofor ve TCKN bilgileri create ekraninda degil, tam gonderim aninda istenir.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(225),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
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
                  label: Text(isLoadingPdf ? 'Hazirlaniyor...' : 'PDF Goster'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EDespatchResultCard extends StatelessWidget {
  const _EDespatchResultCard({required this.result});

  final EDespatchSendResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F6EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB0DEC0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Son E-Irsaliye Gonderimi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B5E3D),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _SummaryTile(label: 'Belge', value: result.documentNoLabel),
              _SummaryTile(
                label: 'Servis No',
                value: result.serviceDocumentNumber.isEmpty
                    ? '-'
                    : result.serviceDocumentNumber,
              ),
              _SummaryTile(
                label: 'E-Irsaliye No',
                value: result.eDespatchDocumentNo,
              ),
              _SummaryTile(
                label: 'Gonderim',
                value: AppFormatters.dateTimeOrDash(result.sentAt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReturnItemsList extends StatelessWidget {
  const _ReturnItemsList({required this.items});

  final List<WarehouseReturnDetailItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(message: 'Bu iade evraginda kalem bulunamadi.');
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReturnItemCard(item: item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ReturnItemCard extends StatelessWidget {
  const _ReturnItemCard({required this.item});

  final WarehouseReturnDetailItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = <String>[
      'Kod ${item.stockCode}',
      'Miktar ${AppFormatters.quantity(item.quantity)}',
      'Birim ${item.unitName}/${item.unitPointer}',
      if (item.unitPrice > 0) 'Fiyat ${AppFormatters.currency(item.unitPrice)}',
      if (item.lineAmount > 0)
        'Tutar ${AppFormatters.currency(item.lineAmount)}',
    ].join(' | ');
    final detail = <String>[
      if (item.warehouseOrderNo.isNotEmpty) 'Bagli ${item.warehouseOrderNo}',
      if (item.description.isNotEmpty) 'Aciklama ${item.description}',
      if (item.projectCode.isNotEmpty) 'Proje ${item.projectCode}',
      if (item.partyCode.isNotEmpty) 'Parti ${item.partyCode}',
      if (item.lotNo > 0) 'Lot ${item.lotNo}',
      if (item.movementGuid.isNotEmpty) 'Guid ${item.movementGuid}',
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
              _PillBadge(label: 'Satir ${item.lineNo}'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            maxLines: 1,
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
              maxLines: 1,
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

class _TileInfoPill extends StatelessWidget {
  const _TileInfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(90),
        ),
      ),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF231C17),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(82),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF231C17),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state});

  final int state;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (state) {
      1 => (const Color(0xFFE6F7EE), const Color(0xFF1B7A46)),
      0 => (const Color(0xFFFFF1D8), const Color(0xFF9A5A00)),
      _ => (const Color(0xFFE9EEF7), const Color(0xFF32598B)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _shippingStateLabel(state),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.label});

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

String _shippingStateLabel(int state) {
  return switch (state) {
    1 => 'Ulasti',
    0 => 'Yolda',
    _ => 'Durum $state',
  };
}
