import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/presentation/view_models/given_company_orders_controller.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/presentation/widgets/given_company_order_create_sheet.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/company_orders_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_picker.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/form_memory/remembered_form_values.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_status.dart';
import 'package:furpa_merkez_terminal/shared/pending_create/pending_create_guard.dart';
import 'package:furpa_merkez_terminal/shared/pending_create/pending_create_repository.dart';
import 'package:furpa_merkez_terminal/shared/utils/client_request_id.dart';
import 'package:furpa_merkez_terminal/shared/utils/safe_create_retry.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_create_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

const String _givenCompanyOrderModuleKey =
    'siparis-islemleri.verilen-firma-siparisleri';

class GivenCompanyOrdersPage extends StatefulWidget {
  const GivenCompanyOrdersPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.canCreate,
    required this.defaultWarehouseNo,
    required this.mobileCustomerCatalogRepository,
    required this.userWarehouseName,
    required this.title,
    required this.subtitle,
    this.currentUserId = '',
    this.draftRepository,
    this.pendingCreateRepository,
    this.emptyListMessage =
        'Secilen tarih araliginda firma siparisi bulunamadi.',
  });

  final CompanyOrdersRepository repository;
  final String accessToken;
  final bool canCreate;
  final String defaultWarehouseNo;
  final MobileCustomerCatalogLocalRepository mobileCustomerCatalogRepository;
  final String userWarehouseName;
  final String title;
  final String subtitle;
  final String currentUserId;
  final CreateDraftRepository? draftRepository;
  final PendingCreateRepository? pendingCreateRepository;
  final String emptyListMessage;

  @override
  State<GivenCompanyOrdersPage> createState() => _GivenCompanyOrdersPageState();
}

class _GivenCompanyOrdersPageState extends State<GivenCompanyOrdersPage> {
  late final GivenCompanyOrdersController _controller;
  late DateTime _startDate;
  late DateTime _endDate;
  CompanyOrderCreateRequest? _pendingCreateRequest;
  CreateDraft? _pendingCreateDraft;
  SafeCreateFailureKind _pendingCreateFailureKind =
      SafeCreateFailureKind.notRetryable;
  DateTime? _pendingRetryNotBefore;
  bool _isRestoringPendingCreate = false;
  bool _hasPendingCreateStorageError = false;

  bool get _usesSafeCreate =>
      widget.canCreate &&
      _controller.canCreate &&
      widget.pendingCreateRepository != null &&
      widget.repository is OfflineSyncStatusProvider<CompanyOrderCreateResult>;

  @override
  void initState() {
    super.initState();
    _controller = GivenCompanyOrdersController(
      repository: widget.repository,
      accessToken: widget.accessToken,
      defaultWarehouseNo: widget.defaultWarehouseNo,
    );
    _startDate = _controller.startDate;
    _endDate = _controller.endDate;
    if (_usesSafeCreate) {
      _isRestoringPendingCreate = true;
      unawaited(_restorePendingCreate());
    }
    unawaited(_controller.loadOrders());
  }

  Future<void> _restorePendingCreate({bool autoRecover = true}) async {
    final repository = widget.pendingCreateRepository;
    if (repository == null) return;
    try {
      final pending = await repository.read(
        moduleKey: _givenCompanyOrderModuleKey,
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
      );
      if (!mounted || pending == null) return;
      final request = CompanyOrderCreateRequest.fromJson(pending.payload);
      if (request.clientRequestId == null || request.clientRequestId!.isEmpty) {
        throw StateError('clientRequestId eksik');
      }
      final failureKind = _failureKindFromName(pending.failureKind);
      setState(() {
        _hasPendingCreateStorageError = false;
        _pendingCreateRequest = request;
        _pendingCreateDraft = pending.draft;
        _pendingCreateFailureKind = failureKind;
        _pendingRetryNotBefore = pending.retryNotBefore;
      });
      if (autoRecover &&
          safeCreateRetryWait(pending.retryNotBefore) == Duration.zero) {
        if (canRetrySafeCreate(failureKind)) {
          await _submitCreateRequest(request, pending.draft);
        } else if (shouldCheckSafeCreateStatus(failureKind)) {
          await _submitCreateRequest(
            request,
            pending.draft,
            statusCheckOnly: true,
          );
        }
      }
    } on Object {
      if (mounted) {
        setState(() => _hasPendingCreateStorageError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bekleyen guvenli siparis kaydi okunamadi. Uygulama verisini '
              'temizlemeden once destek birimine bildirin.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoringPendingCreate = false);
    }
  }

  Future<void> _persistPendingCreate(
    CompanyOrderCreateRequest request,
    CreateDraft? draft, {
    SafeCreateFailureKind? failureKind,
    DateTime? retryNotBefore,
  }) {
    return widget.pendingCreateRepository!.save(
      PendingCreateOperation(
        moduleKey: _givenCompanyOrderModuleKey,
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
    return widget.pendingCreateRepository!.remove(
      moduleKey: _givenCompanyOrderModuleKey,
      userId: widget.currentUserId,
      warehouseNo: widget.defaultWarehouseNo,
      clientRequestId: clientRequestId,
    );
  }

  Future<void> _retryPendingCreate() async {
    final request = _pendingCreateRequest;
    if (request == null) return;
    final wait = safeCreateRetryWait(_pendingRetryNotBefore);
    if (wait > Duration.zero) {
      final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(safeCreateRetryWaitMessage(wait))),
      );
      return;
    }
    await _submitCreateRequest(request, _pendingCreateDraft);
  }

  Future<void> _checkPendingCreateStatus() async {
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
    if (_usesSafeCreate) {
      final hasCapacity = await ensurePendingCreateCapacity(
        context: context,
        repository: widget.pendingCreateRepository!,
        moduleKey: _givenCompanyOrderModuleKey,
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
      );
      if (!hasCapacity || !mounted) return;
    }

    CreateDraft? draft;
    if (widget.draftRepository != null) {
      final launch = await showCreateDraftPicker(
        context: context,
        repository: widget.draftRepository!,
        moduleKey: _givenCompanyOrderModuleKey,
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        createTitle: 'Yeni Verilen Firma Siparisi',
      );
      if (launch == null || !mounted) {
        return;
      }
      draft =
          launch.draft ??
          CreateDraft.empty(
            moduleKey: _givenCompanyOrderModuleKey,
            userId: widget.currentUserId,
            warehouseNo: widget.defaultWarehouseNo,
            title: 'Yeni Verilen Firma Siparisi',
          );
    }
    final request = await openTerminalCreatePage<CompanyOrderCreateRequest>(
      context: context,
      title: 'Yeni Siparis',
      builder: (context) {
        return GivenCompanyOrderCreateSheet(
          repository: widget.repository,
          accessToken: widget.accessToken,
          defaultWarehouseNo: widget.defaultWarehouseNo,
          mobileCustomerCatalogRepository:
              widget.mobileCustomerCatalogRepository,
          draft: draft,
          draftRepository: widget.draftRepository,
        );
      },
    );

    if (request == null || !mounted) {
      return;
    }

    final safeRequest = _usesSafeCreate
        ? request.copyWith(
            clientRequestId: request.clientRequestId?.trim().isNotEmpty == true
                ? request.clientRequestId
                : generateClientRequestId(),
          )
        : request;
    await _submitCreateRequest(safeRequest, draft);
  }

  Future<void> _submitCreateRequest(
    CompanyOrderCreateRequest request,
    CreateDraft? draft, {
    bool statusCheckOnly = false,
  }) async {
    if (_controller.isCreating) return;

    if (_usesSafeCreate) {
      try {
        await _persistPendingCreate(request, draft);
      } on Object {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Guvenli siparis bilgisi cihaza yazilamadi. Islem baslatilmadi.',
              ),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        _pendingCreateRequest = request;
        _pendingCreateDraft = draft;
        if (!statusCheckOnly) {
          _pendingCreateFailureKind = SafeCreateFailureKind.notRetryable;
          _pendingRetryNotBefore = null;
        }
      });
    }

    var result = statusCheckOnly
        ? null
        : await _controller.createOrder(request);
    var recoveredFromStatus = false;

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (result == null && _usesSafeCreate) {
      var failureKind = statusCheckOnly
          ? _pendingCreateFailureKind
          : _controller.createFailureKind;
      var failureMessage = _controller.createError ?? 'Siparis olusturulamadi.';
      DateTime? retryNotBefore;
      final statusProvider =
          widget.repository
              as OfflineSyncStatusProvider<CompanyOrderCreateResult>;
      if (statusCheckOnly ||
          shouldCheckSafeCreateStatus(failureKind) ||
          canRetrySafeCreate(failureKind)) {
        try {
          final provider = widget.repository;
          final recheckProvider =
              provider is OfflineSyncRecheckProvider<CompanyOrderCreateResult>
              ? provider as OfflineSyncRecheckProvider<CompanyOrderCreateResult>
              : null;
          final status = await resolveSafeCreateStatus(
            statusProvider: statusProvider,
            recheckProvider: recheckProvider,
            accessToken: widget.accessToken,
            clientRequestId:
                _controller.createRelatedClientRequestId?.trim().isNotEmpty ==
                    true
                ? _controller.createRelatedClientRequestId!.trim()
                : request.clientRequestId ?? '',
            currentKind: failureKind,
          );
          if (status.isCompleted && status.result != null) {
            result = status.result;
            recoveredFromStatus = true;
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
          // Yerel snapshot, bir sonraki guvenli sorgu icin korunur.
        }
      }

      if (result == null) {
        if (shouldKeepSafeCreatePending(failureKind)) {
          await _persistPendingCreate(
            request,
            draft,
            failureKind: failureKind,
            retryNotBefore: retryNotBefore,
          );
          if (!mounted) return;
          setState(() {
            _pendingCreateFailureKind = failureKind;
            _pendingRetryNotBefore = retryNotBefore;
          });
        } else {
          await _clearPersistedPendingCreate(request.clientRequestId);
          if (!mounted) return;
          setState(() {
            _pendingCreateRequest = null;
            _pendingCreateDraft = null;
            _pendingCreateFailureKind = SafeCreateFailureKind.notRetryable;
            _pendingRetryNotBefore = null;
          });
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(failureMessage),
            action:
                canRetrySafeCreate(failureKind) ||
                    shouldCheckSafeCreateStatus(failureKind) ||
                    shouldRecheckSafeCreate(failureKind)
                ? SnackBarAction(
                    label: canRetrySafeCreate(failureKind)
                        ? 'Tekrar Dene'
                        : shouldRecheckSafeCreate(failureKind)
                        ? 'Dogrula'
                        : 'Kontrol Et',
                    onPressed: () => unawaited(
                      canRetrySafeCreate(failureKind)
                          ? _retryPendingCreate()
                          : _checkPendingCreateStatus(),
                    ),
                  )
                : null,
          ),
        );
        return;
      }
    }

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_controller.createError ?? 'Siparis olusturulamadi.'),
        ),
      );
      return;
    }

    if (_usesSafeCreate) {
      try {
        await _clearPersistedPendingCreate(request.clientRequestId);
      } on Object {
        if (!mounted) return;
        setState(() {
          _pendingCreateRequest = request;
          _pendingCreateDraft = draft;
          _pendingCreateFailureKind = SafeCreateFailureKind.uncertain;
          _pendingRetryNotBefore = null;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${result.documentNoLabel} olusturuldu ancak cihazdaki guvenli '
              'kayit temizlenemedi. Ayni kayitla Tekrar Dene kullanin.',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _pendingCreateRequest = null;
        _pendingCreateDraft = null;
        _pendingCreateFailureKind = SafeCreateFailureKind.notRetryable;
        _pendingRetryNotBefore = null;
      });
    }

    if (recoveredFromStatus) {
      await _controller.loadOrders(
        preferredDocumentSerie: result.documentSerie,
        preferredDocumentOrderNo: result.documentOrderNo,
      );
      if (!mounted) return;
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
          '${result.documentNoLabel} olusturuldu. '
          '${result.lineCount} satir, toplam ${AppFormatters.quantity(result.totalQuantity)} miktar.',
        ),
      ),
    );
    if (draft != null) {
      await widget.draftRepository?.deleteDraft(draft.id);
    }
  }

  Future<void> _toggleOrderSelection(CompanyOrderListItem item) async {
    final detailLoad = _controller.selectOrder(item);
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
                      _CompanyOrderAccordionCard(
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
    await detailLoad;
    await navigation;

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
              _CompanyOrdersAccordionPanel(
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

  Widget _buildHeader() {
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
        if (widget.canCreate && _controller.canCreate)
          FilledButton.tonalIcon(
            onPressed:
                _controller.isCreating ||
                    _isRestoringPendingCreate ||
                    _hasPendingCreateStorageError
                ? null
                : _pendingCreateRequest == null
                ? _openCreateSheet
                : canStartNewSafeCreate(_pendingCreateFailureKind)
                ? _openCreateSheet
                : canRetrySafeCreate(_pendingCreateFailureKind)
                ? _retryPendingCreate
                : shouldCheckSafeCreateStatus(_pendingCreateFailureKind) ||
                      shouldRecheckSafeCreate(_pendingCreateFailureKind)
                ? _checkPendingCreateStatus
                : null,
            icon: _controller.isCreating || _isRestoringPendingCreate
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _hasPendingCreateStorageError
                        ? Icons.error_outline_rounded
                        : _pendingCreateRequest == null ||
                              canStartNewSafeCreate(_pendingCreateFailureKind)
                        ? Icons.add_rounded
                        : Icons.refresh_rounded,
                  ),
            label: Text(
              _controller.isCreating
                  ? 'Kaydediliyor...'
                  : _isRestoringPendingCreate
                  ? 'Kayit kontrol ediliyor...'
                  : _hasPendingCreateStorageError
                  ? 'Destek gerekli'
                  : _pendingCreateRequest == null
                  ? 'Yeni Siparis'
                  : safeCreatePendingActionLabel(_pendingCreateFailureKind),
            ),
          ),
        if (widget.canCreate &&
            _controller.canCreate &&
            _pendingCreateRequest != null)
          FilledButton.icon(
            onPressed:
                _controller.isCreating ||
                    _isRestoringPendingCreate ||
                    _hasPendingCreateStorageError
                ? null
                : _openCreateSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Yeni Siparis'),
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

class _CompanyOrdersAccordionPanel extends StatelessWidget {
  const _CompanyOrdersAccordionPanel({
    required this.controller,
    required this.emptyListMessage,
    required this.onOrderTap,
  });

  final GivenCompanyOrdersController controller;
  final String emptyListMessage;
  final ValueChanged<CompanyOrderListItem> onOrderTap;

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
              padding: const EdgeInsets.only(bottom: 12),
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
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CompanyOrderAccordionCard(
                        item: item,
                        isExpanded:
                            (ModalRoute.of(context)?.isCurrent ?? true) &&
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

class _CompanyOrderAccordionCard extends StatelessWidget {
  const _CompanyOrderAccordionCard({
    required this.item,
    required this.isExpanded,
    required this.detail,
    required this.isLoadingDetail,
    required this.detailError,
    required this.onTap,
  });

  final CompanyOrderListItem item;
  final bool isExpanded;
  final CompanyOrderDetail? detail;
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
                label: 'Teslim',
                value: AppFormatters.dateOrDash(item.deliveryDate),
              ),
              TerminalPdaInfo(
                label: 'Miktar',
                value: AppFormatters.quantity(item.totalQuantity),
              ),
              TerminalPdaInfo(
                label: 'Kalan',
                value: AppFormatters.quantity(item.totalRemainingQuantity),
              ),
              TerminalPdaInfo(
                label: 'Tutar',
                value: AppFormatters.currency(item.totalAmount),
              ),
              TerminalPdaInfo(
                label: 'Adres',
                value: item.customerAddress.isEmpty
                    ? '-'
                    : item.customerAddress,
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

  final CompanyOrderDetail? detail;
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
          _ItemsList(items: detail!.items),
        ],
      ),
    );
  }
}

class _ItemsList extends StatelessWidget {
  const _ItemsList({required this.items});

  final List<CompanyOrderDetailItem> items;

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

  final CompanyOrderDetailItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = <String>[
      'Kod ${item.stockCode}',
      'Birim ${item.unitName}',
      'Miktar ${AppFormatters.quantity(item.quantity)}',
      'Teslim ${AppFormatters.quantity(item.deliveredQuantity)}',
      'Kalan ${AppFormatters.quantity(item.remainingQuantity)}',
      if (item.unitPrice > 0) 'Fiyat ${AppFormatters.currency(item.unitPrice)}',
      if (item.lineAmount > 0)
        'Tutar ${AppFormatters.currency(item.lineAmount)}',
    ].join(' | ');
    final detail = <String>[
      if (item.description.trim().isNotEmpty) 'Aciklama ${item.description}',
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
