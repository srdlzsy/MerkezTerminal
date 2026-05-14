import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/models/company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/given_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_lookup_cache_repository.dart';
import 'package:furpa_merkez_terminal/shared/utils/client_request_id.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class CompanyAcceptanceCreateSheet extends StatefulWidget {
  const CompanyAcceptanceCreateSheet({
    super.key,
    required this.repository,
    required this.ordersRepository,
    required this.accessToken,
    required this.currentUserId,
    required this.defaultWarehouseNo,
    required this.lookupCacheRepository,
  });

  final CompanyAcceptancesRepository repository;
  final GivenCompanyOrdersRepository ordersRepository;
  final String accessToken;
  final String currentUserId;
  final String defaultWarehouseNo;
  final OfflineLookupCacheRepository lookupCacheRepository;

  @override
  State<CompanyAcceptanceCreateSheet> createState() =>
      _CompanyAcceptanceCreateSheetState();
}

class _CompanyAcceptanceCreateSheetState
    extends State<CompanyAcceptanceCreateSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<_AcceptanceLineDraft> _lines = <_AcceptanceLineDraft>[];
  late final TextEditingController _customerController;
  late final TextEditingController _customerCodeController;
  late final TextEditingController _documentNoController;
  late final TextEditingController _delivererController;
  late final TextEditingController _receiverController;
  late final TextEditingController _descriptionController;
  DateTime _movementDate = DateTime.now();
  DateTime _documentDate = DateTime.now();
  bool _allowOrderOverReceiving = false;
  String? _lookupError;

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController();
    _customerCodeController = TextEditingController();
    _documentNoController = TextEditingController();
    _delivererController = TextEditingController();
    _receiverController = TextEditingController();
    _descriptionController = TextEditingController();
    _lines.add(_AcceptanceLineDraft());
  }

  @override
  void dispose() {
    _customerController.dispose();
    _customerCodeController.dispose();
    _documentNoController.dispose();
    _delivererController.dispose();
    _receiverController.dispose();
    _descriptionController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool movementDate}) async {
    final initialDate = movementDate ? _movementDate : _documentDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      if (movementDate) {
        _movementDate = pickedDate;
      } else {
        _documentDate = pickedDate;
      }
    });
  }

  Future<void> _searchCustomer() async {
    final query = _customerController.text.trim();

    if (query.length < 2) {
      setState(() {
        _lookupError = 'Cari aramak icin en az 2 karakter girilmeli.';
      });
      return;
    }

    List<CustomerLookupItem> customers;
    try {
      customers = await _searchCustomersWithFallback(query);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _lookupError = error.toString().replaceFirst('Exception: ', '');
      });
      return;
    }

    if (!mounted) {
      return;
    }

    final selected = await showModalBottomSheet<CustomerLookupItem>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        if (customers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: TerminalEmptyState(message: 'Cari bulunamadi.'),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          itemCount: customers.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = customers[index];
            return ListTile(
              title: Text(item.customerDisplayName),
              subtitle: Text(item.customerCode),
              onTap: () => Navigator.of(context).pop(item),
            );
          },
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _customerController.text = selected.displayLabel;
      _customerCodeController.text = selected.customerCode;
      _lookupError = null;
    });
  }

  Future<void> _searchProduct(_AcceptanceLineDraft line) async {
    final query = line.lookupController.text.trim();

    if (query.length < 2) {
      setState(() {
        _lookupError =
            'Urun aramak icin en az 2 karakter veya barkod girilmeli.';
      });
      return;
    }

    List<SearchProductLookupItem> products;
    try {
      products = await _searchProductsWithFallback(
        query,
        customerCode: _customerCodeController.text.trim(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _lookupError = error.toString().replaceFirst('Exception: ', '');
      });
      return;
    }

    if (!mounted) {
      return;
    }

    if (products.isEmpty) {
      _showFeedback('Bu aramaya uygun urun bulunamadi.');
      return;
    }

    final selected = await showModalBottomSheet<SearchProductLookupItem>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView.separated(
          shrinkWrap: true,
          itemCount: products.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = products[index];
            return ListTile(
              title: Text(item.displayLabel),
              subtitle: Text(
                '${item.unitName} | ${AppFormatters.currency(item.price)}',
              ),
              onTap: () => Navigator.of(context).pop(item),
            );
          },
        );
      },
    );

    if (selected == null) {
      return;
    }

    var mergedIntoExisting = false;
    setState(() {
      mergedIntoExisting = _applyProductToLine(line, selected);
      _lookupError = null;
    });

    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  Future<void> _scanProductWithCamera(_AcceptanceLineDraft line) async {
    if (!supportsCameraBarcodeScanning) {
      setState(() {
        _lookupError = 'Bu cihazda kamera ile barkod okutma desteklenmiyor.';
      });
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Mal Kabul Kamerasi',
      subtitle: 'Barkodu okutun; bulunan urun secim listesine aktarilacak.',
    );

    if (barcode == null || !mounted) {
      return;
    }

    setState(() {
      line.lookupController.text = barcode;
      _lookupError = null;
    });

    await _searchProduct(line);
  }

  bool _applyProductToLine(
    _AcceptanceLineDraft line,
    SearchProductLookupItem product,
  ) {
    final existingLine = _findDuplicateLine(
      currentLine: line,
      barcode: product.barcode,
      stockCode: product.stockCode,
    );

    if (existingLine == null) {
      line.applyProduct(product);
      return false;
    }

    existingLine.quantityController.text = _formatQuantity(
      _readDouble(existingLine.quantityController.text, fallback: 0) +
          _readDouble(line.quantityController.text, fallback: 0),
    );

    if (_readDouble(existingLine.unitPriceController.text, fallback: 0) <= 0) {
      line.applyProduct(product);
      existingLine.unitPriceController.text = line.unitPriceController.text;
    }

    _recycleMergedLine(line, createReplacement: _AcceptanceLineDraft.new);
    return true;
  }

  _AcceptanceLineDraft? _findDuplicateLine({
    required _AcceptanceLineDraft currentLine,
    required String barcode,
    required String stockCode,
  }) {
    if (currentLine.orderGuid != null) {
      return null;
    }

    final targetKey = _productIdentity(barcode: barcode, stockCode: stockCode);
    if (targetKey == null) {
      return null;
    }

    for (final candidate in _lines) {
      if (identical(candidate, currentLine) || candidate.orderGuid != null) {
        continue;
      }

      final selectedProduct = candidate.selectedProduct;
      if (selectedProduct == null) {
        continue;
      }

      final candidateKey = _productIdentity(
        barcode: selectedProduct.barcode,
        stockCode: selectedProduct.stockCode,
      );
      if (candidateKey == targetKey) {
        return candidate;
      }
    }

    return null;
  }

  void _recycleMergedLine(
    _AcceptanceLineDraft line, {
    required _AcceptanceLineDraft Function() createReplacement,
  }) {
    final lineIndex = _lines.indexOf(line);
    line.dispose();

    if (lineIndex == 0) {
      _lines[lineIndex] = createReplacement();
      return;
    }

    _lines.removeAt(lineIndex);
  }

  void _addLine() {
    setState(() {
      _lines.insert(0, _AcceptanceLineDraft());
      _lookupError = null;
    });
  }

  Future<void> _addLinesFromOpenOrders() async {
    final customerCode = _customerCodeController.text.trim();

    if (customerCode.isEmpty) {
      setState(() {
        _lookupError = 'Siparis baglamak icin once cari kodu girilmeli.';
      });
      return;
    }

    List<CompanyOrderListItem> orders;
    try {
      final today = DateTime.now();
      orders = await widget.ordersRepository.fetchOrders(
        accessToken: widget.accessToken,
        filter: CompanyOrderListFilter(
          startDate: DateTime(today.year, today.month, today.day),
          endDate: DateTime.now().add(const Duration(days: 30)),
          warehouseNo: widget.defaultWarehouseNo,
          customerCode: customerCode,
          onlyOpen: true,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _lookupError = error.toString().replaceFirst('Exception: ', '');
      });
      return;
    }

    if (!mounted) {
      return;
    }

    final selectedOrder = await showModalBottomSheet<CompanyOrderListItem>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        if (orders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: TerminalEmptyState(message: 'Acik siparis bulunamadi.'),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          itemCount: orders.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = orders[index];
            return ListTile(
              title: Text(item.documentNoLabel),
              subtitle: Text(
                '${item.customerDisplayName} | Kalan ${AppFormatters.quantity(item.totalRemainingQuantity)}',
              ),
              onTap: () => Navigator.of(context).pop(item),
            );
          },
        );
      },
    );

    if (selectedOrder == null) {
      return;
    }

    CompanyOrderDetail detail;
    try {
      detail = await widget.ordersRepository.fetchOrderDetail(
        accessToken: widget.accessToken,
        documentSerie: selectedOrder.documentSerie,
        documentOrderNo: selectedOrder.documentOrderNo,
        warehouseNo: widget.defaultWarehouseNo,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _lookupError = error.toString().replaceFirst('Exception: ', '');
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      for (final item in detail.items) {
        if (item.remainingQuantity <= 0) {
          continue;
        }

        _lines.add(_AcceptanceLineDraft.fromOrderItem(item));
      }
      _lookupError = null;
    });
  }

  void _submit() {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final customerCode = _customerCodeController.text.trim();
    if (customerCode.isEmpty) {
      setState(() {
        _lookupError = 'Cari kodu zorunludur.';
      });
      return;
    }

    for (var index = 0; index < _lines.length; index += 1) {
      final line = _lines[index];
      if (line.stockCodeController.text.trim().isEmpty) {
        setState(() {
          _lookupError = '${index + 1}. satir icin urun secin.';
        });
        return;
      }

      if (line.quantity <= 0) {
        setState(() {
          _lookupError =
              '${index + 1}. satir icin miktar sifirdan buyuk olmali.';
        });
        return;
      }
    }

    Navigator.of(context).pop(
      CompanyAcceptanceCreateRequest(
        customerCode: customerCode,
        movementDate: _movementDate,
        documentDate: _documentDate,
        documentNo: _documentNoController.text.trim(),
        clientRequestId: generateClientRequestId(),
        deliverer: _delivererController.text.trim(),
        receiver: _receiverController.text.trim(),
        description: _descriptionController.text.trim(),
        allowOrderOverReceiving: _allowOrderOverReceiving,
        lines: _lines
            .map(
              (line) => CompanyAcceptanceCreateLine(
                stockCode: line.stockCodeController.text.trim(),
                quantity: line.quantity,
                unitPrice: line.unitPrice,
                unitPointer: line.unitPointer,
                lastConsumingDate: line.lastConsumingDate,
                orderGuid: line.orderGuid,
                description: line.descriptionController.text.trim(),
                partyCode: line.partyCodeController.text.trim(),
                lotNo: line.lotNo,
                projectCode: line.projectCodeController.text.trim(),
                customerResponsibilityCenter: line.customerRcController.text
                    .trim(),
                productResponsibilityCenter: line.productRcController.text
                    .trim(),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Future<List<CustomerLookupItem>> _searchCustomersWithFallback(
    String query,
  ) async {
    try {
      final items = await widget.repository.searchCustomers(
        accessToken: widget.accessToken,
        query: query,
      );
      await widget.lookupCacheRepository.cacheCustomers(
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        items: items,
      );
      return items;
    } on ApiException {
      final cached = await widget.lookupCacheRepository.searchCustomers(
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        query: query,
      );
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  Future<List<SearchProductLookupItem>> _searchProductsWithFallback(
    String query, {
    String? customerCode,
  }) async {
    final normalizedCustomerCode = customerCode?.trim();
    try {
      final items = await widget.repository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        query: query,
        customerCode:
            normalizedCustomerCode == null || normalizedCustomerCode.isEmpty
            ? null
            : normalizedCustomerCode,
      );
      await widget.lookupCacheRepository.cacheAcceptanceProducts(
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        customerCode: normalizedCustomerCode,
        items: items,
      );
      return items;
    } on ApiException {
      final cached = await widget.lookupCacheRepository
          .searchAcceptanceProducts(
            userId: widget.currentUserId,
            warehouseNo: widget.defaultWarehouseNo,
            query: query,
            customerCode: normalizedCustomerCode,
          );
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            const TerminalSheetHeader(
              title: 'Yeni Firma Mal Kabul',
              subtitle:
                  'Ayni fis icinde siparisli ve siparissiz satirlar bir arada gidebilir. Siparisli satirlarda orderGuid otomatik tasinir.',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _customerController,
                    decoration: const InputDecoration(
                      labelText: 'Cari Arama',
                      hintText: 'Cari adi veya kodu',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _searchCustomer,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Bul'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerCodeController,
              decoration: const InputDecoration(
                labelText: 'Cari Kodu*',
                hintText: 'Internet yoksa elle girin',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Cari kodu zorunlu';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                TerminalFilterButton(
                  label: 'Hareket Tarihi',
                  value: AppFormatters.date(_movementDate),
                  onPressed: () => _pickDate(movementDate: true),
                ),
                TerminalFilterButton(
                  label: 'Belge Tarihi',
                  value: AppFormatters.date(_documentDate),
                  onPressed: () => _pickDate(movementDate: false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentNoController,
              decoration: const InputDecoration(labelText: 'Belge No'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    controller: _delivererController,
                    decoration: const InputDecoration(labelText: 'Teslim Eden'),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    controller: _receiverController,
                    decoration: const InputDecoration(labelText: 'Teslim Alan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Aciklama'),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _allowOrderOverReceiving,
              title: const Text(
                'Siparis kalanindan fazla kabul etmeye izin ver',
              ),
              subtitle: const Text(
                'Backend fazla miktari siparissiz hareket olarak ayirabilir.',
              ),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _allowOrderOverReceiving = value ?? false;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Text(
                  'Satirlar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _addLinesFromOpenOrders,
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Siparis Bagla'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _addLine,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Satir'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._lines.asMap().entries.map((entry) {
              final index = entry.key;
              final line = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withAlpha(90),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Satir ${index + 1}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (line.orderGuid != null &&
                              line.orderGuid!.isNotEmpty)
                            const TerminalBadge(label: 'Siparisli'),
                          if (_lines.length > 1)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  line.dispose();
                                  _lines.removeAt(index);
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              controller: line.lookupController,
                              decoration: const InputDecoration(
                                labelText: 'Barkod / stok kodu / urun adi',
                                hintText: 'Arama veya barkod',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () => _searchProduct(line),
                            icon: const Icon(Icons.search_rounded),
                            label: const Text('Urun'),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: () => _scanProductWithCamera(line),
                            tooltip: 'Kamera ile oku',
                            icon: const Icon(Icons.photo_camera_back_rounded),
                          ),
                        ],
                      ),
                      if (line.selectedProduct != null) ...<Widget>[
                        const SizedBox(height: 8),
                        TerminalMessageBlock.info(
                          message:
                              '${line.selectedProduct!.stockCode} | ${line.selectedProduct!.stockName} | ${line.selectedProduct!.unitName} | ${AppFormatters.currency(line.selectedProduct!.price)}',
                        ),
                      ],
                      TextFormField(
                        controller: line.quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9,\.]'),
                          ),
                        ],
                        decoration: const InputDecoration(labelText: 'Miktar'),
                        validator: (_) {
                          if (line.quantity <= 0) {
                            return 'Miktar > 0';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (_lookupError != null) ...<Widget>[
              TerminalMessageBlock.error(message: _lookupError!),
              const SizedBox(height: 12),
            ],
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
                    label: const Text('Mal Kabul Et'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String? _productIdentity({
    required String barcode,
    required String stockCode,
  }) {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isNotEmpty) {
      return 'b:$normalizedBarcode';
    }

    final normalizedStockCode = stockCode.trim();
    if (normalizedStockCode.isNotEmpty) {
      return 's:$normalizedStockCode';
    }

    return null;
  }

  static String _formatQuantity(double value) {
    final fixed = value.toStringAsFixed(6);
    final normalized = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    return normalized.replaceAll('.', ',');
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
}

class _AcceptanceLineDraft {
  _AcceptanceLineDraft()
    : lookupController = TextEditingController(),
      stockCodeController = TextEditingController(),
      quantityController = TextEditingController(text: '1'),
      unitPriceController = TextEditingController(text: '0'),
      descriptionController = TextEditingController(),
      partyCodeController = TextEditingController(),
      lotNoController = TextEditingController(text: '0'),
      projectCodeController = TextEditingController(),
      customerRcController = TextEditingController(),
      productRcController = TextEditingController(),
      lastConsumingDateController = TextEditingController();

  _AcceptanceLineDraft.fromOrderItem(CompanyOrderDetailItem item)
    : lookupController = TextEditingController(
        text: '${item.stockCode} - ${item.stockName}',
      ),
      stockCodeController = TextEditingController(text: item.stockCode),
      quantityController = TextEditingController(
        text: item.remainingQuantity.toString(),
      ),
      unitPriceController = TextEditingController(
        text: item.unitPrice.toString(),
      ),
      descriptionController = TextEditingController(text: item.description),
      partyCodeController = TextEditingController(),
      lotNoController = TextEditingController(text: '0'),
      projectCodeController = TextEditingController(text: item.projectCode),
      customerRcController = TextEditingController(),
      productRcController = TextEditingController(),
      lastConsumingDateController = TextEditingController() {
    selectedProduct = SearchProductLookupItem(
      warehouseNo: 0,
      barcode: '',
      stockCode: item.stockCode,
      stockName: item.stockName,
      price: item.unitPrice,
      priceTypeCode: 0,
      unitName: item.unitName,
      unitMultiplier: 1,
      secondaryUnitName: '',
      secondaryUnitMultiplier: 0,
      salesBlockCode: null,
      orderBlockCode: null,
      goodsAcceptanceBlockCode: null,
      isSalesBlocked: false,
      isOrderBlocked: false,
      isGoodsAcceptanceBlocked: false,
      productManagerCode: '',
    );
    orderGuid = item.orderGuid;
    unitPointer = item.unitPointer;
  }

  final TextEditingController lookupController;
  final TextEditingController stockCodeController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final TextEditingController descriptionController;
  final TextEditingController partyCodeController;
  final TextEditingController lotNoController;
  final TextEditingController projectCodeController;
  final TextEditingController customerRcController;
  final TextEditingController productRcController;
  final TextEditingController lastConsumingDateController;

  SearchProductLookupItem? selectedProduct;
  String? orderGuid;
  int unitPointer = 1;

  double get quantity => _readDouble(quantityController.text, fallback: 0);
  double get unitPrice => _readDouble(unitPriceController.text, fallback: 0);
  int get lotNo => _readInt(lotNoController.text, fallback: 0);
  DateTime? get lastConsumingDate {
    final raw = lastConsumingDateController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  void applyProduct(SearchProductLookupItem product) {
    selectedProduct = product;
    lookupController.text = product.displayLabel;
    stockCodeController.text = product.stockCode;
    unitPriceController.text = product.price.toString();
    unitPointer = 1;
  }

  void dispose() {
    lookupController.dispose();
    stockCodeController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    descriptionController.dispose();
    partyCodeController.dispose();
    lotNoController.dispose();
    projectCodeController.dispose();
    customerRcController.dispose();
    productRcController.dispose();
    lastConsumingDateController.dispose();
  }
}

double _readDouble(String value, {required double fallback}) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
}

int _readInt(String value, {required int fallback}) {
  return int.tryParse(value.trim()) ?? fallback;
}
