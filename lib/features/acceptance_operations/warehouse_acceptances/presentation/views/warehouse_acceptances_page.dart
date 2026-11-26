import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/models/warehouse_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/warehouse_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/presentation/view_models/warehouse_acceptances_controller.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_controller.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

typedef WarehouseAcceptanceSubmitCallback =
    Future<bool> Function(WarehouseAcceptanceRequest request);

const double _warehouseAcceptanceQuantityTolerance = 0.000001;

class WarehouseAcceptancesPage extends StatefulWidget {
  const WarehouseAcceptancesPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
    required this.canSubmit,
  });

  final WarehouseAcceptancesRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;
  final String userWarehouseName;
  final bool canSubmit;

  @override
  State<WarehouseAcceptancesPage> createState() =>
      _WarehouseAcceptancesPageState();
}

class _WarehouseAcceptancesPageState extends State<WarehouseAcceptancesPage> {
  late final WarehouseAcceptancesController _controller;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _controller = WarehouseAcceptancesController(
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

  Future<void> _toggleSelection(WarehouseAcceptanceListItem item) async {
    final detailLoad = _controller.selectAcceptance(item);
    if (!mounted) {
      return;
    }

    final navigation = Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (detailContext) {
          return ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              return Scaffold(
                appBar: AppBar(title: Text(item.documentNoLabel)),
                body: SafeArea(
                  child: Padding(
                    padding: terminalPdaListPagePadding(context),
                    child: Column(
                      children: <Widget>[
                        _AcceptanceDocumentSummary(item: item),
                        const SizedBox(height: 6),
                        Expanded(
                          child: _AcceptanceDetailBody(
                            key: ValueKey(item.documentNoLabel),
                            isReturn:
                                _controller
                                    .selectedAcceptanceDetail
                                    ?.header
                                    .isReturn ??
                                item.isReturn,
                            detail: _controller.selectedAcceptanceDetail,
                            isLoading: _controller.isLoadingDetail,
                            isSubmitting: _controller.isSubmitting,
                            detailError: _controller.detailError,
                            submitError: _controller.submitError,
                            canSubmit: widget.canSubmit,
                            onSubmit: (request) => _submitAcceptanceAndClose(
                              detailContext,
                              request,
                            ),
                          ),
                        ),
                      ],
                    ),
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

  Future<bool> _submitAcceptanceAndClose(
    BuildContext detailContext,
    WarehouseAcceptanceRequest request,
  ) async {
    final succeeded = await _submitAcceptance(request);
    if (succeeded && detailContext.mounted) {
      Navigator.of(detailContext).pop();
    }
    return succeeded;
  }

  Future<bool> _submitAcceptance(WarehouseAcceptanceRequest request) async {
    final result = await _controller.acceptShipment(request);

    if (!mounted) {
      return false;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_controller.submitError ?? 'Mal kabul kaydedilemedi.'),
        ),
      );
      return false;
    }

    final documentType = result.isReturn ? 'iade' : 'sevk';
    final discrepancyInfo = result.hasDiscrepancy
        ? ' Eksik ${AppFormatters.quantity(result.totalMissingQuantity)}, fazla ${AppFormatters.quantity(result.totalExcessQuantity)}.'
        : '';

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.documentNoLabel} $documentType kabul edildi. Toplam kabul ${AppFormatters.quantity(result.totalReceivedQuantity)}.$discrepancyInfo',
        ),
      ),
    );
    return true;
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
              _AcceptanceAccordionPanel(
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
    final lastResult = _controller.lastAcceptanceResult;

    return TerminalListHeaderCard(
      title: 'Depo Mal Kabulleri',
      subtitle:
          'Bekleyen gelen depo sevk ve iadelerini listeler, detaydan sayim miktari girilip ayni ekrandan kabul edilir.',
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Varsayilan depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(
          label: 'Bekleyen sevk/iade',
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
        _WarehouseAcceptanceListButton(
          onPressed: _controller.isLoadingList ? null : _applyFilters,
        ),
        OutlinedButton.icon(
          onPressed: _controller.isLoadingList ? null : _resetFilters,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Temizle'),
        ),
      ],
      footer: lastResult == null
          ? null
          : _AcceptanceResultBanner(result: lastResult),
    );
  }
}

class _WarehouseAcceptanceListButton extends StatelessWidget {
  const _WarehouseAcceptanceListButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.search_rounded),
      label: const Text('Listele'),
    );
  }
}

class _AcceptanceAccordionPanel extends StatelessWidget {
  const _AcceptanceAccordionPanel({
    required this.controller,
    required this.onTap,
  });

  final WarehouseAcceptancesController controller;
  final ValueChanged<WarehouseAcceptanceListItem> onTap;

  @override
  Widget build(BuildContext context) {
    if (controller.listError != null && controller.acceptances.isEmpty) {
      return SectionCard(
        title: 'Bekleyen Sevk/Iadeler',
        subtitle: 'Listeleme sirasinda hata olustu.',
        child: _ErrorBlock(message: controller.listError!),
      );
    }

    return SectionCard(
      title: 'Bekleyen Sevk/Iadeler',
      subtitle: controller.isLoadingList
          ? 'Liste yenileniyor...'
          : '${controller.acceptances.length} kayit bulundu.',
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
          else if (controller.acceptances.isEmpty)
            const _EmptyState(
              message:
                  'Secilen tarih araliginda bekleyen depo sevki veya iadesi bulunamadi.',
            )
          else
            Column(
              children: controller.acceptances
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AcceptanceAccordionCard(
                        item: item,
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

class _AcceptanceAccordionCard extends StatelessWidget {
  const _AcceptanceAccordionCard({required this.item, required this.onTap});

  final WarehouseAcceptanceListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TerminalPdaRecordCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TerminalPdaCardHeader(
            title: item.documentNoLabel,
            subtitle: '${item.sourceWarehouse} -> ${item.targetWarehouse}',
            trailing: TerminalPdaCardTrailing(
              badges: <Widget>[
                _DocumentTypeBadge(isReturn: item.isReturn),
                _StateBadge(state: item.shippingState),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TerminalPdaInfoGrid(
            compact: true,
            items: <TerminalPdaInfo>[
              TerminalPdaInfo(
                label: 'Sevk Trh',
                value: AppFormatters.dateOrDash(item.movementDate),
              ),
              TerminalPdaInfo(
                label: item.isReturn ? 'Iade' : 'Siparis',
                value: item.warehouseOrderNo.isEmpty
                    ? '-'
                    : item.warehouseOrderNo,
              ),
              TerminalPdaInfo(
                label: 'Miktar',
                value: AppFormatters.quantity(item.totalQuantity),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcceptanceDocumentSummary extends StatelessWidget {
  const _AcceptanceDocumentSummary({required this.item});

  final WarehouseAcceptanceListItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _DocumentTypeBadge(isReturn: item.isReturn),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${item.sourceWarehouse} -> ${item.targetWarehouse}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${AppFormatters.quantity(item.totalQuantity)} miktar',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF6B5A4A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AcceptanceDetailBody extends StatelessWidget {
  const _AcceptanceDetailBody({
    super.key,
    required this.detail,
    required this.isReturn,
    required this.isLoading,
    required this.isSubmitting,
    required this.detailError,
    required this.submitError,
    required this.canSubmit,
    required this.onSubmit,
  });

  final WarehouseAcceptanceDetail? detail;
  final bool isReturn;
  final bool isLoading;
  final bool isSubmitting;
  final String? detailError;
  final String? submitError;
  final bool canSubmit;
  final WarehouseAcceptanceSubmitCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (detailError != null) {
      return _ErrorBlock(message: detailError!);
    }

    if (detail == null) {
      return const _EmptyState(message: 'Detay bilgisi yuklenemedi.');
    }

    return _AcceptanceReadyBody(
      detail: detail!,
      isReturn: isReturn,
      isSubmitting: isSubmitting,
      submitError: submitError,
      canSubmit: canSubmit,
      onSubmit: onSubmit,
    );
  }
}

class _AcceptanceReadyBody extends StatefulWidget {
  const _AcceptanceReadyBody({
    required this.detail,
    required this.isReturn,
    required this.isSubmitting,
    required this.submitError,
    required this.canSubmit,
    required this.onSubmit,
  });

  final WarehouseAcceptanceDetail detail;
  final bool isReturn;
  final bool isSubmitting;
  final String? submitError;
  final bool canSubmit;
  final WarehouseAcceptanceSubmitCallback onSubmit;

  @override
  State<_AcceptanceReadyBody> createState() => _AcceptanceReadyBodyState();
}

class _AcceptanceReadyBodyState extends State<_AcceptanceReadyBody> {
  late final List<_AcceptanceLineDraft> _drafts;
  late final TextEditingController _scanController;
  late final FocusNode _scanFocusNode;
  bool _allowDiscrepancy = false;
  String? _validationMessage;
  String _scanQuery = '';

  @override
  void initState() {
    super.initState();
    _drafts = widget.detail.items
        .map(_AcceptanceLineDraft.fromDetailItem)
        .toList(growable: false);
    _scanController = TextEditingController();
    _scanFocusNode = FocusNode();
    _scanController.addListener(_handleScanTextChanged);
    _focusScanField();
  }

  @override
  void dispose() {
    _scanController.removeListener(_handleScanTextChanged);
    _scanController.dispose();
    _scanFocusNode.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _handleScanTextChanged() {
    final nextQuery = _scanController.text;
    if (nextQuery == _scanQuery) {
      return;
    }
    setState(() {
      _scanQuery = nextQuery;
    });
  }

  void _focusScanField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scanFocusNode.requestFocus();
      }
    });
  }

  List<_AcceptanceLineDraft> get _visibleDrafts {
    final query = _scanQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _drafts;
    }

    return _drafts
        .where(
          (draft) =>
              draft.stockCode.toLowerCase().contains(query) ||
              draft.stockName.toLowerCase().contains(query) ||
              draft.shortGuid.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  bool get _hasDiscrepancy {
    return _drafts.any((draft) => draft.differenceType != 'none');
  }

  bool get _hasRequiredEDespatch {
    return widget.detail.header.hasRequiredEDespatchForAcceptance;
  }

  Future<void> _submit() async {
    if (widget.isSubmitting) {
      return;
    }

    if (!_hasRequiredEDespatch) {
      setState(() {
        _validationMessage =
            'Gonderen taraf e-irsaliyesi olusmadan depo mal kabul yapilamaz.';
      });
      return;
    }

    if (_drafts.isEmpty) {
      setState(() {
        _validationMessage = 'Kabul edilecek satir bulunamadi.';
      });
      return;
    }

    if (_drafts.any((draft) => draft.receivedQuantity < 0)) {
      setState(() {
        _validationMessage = 'Sayilan miktar negatif olamaz.';
      });
      return;
    }

    if (_hasDiscrepancy && !_allowDiscrepancy) {
      setState(() {
        _validationMessage =
            'Eksik veya fazla kabul var. Devam etmek icin fark onayini acin.';
      });
      return;
    }

    setState(() {
      _validationMessage = null;
    });

    await widget.onSubmit(
      WarehouseAcceptanceRequest(
        allowDiscrepancy: _hasDiscrepancy && _allowDiscrepancy,
        lines: _drafts
            .map(
              (draft) => WarehouseAcceptanceRequestLine(
                movementGuid: draft.movementGuid,
                receivedQuantity: draft.receivedQuantity,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitError = widget.submitError;
    final hasRequiredEDespatch = _hasRequiredEDespatch;
    final statusMessage =
        _validationMessage ??
        submitError ??
        (!hasRequiredEDespatch
            ? 'Gonderen taraf e-irsaliyesi olusmadan kabul yapilamaz.'
            : !widget.canSubmit
            ? 'Bu kullanicida mal kabul kaydetme yetkisi yok.'
            : null);
    final statusIsError = _validationMessage != null || submitError != null;
    final visibleDrafts = _visibleDrafts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ProductLookupField(
          controller: _scanController,
          focusNode: _scanFocusNode,
          autofocus: true,
          suppressSoftKeyboard: true,
          labelText: 'Stok kodu / barkod okut',
          hintText: 'Kalemi bul',
          onSubmit: _focusScanField,
          suffixIcon: _scanQuery.trim().isEmpty
              ? const Icon(Icons.qr_code_scanner_rounded, size: 18)
              : IconButton(
                  onPressed: () {
                    _scanController.clear();
                    setState(() {
                      _scanQuery = '';
                    });
                    _focusScanField();
                  },
                  tooltip: 'Temizle',
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
        ),
        const SizedBox(height: 5),
        Text(
          _scanQuery.trim().isEmpty
              ? '${_drafts.length} kalem · Sayilan miktari kontrol edin.'
              : '${visibleDrafts.length}/${_drafts.length} kalem eslesti.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11.5,
            color: const Color(0xFF536171),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Expanded(
          child: visibleDrafts.isEmpty
              ? const Center(
                  child: _InfoBlock(
                    message:
                        'Okutulan kodla eslesen kalem bulunamadi. Kodu kontrol edin.',
                  ),
                )
              : ListView.separated(
                  key: const ValueKey<String>('warehouse-acceptance-lines'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 4),
                  itemCount: visibleDrafts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    return _AcceptanceLineCard(
                      lineNo: index + 1,
                      draft: visibleDrafts[index],
                      onChanged: () {
                        setState(() {
                          _validationMessage = null;
                        });
                      },
                    );
                  },
                ),
        ),
        if (_hasDiscrepancy)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            value: _allowDiscrepancy,
            onChanged: (value) {
              setState(() {
                _allowDiscrepancy = value ?? false;
                _validationMessage = null;
              });
            },
            title: const Text(
              'Eksik/fazla miktari onayliyorum',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        if (statusMessage != null) ...<Widget>[
          const SizedBox(height: 4),
          if (statusIsError)
            _ErrorBlock(message: statusMessage)
          else
            _InfoBlock(message: statusMessage),
        ],
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                widget.canSubmit && hasRequiredEDespatch && !widget.isSubmitting
                ? _submit
                : null,
            icon: widget.isSubmitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.inventory_2_rounded),
            label: Text(widget.isSubmitting ? 'Kaydediliyor...' : 'Kabul Et'),
          ),
        ),
      ],
    );
  }
}

class _AcceptanceLineCard extends StatelessWidget {
  const _AcceptanceLineCard({
    required this.lineNo,
    required this.draft,
    required this.onChanged,
  });

  final int lineNo;
  final _AcceptanceLineDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(115),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withAlpha(110),
                  ),
                ),
                child: Text(
                  lineNo.toString().padLeft(2, '0'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    height: 1,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  draft.stockName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 13.5,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF182230),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _DifferenceBadge(type: draft.differenceType),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.qr_code_scanner_rounded,
                size: 14,
                color: theme.colorScheme.onSurface.withAlpha(185),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      draft.stockCode,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurface.withAlpha(215),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Evrak ${AppFormatters.quantity(draft.shippedQuantity)} ${draft.unitName}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11.5,
                        color: const Color(0xFF1C2D40),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (draft.extraInfo.isNotEmpty)
                      Text(
                        draft.extraInfo,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TerminalQuantityStepper(
            controller: draft.receivedQuantityController,
            label: 'Sayilan',
            minimum: 0,
            dense: true,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
            ],
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}

class _AcceptanceResultBanner extends StatelessWidget {
  const _AcceptanceResultBanner({required this.result});

  final WarehouseAcceptanceResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F6EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB0DEC0)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          _MiniMetric(label: 'Son kabul', value: result.documentNoLabel),
          _MiniMetric(label: 'Tip', value: result.isReturn ? 'Iade' : 'Sevk'),
          _MiniMetric(
            label: 'Toplam kabul',
            value: AppFormatters.quantity(result.totalReceivedQuantity),
          ),
          _MiniMetric(
            label: 'Eksik',
            value: AppFormatters.quantity(result.totalMissingQuantity),
          ),
          _MiniMetric(
            label: 'Fazla',
            value: AppFormatters.quantity(result.totalExcessQuantity),
          ),
          _MiniMetric(
            label: 'Durum',
            value: result.hasDiscrepancy
                ? result.differenceResolutionStatus
                : 'tam',
          ),
        ],
      ),
    );
  }
}

class _AcceptanceLineDraft {
  _AcceptanceLineDraft({
    required this.movementGuid,
    required this.stockCode,
    required this.stockName,
    required this.unitName,
    required this.unitPointer,
    required this.shippedQuantity,
    required this.extraInfo,
  }) : receivedQuantityController = TextEditingController(
         text: productEntryController.formatQuantity(shippedQuantity),
       );

  factory _AcceptanceLineDraft.fromDetailItem(
    WarehouseAcceptanceDetailItem item,
  ) {
    final cleanNote = terminalDisplayableNote(item.description);
    final extra = <String>[
      ?cleanNote,
      if (item.partyCode.isNotEmpty) 'Parti ${item.partyCode}',
      if (item.lotNo > 0) 'Lot ${item.lotNo}',
    ].join(' · ');

    return _AcceptanceLineDraft(
      movementGuid: item.movementGuid,
      stockCode: item.stockCode,
      stockName: item.stockName,
      unitName: item.unitName,
      unitPointer: item.unitPointer,
      shippedQuantity: item.quantity,
      extraInfo: extra,
    );
  }

  final String movementGuid;
  final String stockCode;
  final String stockName;
  final String unitName;
  final int unitPointer;
  final double shippedQuantity;
  final String extraInfo;
  final TextEditingController receivedQuantityController;

  double get receivedQuantity {
    final raw = receivedQuantityController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw) ?? 0;
  }

  double get differenceValue {
    final difference = receivedQuantity - shippedQuantity;
    return difference.abs() <= _warehouseAcceptanceQuantityTolerance
        ? 0
        : difference;
  }

  String get differenceType {
    if (differenceValue == 0) {
      return 'none';
    }

    return differenceValue < 0 ? 'missing' : 'excess';
  }

  String get shortGuid {
    if (movementGuid.length <= 8) {
      return movementGuid;
    }

    return movementGuid.substring(0, 8);
  }

  void dispose() {
    receivedQuantityController.dispose();
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF231C17),
        ),
      ),
    );
  }
}

class _DifferenceBadge extends StatelessWidget {
  const _DifferenceBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = switch (type) {
      'missing' => (const Color(0xFFFFF1D8), const Color(0xFF9A5A00), 'Eksik'),
      'excess' => (const Color(0xFFFFE5E5), const Color(0xFF7A1818), 'Fazla'),
      _ => (const Color(0xFFE6F7EE), const Color(0xFF1B7A46), 'Tam'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _shippingStateLabel(state),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DocumentTypeBadge extends StatelessWidget {
  const _DocumentTypeBadge({required this.isReturn});

  final bool isReturn;

  @override
  Widget build(BuildContext context) {
    final background = isReturn
        ? const Color(0xFFFFEEDB)
        : const Color(0xFFE9EEF7);
    final foreground = isReturn
        ? const Color(0xFF8A4B00)
        : const Color(0xFF32598B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isReturn ? 'Iade' : 'Sevk',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8DFEC)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF35506D)),
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

String _shippingStateLabel(int state) {
  return switch (state) {
    1 => 'Ulasti',
    0 => 'Yolda',
    _ => 'Durum $state',
  };
}
