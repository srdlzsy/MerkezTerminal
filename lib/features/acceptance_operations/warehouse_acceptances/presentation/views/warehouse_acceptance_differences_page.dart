import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/models/warehouse_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/warehouse_acceptances/data/warehouse_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class WarehouseAcceptanceDifferencesPage extends StatefulWidget {
  const WarehouseAcceptanceDifferencesPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
  });

  final WarehouseAcceptancesRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;
  final String userWarehouseName;

  @override
  State<WarehouseAcceptanceDifferencesPage> createState() =>
      _WarehouseAcceptanceDifferencesPageState();
}

class _WarehouseAcceptanceDifferencesPageState
    extends State<WarehouseAcceptanceDifferencesPage> {
  DateTime _startDate = defaultFilterStartDate();
  DateTime _endDate = defaultFilterEndDate();
  WarehouseAcceptanceDifferenceScope _scope =
      WarehouseAcceptanceDifferenceScope.accepted;
  bool _isLoading = false;
  String? _errorMessage;
  List<WarehouseAcceptanceDifferenceItem> _items =
      const <WarehouseAcceptanceDifferenceItem>[];

  @override
  void initState() {
    super.initState();
    unawaited(_loadDifferences());
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

  Future<void> _loadDifferences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.repository.fetchDifferences(
        accessToken: widget.accessToken,
        filter: WarehouseAcceptanceDifferenceFilter(
          startDate: _normalizedDate(_startDate),
          endDate: _normalizedDate(_endDate),
          scope: _scope,
          warehouseNo: widget.defaultWarehouseNo,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _items = const <WarehouseAcceptanceDifferenceItem>[];
        _errorMessage = error.message;
        _isLoading = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _startDate = defaultFilterStartDate();
      _endDate = defaultFilterEndDate();
      _scope = WarehouseAcceptanceDifferenceScope.accepted;
    });

    unawaited(_loadDifferences());
  }

  @override
  Widget build(BuildContext context) {
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
          _buildResults(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return TerminalListHeaderCard(
      title: 'Mal Kabul Farklari',
      subtitle: 'Kabul edilen sevk ve iadelerdeki eksik/fazla farklari.',
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Varsayilan depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(label: 'Fark kaydi', value: '${_items.length}'),
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
        SegmentedButton<WarehouseAcceptanceDifferenceScope>(
          segments: const <ButtonSegment<WarehouseAcceptanceDifferenceScope>>[
            ButtonSegment<WarehouseAcceptanceDifferenceScope>(
              value: WarehouseAcceptanceDifferenceScope.accepted,
              icon: Icon(Icons.call_received_rounded),
              label: Text('Kabul Ettigim'),
            ),
            ButtonSegment<WarehouseAcceptanceDifferenceScope>(
              value: WarehouseAcceptanceDifferenceScope.created,
              icon: Icon(Icons.call_made_rounded),
              label: Text('Olusturdugum'),
            ),
          ],
          selected: <WarehouseAcceptanceDifferenceScope>{_scope},
          onSelectionChanged: _isLoading
              ? null
              : (selection) {
                  setState(() {
                    _scope = selection.first;
                  });
                  unawaited(_loadDifferences());
                },
        ),
      ],
      actions: <Widget>[
        FilledButton.icon(
          onPressed: _isLoading ? null : _loadDifferences,
          icon: const Icon(Icons.search_rounded),
          label: const Text('Listele'),
        ),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _resetFilters,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Temizle'),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return SectionCard(
      title: 'Farklar',
      subtitle: _isLoading
          ? 'Liste yenileniyor...'
          : '${_items.length} kayit bulundu.',
      child: Column(
        children: <Widget>[
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TerminalMessageBlock.error(message: _errorMessage!),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: CircularProgressIndicator(),
            )
          else if (_items.isEmpty)
            const TerminalEmptyState(
              message: 'Secilen filtrelerle mal kabul farki bulunamadi.',
            )
          else
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DifferenceCard(item: item),
              ),
            ),
        ],
      ),
    );
  }

  static DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _DifferenceCard extends StatelessWidget {
  const _DifferenceCard({required this.item});

  final WarehouseAcceptanceDifferenceItem item;

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
                  item.documentNoLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _DocumentTypeBadge(isReturn: item.isReturn),
              const SizedBox(width: 8),
              _DifferenceTypeBadge(type: item.differenceType),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${item.sourceWarehouse} -> ${item.targetWarehouse}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B5A4A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.productCode} - ${item.productName}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _DifferenceMetric(
                label: 'Evrak',
                value: AppFormatters.dateOrDash(item.movementDate),
              ),
              _DifferenceMetric(
                label: 'Miktar',
                value: AppFormatters.quantity(item.quantity),
              ),
              _DifferenceMetric(
                label: 'Kabul',
                value: AppFormatters.quantity(item.receivedQuantity),
              ),
              _DifferenceMetric(
                label: 'Fark',
                value: AppFormatters.quantity(item.differenceQuantity.abs()),
              ),
              _DifferenceMetric(label: 'Guid', value: item.shortGuid),
            ],
          ),
          if (item.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              item.description,
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

class _DifferenceMetric extends StatelessWidget {
  const _DifferenceMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(82),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isReturn ? 'Iade' : 'Sevk',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DifferenceTypeBadge extends StatelessWidget {
  const _DifferenceTypeBadge({required this.type});

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
