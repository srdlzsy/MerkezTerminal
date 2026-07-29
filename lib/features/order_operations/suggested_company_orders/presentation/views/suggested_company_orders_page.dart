import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/data/models/suggested_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/data/suggested_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/suggested_company_orders/presentation/view_models/suggested_company_orders_controller.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class SuggestedCompanyOrdersPage extends StatefulWidget {
  const SuggestedCompanyOrdersPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.canCreate,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
    required this.mobileCustomerCatalogRepository,
  });

  final SuggestedCompanyOrdersRepository repository;
  final String accessToken;
  final bool canCreate;
  final String defaultWarehouseNo;
  final String userWarehouseName;
  final MobileCustomerCatalogLocalRepository mobileCustomerCatalogRepository;

  @override
  State<SuggestedCompanyOrdersPage> createState() =>
      _SuggestedCompanyOrdersPageState();
}

class _SuggestedCompanyOrdersPageState
    extends State<SuggestedCompanyOrdersPage> {
  late final SuggestedCompanyOrdersController _controller;
  late final TextEditingController _supplierCodeController;
  late final TextEditingController _descriptionController;
  final Map<String, TextEditingController> _quantityControllers =
      <String, TextEditingController>{};

  CustomerLookupItem? _selectedSupplier;
  late DateTime _orderDate;
  late DateTime _deliveryDate;

  @override
  void initState() {
    super.initState();
    _controller = SuggestedCompanyOrdersController(
      repository: widget.repository,
      accessToken: widget.accessToken,
    )..addListener(_handleControllerChanged);
    _supplierCodeController = TextEditingController();
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
    _supplierCodeController.dispose();
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
    final supplierCode = _supplierCodeController.text.trim();
    if (supplierCode.isEmpty) {
      _showFeedback('Firma/tedarikci kodu girin veya aramadan secin.');
      await _controller.loadSuggestions(supplierCode: '');
      return;
    }

    final selectedSupplier = _selectedSupplier;
    if (selectedSupplier != null &&
        selectedSupplier.customerCode.trim() != supplierCode) {
      setState(() => _selectedSupplier = null);
    }

    await _controller.loadSuggestions(supplierCode: supplierCode);
  }

  Future<void> _openSupplierLookup() async {
    final supplier = await showModalBottomSheet<CustomerLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _SupplierLookupSheet(
        repository: widget.repository,
        accessToken: widget.accessToken,
        mobileCustomerCatalogRepository: widget.mobileCustomerCatalogRepository,
        initialQuery: _supplierCodeController.text,
      ),
    );

    if (supplier == null || !mounted) {
      return;
    }

    setState(() {
      _selectedSupplier = supplier;
      _supplierCodeController.text = supplier.customerCode;
    });
    unawaited(_loadSuggestions());
  }

  Future<void> _convertSelected() async {
    final result = await _controller.convertSelected(
      orderDate: _orderDate,
      deliveryDate: _deliveryDate,
      description1: _descriptionController.text.trim(),
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
          _buildListSection(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isBusy = _controller.isLoadingList || _controller.isConverting;
    final selectedSupplier = _selectedSupplier;
    final supplierLabel = selectedSupplier == null
        ? 'Secilmedi'
        : selectedSupplier.displayLabel;

    return TerminalListHeaderCard(
      title: 'Onerilen Firma Siparisleri',
      subtitle: 'Tedarikciye gore firma siparisi onerilerini olusturun.',
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(label: 'Firma', value: supplierLabel),
        TerminalInfoChip(label: 'Kayit', value: '${_controller.items.length}'),
        TerminalInfoChip(
          label: 'Secili',
          value: '${_controller.selectedCount}',
        ),
        TerminalInfoChip(
          label: 'Toplam',
          value: AppFormatters.quantity(_controller.selectedTotalQuantity),
        ),
        TerminalInfoChip(
          label: 'Tutar',
          value: AppFormatters.currency(_controller.selectedTotalAmount),
        ),
      ],
      filters: <Widget>[
        SizedBox(
          width: 164,
          child: TextField(
            controller: _supplierCodeController,
            enabled: !isBusy,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _loadSuggestions(),
            decoration: const InputDecoration(
              labelText: 'Firma Kodu',
              isDense: true,
              prefixIcon: Icon(Icons.business_rounded, size: 18),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: isBusy ? null : _openSupplierLookup,
          tooltip: 'Firma ara',
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
              : _controller.selectAllSuggested,
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('Tumunu Sec'),
        ),
        OutlinedButton.icon(
          onPressed: isBusy || !_controller.hasSelection
              ? null
              : _controller.clearSelection,
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

  Widget _buildListSection() {
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
              message: _controller.supplierCode == null
                  ? 'Firma/tedarikci secin, sonra onerileri listeleyin.'
                  : 'Bu firma icin onerilen siparis bulunamadi.',
            )
          else
            Column(
              children: _controller.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SuggestedCompanyOrderCard(
                        item: item,
                        isSelected: _controller.isSelected(item),
                        quantityController:
                            _quantityControllers[item.identity]!,
                        onToggle: () => _controller.toggleItem(item),
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

class _SuggestedCompanyOrderCard extends StatelessWidget {
  const _SuggestedCompanyOrderCard({
    required this.item,
    required this.isSelected,
    required this.quantityController,
    required this.onToggle,
    required this.onQuantityChanged,
  });

  final SuggestedCompanyOrderListItem item;
  final bool isSelected;
  final TextEditingController quantityController;
  final VoidCallback onToggle;
  final ValueChanged<String> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = <String>[
      item.stockCode,
      if (item.barcode.trim().isNotEmpty) item.barcode,
      if (item.modelCode.trim().isNotEmpty) 'Model ${item.modelCode}',
    ].where((part) => part.trim().isNotEmpty).join(' | ');

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
                  label:
                      'Oneri ${AppFormatters.quantity(item.suggestedOrderQuantity)}',
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
              TerminalPdaInfo(
                label: 'Mevcut',
                value: AppFormatters.quantity(item.targetOnHand),
              ),
              TerminalPdaInfo(
                label: 'Satis',
                value: AppFormatters.quantity(item.salesQuantity),
              ),
              TerminalPdaInfo(
                label: 'Acik',
                value: AppFormatters.quantity(item.openCompanyOrderQuantity),
              ),
              TerminalPdaInfo(
                label: 'Ihtiyac',
                value: AppFormatters.quantity(item.needQuantity),
              ),
              TerminalPdaInfo(
                label: 'Koli',
                value: AppFormatters.quantity(item.packageFactor),
              ),
              TerminalPdaInfo(
                label: 'Asgari',
                value: AppFormatters.quantity(item.minimumPurchaseQuantity),
              ),
              TerminalPdaInfo(
                label: 'Fiyat',
                value: AppFormatters.currency(item.purchasePrice),
              ),
              TerminalPdaInfo(
                label: 'Teslim',
                value: item.deliveryDay == null
                    ? '-'
                    : '${item.deliveryDay} gun',
              ),
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
                    onChanged: onQuantityChanged,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Orijinal oneri ${AppFormatters.quantity(item.suggestedOrderQuantity)} | Tutar ${AppFormatters.currency(item.lineAmount(_readQuantity(quantityController.text)))}',
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

  static double _readQuantity(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return 0;
    }
    return double.tryParse(normalized) ?? 0;
  }
}

class _SupplierLookupSheet extends StatefulWidget {
  const _SupplierLookupSheet({
    required this.repository,
    required this.accessToken,
    required this.mobileCustomerCatalogRepository,
    required this.initialQuery,
  });

  final SuggestedCompanyOrdersRepository repository;
  final String accessToken;
  final MobileCustomerCatalogLocalRepository mobileCustomerCatalogRepository;
  final String initialQuery;

  @override
  State<_SupplierLookupSheet> createState() => _SupplierLookupSheetState();
}

class _SupplierLookupSheetState extends State<_SupplierLookupSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  List<CustomerLookupItem> _items = const <CustomerLookupItem>[];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().length >= 2) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final query = _queryController.text.trim();
    if (query.length < 2) {
      setState(() {
        _errorMessage = 'En az 2 karakter girin.';
        _items = const <CustomerLookupItem>[];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.repository.searchSuppliers(
        accessToken: widget.accessToken,
        query: query,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      final catalogItems = await widget.mobileCustomerCatalogRepository
          .searchCustomers(query: query);
      if (!mounted) {
        return;
      }

      if (catalogItems.isNotEmpty) {
        setState(() {
          _items = catalogItems
              .map((item) => item.toCustomerLookupItem())
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
                        'Firma Ara',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Firma kodu veya ad ile arayin.',
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
                                item.taxNumber,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              enabled: !item.isLocked && !item.isClosed,
                              onTap: item.isLocked || item.isClosed
                                  ? null
                                  : () => Navigator.of(context).pop(item),
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
