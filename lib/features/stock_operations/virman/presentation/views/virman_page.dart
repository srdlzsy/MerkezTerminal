import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/utils/default_filter_dates.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/models/virman_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/data/virman_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/virman/presentation/view_models/virman_controller.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class VirmanPage extends StatefulWidget {
  const VirmanPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.canCreate,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
  });

  final VirmanRepository repository;
  final String accessToken;
  final bool canCreate;
  final String defaultWarehouseNo;
  final String userWarehouseName;

  @override
  State<VirmanPage> createState() => _VirmanPageState();
}

class _VirmanPageState extends State<VirmanPage> {
  late final VirmanController _controller;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _controller = VirmanController(
      repository: widget.repository,
      accessToken: widget.accessToken,
      defaultWarehouseNo: widget.defaultWarehouseNo,
    );
    _startDate = _controller.startDate;
    _endDate = _controller.endDate;
    unawaited(_controller.loadVirmans());
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

  Future<void> _toggleSelection(VirmanListItem item) async {
    if (_controller.selectedVirman?.documentNoLabel == item.documentNoLabel) {
      _controller.clearSelection();
      return;
    }

    await _controller.selectVirman(item);
  }

  Future<void> _openCreateSheet() async {
    final request = await showModalBottomSheet<VirmanCreateRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return const _VirmanCreateSheet();
      },
    );

    if (request == null || !mounted) {
      return;
    }

    final result = await _controller.createVirman(request);

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_controller.createError ?? 'Virman kaydedilemedi.'),
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
      title: 'Virmanlar',
      subtitle:
          'Liste, detay ve yeni virman olusturma akisi ayni operasyon panelinde toplandi.',
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Varsayilan depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(
          label: 'Kayit',
          value: '${_controller.virmans.length}',
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
            onPressed: _controller.isCreating || _controller.isLoadingList
                ? null
                : _openCreateSheet,
            icon: _controller.isCreating
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.swap_horiz_rounded),
            label: Text(
              _controller.isCreating ? 'Kaydediliyor...' : 'Yeni Virman',
            ),
          ),
      ],
    );
  }

  Widget _buildListCard() {
    if (_controller.listError != null && _controller.virmans.isEmpty) {
      return SectionCard(
        title: 'Virman Listesi',
        subtitle: 'Listeleme sirasinda hata olustu.',
        child: TerminalMessageBlock.error(message: _controller.listError!),
      );
    }

    return SectionCard(
      title: 'Virman Listesi',
      subtitle: _controller.isLoadingList
          ? 'Liste yenileniyor...'
          : '${_controller.virmans.length} kayit bulundu.',
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
          else if (_controller.virmans.isEmpty)
            const TerminalEmptyState(
              message: 'Secilen tarih araliginda virman kaydi bulunamadi.',
            )
          else
            Column(
              children: _controller.virmans
                  .map((item) {
                    final isExpanded =
                        _controller.selectedVirman?.documentNoLabel ==
                        item.documentNoLabel;
                    final detail = isExpanded
                        ? _controller.selectedVirmanDetail
                        : null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _toggleSelection(item),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isExpanded
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withAlpha(90),
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
                                    Expanded(
                                      child: TerminalLabeledValue(
                                        label: 'Belge Trh',
                                        value: AppFormatters.dateOrDash(
                                          item.documentDate,
                                        ),
                                      ),
                                    ),
                                    TerminalBadge(
                                      label: '${item.lineCount} satir',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: TerminalLabeledValue(
                                        label: 'Hareket',
                                        value: AppFormatters.dateOrDash(
                                          item.movementDate,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TerminalLabeledValue(
                                        label: 'Tipler',
                                        value: _formatMovementTypes(
                                          item.movementTypes,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TerminalLabeledValue(
                                        label: 'Toplam',
                                        value: AppFormatters.quantity(
                                          item.totalQuantity,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.description.isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 8),
                                  Text(
                                    item.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF5C6B80),
                                        ),
                                  ),
                                ],
                                if (isExpanded) ...<Widget>[
                                  const SizedBox(height: 12),
                                  if (_controller.isLoadingDetail)
                                    const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  else if (_controller.detailError != null)
                                    TerminalMessageBlock.error(
                                      message: _controller.detailError!,
                                    )
                                  else if (detail == null)
                                    const TerminalEmptyState(
                                      message: 'Detay bilgisi yuklenemedi.',
                                    )
                                  else
                                    _VirmanDetailSection(detail: detail),
                                ],
                              ],
                            ),
                          ),
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

class _VirmanDetailSection extends StatelessWidget {
  const _VirmanDetailSection({required this.detail});

  final VirmanDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            TerminalSummaryTile(
              label: 'Depo',
              value:
                  '${detail.header.warehouseNo} - ${detail.header.warehouseName}',
            ),
            TerminalSummaryTile(
              label: 'Belge Tarihi',
              value: AppFormatters.dateOrDash(detail.header.documentDate),
            ),
            TerminalSummaryTile(
              label: 'Hareket Tarihi',
              value: AppFormatters.dateOrDash(detail.header.movementDate),
            ),
            TerminalSummaryTile(
              label: 'Tipler',
              value: _formatMovementTypes(detail.header.movementTypes),
            ),
            TerminalSummaryTile(
              label: 'Toplam Miktar',
              value: AppFormatters.quantity(detail.header.totalQuantity),
            ),
            TerminalSummaryTile(
              label: 'Toplam Tutar',
              value: AppFormatters.currency(detail.header.totalAmount),
            ),
          ],
        ),
        if (detail.header.description.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          TerminalMessageBlock.info(message: detail.header.description),
        ],
        const SizedBox(height: 12),
        if (detail.items.isEmpty)
          const TerminalEmptyState(message: 'Bu virmanda satir bulunamadi.')
        else
          Column(
            children: detail.items
                .map((line) {
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
                                  line.stockName,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TerminalBadge(label: 'Tip ${line.movementType}'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Kod ${line.stockCode} | Miktar ${AppFormatters.quantity(line.quantity)} | Birim ${line.unitName}/${line.unitPointer}',
                          ),
                          if (line.description.isNotEmpty ||
                              line.partyCode.isNotEmpty ||
                              line.lotNo > 0 ||
                              line.projectCode.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (line.description.isNotEmpty)
                                  'Aciklama ${line.description}',
                                if (line.partyCode.isNotEmpty)
                                  'Parti ${line.partyCode}',
                                if (line.lotNo > 0) 'Lot ${line.lotNo}',
                                if (line.projectCode.isNotEmpty)
                                  'Proje ${line.projectCode}',
                              ].join(' | '),
                              style: Theme.of(context).textTheme.bodySmall,
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
    );
  }
}

class _VirmanCreateSheet extends StatefulWidget {
  const _VirmanCreateSheet();

  @override
  State<_VirmanCreateSheet> createState() => _VirmanCreateSheetState();
}

class _VirmanCreateSheetState extends State<_VirmanCreateSheet> {
  final TextEditingController _documentNoController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<_VirmanDraftLine> _lines = <_VirmanDraftLine>[_VirmanDraftLine()];
  DateTime _movementDate = DateTime.now();
  DateTime _documentDate = DateTime.now();
  String? _errorMessage;

  @override
  void dispose() {
    _documentNoController.dispose();
    _descriptionController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool isMovementDate}) async {
    final initialDate = isMovementDate ? _movementDate : _documentDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      if (isMovementDate) {
        _movementDate = pickedDate;
      } else {
        _documentDate = pickedDate;
      }
    });
  }

  void _addLine() {
    setState(() {
      _lines.add(_VirmanDraftLine());
    });
  }

  void _removeLine(_VirmanDraftLine line) {
    if (_lines.length == 1) {
      return;
    }

    setState(() {
      _lines.remove(line);
      line.dispose();
    });
  }

  void _submit() {
    final requestLines = <VirmanCreateLine>[];

    for (final line in _lines) {
      final stockCode = line.stockCodeController.text.trim();
      final movementType = int.tryParse(
        line.movementTypeController.text.trim(),
      );
      final quantity = double.tryParse(line.quantityController.text.trim());
      final unitPointer = int.tryParse(line.unitPointerController.text.trim());
      final lotNo = int.tryParse(line.lotNoController.text.trim()) ?? 0;

      if (stockCode.isEmpty) {
        setState(() {
          _errorMessage = 'Her satirda stok kodu zorunlu.';
        });
        return;
      }

      if (movementType == null || movementType < 0) {
        setState(() {
          _errorMessage = 'Her satirda gecerli bir movementType girilmeli.';
        });
        return;
      }

      if (quantity == null || quantity <= 0) {
        setState(() {
          _errorMessage = 'Her satirda miktar sifirdan buyuk olmali.';
        });
        return;
      }

      if (unitPointer == null || unitPointer <= 0) {
        setState(() {
          _errorMessage = 'Her satirda unitPointer sifirdan buyuk olmali.';
        });
        return;
      }

      requestLines.add(
        VirmanCreateLine(
          stockCode: stockCode,
          movementType: movementType,
          quantity: quantity,
          unitPointer: unitPointer,
          description: line.descriptionController.text.trim(),
          partyCode: line.partyCodeController.text.trim(),
          lotNo: lotNo,
          projectCode: line.projectCodeController.text.trim(),
        ),
      );
    }

    setState(() {
      _errorMessage = null;
    });

    Navigator.of(context).pop(
      VirmanCreateRequest(
        movementDate: _movementDate,
        documentDate: _documentDate,
        documentNo: _documentNoController.text.trim(),
        description: _descriptionController.text.trim(),
        lines: requestLines,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + viewInsets.bottom),
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          const TerminalSheetHeader(
            title: 'Yeni Virman',
            subtitle:
                'Virman satirlarinda movementType zorunludur. API dokumanindaki ornege uygun olarak varsayilan deger 2 ile baslatildi.',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              TerminalFilterButton(
                label: 'Hareket Tarihi',
                value: AppFormatters.date(_movementDate),
                onPressed: () => _pickDate(isMovementDate: true),
              ),
              TerminalFilterButton(
                label: 'Belge Tarihi',
                value: AppFormatters.date(_documentDate),
                onPressed: () => _pickDate(isMovementDate: false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _documentNoController,
            decoration: const InputDecoration(labelText: 'Belge No'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Aciklama'),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Text(
                'Satirlar',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: _addLine,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Satir Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: _lines
                .map((line) {
                  final index = _lines.indexOf(line);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _VirmanDraftLineCard(
                      index: index,
                      line: line,
                      canRemove: _lines.length > 1,
                      onRemove: () => _removeLine(line),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          if (_errorMessage != null) ...<Widget>[
            const SizedBox(height: 8),
            TerminalMessageBlock.error(message: _errorMessage!),
          ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Vazgec'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('Virmani Kaydet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VirmanDraftLineCard extends StatelessWidget {
  const _VirmanDraftLineCard({
    required this.index,
    required this.line,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _VirmanDraftLine line;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(86),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Satir ${index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Satiri sil',
                ),
            ],
          ),
          TextField(
            controller: line.stockCodeController,
            decoration: const InputDecoration(labelText: 'Stok Kodu*'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: line.quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Miktar*'),
          ),
        ],
      ),
    );
  }
}

class _VirmanDraftLine {
  _VirmanDraftLine()
    : stockCodeController = TextEditingController(),
      movementTypeController = TextEditingController(text: '2'),
      quantityController = TextEditingController(text: '1'),
      unitPointerController = TextEditingController(text: '1'),
      descriptionController = TextEditingController(),
      partyCodeController = TextEditingController(),
      lotNoController = TextEditingController(text: '0'),
      projectCodeController = TextEditingController();

  final TextEditingController stockCodeController;
  final TextEditingController movementTypeController;
  final TextEditingController quantityController;
  final TextEditingController unitPointerController;
  final TextEditingController descriptionController;
  final TextEditingController partyCodeController;
  final TextEditingController lotNoController;
  final TextEditingController projectCodeController;

  void dispose() {
    stockCodeController.dispose();
    movementTypeController.dispose();
    quantityController.dispose();
    unitPointerController.dispose();
    descriptionController.dispose();
    partyCodeController.dispose();
    lotNoController.dispose();
    projectCodeController.dispose();
  }
}

String _formatMovementTypes(List<int> movementTypes) {
  if (movementTypes.isEmpty) {
    return '-';
  }

  return movementTypes.map((item) => item.toString()).join(', ');
}
