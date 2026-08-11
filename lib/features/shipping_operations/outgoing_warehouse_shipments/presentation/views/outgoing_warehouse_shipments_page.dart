import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/order_operations/received_warehouse_orders/data/received_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/presentation/views/warehouse_return_pdf_preview_page.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/presentation/widgets/warehouse_return_e_despatch_sheet.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/outgoing_warehouse_shipments_repository.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/presentation/view_models/outgoing_warehouse_shipments_controller.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/presentation/widgets/outgoing_warehouse_shipment_create_sheet.dart';
import 'package:furpa_merkez_terminal/shared/data/despatch_drivers_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_picker.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/utils/safe_create_retry.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_create_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class OutgoingWarehouseShipmentsPage extends StatefulWidget {
  const OutgoingWarehouseShipmentsPage({
    super.key,
    required this.repository,
    required this.receivedWarehouseOrdersRepository,
    required this.accessToken,
    required this.canCreate,
    required this.defaultWarehouseNo,
    required this.mobileWarehouseCatalogRepository,
    required this.userWarehouseName,
    required this.title,
    required this.subtitle,
    this.emptyListMessage = 'Secilen tarih araliginda sevk bulunamadi.',
    this.currentUserId = '',
    this.draftModuleKey = '',
    this.draftRepository,
    this.despatchDriversRepository,
  });

  final OutgoingWarehouseShipmentsRepository repository;
  final ReceivedWarehouseOrdersRepository receivedWarehouseOrdersRepository;
  final String accessToken;
  final bool canCreate;
  final String defaultWarehouseNo;
  final MobileWarehouseCatalogLocalRepository mobileWarehouseCatalogRepository;
  final String userWarehouseName;
  final String title;
  final String subtitle;
  final String emptyListMessage;
  final String currentUserId;
  final String draftModuleKey;
  final CreateDraftRepository? draftRepository;
  final DespatchDriversRepository? despatchDriversRepository;

  @override
  State<OutgoingWarehouseShipmentsPage> createState() =>
      _OutgoingWarehouseShipmentsPageState();
}

class _OutgoingWarehouseShipmentsPageState
    extends State<OutgoingWarehouseShipmentsPage> {
  late final OutgoingWarehouseShipmentsController _controller;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _controller = OutgoingWarehouseShipmentsController(
      repository: widget.repository,
      accessToken: widget.accessToken,
      defaultWarehouseNo: widget.defaultWarehouseNo,
    );
    _startDate = _controller.startDate;
    _endDate = _controller.endDate;
    unawaited(_controller.loadShipments());
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
    if (widget.draftRepository != null && widget.draftModuleKey.isNotEmpty) {
      final launch = await showCreateDraftPicker(
        context: context,
        repository: widget.draftRepository!,
        moduleKey: widget.draftModuleKey,
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        createTitle: 'Yeni Giden Depolar Arasi Sevk',
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
            title: 'Yeni Giden Depolar Arasi Sevk',
          );
    }

    final request =
        await openTerminalCreatePage<WarehouseShipmentCreateRequest>(
          context: context,
          title: 'Yeni Sevk',
          builder: (context) {
            return OutgoingWarehouseShipmentCreateSheet(
              repository: widget.repository,
              receivedWarehouseOrdersRepository:
                  widget.receivedWarehouseOrdersRepository,
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

    await _submitCreateRequest(request, draft);
  }

  Future<void> _submitCreateRequest(
    WarehouseShipmentCreateRequest request,
    CreateDraft? draft,
  ) async {
    final result = await _controller.createShipment(request);

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_controller.createError ?? 'Sevk olusturulamadi.'),
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

    final linkedInfo = result.linkedWarehouseOrderLineCount > 0
        ? ' ${result.linkedWarehouseOrderLineCount} satir siparise baglandi.'
        : '';

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.documentNoLabel} olusturuldu. ${result.lineCount} satir, toplam ${AppFormatters.quantity(result.totalQuantity)} miktar.$linkedInfo',
        ),
      ),
    );
    if (draft != null) {
      await widget.draftRepository?.deleteDraft(draft.id);
    }
  }

  Future<void> _toggleSelection(WarehouseShipmentListItem item) async {
    await _controller.selectShipment(item);
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
                      _ShipmentAccordionCard(
                        item: item,
                        isExpanded: true,
                        detail: _controller.selectedShipmentDetail,
                        isLoadingDetail: _controller.isLoadingDetail,
                        detailError: _controller.detailError,
                        canSendEDespatch: _controller.canSendEDespatch,
                        canViewEDespatchPdf: _controller.canViewEDespatchPdf,
                        lastEDespatchResult: _controller.lastEDespatchResult,
                        isSendingEDespatch: _controller.isSendingEDespatch,
                        isLoadingPdf: _controller.isLoadingPdf,
                        onSendEDespatch: _openEDespatchSheet,
                        onShowPdf: _openPdfPreview,
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

  Future<void> _openEDespatchSheet() async {
    final currentShipment = _controller.selectedShipment;
    final currentDetail = _controller.selectedShipmentDetail;

    if (currentShipment == null || !_controller.canSendEDespatch) {
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
          documentNoLabel: currentShipment.documentNoLabel,
          initialPlaque: header?.plaque ?? '',
          initialDriverNameSurname: header?.driverNameSurname ?? '',
          initialDriverTckn: header?.driverTckn ?? '',
          onSearchDrivers: widget.despatchDriversRepository == null
              ? null
              : (query) => widget.despatchDriversRepository!.searchDrivers(
                  accessToken: widget.accessToken,
                  search: query,
                  take: 20,
                ),
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
    final currentShipment = _controller.selectedShipment;

    if (currentShipment == null || !_controller.canViewEDespatchPdf) {
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
            documentNoLabel: currentShipment.documentNoLabel,
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
              _ShipmentAccordionPanel(
                controller: _controller,
                emptyListMessage: widget.emptyListMessage,
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
      title: widget.title,
      subtitle: widget.subtitle,
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Varsayilan depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(
          label: 'Kayit',
          value: '${_controller.shipments.length}',
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
                : const Icon(Icons.local_shipping_outlined),
            label: Text(
              _controller.isCreating ? 'Kaydediliyor...' : 'Yeni Sevk',
            ),
          ),
      ],
    );
  }
}

class _ShipmentAccordionPanel extends StatelessWidget {
  const _ShipmentAccordionPanel({
    required this.controller,
    required this.emptyListMessage,
    required this.onTap,
    required this.onSendEDespatch,
    required this.onShowPdf,
  });

  final OutgoingWarehouseShipmentsController controller;
  final String emptyListMessage;
  final ValueChanged<WarehouseShipmentListItem> onTap;
  final VoidCallback onSendEDespatch;
  final VoidCallback onShowPdf;

  @override
  Widget build(BuildContext context) {
    if (controller.listError != null && controller.shipments.isEmpty) {
      return SectionCard(
        title: 'Sevk Listesi',
        subtitle: 'Listeleme sirasinda hata olustu.',
        child: _ErrorBlock(message: controller.listError!),
      );
    }

    return SectionCard(
      title: 'Sevk Listesi',
      subtitle: controller.isLoadingList
          ? 'Liste yenileniyor...'
          : '${controller.shipments.length} kayit bulundu.',
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
          else if (controller.shipments.isEmpty)
            _EmptyState(message: emptyListMessage)
          else
            Column(
              children: controller.shipments
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ShipmentAccordionCard(
                        item: item,
                        isExpanded:
                            controller.selectedShipment?.documentNoLabel ==
                            item.documentNoLabel,
                        detail:
                            controller.selectedShipment?.documentNoLabel ==
                                item.documentNoLabel
                            ? controller.selectedShipmentDetail
                            : null,
                        isLoadingDetail:
                            controller.selectedShipment?.documentNoLabel ==
                                item.documentNoLabel &&
                            controller.isLoadingDetail,
                        detailError:
                            controller.selectedShipment?.documentNoLabel ==
                                item.documentNoLabel
                            ? controller.detailError
                            : null,
                        canSendEDespatch:
                            controller.selectedShipment?.documentNoLabel ==
                                item.documentNoLabel &&
                            controller.canSendEDespatch,
                        canViewEDespatchPdf:
                            controller.selectedShipment?.documentNoLabel ==
                                item.documentNoLabel &&
                            controller.canViewEDespatchPdf,
                        lastEDespatchResult:
                            controller.selectedShipment?.documentNoLabel ==
                                item.documentNoLabel
                            ? controller.lastEDespatchResult
                            : null,
                        isSendingEDespatch:
                            controller.selectedShipment?.documentNoLabel ==
                                item.documentNoLabel &&
                            controller.isSendingEDespatch,
                        isLoadingPdf:
                            controller.selectedShipment?.documentNoLabel ==
                                item.documentNoLabel &&
                            controller.isLoadingPdf,
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

class _ShipmentAccordionCard extends StatelessWidget {
  const _ShipmentAccordionCard({
    required this.item,
    required this.isExpanded,
    required this.detail,
    required this.isLoadingDetail,
    required this.detailError,
    required this.canSendEDespatch,
    required this.canViewEDespatchPdf,
    required this.lastEDespatchResult,
    required this.isSendingEDespatch,
    required this.isLoadingPdf,
    required this.onSendEDespatch,
    required this.onShowPdf,
    required this.onTap,
  });

  final WarehouseShipmentListItem item;
  final bool isExpanded;
  final WarehouseShipmentDetail? detail;
  final bool isLoadingDetail;
  final String? detailError;
  final bool canSendEDespatch;
  final bool canViewEDespatchPdf;
  final EDespatchSendResult? lastEDespatchResult;
  final bool isSendingEDespatch;
  final bool isLoadingPdf;
  final VoidCallback onSendEDespatch;
  final VoidCallback onShowPdf;
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
            subtitle: '${item.sourceWarehouse} -> ${item.targetWarehouse}',
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _StateBadge(state: item.shippingState),
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
                label: 'Sevk Trh',
                value: AppFormatters.dateOrDash(item.movementDate),
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
                    child: _ShipmentDetailBody(
                      detail: detail,
                      isLoading: isLoadingDetail,
                      errorMessage: detailError,
                      canSendEDespatch: canSendEDespatch,
                      canViewEDespatchPdf: canViewEDespatchPdf,
                      lastEDespatchResult: lastEDespatchResult,
                      isSendingEDespatch: isSendingEDespatch,
                      isLoadingPdf: isLoadingPdf,
                      onSendEDespatch: onSendEDespatch,
                      onShowPdf: onShowPdf,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ShipmentDetailBody extends StatelessWidget {
  const _ShipmentDetailBody({
    required this.detail,
    required this.isLoading,
    required this.errorMessage,
    required this.canSendEDespatch,
    required this.canViewEDespatchPdf,
    required this.lastEDespatchResult,
    required this.isSendingEDespatch,
    required this.isLoadingPdf,
    required this.onSendEDespatch,
    required this.onShowPdf,
  });

  final WarehouseShipmentDetail? detail;
  final bool isLoading;
  final String? errorMessage;
  final bool canSendEDespatch;
  final bool canViewEDespatchPdf;
  final EDespatchSendResult? lastEDespatchResult;
  final bool isSendingEDespatch;
  final bool isLoadingPdf;
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
      return _ErrorBlock(message: errorMessage!);
    }

    if (detail == null) {
      return const _EmptyState(message: 'Detay bilgisi yuklenemedi.');
    }

    return TerminalPdaDetailPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (canSendEDespatch || canViewEDespatchPdf) ...<Widget>[
            _ShipmentActionStrip(
              canSendEDespatch: canSendEDespatch,
              canViewEDespatchPdf: canViewEDespatchPdf,
              isSendingEDespatch: isSendingEDespatch,
              isLoadingPdf: isLoadingPdf,
              onSendEDespatch: onSendEDespatch,
              onShowPdf: onShowPdf,
            ),
            const SizedBox(height: 18),
          ],
          if (lastEDespatchResult case final result?) ...<Widget>[
            const SizedBox(height: 18),
            _ShipmentEDespatchResultCard(result: result),
          ],
          const SizedBox(height: 18),
          Text(
            'Kalemler',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _ShipmentItemsList(items: detail!.items),
        ],
      ),
    );
  }
}

class _ShipmentActionStrip extends StatelessWidget {
  const _ShipmentActionStrip({
    required this.canSendEDespatch,
    required this.canViewEDespatchPdf,
    required this.isSendingEDespatch,
    required this.isLoadingPdf,
    required this.onSendEDespatch,
    required this.onShowPdf,
  });

  final bool canSendEDespatch;
  final bool canViewEDespatchPdf;
  final bool isSendingEDespatch;
  final bool isLoadingPdf;
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

class _ShipmentEDespatchResultCard extends StatelessWidget {
  const _ShipmentEDespatchResultCard({required this.result});

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

class _ShipmentItemsList extends StatelessWidget {
  const _ShipmentItemsList({required this.items});

  final List<WarehouseShipmentDetailItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(message: 'Bu sevkte kalem bulunamadi.');
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShipmentItemCard(item: item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ShipmentItemCard extends StatelessWidget {
  const _ShipmentItemCard({required this.item});

  final WarehouseShipmentDetailItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = <String>[
      'Kod ${item.stockCode}',
      'Miktar ${AppFormatters.quantity(item.quantity)}',
      'Birim ${item.unitName}',
      if (item.unitPrice > 0) 'Fiyat ${AppFormatters.currency(item.unitPrice)}',
      if (item.lineAmount > 0)
        'Tutar ${AppFormatters.currency(item.lineAmount)}',
    ].join(' | ');
    final detail = <String>[
      if (item.warehouseOrderNo.isNotEmpty) 'Siparis ${item.warehouseOrderNo}',
      if (item.description.isNotEmpty) 'Aciklama ${item.description}',
    ].join(' | ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
