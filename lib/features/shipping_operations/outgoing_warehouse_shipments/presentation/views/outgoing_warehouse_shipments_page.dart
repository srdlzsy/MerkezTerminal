import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/green_grocer/product_cases/data/green_grocer_product_cases_repository.dart';
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
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_status.dart';
import 'package:furpa_merkez_terminal/shared/pending_create/pending_create_repository.dart';
import 'package:furpa_merkez_terminal/shared/utils/completed_create_cleanup.dart';
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
    this.greenGrocerProductCasesRepository,
    required this.userWarehouseName,
    required this.title,
    required this.subtitle,
    this.emptyListMessage = 'Secilen tarih araliginda sevk bulunamadi.',
    this.currentUserId = '',
    this.draftModuleKey = '',
    this.draftRepository,
    required this.pendingCreateRepository,
    this.despatchDriversRepository,
  });

  final OutgoingWarehouseShipmentsRepository repository;
  final ReceivedWarehouseOrdersRepository receivedWarehouseOrdersRepository;
  final String accessToken;
  final bool canCreate;
  final String defaultWarehouseNo;
  final MobileWarehouseCatalogLocalRepository mobileWarehouseCatalogRepository;
  final GreenGrocerProductCasesRepository? greenGrocerProductCasesRepository;
  final String userWarehouseName;
  final String title;
  final String subtitle;
  final String emptyListMessage;
  final String currentUserId;
  final String draftModuleKey;
  final CreateDraftRepository? draftRepository;
  final PendingCreateRepository pendingCreateRepository;
  final DespatchDriversRepository? despatchDriversRepository;

  @override
  State<OutgoingWarehouseShipmentsPage> createState() =>
      _OutgoingWarehouseShipmentsPageState();
}

class _OutgoingWarehouseShipmentsPageState
    extends State<OutgoingWarehouseShipmentsPage> {
  late final OutgoingWarehouseShipmentsController _controller;
  WarehouseShipmentCreateRequest? _pendingCreateRequest;
  CreateDraft? _pendingCreateDraft;
  SafeCreateFailureKind _pendingCreateFailureKind =
      SafeCreateFailureKind.notRetryable;
  bool _isRestoringPendingCreate = false;
  bool _hasPendingCreateStorageError = false;
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
    if (widget.canCreate) {
      _isRestoringPendingCreate = true;
      unawaited(_restorePendingCreate());
    }
    unawaited(_controller.loadShipments());
  }

  Future<void> _restorePendingCreate() async {
    try {
      final pending = await widget.pendingCreateRepository.read(
        moduleKey: widget.draftModuleKey,
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
      );
      if (!mounted || pending == null) {
        return;
      }
      final request = WarehouseShipmentCreateRequest.fromJson(pending.payload);
      final failureKind = _failureKindFromName(pending.failureKind);
      setState(() {
        _hasPendingCreateStorageError = false;
        _pendingCreateRequest = request;
        _pendingCreateDraft = pending.draft;
        _pendingCreateFailureKind = failureKind;
      });
    } on Object {
      if (mounted) {
        setState(() => _hasPendingCreateStorageError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bekleyen guvenli sevk kaydi okunamadi. Uygulama verisini '
              'temizlemeden once destek birimine bildirin.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoringPendingCreate = false);
        if (_pendingCreateRequest != null) {
          unawaited(_reconcileRestoredPendingCreate());
        }
      }
    }
  }

  Future<void> _persistPendingCreate(
    WarehouseShipmentCreateRequest request,
    CreateDraft? draft, {
    SafeCreateFailureKind? failureKind,
    DateTime? retryNotBefore,
  }) {
    return widget.pendingCreateRepository.save(
      PendingCreateOperation(
        moduleKey: widget.draftModuleKey,
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        payload: request.toJson(),
        updatedAt: DateTime.now(),
        failureKind: failureKind?.name,
        retryNotBefore: retryNotBefore,
        draft: draft,
      ),
    );
  }

  Future<void> _clearPersistedPendingCreate([String? clientRequestId]) {
    return widget.pendingCreateRepository.remove(
      moduleKey: widget.draftModuleKey,
      userId: widget.currentUserId,
      warehouseNo: widget.defaultWarehouseNo,
      clientRequestId: clientRequestId,
    );
  }

  Future<void> _reconcileRestoredPendingCreate() async {
    final request = _pendingCreateRequest;
    if (request == null) return;
    await _submitCreateRequest(
      request,
      _pendingCreateDraft,
      statusCheckOnly: true,
    );
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

    var submittedInline = false;
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
              greenGrocerProductCasesRepository:
                  widget.greenGrocerProductCasesRepository,
              draft: draft,
              draftRepository: widget.draftRepository,
            );
          },
          onSubmit: (request) async {
            submittedInline = true;
            return _submitCreateRequest(request, draft);
          },
        );

    if (request == null || !mounted || submittedInline) {
      return;
    }

    await _submitCreateRequest(request, draft);
  }

  Future<bool> _submitCreateRequest(
    WarehouseShipmentCreateRequest request,
    CreateDraft? draft, {
    bool statusCheckOnly = false,
  }) async {
    if (_controller.isCreating) {
      return false;
    }

    try {
      await _persistPendingCreate(request, draft);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Guvenli kayit bilgisi cihaza yazilamadi. Islem baslatilmadi.',
            ),
          ),
        );
      }
      return false;
    }

    setState(() {
      _pendingCreateRequest = request;
      _pendingCreateDraft = draft;
      if (!statusCheckOnly) {
        _pendingCreateFailureKind = SafeCreateFailureKind.notRetryable;
      }
    });

    var result = statusCheckOnly
        ? null
        : await _controller.createShipment(request);

    if (!mounted) {
      if (result != null) {
        await completeLocalCreateState(
          pendingRepository: widget.pendingCreateRepository,
          moduleKey: widget.draftModuleKey,
          userId: widget.currentUserId,
          warehouseNo: widget.defaultWarehouseNo,
          clientRequestId: request.clientRequestId ?? '',
          draftRepository: widget.draftRepository,
          draftId: draft?.id,
        );
      }
      return false;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (result == null) {
      var failureKind = statusCheckOnly
          ? _pendingCreateFailureKind
          : _controller.createFailureKind;
      var failureMessage = _controller.createError ?? 'Sevk olusturulamadi.';
      DateTime? retryNotBefore;
      final provider = widget.repository;
      final statusProvider =
          provider is OfflineSyncStatusProvider<WarehouseShipmentCreateResult>
          ? provider as OfflineSyncStatusProvider<WarehouseShipmentCreateResult>
          : null;
      if ((statusCheckOnly ||
              shouldCheckSafeCreateStatus(failureKind) ||
              canRetrySafeCreate(failureKind)) &&
          statusProvider != null) {
        try {
          final recheckProvider =
              provider
                  is OfflineSyncRecheckProvider<WarehouseShipmentCreateResult>
              ? provider
                    as OfflineSyncRecheckProvider<WarehouseShipmentCreateResult>
              : null;
          final status = await resolveSafeCreateStatus(
            statusProvider: statusProvider,
            recheckProvider: recheckProvider,
            accessToken: widget.accessToken,
            clientRequestId: request.clientRequestId ?? '',
            currentKind: failureKind,
          );
          if (status.isCompleted && status.result != null) {
            result = status.result;
          } else {
            failureKind = classifyOfflineSyncStatus(status);
            failureMessage = safeCreateOfflineSyncErrorMessage(
              status,
              fallback: failureMessage,
            );
            retryNotBefore = status.retryNotBefore();
          }
        } on ApiException catch (error) {
          if (hasSafeCreateDecisionMetadata(error)) {
            failureKind = classifySafeCreateException(error);
            failureMessage = safeCreateRetryErrorMessage(error);
            retryNotBefore = safeCreateRetryNotBefore(
              retryable: error.retryable,
              retryAfterSeconds: error.retryAfterSeconds,
            );
          }
        } on Object {
          // POST sonucu belirsiz kalir; yerel snapshot korunur.
        }
      }
      if (result != null) {
        // Asil create cevabi kaybolmus olsa da status endpointi sonucu buldu.
      } else {
        final keepsPending = shouldKeepSafeCreatePending(failureKind);
        if (keepsPending) {
          await _persistPendingCreate(
            request,
            draft,
            failureKind: failureKind,
            retryNotBefore: retryNotBefore,
          );
          if (!mounted) {
            return false;
          }
          setState(() {
            _pendingCreateFailureKind = failureKind;
          });
        } else {
          await _clearPersistedPendingCreate(request.clientRequestId);
          if (!mounted) {
            return false;
          }
          setState(() {
            _pendingCreateRequest = null;
            _pendingCreateDraft = null;
            _pendingCreateFailureKind = SafeCreateFailureKind.notRetryable;
          });
        }
        messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
        return false;
      }
    }

    if (!mounted) {
      return false;
    }
    setState(() {
      _pendingCreateRequest = null;
      _pendingCreateDraft = null;
      _pendingCreateFailureKind = SafeCreateFailureKind.notRetryable;
    });
    await completeLocalCreateState(
      pendingRepository: widget.pendingCreateRepository,
      moduleKey: widget.draftModuleKey,
      userId: widget.currentUserId,
      warehouseNo: widget.defaultWarehouseNo,
      clientRequestId: request.clientRequestId ?? '',
      draftRepository: widget.draftRepository,
      draftId: draft?.id,
    );
    if (!mounted) {
      return false;
    }

    if (statusCheckOnly) {
      await _controller.loadShipments(
        preferredDocumentSerie: result.documentSerie,
        preferredDocumentOrderNo: result.documentOrderNo,
      );
      if (!mounted) {
        return false;
      }
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
    return true;
  }

  Future<void> _toggleSelection(WarehouseShipmentListItem item) async {
    final detailLoad = _controller.selectShipment(item);
    if (!mounted) {
      return;
    }

    final navigation = Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              return Scaffold(
                appBar: AppBar(title: Text(item.documentNoLabel)),
                body: SafeArea(
                  child: ListView(
                    padding: terminalPdaListPagePadding(context),
                    children: <Widget>[
                      _ShipmentAccordionCard(
                        item: item,
                        isExpanded: true,
                        isDetailPage: true,
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
    await detailLoad;
    await navigation;

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

    final message =
        '${result.documentNoLabel} icin e-irsaliye gonderildi. '
        'Belge: ${result.serviceDocumentLabel}'
        '${result.isMikroMetadataPending ? ' | Mikro isaretlemesi bekliyor.' : ''}'
        '${result.hasWarning ? ' | Uyari: ${result.warningMessage}' : ''}';
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: result.hasWarning
            ? const Duration(seconds: 8)
            : const Duration(seconds: 4),
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
            padding: terminalPdaListPagePadding(context),
            children: <Widget>[
              _buildHeader(),
              const SizedBox(height: 8),
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
            onPressed:
                _controller.isCreating ||
                    _isRestoringPendingCreate ||
                    _hasPendingCreateStorageError
                ? null
                : _openCreateSheet,
            icon: _controller.isCreating || _isRestoringPendingCreate
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _hasPendingCreateStorageError
                        ? Icons.error_outline_rounded
                        : Icons.local_shipping_outlined,
                  ),
            label: Text(
              _controller.isCreating
                  ? 'Kaydediliyor...'
                  : _isRestoringPendingCreate
                  ? 'Kayit kontrol ediliyor...'
                  : _hasPendingCreateStorageError
                  ? 'Destek gerekli'
                  : 'Yeni Sevk',
            ),
          ),
      ],
    );
  }
}

SafeCreateFailureKind _failureKindFromName(String? value) {
  return SafeCreateFailureKind.values.firstWhere(
    (item) => item.name == value,
    orElse: () => SafeCreateFailureKind.uncertain,
  );
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
      dense: true,
      framed: false,
      child: Column(
        children: <Widget>[
          if (controller.listError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ShipmentAccordionCard(
                        item: item,
                        isExpanded:
                            (ModalRoute.of(context)?.isCurrent ?? true) &&
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
    this.isDetailPage = false,
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
  final bool isDetailPage;
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
    final docDate = AppFormatters.dateOrDash(item.documentDate);
    final moveDate = AppFormatters.dateOrDash(item.movementDate);
    final infoItems = <TerminalPdaInfo>[
      TerminalPdaInfo(
        label: docDate == moveDate ? 'Tarih' : 'Belge Trh',
        value: docDate,
      ),
      if (docDate != moveDate)
        TerminalPdaInfo(label: 'Sevk Trh', value: moveDate),
      TerminalPdaInfo(
        label: 'Miktar',
        value: AppFormatters.quantity(item.totalQuantity),
      ),
    ];

    if (isDetailPage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TerminalPdaDetailPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TerminalPdaCardHeader(
                  title: '${item.sourceWarehouse} -> ${item.targetWarehouse}',
                  trailing: _StateBadge(state: item.shippingState),
                ),
                const SizedBox(height: 6),
                TerminalPdaInfoGrid(compact: true, items: infoItems),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _ShipmentDetailBody(
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
        ],
      );
    }

    return TerminalPdaRecordCard(
      isSelected: isExpanded,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TerminalPdaCardHeader(
            title: item.documentNoLabel,
            subtitle: '${item.sourceWarehouse} -> ${item.targetWarehouse}',
            trailing: TerminalPdaCardTrailing(
              badges: <Widget>[_StateBadge(state: item.shippingState)],
              isExpanded: isExpanded,
            ),
          ),
          const SizedBox(height: 6),
          TerminalPdaInfoGrid(compact: true, items: infoItems),
          AnimatedSize(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
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
            TerminalEDespatchActionStrip(
              canSendEDespatch: canSendEDespatch,
              canViewEDespatchPdf: canViewEDespatchPdf,
              isSendingEDespatch: isSendingEDespatch,
              isLoadingPdf: isLoadingPdf,
              onSendEDespatch: onSendEDespatch,
              onShowPdf: onShowPdf,
            ),
            const SizedBox(height: 8),
          ],
          if (lastEDespatchResult case final result?) ...<Widget>[
            _ShipmentEDespatchResultCard(result: result),
            const SizedBox(height: 8),
          ],
          Text(
            'Kalemler (${detail!.items.length})',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          _ShipmentItemsList(items: detail!.items),
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
          if (result.hasWarning) ...<Widget>[
            const SizedBox(height: 12),
            TerminalMessageBlock.info(
              message: 'Uyari: ${result.warningMessage}',
            ),
          ],
          if (result.isMikroMetadataPending) ...<Widget>[
            const SizedBox(height: 12),
            TerminalMessageBlock.info(message: result.metadataStatusMessage),
          ],
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

    final zeroBased = items.any((item) => item.lineNo == 0);
    return Column(
      children: items
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ShipmentItemCard(
                item: entry.value,
                displayLineNo: terminalDisplayLineNo(
                  entry.value.lineNo,
                  entry.key,
                  zeroBasedList: zeroBased,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ShipmentItemCard extends StatelessWidget {
  const _ShipmentItemCard({required this.item, required this.displayLineNo});

  final WarehouseShipmentDetailItem item;
  final int displayLineNo;

  @override
  Widget build(BuildContext context) {
    return TerminalDetailLineCard(
      lineNo: displayLineNo,
      stockName: item.stockName,
      stockCode: item.stockCode,
      quantityLabel:
          '${AppFormatters.quantity(item.quantity)} ${item.unitName}'.trim(),
      secondaryFacts: <String>[
        if (item.warehouseOrderNo.trim().isNotEmpty)
          'Siparis ${item.warehouseOrderNo.trim()}',
      ],
      priceFacts: <String>[
        if (item.unitPrice > 0) 'Fiyat ${AppFormatters.currency(item.unitPrice)}',
        if (item.lineAmount > 0)
          'Tutar ${AppFormatters.currency(item.lineAmount)}',
      ],
      note: item.description,
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
