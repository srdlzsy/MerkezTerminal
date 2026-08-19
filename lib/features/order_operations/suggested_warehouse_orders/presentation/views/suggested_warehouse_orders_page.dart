import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/models/suggested_warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/data/suggested_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_warehouse_orders/presentation/view_models/suggested_warehouse_orders_controller.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class SuggestedWarehouseOrdersPage extends StatefulWidget {
  const SuggestedWarehouseOrdersPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.canCreate,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
    required this.mobileWarehouseCatalogRepository,
  });

  final SuggestedWarehouseOrdersRepository repository;
  final String accessToken;
  final bool canCreate;
  final String defaultWarehouseNo;
  final String userWarehouseName;
  final MobileWarehouseCatalogLocalRepository mobileWarehouseCatalogRepository;

  @override
  State<SuggestedWarehouseOrdersPage> createState() =>
      _SuggestedWarehouseOrdersPageState();
}

class _SuggestedWarehouseOrdersPageState
    extends State<SuggestedWarehouseOrdersPage> {
  late final SuggestedWarehouseOrdersController _controller;
  late final TextEditingController _sourceWarehouseNoController;
  late final TextEditingController _descriptionController;
  final Map<String, TextEditingController> _quantityControllers =
      <String, TextEditingController>{};

  WarehouseLookupItem? _selectedSourceWarehouse;
  late DateTime _orderDate;
  late DateTime _deliveryDate;

  @override
  void initState() {
    super.initState();
    _controller = SuggestedWarehouseOrdersController(
      repository: widget.repository,
      accessToken: widget.accessToken,
    )..addListener(_handleControllerChanged);
    _sourceWarehouseNoController = TextEditingController();
    _descriptionController = TextEditingController(
      text: 'Onerilen siparisten olustu',
    );
    _orderDate = _normalizedDate(DateTime.now());
    _deliveryDate = _normalizedDate(DateTime.now());
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    _sourceWarehouseNoController.dispose();
    _descriptionController.dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    _syncQuantityControllers();
    if (mounted) {
      setState(() {});
    }
  }

  void _syncQuantityControllers() {
    final activeKeys = _controller.items.map((item) => item.identity).toSet();
    final staleKeys = _quantityControllers.keys
        .where((key) => !activeKeys.contains(key))
        .toList(growable: false);
    for (final key in staleKeys) {
      _quantityControllers.remove(key)?.dispose();
    }

    for (final item in _controller.items) {
      final key = item.identity;
      if (key.isEmpty) {
        continue;
      }
      final controller = _quantityControllers.putIfAbsent(
        key,
        () => TextEditingController(
          text: _formatQuantity(_controller.quantityFor(item)),
        ),
      );
      if (!_controller.isSelected(item)) {
        final nextText = _formatQuantity(_controller.quantityFor(item));
        if (controller.text != nextText) {
          controller.text = nextText;
          controller.selection = TextSelection.collapsed(
            offset: controller.text.length,
          );
        }
      }
    }
  }

  Future<void> _pickDate({required bool isOrderDate}) async {
    final initialDate = isOrderDate ? _orderDate : _deliveryDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      if (isOrderDate) {
        _orderDate = _normalizedDate(pickedDate);
        if (_deliveryDate.isBefore(_orderDate)) {
          _deliveryDate = _orderDate;
        }
      } else {
        _deliveryDate = _normalizedDate(pickedDate);
        if (_orderDate.isAfter(_deliveryDate)) {
          _orderDate = _deliveryDate;
        }
      }
    });
  }

  Future<void> _loadSuggestions() async {
    final sourceWarehouseNo = int.tryParse(
      _sourceWarehouseNoController.text.trim(),
    );
    if (sourceWarehouseNo == null || sourceWarehouseNo <= 0) {
      _showFeedback('Kaynak depo no girin veya depo aramadan secin.');
      await _controller.loadSuggestions(sourceWarehouseNo: 0);
      return;
    }

    final selectedSourceWarehouse = _selectedSourceWarehouse;
    if (selectedSourceWarehouse != null &&
        selectedSourceWarehouse.warehouseNo != sourceWarehouseNo) {
      setState(() => _selectedSourceWarehouse = null);
    }

    await _controller.loadSuggestions(
      sourceWarehouseNo: sourceWarehouseNo,
      useSourceProducts: usesSuggestedWarehouseOrderSourceProducts(
        sourceWarehouseNo,
      ),
    );
  }

  Future<void> _openWarehouseLookup() async {
    final warehouse = await showModalBottomSheet<WarehouseLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _WarehouseLookupSheet(
        repository: widget.repository,
        accessToken: widget.accessToken,
        mobileWarehouseCatalogRepository:
            widget.mobileWarehouseCatalogRepository,
        initialQuery: _sourceWarehouseNoController.text,
      ),
    );

    if (warehouse == null || !mounted) {
      return;
    }

    setState(() {
      _selectedSourceWarehouse = warehouse;
      _sourceWarehouseNoController.text = warehouse.warehouseNo.toString();
    });
    unawaited(_loadSuggestions());
  }

  void _toggleItem(SuggestedWarehouseOrderListItem item) {
    _controller.toggleItem(item);
  }

  void _selectAllSuggested() {
    _controller.selectAllSuggested();
  }

  void _clearSelection() {
    _controller.clearSelection();
  }

  Future<void> _convertSelected() async {
    final result = await _controller.convertSelected(
      orderDate: _orderDate,
      deliveryDate: _deliveryDate,
      description: _descriptionController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (result == null) {
      _showFeedback(_controller.convertError ?? 'Siparis olusturulamadi.');
      return;
    }

    _showFeedback(
      '${result.documentNoLabel} olusturuldu. '
      '${result.lineCount} satir, toplam ${AppFormatters.quantity(result.totalQuantity)} miktar.',
    );
  }

  void _showFeedback(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
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
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildListSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isBusy = _controller.isLoadingList || _controller.isConverting;
    final selectedSourceWarehouse = _selectedSourceWarehouse;
    final sourceLabel = selectedSourceWarehouse == null
        ? 'Secilmedi'
        : selectedSourceWarehouse.displayLabel;

    return TerminalListHeaderCard(
      title: 'Onerilen Depo Siparisleri',
      subtitle: 'Kaynak depodan ihtiyaca gore siparis olusturun.',
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Hedef depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(label: 'Kaynak', value: sourceLabel),
        TerminalInfoChip(label: 'Kayit', value: '${_controller.items.length}'),
        TerminalInfoChip(
          label: 'Secili',
          value: '${_controller.selectedCount}',
        ),
        TerminalInfoChip(
          label: 'Toplam',
          value: AppFormatters.quantity(_controller.selectedTotalQuantity),
        ),
      ],
      filters: <Widget>[
        SizedBox(
          width: 138,
          child: TextField(
            controller: _sourceWarehouseNoController,
            enabled: !isBusy,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _loadSuggestions(),
            decoration: const InputDecoration(
              labelText: 'Kaynak Depo',
              isDense: true,
              prefixIcon: Icon(Icons.warehouse_rounded, size: 18),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: isBusy ? null : _openWarehouseLookup,
          tooltip: 'Kaynak depo ara',
          icon: const Icon(Icons.manage_search_rounded),
        ),
        TerminalFilterButton(
          label: 'Siparis',
          value: AppFormatters.date(_orderDate),
          onPressed: isBusy ? () {} : () => _pickDate(isOrderDate: true),
        ),
        TerminalFilterButton(
          label: 'Teslim',
          value: AppFormatters.date(_deliveryDate),
          onPressed: isBusy ? () {} : () => _pickDate(isOrderDate: false),
        ),
        SizedBox(
          width: 220,
          child: TextField(
            controller: _descriptionController,
            enabled: !isBusy,
            minLines: 1,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Aciklama',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            ),
          ),
        ),
      ],
      actions: <Widget>[
        FilledButton.icon(
          onPressed: isBusy ? null : _loadSuggestions,
          icon: _controller.isLoadingList
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search_rounded),
          label: Text(_controller.isLoadingList ? 'Yukleniyor' : 'Listele'),
        ),
        OutlinedButton.icon(
          onPressed: isBusy || _controller.items.isEmpty
              ? null
              : _selectAllSuggested,
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('Tumunu Sec'),
        ),
        OutlinedButton.icon(
          onPressed: isBusy || !_controller.hasSelection
              ? null
              : _clearSelection,
          icon: const Icon(Icons.clear_all_rounded),
          label: const Text('Temizle'),
        ),
        if (widget.canCreate)
          FilledButton.tonalIcon(
            onPressed: isBusy || !_controller.hasSelection
                ? null
                : _convertSelected,
            icon: _controller.isConverting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_check_rounded),
            label: Text(
              _controller.isConverting ? 'Olusuyor' : 'Siparise Cevir',
            ),
          ),
      ],
    );
  }

  Widget _buildListSection(BuildContext context) {
    final listError = _controller.listError;
    final convertError = _controller.convertError;

    return SectionCard(
      title: 'Onerilen Kalemler',
      subtitle: _controller.isLoadingList
          ? 'Oneriler hesaplaniyor...'
          : '${_controller.items.length} urun bulundu.',
      child: Column(
        children: <Widget>[
          if (convertError != null) ...<Widget>[
            TerminalMessageBlock.error(message: convertError),
            const SizedBox(height: 10),
          ],
          if (listError != null) ...<Widget>[
            TerminalMessageBlock.error(message: listError),
            const SizedBox(height: 10),
          ],
          if (_controller.isLoadingList)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_controller.items.isEmpty)
            TerminalEmptyState(
              message: _controller.sourceWarehouseNo == null
                  ? 'Kaynak depo secin, sonra onerileri listeleyin.'
                  : 'Bu kaynak depo icin onerilen siparis bulunamadi.',
            )
          else
            Column(
              children: _controller.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SuggestedWarehouseOrderCard(
                        item: item,
                        isSelected: _controller.isSelected(item),
                        quantityController:
                            _quantityControllers[item.identity]!,
                        onToggle: () => _toggleItem(item),
                        onQuantityChanged: (value) {
                          _controller.updateQuantity(item, value);
                        },
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  static DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _SuggestedWarehouseOrderCard extends StatelessWidget {
  const _SuggestedWarehouseOrderCard({
    required this.item,
    required this.isSelected,
    required this.quantityController,
    required this.onToggle,
    required this.onQuantityChanged,
  });

  final SuggestedWarehouseOrderListItem item;
  final bool isSelected;
  final TextEditingController quantityController;
  final VoidCallback onToggle;
  final ValueChanged<String> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = <String>[
      if (item.stockCode.trim().isNotEmpty) 'Kod ${item.stockCode}',
      if (item.packageFactor > 0)
        'Koli ${AppFormatters.quantity(item.packageFactor)}',
      if (item.barcode.trim().isNotEmpty) item.barcode,
      if (item.modelName.trim().isNotEmpty) item.modelName,
      if (item.modelName.trim().isEmpty && item.modelCode.trim().isNotEmpty)
        'Model ${item.modelCode}',
      if (item.unitName.trim().isNotEmpty) item.unitName,
    ].where((part) => part.trim().isNotEmpty).join(' | ');
    final badgeLabel = item.needsManualQuantity
        ? 'Miktar gir'
        : 'Oneri ${AppFormatters.quantity(item.defaultOrderQuantity)}';

    return TerminalPdaRecordCard(
      isSelected: isSelected,
      onTap: onToggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TerminalPdaCardHeader(
            title: item.stockName,
            subtitle: subtitle,
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Checkbox(
                  value: isSelected,
                  onChanged: item.canBeSelected ? (_) => onToggle() : null,
                  visualDensity: VisualDensity.compact,
                ),
                TerminalBadge(
                  label: badgeLabel,
                  backgroundColor: item.canBeSelected
                      ? theme.colorScheme.primary.withAlpha(18)
                      : theme.colorScheme.errorContainer,
                  foregroundColor: item.canBeSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onErrorContainer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TerminalPdaInfoGrid(
            items: <TerminalPdaInfo>[
              if (item.needsManualQuantity) ...<TerminalPdaInfo>[
                TerminalPdaInfo(
                  label: 'Tur',
                  value: item.sourceProductGroupLabel,
                ),
                TerminalPdaInfo(
                  label: 'Birim',
                  value: item.unitName.trim().isEmpty ? '-' : item.unitName,
                ),
                TerminalPdaInfo(
                  label: 'Koli',
                  value: item.packageFactor > 0
                      ? AppFormatters.quantity(item.packageFactor)
                      : '-',
                ),
                const TerminalPdaInfo(label: 'Oneri', value: 'Elle girilecek'),
              ] else ...<TerminalPdaInfo>[
                TerminalPdaInfo(
                  label: 'Hedef',
                  value: AppFormatters.quantity(item.targetOnHand),
                ),
                TerminalPdaInfo(
                  label: 'Kaynak',
                  value: AppFormatters.quantity(item.sourceOnHand),
                ),
                TerminalPdaInfo(
                  label: 'Satis',
                  value: AppFormatters.quantity(item.salesQuantity),
                ),
                TerminalPdaInfo(
                  label: 'Acik',
                  value: AppFormatters.quantity(item.openIncomingOrderQuantity),
                ),
                TerminalPdaInfo(
                  label: 'Ihtiyac',
                  value: AppFormatters.quantity(item.needQuantity),
                ),
                TerminalPdaInfo(
                  label: 'Gun',
                  value: AppFormatters.quantity(item.recommendedDay),
                ),
                TerminalPdaInfo(
                  label: 'Koli',
                  value: item.packageFactor > 0
                      ? AppFormatters.quantity(item.packageFactor)
                      : '-',
                ),
              ],
            ],
          ),
          if (isSelected) ...<Widget>[
            const SizedBox(height: 8),
            TerminalPdaDetailPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TerminalQuantityStepper(
                    controller: quantityController,
                    label: 'Siparis Miktari*',
                    minimum: 0,
                    maximum: item.sourceOnHand > 0 ? item.sourceOnHand : null,
                    onChanged: onQuantityChanged,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.needsManualQuantity
                        ? 'Manav urunlerinde miktari kullanici belirler; 0 miktarli satir siparise cevrilmez.'
                        : 'Orijinal oneri ${AppFormatters.quantity(item.suggestedOrderQuantity)} | Hedef stok ${AppFormatters.quantity(item.recommendedStockQuantity)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WarehouseLookupSheet extends StatefulWidget {
  const _WarehouseLookupSheet({
    required this.repository,
    required this.accessToken,
    required this.mobileWarehouseCatalogRepository,
    required this.initialQuery,
  });

  final SuggestedWarehouseOrdersRepository repository;
  final String accessToken;
  final MobileWarehouseCatalogLocalRepository mobileWarehouseCatalogRepository;
  final String initialQuery;

  @override
  State<_WarehouseLookupSheet> createState() => _WarehouseLookupSheetState();
}

class _WarehouseLookupSheetState extends State<_WarehouseLookupSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  List<WarehouseLookupItem> _items = <WarehouseLookupItem>[];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery);
    unawaited(_load());
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.repository.searchWarehouses(
        accessToken: widget.accessToken,
        query: _queryController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      final catalogItems = await widget.mobileWarehouseCatalogRepository
          .searchWarehouses(query: _queryController.text);
      if (!mounted) {
        return;
      }

      if (catalogItems.isNotEmpty) {
        setState(() {
          _items = catalogItems
              .map((item) => item.toWarehouseLookupItem())
              .toList(growable: false);
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: Material(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Kaynak Depo Ara',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Depo no veya ad ile arayin.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TerminalLookupSearchField(
                              controller: _queryController,
                              onSearch: _load,
                              decoration: const InputDecoration(
                                hintText: 'Ara...',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _isLoading ? null : _load,
                            icon: const Icon(Icons.search_rounded),
                            label: const Text('Ara'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: TerminalMessageBlock.error(
                            message: _errorMessage!,
                          ),
                        )
                      : _items.isEmpty
                      ? const TerminalEmptyState(message: 'Sonuc bulunamadi.')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              tileColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withAlpha(40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              title: Text(
                                item.displayLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${item.district} ${item.province}'.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.of(context).pop(item),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
