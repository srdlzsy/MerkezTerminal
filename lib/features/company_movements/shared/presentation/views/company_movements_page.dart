import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/company_movements_repository.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/data/models/company_movement_models.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/presentation/view_models/company_movements_controller.dart';
import 'package:furpa_merkez_terminal/features/company_movements/shared/presentation/widgets/company_movement_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/presentation/views/warehouse_return_pdf_preview_page.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/presentation/widgets/warehouse_return_e_despatch_sheet.dart';
import 'package:furpa_merkez_terminal/shared/data/despatch_drivers_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_picker.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/form_memory/remembered_form_values.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_status.dart';
import 'package:furpa_merkez_terminal/shared/pending_create/pending_create_repository.dart';
import 'package:furpa_merkez_terminal/shared/utils/completed_create_cleanup.dart';
import 'package:furpa_merkez_terminal/shared/utils/safe_create_retry.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_create_page.dart';
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
    required this.pendingCreateRepository,
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
    this.despatchDriversRepository,
    this.initialCustomer,
    this.openCreateOnStart = false,
    this.returnToPreviousAfterInitialCreate = false,
  });

  final CompanyMovementsRepository repository;
  final String accessToken;
  final bool canCreate;
  final String currentUserId;
  final String draftModuleKey;
  final CreateDraftRepository? draftRepository;
  final PendingCreateRepository pendingCreateRepository;
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
  final DespatchDriversRepository? despatchDriversRepository;
  final CustomerLookupItem? initialCustomer;
  final bool openCreateOnStart;
  final bool returnToPreviousAfterInitialCreate;

  @override
  State<CompanyMovementsPage> createState() => _CompanyMovementsPageState();
}

class _CompanyMovementsPageState extends State<CompanyMovementsPage> {
  late final CompanyMovementsController _controller;
  CompanyMovementCreateRequest? _pendingCreateRequest;
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
    _controller = CompanyMovementsController(
      repository: widget.repository,
      accessToken: widget.accessToken,
      defaultWarehouseNo: widget.defaultWarehouseNo,
    );
    _startDate = _controller.startDate;
    _endDate = _controller.endDate;
    if (widget.openCreateOnStart && widget.initialCustomer != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_openInitialCreateSheet());
        }
      });
    }
    if (widget.canCreate && _controller.canCreate) {
      _isRestoringPendingCreate = true;
      unawaited(_restorePendingCreate());
    }
    unawaited(_controller.loadMovements());
  }

  Future<void> _openInitialCreateSheet() async {
    await _openCreateSheet(
      initialCustomer: widget.initialCustomer,
      skipDraftPicker: true,
    );
    if (!mounted || !widget.returnToPreviousAfterInitialCreate) {
      return;
    }

    await Navigator.of(context).maybePop();
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
      final request = CompanyMovementCreateRequest.fromJson(pending.payload);
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
              'Bekleyen guvenli evrak kaydi okunamadi. Uygulama verisini '
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
    CompanyMovementCreateRequest request,
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

  Future<void> _toggleSelection(CompanyMovementListItem item) async {
    final detailLoad = _controller.selectMovement(item);
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
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      20 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: <Widget>[
                      _MovementCard(
                        item: item,
                        detail: _controller.selectedMovementDetail,
                        isExpanded: true,
                        isLoadingDetail: _controller.isLoadingDetail,
                        detailError: _controller.detailError,
                        canSendEDespatch: _controller.canSendEDespatch,
                        canViewEDespatchPdf: _controller.canViewEDespatchPdf,
                        isSendingEDespatch: _controller.isSendingEDespatch,
                        isLoadingPdf: _controller.isLoadingPdf,
                        lastEDespatchResult: _controller.lastEDespatchResult,
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

  Future<void> _openCreateSheet({
    CustomerLookupItem? initialCustomer,
    bool skipDraftPicker = false,
  }) async {
    CreateDraft? draft;
    final draftRepository = widget.draftRepository;
    if (draftRepository != null &&
        widget.draftModuleKey.isNotEmpty &&
        skipDraftPicker) {
      draft = CreateDraft.empty(
        moduleKey: widget.draftModuleKey,
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        title: widget.createTitle,
      );
    } else if (draftRepository != null && widget.draftModuleKey.isNotEmpty) {
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

    var submittedInline = false;
    final request = await openTerminalCreatePage<CompanyMovementCreateRequest>(
      context: context,
      title: widget.createTitle,
      builder: (context) {
        return CompanyMovementCreateSheet(
          repository: widget.repository,
          accessToken: widget.accessToken,
          defaultWarehouseNo: widget.defaultWarehouseNo,
          mobileCustomerCatalogRepository:
              widget.mobileCustomerCatalogRepository,
          title: widget.createTitle,
          helperText: widget.createHelperText,
          submitLabel: 'Kaydet',
          barcodeOperationType: widget.draftModuleKey.contains('iade')
              ? 'return'
              : 'shipment',
          barcodeScreenCode: widget.draftModuleKey.split('.').last,
          showDocumentNoField: widget.showCreateDocumentNoField,
          draft: draft,
          draftRepository: draftRepository,
          initialCustomer: initialCustomer,
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
    CompanyMovementCreateRequest request,
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
        : await _controller.createMovement(request);

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
      var failureMessage = _controller.createError ?? 'Evrak olusturulamadi.';
      DateTime? retryNotBefore;
      final provider = widget.repository;
      final statusProvider =
          provider is OfflineSyncStatusProvider<CompanyMovementCreateResult>
          ? provider as OfflineSyncStatusProvider<CompanyMovementCreateResult>
          : null;
      if ((statusCheckOnly ||
              shouldCheckSafeCreateStatus(failureKind) ||
              canRetrySafeCreate(failureKind)) &&
          statusProvider != null) {
        try {
          final recheckProvider =
              provider
                  is OfflineSyncRecheckProvider<CompanyMovementCreateResult>
              ? provider
                    as OfflineSyncRecheckProvider<CompanyMovementCreateResult>
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
      if (result == null) {
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
      await _controller.loadMovements(
        preferredDocumentSerie: result.documentSerie,
        preferredDocumentOrderNo: result.documentOrderNo,
      );
      if (!mounted) {
        return false;
      }
    }

    unawaited(
      RememberedFormValuesRepository().rememberAll(
        warehouseNo: widget.defaultWarehouseNo,
        values: <RememberedFormField, String>{
          RememberedFormField.deliverer: request.deliverer,
          RememberedFormField.receiver: request.receiver,
        },
      ),
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.documentNoLabel} olusturuldu. ${result.lineCount} satir, toplam ${AppFormatters.quantity(result.totalQuantity)} miktar.',
        ),
      ),
    );
    return true;
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
                        : Icons.add_rounded,
                  ),
            label: Text(
              _controller.isCreating
                  ? 'Kaydediliyor...'
                  : _isRestoringPendingCreate
                  ? 'Kayit kontrol ediliyor...'
                  : _hasPendingCreateStorageError
                  ? 'Destek gerekli'
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
                        (ModalRoute.of(context)?.isCurrent ?? true) &&
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

SafeCreateFailureKind _failureKindFromName(String? value) {
  return SafeCreateFailureKind.values.firstWhere(
    (item) => item.name == value,
    orElse: () => SafeCreateFailureKind.uncertain,
  );
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

    return TerminalPdaRecordCard(
      isSelected: isExpanded,
      onTap: onTap,
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
                label: 'Hareket',
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

    return TerminalPdaDetailPanel(
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
          ],
          if (lastEDespatchResult != null) ...<Widget>[
            const SizedBox(height: 12),
            TerminalMessageBlock.info(
              message:
                  'Son e-irsaliye: ${lastEDespatchResult!.documentNoLabel} | '
                  '${lastEDespatchResult!.serviceDocumentLabel}'
                  '${lastEDespatchResult!.isMikroMetadataPending ? '\n${lastEDespatchResult!.metadataStatusMessage}' : ''}'
                  '${lastEDespatchResult!.hasWarning ? '\nUyari: ${lastEDespatchResult!.warningMessage}' : ''}',
            ),
          ],
          if (detail!.header.deliverer.trim().isNotEmpty ||
              detail!.header.receiver.trim().isNotEmpty) ...<Widget>[
            TerminalPdaInfoGrid(
              items: <TerminalPdaInfo>[
                if (detail!.header.deliverer.trim().isNotEmpty)
                  TerminalPdaInfo(
                    label: 'Teslim Eden',
                    value: detail!.header.deliverer,
                  ),
                if (detail!.header.receiver.trim().isNotEmpty)
                  TerminalPdaInfo(
                    label: 'Teslim Alan',
                    value: detail!.header.receiver,
                  ),
              ],
            ),
            const SizedBox(height: 12),
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
                      'Birim ${item.unitName}',
                      'Miktar ${AppFormatters.quantity(item.quantity)}',
                      if (item.unitPrice > 0)
                        'Fiyat ${AppFormatters.currency(item.unitPrice)}',
                      if (item.lineAmount > 0)
                        'Tutar ${AppFormatters.currency(item.lineAmount)}',
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
