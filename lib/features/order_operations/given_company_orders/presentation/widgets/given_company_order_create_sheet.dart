import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/company_orders_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

enum _CompanyProductEntryMode { barcode, search, camera }

class GivenCompanyOrderCreateSheet extends StatefulWidget {
  const GivenCompanyOrderCreateSheet({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
  });

  final CompanyOrdersRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;

  @override
  State<GivenCompanyOrderCreateSheet> createState() =>
      _GivenCompanyOrderCreateSheetState();
}

class _GivenCompanyOrderCreateSheetState
    extends State<GivenCompanyOrderCreateSheet>
    with CreateFormValidation {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _customerCodeController;
  late final TextEditingController _delivererController;
  late final TextEditingController _receiverController;
  late final TextEditingController _description1Controller;
  late final TextEditingController _description2Controller;
  late DateTime _orderDate;
  late DateTime _deliveryDate;
  late List<_CompanyOrderLineDraft> _lines;
  late _CompanyProductEntryMode _entryMode;
  CustomerLookupItem? _selectedCustomer;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _customerCodeController = TextEditingController();
    _delivererController = TextEditingController();
    _receiverController = TextEditingController();
    _description1Controller = TextEditingController();
    _description2Controller = TextEditingController();
    _orderDate = _normalizeDate(DateTime.now());
    _deliveryDate = _normalizeDate(DateTime.now());
    _lines = <_CompanyOrderLineDraft>[_CompanyOrderLineDraft()];
    _entryMode = _CompanyProductEntryMode.barcode;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _customerCodeController.dispose();
    _delivererController.dispose();
    _receiverController.dispose();
    _description1Controller.dispose();
    _description2Controller.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool isOrderDate}) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isOrderDate ? _orderDate : _deliveryDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      if (isOrderDate) {
        _orderDate = pickedDate;
        if (_deliveryDate.isBefore(_orderDate)) {
          _deliveryDate = _orderDate;
        }
      } else {
        _deliveryDate = pickedDate;
        if (_orderDate.isAfter(_deliveryDate)) {
          _orderDate = _deliveryDate;
        }
      }
    });
  }

  Future<void> _searchCustomer() async {
    final customer = await showModalBottomSheet<CustomerLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _CustomerLookupSheet(
        repository: widget.repository,
        accessToken: widget.accessToken,
      ),
    );

    if (customer == null || !mounted) {
      return;
    }

    setState(() {
      _selectedCustomer = customer;
      _customerCodeController.text = customer.customerCode;
      _validationMessage = null;
      for (final line in _lines) {
        line.clearProduct();
      }
    });
  }

  Future<void> _searchProduct(_CompanyOrderLineDraft line) async {
    final customer = _selectedCustomer;
    if (customer == null) {
      setState(() {
        line.setLookupStatus(
          'Urun aramasi icin once cari secilmeli.',
          isError: true,
        );
      });
      _showFeedback('Once bir musteri secin.');
      return;
    }

    setState(() {
      line.setLookupStatus('Urun arama penceresi aciliyor.');
    });

    final product = await showModalBottomSheet<CompanyOrderProductLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _CompanyProductLookupSheet(
        repository: widget.repository,
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        customerCode: customer.customerCode,
      ),
    );

    if (product == null || !mounted) {
      if (mounted) {
        setState(() {
          line.setLookupStatus('Urun secimi yapilmadi.');
        });
      }
      return;
    }

    var mergedIntoExisting = false;
    setState(() {
      mergedIntoExisting = _applyProductToLine(line, product);
      if (!mergedIntoExisting) {
        line.setLookupStatus(
          'Secildi: ${product.stockCode} | ${product.stockName}',
        );
      }
      _validationMessage = null;
    });

    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  Future<void> _findProductByBarcode(_CompanyOrderLineDraft line) async {
    final customer = _selectedCustomer;
    if (customer == null) {
      setState(() {
        line.setLookupStatus(
          'Barkod aramasi icin once cari secilmeli.',
          isError: true,
        );
      });
      _showFeedback('Barkod aramasi icin once musteri secin.');
      return;
    }

    final barcode = line.barcodeController.text.trim();
    if (barcode.length < 3) {
      setState(() {
        line.setLookupStatus(
          'Barkod alanina gecerli bir deger girin.',
          isError: true,
        );
      });
      _showFeedback('Barkod alanina gecerli bir deger girin.');
      return;
    }

    try {
      setState(() {
        line.setLookupStatus('API araniyor: $barcode', isLoading: true);
        _validationMessage = null;
      });

      final products = await widget.repository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        customerCode: customer.customerCode,
        query: barcode,
      );

      if (!mounted) {
        return;
      }

      if (products.isEmpty) {
        setState(() {
          line.setLookupStatus(
            'API cevap verdi ama barkoda ait urun bulunamadi: $barcode',
            isError: true,
          );
        });
        _showFeedback('Bu barkoda ait urun bulunamadi.');
        return;
      }

      var mergedIntoExisting = false;
      setState(() {
        mergedIntoExisting = _applyProductToLine(line, products.first);
        if (!mergedIntoExisting) {
          line.setLookupStatus(
            '${products.length} sonuc geldi. Secildi: ${products.first.stockCode} | ${products.first.stockName}',
          );
        }
        _validationMessage = null;
      });

      if (mergedIntoExisting) {
        _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showFeedback(error.toString().replaceFirst('Exception: ', '').trim());
      setState(() {
        line.setLookupStatus(
          'API hata dondu: ${error.toString().replaceFirst('Exception: ', '').trim()}',
          isError: true,
        );
      });
    }
  }

  Future<void> _scanProductWithCamera(_CompanyOrderLineDraft line) async {
    final customer = _selectedCustomer;
    if (customer == null) {
      setState(() {
        line.setLookupStatus(
          'Kamera ile okuma icin once cari secilmeli.',
          isError: true,
        );
      });
      _showFeedback('Kamera ile okuma icin once musteri secin.');
      return;
    }

    if (!supportsCameraBarcodeScanning) {
      setState(() {
        line.setLookupStatus(
          'Bu cihazda kamera ile barkod okutma desteklenmiyor.',
          isError: true,
        );
      });
      _showFeedback('Bu cihazda kamera ile barkod okutma desteklenmiyor.');
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Firma Siparisi Kamerasi',
      subtitle: 'Barkodu okutun; secili cari icin urun otomatik bulunacak.',
    );

    if (barcode == null || !mounted) {
      return;
    }

    line.barcodeController.text = barcode;
    setState(() {
      line.setLookupStatus('Barkod okundu: $barcode. API aramasi basliyor.');
    });
    await _findProductByBarcode(line);
  }

  bool _applyProductToLine(
    _CompanyOrderLineDraft line,
    CompanyOrderProductLookupItem product,
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
      _parseDouble(existingLine.quantityController.text) +
          _parseDouble(line.quantityController.text),
    );

    if (_parseDouble(existingLine.unitPriceController.text) <= 0) {
      line.applyProduct(product);
      existingLine.unitPriceController.text = line.unitPriceController.text;
    }

    _recycleMergedLine(line, createReplacement: _CompanyOrderLineDraft.new);
    return true;
  }

  _CompanyOrderLineDraft? _findDuplicateLine({
    required _CompanyOrderLineDraft currentLine,
    required String barcode,
    required String stockCode,
  }) {
    final targetKey = _productIdentity(barcode: barcode, stockCode: stockCode);
    if (targetKey == null) {
      return null;
    }

    for (final candidate in _lines) {
      if (identical(candidate, currentLine)) {
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
    _CompanyOrderLineDraft line, {
    required _CompanyOrderLineDraft Function() createReplacement,
  }) {
    final lineIndex = _lines.indexOf(line);
    line.dispose();

    if (lineIndex == 0) {
      _lines[lineIndex] = createReplacement();
      return;
    }

    _lines = _lines.where((item) => item != line).toList(growable: false);
  }

  void _addLine() {
    setState(() {
      _lines = <_CompanyOrderLineDraft>[_CompanyOrderLineDraft(), ..._lines];
      _validationMessage = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeLine(_CompanyOrderLineDraft line) {
    if (_lines.length == 1) {
      return;
    }

    setState(() {
      _lines = _lines.where((item) => item != line).toList(growable: false);
      line.dispose();
      _validationMessage = null;
    });
  }

  void _submit() {
    if (!validateCreateForm(_formKey)) {
      setState(() {
        _validationMessage = 'Lutfen zorunlu alanlari duzeltin.';
      });
      return;
    }

    final customer = _selectedCustomer;
    if (customer == null) {
      setState(() {
        _validationMessage = 'Siparis olusturmak icin musteri secimi zorunlu.';
      });
      return;
    }

    if (_lines.isEmpty) {
      setState(() {
        _validationMessage = 'En az bir satir olusturulmasi gerekiyor.';
      });
      return;
    }

    final requestLines = <CompanyOrderCreateLine>[];
    for (var index = 0; index < _lines.length; index += 1) {
      final line = _lines[index];
      final stockCode = line.stockCodeController.text.trim();
      final quantity = _parseDouble(line.quantityController.text);
      final unitPrice = _parseDouble(line.unitPriceController.text);

      if (stockCode.isEmpty) {
        setState(() {
          _validationMessage = '${index + 1}. satir icin urun secin.';
        });
        return;
      }

      if (quantity <= 0) {
        setState(() {
          _validationMessage =
              '${index + 1}. satir icin miktar sifirdan buyuk olmali.';
        });
        return;
      }

      requestLines.add(
        CompanyOrderCreateLine(
          stockCode: stockCode,
          quantity: quantity,
          recommendedQuantity: 0,
          unitPrice: unitPrice,
          unitPointer: 1,
          description1: '',
          description2: '',
          packageCode: '',
          projectCode: '',
          customerResponsibilityCenter: '',
          productResponsibilityCenter: '',
        ),
      );
    }

    Navigator.of(context).pop(
      CompanyOrderCreateRequest(
        customerCode: customer.customerCode,
        orderDate: _orderDate,
        deliveryDate: _deliveryDate,
        description1: _description1Controller.text.trim(),
        description2: _description2Controller.text.trim(),
        deliverer: _delivererController.text.trim(),
        receiver: _receiverController.text.trim(),
        lines: requestLines,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.94,
          child: Material(
            color: theme.scaffoldBackgroundColor,
            child: Form(
              key: _formKey,
              autovalidateMode: createFormAutovalidateMode,
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withAlpha(14),
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Yeni Verilen Firma Siparisi',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Depo: ${widget.defaultWarehouseNo}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 26),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        _buildCustomerSection(theme),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _buildDateButton(
                                theme: theme,
                                label: 'Siparis',
                                date: _orderDate,
                                onPressed: () => _pickDate(isOrderDate: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateButton(
                                theme: theme,
                                label: 'Teslim',
                                date: _deliveryDate,
                                onPressed: () => _pickDate(isOrderDate: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            _buildCompactTextField(
                              controller: _delivererController,
                              label: 'Teslim Eden',
                            ),
                            _buildCompactTextField(
                              controller: _receiverController,
                              label: 'Teslim Alan',
                            ),
                            _buildCompactTextField(
                              controller: _description1Controller,
                              label: 'Aciklama 1',
                            ),
                            _buildCompactTextField(
                              controller: _description2Controller,
                              label: 'Aciklama 2',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Text(
                                  'Urun girisi:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              _buildModeChip(
                                'Barkod ile',
                                _CompanyProductEntryMode.barcode,
                              ),
                              _buildModeChip(
                                'Arama ile',
                                _CompanyProductEntryMode.search,
                              ),
                              _buildModeChip(
                                'Kamera ile',
                                _CompanyProductEntryMode.camera,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._lines.asMap().entries.map(
                          (entry) => _buildLineCard(
                            theme: theme,
                            index: entry.key,
                            line: entry.value,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _selectedCustomer != null
                                ? _addLine
                                : null,
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Yeni Satir Ekle'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_validationMessage != null) ...<Widget>[
                          const SizedBox(height: 16),
                          _ValidationBlock(message: _validationMessage!),
                        ],
                        const SizedBox(height: 16),
                        TerminalFormActionRow(
                          submitFlex: 2,
                          cancel: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Vazgec'),
                          ),
                          submit: FilledButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Siparisi Olustur'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _customerCodeController,
                    readOnly: true,
                    onTap: _searchCustomer,
                    decoration: const InputDecoration(
                      labelText: 'Musteri Kodu*',
                      hintText: 'Cari secin',
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Zorunlu';
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: _searchCustomer,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.business_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Sec'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_selectedCustomer != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(55),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _selectedCustomer!.displayLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Temsilci: ${_selectedCustomer!.representativeCode.isEmpty ? '-' : _selectedCustomer!.representativeCode}'
                    ' | Vergi No: ${_selectedCustomer!.taxNumber.isEmpty ? '-' : _selectedCustomer!.taxNumber}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required ThemeData theme,
    required String label,
    required DateTime date,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(label, style: const TextStyle(fontSize: 10)),
              Text(
                AppFormatters.date(date),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildModeChip(String label, _CompanyProductEntryMode mode) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _entryMode == mode,
      onSelected: (_) {
        setState(() {
          _entryMode = mode;
          _validationMessage = null;
        });
      },
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildLineCard({
    required ThemeData theme,
    required int index,
    required _CompanyOrderLineDraft line,
  }) {
    final product = line.selectedProduct;
    final customerSelected = _selectedCustomer != null;
    final isBarcodeMode = _entryMode == _CompanyProductEntryMode.barcode;
    final isCameraMode = _entryMode == _CompanyProductEntryMode.camera;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(30),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product?.stockName ?? 'Urun secilmedi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: product != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: product != null
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_lines.length > 1)
                  IconButton(
                    onPressed: () => _removeLine(line),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                if (isBarcodeMode)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: line.barcodeController,
                          enabled: customerSelected,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!line.isLookupStatusLoading) {
                              _findProductByBarcode(line);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Barkod',
                            hintText: 'Tarat veya yaz',
                            suffixIcon: Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed:
                            customerSelected && !line.isLookupStatusLoading
                            ? () => _findProductByBarcode(line)
                            : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Bul'),
                      ),
                    ],
                  )
                else if (isCameraMode)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: customerSelected && !line.isLookupStatusLoading
                          ? () => _scanProductWithCamera(line)
                          : null,
                      icon: const Icon(
                        Icons.photo_camera_back_rounded,
                        size: 18,
                      ),
                      label: Text(
                        product == null ? 'Kamera ile Oku' : 'Tekrar Kamera Ac',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: customerSelected && !line.isLookupStatusLoading
                          ? () => _searchProduct(line)
                          : null,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: Text(
                        product == null ? 'Urun Sec' : 'Urun Degistir',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (!customerSelected) ...<Widget>[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6EFE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Bu satirda isleme baslamak icin once cari secin.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5B4738),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (line.lookupStatusMessage != null) ...<Widget>[
                  const SizedBox(height: 8),
                  if (line.isLookupStatusLoading)
                    TerminalMessageBlock.loading(
                      message: line.lookupStatusMessage!,
                    )
                  else if (line.isLookupStatusError)
                    TerminalMessageBlock.error(
                      message: line.lookupStatusMessage!,
                    )
                  else
                    TerminalMessageBlock.info(
                      message: line.lookupStatusMessage!,
                    ),
                ],
                const SizedBox(height: 10),
                TextFormField(
                  controller: line.quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                  ],
                  decoration: const InputDecoration(labelText: 'Miktar*'),
                  validator: (value) {
                    if (_parseDouble(value ?? '') <= 0) {
                      return 'Zorunlu';
                    }

                    return null;
                  },
                ),
                if (product != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      [
                        'Birim: ${product.unitName}',
                        'Varsayilan fiyat: ${AppFormatters.currency(product.price)}',
                        if (product.isOrderBlocked) 'Siparis blokeli',
                        if (product.isSalesBlocked) 'Satis blokeli',
                      ].join(' | '),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static double _parseDouble(String raw) {
    return double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;
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

class _CompanyOrderLineDraft {
  _CompanyOrderLineDraft()
    : barcodeController = TextEditingController(),
      stockCodeController = TextEditingController(),
      quantityController = TextEditingController(text: '1'),
      unitPriceController = TextEditingController(text: '0');

  CompanyOrderProductLookupItem? selectedProduct;
  String? lookupStatusMessage;
  bool isLookupStatusLoading = false;
  bool isLookupStatusError = false;
  final TextEditingController barcodeController;
  final TextEditingController stockCodeController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;

  void applyProduct(CompanyOrderProductLookupItem product) {
    selectedProduct = product;
    barcodeController.text = product.barcode;
    stockCodeController.text = product.stockCode;
    if (_parseDouble(unitPriceController.text) == 0 && product.price > 0) {
      unitPriceController.text = _formatNumber(product.price);
    }
  }

  void clearProduct() {
    selectedProduct = null;
    barcodeController.clear();
    stockCodeController.clear();
    unitPriceController.text = '0';
    lookupStatusMessage = null;
    isLookupStatusLoading = false;
    isLookupStatusError = false;
  }

  void setLookupStatus(
    String message, {
    bool isLoading = false,
    bool isError = false,
  }) {
    lookupStatusMessage = message;
    isLookupStatusLoading = isLoading;
    isLookupStatusError = isError;
  }

  void dispose() {
    barcodeController.dispose();
    stockCodeController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }

  static double _parseDouble(String raw) {
    return double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;
  }

  static String _formatNumber(double value) {
    final raw = value.toStringAsFixed(2);
    if (raw.endsWith('.00')) {
      return raw.substring(0, raw.length - 3);
    }

    return raw.replaceAll('.', ',');
  }
}

class _CustomerLookupSheet extends StatefulWidget {
  const _CustomerLookupSheet({
    required this.repository,
    required this.accessToken,
  });

  final CompanyOrdersRepository repository;
  final String accessToken;

  @override
  State<_CustomerLookupSheet> createState() => _CustomerLookupSheetState();
}

class _CustomerLookupSheetState extends State<_CustomerLookupSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  List<CustomerLookupItem> _items = const <CustomerLookupItem>[];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
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
      final items = await widget.repository.searchCustomers(
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
    return _LookupScaffold(
      title: 'Cari Ara',
      subtitle: 'Kod veya unvan ile arama yapin.',
      queryController: _queryController,
      onSearch: _load,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      isEmpty: _items.isEmpty,
      emptyMessage: 'Sonuc bulunamadi.',
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            tileColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withAlpha(40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Text(
              item.displayLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                if (item.representativeCode.isNotEmpty)
                  'Temsilci ${item.representativeCode}',
                if (item.taxNumber.isNotEmpty) 'Vergi ${item.taxNumber}',
              ].join(' | '),
            ),
            trailing: item.isClosed ? const Icon(Icons.block_rounded) : null,
            onTap: () => Navigator.of(context).pop(item),
          );
        },
      ),
    );
  }
}

class _CompanyProductLookupSheet extends StatefulWidget {
  const _CompanyProductLookupSheet({
    required this.repository,
    required this.accessToken,
    required this.warehouseNo,
    required this.customerCode,
  });

  final CompanyOrdersRepository repository;
  final String accessToken;
  final String warehouseNo;
  final String customerCode;

  @override
  State<_CompanyProductLookupSheet> createState() =>
      _CompanyProductLookupSheetState();
}

class _CompanyProductLookupSheetState
    extends State<_CompanyProductLookupSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  List<CompanyOrderProductLookupItem> _items =
      const <CompanyOrderProductLookupItem>[];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
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
        _items = const <CompanyOrderProductLookupItem>[];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.repository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.warehouseNo,
        customerCode: widget.customerCode,
        query: query,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
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
    return _LookupScaffold(
      title: 'Urun Ara',
      subtitle:
          'Secili cari: ${widget.customerCode} | Stok kodu, adi veya barkod.',
      queryController: _queryController,
      onSearch: _load,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      isEmpty: _items.isEmpty,
      emptyMessage: 'Sonuc bulunamadi.',
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            tileColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withAlpha(40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Text(
              item.displayLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                'Birim ${item.unitName}',
                'Fiyat ${AppFormatters.currency(item.price)}',
                if (item.isOrderBlocked) 'Siparis blokeli',
                if (item.isSalesBlocked) 'Satis blokeli',
              ].join(' | '),
            ),
            onTap: () => Navigator.of(context).pop(item),
          );
        },
      ),
    );
  }
}

class _LookupScaffold extends StatelessWidget {
  const _LookupScaffold({
    required this.title,
    required this.subtitle,
    required this.queryController,
    required this.onSearch,
    required this.isLoading,
    required this.errorMessage,
    required this.isEmpty,
    required this.emptyMessage,
    required this.child,
  });

  final String title;
  final String subtitle;
  final TextEditingController queryController;
  final VoidCallback onSearch;
  final bool isLoading;
  final String? errorMessage;
  final bool isEmpty;
  final String emptyMessage;
  final Widget child;

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
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: queryController,
                              onSubmitted: (_) => onSearch(),
                              decoration: const InputDecoration(
                                hintText: 'Ara...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: isLoading ? null : onSearch,
                            child: const Text('Ara'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                      ? Center(child: Text(errorMessage!))
                      : isEmpty
                      ? Center(child: Text(emptyMessage))
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: child,
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

class _ValidationBlock extends StatelessWidget {
  const _ValidationBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
