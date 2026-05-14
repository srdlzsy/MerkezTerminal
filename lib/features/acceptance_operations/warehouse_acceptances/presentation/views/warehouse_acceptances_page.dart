import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/models/warehouse_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/warehouse_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/presentation/view_models/warehouse_acceptances_controller.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

typedef WarehouseAcceptanceSubmitCallback =
    Future<void> Function(WarehouseAcceptanceRequest request);

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
    if (_controller.selectedAcceptance?.documentNoLabel ==
        item.documentNoLabel) {
      _controller.clearSelection();
      return;
    }

    await _controller.selectAcceptance(item);
  }

  Future<void> _submitAcceptance(WarehouseAcceptanceRequest request) async {
    final result = await _controller.acceptShipment(request);

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_controller.submitError ?? 'Mal kabul kaydedilemedi.'),
        ),
      );
      return;
    }

    final discrepancyInfo = result.hasDiscrepancy
        ? ' Eksik ${AppFormatters.quantity(result.totalMissingQuantity)}, fazla ${AppFormatters.quantity(result.totalExcessQuantity)}.'
        : '';

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.documentNoLabel} kabul edildi. Toplam kabul ${AppFormatters.quantity(result.totalReceivedQuantity)}.$discrepancyInfo',
        ),
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
              _AcceptanceAccordionPanel(
                controller: _controller,
                canSubmit: widget.canSubmit,
                onTap: _toggleSelection,
                onSubmit: _submitAcceptance,
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
          'Bekleyen gelen depo sevklerini listeler, detaydan sayim miktari girilip ayni ekrandan kabul edilir.',
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Varsayilan depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(
          label: 'Bekleyen evrak',
          value: '${_controller.acceptances.length}',
        ),
        TerminalInfoChip(
          label: 'Yetki',
          value: widget.canSubmit ? 'Kabul var' : 'Salt gorunum',
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
      ],
      footer: lastResult == null
          ? null
          : _AcceptanceResultBanner(result: lastResult),
    );
  }
}

class _AcceptanceAccordionPanel extends StatelessWidget {
  const _AcceptanceAccordionPanel({
    required this.controller,
    required this.canSubmit,
    required this.onTap,
    required this.onSubmit,
  });

  final WarehouseAcceptancesController controller;
  final bool canSubmit;
  final ValueChanged<WarehouseAcceptanceListItem> onTap;
  final WarehouseAcceptanceSubmitCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (controller.listError != null && controller.acceptances.isEmpty) {
      return SectionCard(
        title: 'Bekleyen Sevkler',
        subtitle: 'Listeleme sirasinda hata olustu.',
        child: _ErrorBlock(message: controller.listError!),
      );
    }

    return SectionCard(
      title: 'Bekleyen Sevkler',
      subtitle: controller.isLoadingList
          ? 'Liste yenileniyor...'
          : '${controller.acceptances.length} kayit bulundu.',
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
          else if (controller.acceptances.isEmpty)
            const _EmptyState(
              message:
                  'Secilen tarih araliginda bekleyen depo sevki bulunamadi.',
            )
          else
            Column(
              children: controller.acceptances
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AcceptanceAccordionCard(
                        item: item,
                        isExpanded:
                            controller.selectedAcceptance?.documentNoLabel ==
                            item.documentNoLabel,
                        detail:
                            controller.selectedAcceptance?.documentNoLabel ==
                                item.documentNoLabel
                            ? controller.selectedAcceptanceDetail
                            : null,
                        isLoadingDetail:
                            controller.selectedAcceptance?.documentNoLabel ==
                                item.documentNoLabel &&
                            controller.isLoadingDetail,
                        isSubmitting:
                            controller.selectedAcceptance?.documentNoLabel ==
                                item.documentNoLabel &&
                            controller.isSubmitting,
                        detailError:
                            controller.selectedAcceptance?.documentNoLabel ==
                                item.documentNoLabel
                            ? controller.detailError
                            : null,
                        submitError:
                            controller.selectedAcceptance?.documentNoLabel ==
                                item.documentNoLabel
                            ? controller.submitError
                            : null,
                        canSubmit: canSubmit,
                        onSubmit: onSubmit,
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
  const _AcceptanceAccordionCard({
    required this.item,
    required this.isExpanded,
    required this.detail,
    required this.isLoadingDetail,
    required this.isSubmitting,
    required this.detailError,
    required this.submitError,
    required this.canSubmit,
    required this.onSubmit,
    required this.onTap,
  });

  final WarehouseAcceptanceListItem item;
  final bool isExpanded;
  final WarehouseAcceptanceDetail? detail;
  final bool isLoadingDetail;
  final bool isSubmitting;
  final String? detailError;
  final String? submitError;
  final bool canSubmit;
  final WarehouseAcceptanceSubmitCallback onSubmit;
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    flex: 4,
                    child: _InlineField(
                      label: 'Belge',
                      value: item.documentNoLabel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _InlineField(
                      label: 'Sevk Trh',
                      value: AppFormatters.dateOrDash(item.movementDate),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: _InlineField(
                      label: 'Rota',
                      value:
                          '${item.sourceWarehouse} -> ${item.targetWarehouse}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: _InlineField(
                      label: 'Siparis',
                      value: item.warehouseOrderNo.isEmpty
                          ? '-'
                          : item.warehouseOrderNo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _InlineField(
                      label: 'Miktar',
                      value: AppFormatters.quantity(item.totalQuantity),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StateBadge(state: item.shippingState),
                  const SizedBox(width: 2),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22,
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
                        child: _AcceptanceDetailBody(
                          key: ValueKey(item.documentNoLabel),
                          detail: detail,
                          isLoading: isLoadingDetail,
                          isSubmitting: isSubmitting,
                          detailError: detailError,
                          submitError: submitError,
                          canSubmit: canSubmit,
                          onSubmit: onSubmit,
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

class _AcceptanceDetailBody extends StatelessWidget {
  const _AcceptanceDetailBody({
    super.key,
    required this.detail,
    required this.isLoading,
    required this.isSubmitting,
    required this.detailError,
    required this.submitError,
    required this.canSubmit,
    required this.onSubmit,
  });

  final WarehouseAcceptanceDetail? detail;
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
    required this.isSubmitting,
    required this.submitError,
    required this.canSubmit,
    required this.onSubmit,
  });

  final WarehouseAcceptanceDetail detail;
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
  }

  @override
  void dispose() {
    _scanController.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
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

  double get _totalReceivedQuantity {
    return _drafts.fold<double>(
      0,
      (total, draft) => total + draft.receivedQuantity,
    );
  }

  double get _totalShippedQuantity {
    return _drafts.fold<double>(
      0,
      (total, draft) => total + draft.shippedQuantity,
    );
  }

  double get _totalMissingQuantity {
    return _drafts.fold<double>(
      0,
      (total, draft) =>
          total + (draft.differenceValue < 0 ? -draft.differenceValue : 0),
    );
  }

  double get _totalExcessQuantity {
    return _drafts.fold<double>(
      0,
      (total, draft) =>
          total + (draft.differenceValue > 0 ? draft.differenceValue : 0),
    );
  }

  Future<void> _submit() async {
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
          _AcceptanceHeaderSummary(
            header: widget.detail.header,
            totalReceivedQuantity: _totalReceivedQuantity,
            totalShippedQuantity: _totalShippedQuantity,
            totalMissingQuantity: _totalMissingQuantity,
            totalExcessQuantity: _totalExcessQuantity,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withAlpha(80),
              ),
            ),
            child: Text(
              'Her satirda varsayilan olarak sevk miktari gelir. Gerekirse sayilan miktari guncelleyin; eslestirme movementGuid ile yapilir.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.35,
                color: const Color(0xFF5B4738),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _scanController,
            onChanged: (value) {
              setState(() {
                _scanQuery = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Stok kodu / barkod okut',
              hintText: 'Kalemi hizli bul',
              suffixIcon: _scanQuery.trim().isEmpty
                  ? const Icon(Icons.qr_code_scanner_rounded)
                  : IconButton(
                      onPressed: () {
                        _scanController.clear();
                        setState(() {
                          _scanQuery = '';
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _scanQuery.trim().isEmpty
                ? '${_drafts.length} kalem hazir.'
                : '${_visibleDrafts.length}/${_drafts.length} kalem eslesti.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B5A4A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kalemler',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (_visibleDrafts.isEmpty)
            const _InfoBlock(
              message:
                  'Okutulan kodla eslesen kalem bulunamadi. Stok kodunu veya arama metnini kontrol edin.',
            )
          else
            Column(
              children: _visibleDrafts
                  .map(
                    (draft) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AcceptanceLineCard(
                        draft: draft,
                        onChanged: () {
                          setState(() {
                            _validationMessage = null;
                          });
                        },
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          if (_hasDiscrepancy) ...<Widget>[
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  _allowDiscrepancy = !_allowDiscrepancy;
                  _validationMessage = null;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5D9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8C667)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Checkbox(
                      value: _allowDiscrepancy,
                      onChanged: (value) {
                        setState(() {
                          _allowDiscrepancy = value ?? false;
                          _validationMessage = null;
                        });
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Eksik veya fazla kabul oldugunu onayliyorum. Bu durumda allowDiscrepancy=true gonderilecek.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF6A4D00),
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!widget.canSubmit) ...<Widget>[
            const SizedBox(height: 10),
            const _InfoBlock(
              message:
                  'Bu kullanicida mal kabul kaydetme yetkisi yok. Ekran salt okunur modda gosteriliyor.',
            ),
          ],
          if (_validationMessage != null) ...<Widget>[
            const SizedBox(height: 10),
            _ErrorBlock(message: _validationMessage!),
          ],
          if (submitError != null) ...<Widget>[
            const SizedBox(height: 10),
            _ErrorBlock(message: submitError),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: widget.canSubmit && !widget.isSubmitting
                  ? _submit
                  : null,
              icon: widget.isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.inventory_2_rounded),
              label: Text(
                widget.isSubmitting
                    ? 'Kaydediliyor...'
                    : 'Depo Sevki Mal Kabul Et',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcceptanceHeaderSummary extends StatelessWidget {
  const _AcceptanceHeaderSummary({
    required this.header,
    required this.totalReceivedQuantity,
    required this.totalShippedQuantity,
    required this.totalMissingQuantity,
    required this.totalExcessQuantity,
  });

  final WarehouseAcceptanceDetailHeader header;
  final double totalReceivedQuantity;
  final double totalShippedQuantity;
  final double totalMissingQuantity;
  final double totalExcessQuantity;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _SummaryTile(label: 'Belge', value: header.documentNoLabel),
        _SummaryTile(
          label: 'Kaynak',
          value: '${header.sourceWarehouseNo} - ${header.sourceWarehouse}',
        ),
        _SummaryTile(
          label: 'Hedef',
          value: '${header.targetWarehouseNo} - ${header.targetWarehouse}',
        ),
        _SummaryTile(label: 'Transit', value: '${header.shippingWarehouseNo}'),
        _SummaryTile(
          label: 'Toplam Sevk',
          value: AppFormatters.quantity(totalShippedQuantity),
        ),
        _SummaryTile(
          label: 'Toplam Sayim',
          value: AppFormatters.quantity(totalReceivedQuantity),
        ),
        _SummaryTile(
          label: 'Eksik',
          value: AppFormatters.quantity(totalMissingQuantity),
        ),
        _SummaryTile(
          label: 'Fazla',
          value: AppFormatters.quantity(totalExcessQuantity),
        ),
      ],
    );
  }
}

class _AcceptanceLineCard extends StatelessWidget {
  const _AcceptanceLineCard({required this.draft, required this.onChanged});

  final _AcceptanceLineDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  draft.stockName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF231C17),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _DifferenceBadge(type: draft.differenceType),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Kod ${draft.stockCode} | Sevk ${AppFormatters.quantity(draft.shippedQuantity)} | Birim ${draft.unitName}/${draft.unitPointer}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B5A4A),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (draft.extraInfo.isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              draft.extraInfo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B5A4A),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 150,
                child: TextField(
                  controller: draft.receivedQuantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Sayilan miktar',
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              _MiniMetric(
                label: 'Fark',
                value: AppFormatters.quantity(draft.differenceValue.abs()),
              ),
              _MiniMetric(label: 'Guid', value: draft.shortGuid),
            ],
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
         text: AppFormatters.quantity(shippedQuantity).replaceAll('.', ''),
       );

  factory _AcceptanceLineDraft.fromDetailItem(
    WarehouseAcceptanceDetailItem item,
  ) {
    final extra = <String>[
      if (item.description.isNotEmpty) 'Aciklama ${item.description}',
      if (item.partyCode.isNotEmpty) 'Parti ${item.partyCode}',
      if (item.lotNo > 0) 'Lot ${item.lotNo}',
    ].join(' | ');

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

  double get differenceValue => receivedQuantity - shippedQuantity;

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

class _InlineField extends StatelessWidget {
  const _InlineField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: const Color(0xFF6B5A4A),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: const Color(0xFF231C17),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
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

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(82),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF231C17),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
