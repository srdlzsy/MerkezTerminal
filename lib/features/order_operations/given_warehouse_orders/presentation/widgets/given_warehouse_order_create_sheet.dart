import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';

enum _ProductEntryMode { barcode, search, camera }

class GivenWarehouseOrderCreateSheet extends StatefulWidget {
  const GivenWarehouseOrderCreateSheet({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
  });

  final WarehouseOrdersRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;

  @override
  State<GivenWarehouseOrderCreateSheet> createState() =>
      _GivenWarehouseOrderCreateSheetState();
}

class _GivenWarehouseOrderCreateSheetState
    extends State<GivenWarehouseOrderCreateSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _outWarehouseNoController;
  late DateTime _orderDate;
  late DateTime _deliveryDate;
  late List<_CreateLineDraft> _lines;
  late _ProductEntryMode _entryMode;
  WarehouseLookupItem? _selectedWarehouse;
  String? _validationMessage;
  final ScrollController _scrollController = ScrollController();

  bool get _hasWarehouseSelection {
    return _selectedWarehouse != null ||
        (int.tryParse(_outWarehouseNoController.text.trim()) ?? 0) > 0;
  }

  @override
  void initState() {
    super.initState();
    _outWarehouseNoController = TextEditingController();
    _orderDate = _normalizeDate(DateTime.now());
    _deliveryDate = _normalizeDate(DateTime.now());
    _lines = <_CreateLineDraft>[_CreateLineDraft()];
    _entryMode = _ProductEntryMode.barcode;
  }

  @override
  void dispose() {
    _outWarehouseNoController.dispose();
    _scrollController.dispose();
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

  Future<void> _searchWarehouse() async {
    final warehouse = await showModalBottomSheet<WarehouseLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _WarehouseLookupSheet(
        repository: widget.repository,
        accessToken: widget.accessToken,
      ),
    );

    if (warehouse == null || !mounted) {
      return;
    }

    setState(() {
      _selectedWarehouse = warehouse;
      _outWarehouseNoController.text = warehouse.warehouseNo.toString();
    });
  }

  Future<void> _searchProduct(_CreateLineDraft line) async {
    if (!_hasWarehouseSelection) {
      _showFeedback('Once karsi depo secin, sonra kalem okutun.');
      return;
    }

    final product = await showModalBottomSheet<ProductLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _ProductLookupSheet(
        repository: widget.repository,
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
      ),
    );

    if (product == null || !mounted) {
      return;
    }

    var mergedIntoExisting = false;
    setState(() {
      mergedIntoExisting = _applyProductToLine(line, product);
    });

    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  Future<void> _findProductByBarcode(_CreateLineDraft line) async {
    if (!_hasWarehouseSelection) {
      _showFeedback('Once karsi depo secin, sonra barkod okutun.');
      return;
    }

    final barcode = line.barcodeController.text.trim();

    if (barcode.length < 3) {
      _showFeedback('Barkod alanına geçerli bir değer girin.');
      return;
    }

    try {
      final products = await widget.repository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        query: barcode,
      );

      if (!mounted) {
        return;
      }

      if (products.isEmpty) {
        _showFeedback('Bu barkoda ait ürün bulunamadı.');
        return;
      }

      var mergedIntoExisting = false;
      setState(() {
        mergedIntoExisting = _applyProductToLine(line, products.first);
      });

      if (mergedIntoExisting) {
        _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showFeedback(error.toString().replaceFirst('Exception: ', '').trim());
    }
  }

  Future<void> _scanProductWithCamera(_CreateLineDraft line) async {
    if (!_hasWarehouseSelection) {
      _showFeedback('Once karsi depo secin, sonra kamera ile okutun.');
      return;
    }

    if (!supportsCameraBarcodeScanning) {
      _showFeedback('Bu cihazda kamera ile barkod okutma desteklenmiyor.');
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Depo Siparisi Kamerasi',
      subtitle: 'Barkodu okutun; bulunan urun satira eklenecek.',
    );

    if (barcode == null || !mounted) {
      return;
    }

    line.barcodeController.text = barcode;
    await _findProductByBarcode(line);
  }

  void _addLine() {
    setState(() {
      _lines = <_CreateLineDraft>[_CreateLineDraft(), ..._lines];
      // Yeni satıra scroll yap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  bool _applyProductToLine(_CreateLineDraft line, ProductLookupItem product) {
    final existingLine = _findDuplicateLine(
      currentLine: line,
      barcode: product.barcode,
      stockCode: product.stockCode,
    );

    if (existingLine == null) {
      line.applyProduct(product);
      return false;
    }

    final additionalQuantity = line.quantityController.text.trim().isEmpty
        ? 1
        : _parseDouble(line.quantityController.text);
    existingLine.quantityController.text = _formatQuantity(
      _parseDouble(existingLine.quantityController.text) + additionalQuantity,
    );
    _recycleMergedLine(line, createReplacement: _CreateLineDraft.new);
    return true;
  }

  _CreateLineDraft? _findDuplicateLine({
    required _CreateLineDraft currentLine,
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
    _CreateLineDraft line, {
    required _CreateLineDraft Function() createReplacement,
  }) {
    final lineIndex = _lines.indexOf(line);
    line.dispose();

    if (lineIndex == 0) {
      _lines[lineIndex] = createReplacement();
      return;
    }

    _lines = _lines.where((item) => item != line).toList(growable: false);
  }

  void _removeLine(_CreateLineDraft line) {
    if (_lines.length == 1) {
      return;
    }

    setState(() {
      _lines = _lines.where((item) => item != line).toList(growable: false);
      line.dispose();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _validationMessage = 'Lütfen zorunlu alanları düzeltin.');
      return;
    }

    final outWarehouseNo = int.tryParse(_outWarehouseNoController.text.trim());

    if (outWarehouseNo == null || outWarehouseNo <= 0) {
      setState(
        () => _validationMessage = 'Geçerli bir karşı depo numarası girin.',
      );
      return;
    }

    final request = WarehouseOrderCreateRequest(
      outWarehouseNo: outWarehouseNo,
      orderDate: _orderDate,
      deliveryDate: _deliveryDate,
      description: '',
      lines: _lines
          .map(
            (line) => WarehouseOrderCreateLine(
              stockCode: line.stockCodeController.text.trim(),
              quantity: _parseDouble(line.quantityController.text),
              recommendedQuantity: 0,
              unitPrice: 0,
              unitPointer: 1,
              description: '',
              packageCode: '',
              projectCode: '',
              responsibilityCenter: '',
            ),
          )
          .toList(growable: false),
    );

    Navigator.of(context).pop(request);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.94,
          child: Material(
            color: theme.scaffoldBackgroundColor,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ========== HEADER (Sabit) ==========
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yeni Verilen Depo Siparişi',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kaynak depo: ${widget.defaultWarehouseNo}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 28),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // ========== ANA İÇERİK (Scroll) ==========
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // --- Depo Bilgileri (Kompakt) ---
                        _buildWarehouseSection(theme),
                        const SizedBox(height: 16),

                        // --- Tarihler (Yatay) ---
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateButton(
                                label: 'Sipariş',
                                date: _orderDate,
                                onPressed: () => _pickDate(isOrderDate: true),
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateButton(
                                label: 'Teslim',
                                date: _deliveryDate,
                                onPressed: () => _pickDate(isOrderDate: false),
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // --- Giriş Modu Seçici (Kompakt) ---
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Ürün girişi:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              _buildModeChip(
                                'Barkod ile',
                                _ProductEntryMode.barcode,
                              ),
                              _buildModeChip(
                                'Arama ile',
                                _ProductEntryMode.search,
                              ),
                              _buildModeChip(
                                'Kamera ile',
                                _ProductEntryMode.camera,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- Satırlar ---
                        ..._lines.asMap().entries.map(
                          (entry) => _buildLineCard(
                            index: entry.key,
                            line: entry.value,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- Satır Ekle Butonu ---
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _hasWarehouseSelection ? _addLine : null,
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Yeni Satır Ekle'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                        if (_validationMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _validationMessage!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // --- Aksiyon Butonları ---
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Vazgeç'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.save_rounded),
                                label: const Text('Siparişi Oluştur'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildWarehouseSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
      child: Column(
        children: [
          // Satır: Karşı Depo Seçimi
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _outWarehouseNoController,
                    readOnly: true,
                    onTap: _searchWarehouse,
                    decoration: const InputDecoration(
                      labelText: 'Karşı Depo No*',
                      hintText: 'Depo seçin',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Zorunlu';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: _searchWarehouse,
                  child: const Row(
                    children: [
                      Icon(Icons.warehouse, size: 18),
                      SizedBox(width: 6),
                      Text('Seç'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Seçili Depo Bilgisi (varsa)
          if (_selectedWarehouse != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(50),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedWarehouse!.displayLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_selectedWarehouse!.district.isNotEmpty)
                          Text(
                            '${_selectedWarehouse!.district} / ${_selectedWarehouse!.province}',
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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

  Widget _buildModeChip(String label, _ProductEntryMode mode) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _entryMode == mode,
      onSelected: (_) => setState(() => _entryMode = mode),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildLineCard({
    required int index,
    required _CreateLineDraft line,
    required ThemeData theme,
  }) {
    final product = line.selectedProduct;
    final isBarcodeMode = _entryMode == _ProductEntryMode.barcode;
    final isCameraMode = _entryMode == _ProductEntryMode.camera;
    final canScan = _hasWarehouseSelection;

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
        children: [
          // Satır başlığı + sil butonu
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
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
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
                    product?.stockName ?? 'Ürün seçilmedi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: product != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: product != null
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

          // İçerik
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // Ürün seçme bölümü
                if (!canScan)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6EFE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Bu satirda isleme baslamak icin once karsi depo secin.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5B4738),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (isBarcodeMode)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: line.barcodeController,
                          enabled: canScan,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _findProductByBarcode(line),
                          decoration: const InputDecoration(
                            labelText: 'Barkod',
                            hintText: 'Tarat veya yaz',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            suffixIcon: Icon(Icons.qr_code_scanner, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: canScan
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
                      onPressed: canScan
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
                      onPressed: canScan ? () => _searchProduct(line) : null,
                      icon: const Icon(Icons.search, size: 18),
                      label: Text(
                        product == null ? 'Ürün Seç' : 'Ürün Değiştir',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: line.quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Miktar*',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').trim().replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed <= 0) {
                      return 'Zorunlu';
                    }
                    return null;
                  },
                ),

                // Ürün bilgisi (seçiliyse)
                if (product != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(80),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Birim: ${product.unitName}${product.isOrderBlocked ? ' | ⚠️ Sipariş blokeli' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  static DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static double _parseDouble(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;

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

// ==================== LOOKUP SHEETS (Optimize edildi) ====================

class _WarehouseLookupSheet extends StatefulWidget {
  const _WarehouseLookupSheet({
    required this.repository,
    required this.accessToken,
  });
  final WarehouseOrdersRepository repository;
  final String accessToken;

  @override
  State<_WarehouseLookupSheet> createState() => _WarehouseLookupSheetState();
}

class _WarehouseLookupSheetState extends State<_WarehouseLookupSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  List<WarehouseLookupItem> _items = [];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _load();
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
    return _buildLookupSheet(
      title: 'Depo Ara',
      subtitle: 'Depo no veya ad ile arayın',
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
            subtitle: Text('${item.district} ${item.province}'.trim()),
            onTap: () => Navigator.of(context).pop(item),
          );
        },
      ),
    );
  }

  Widget _buildLookupSheet({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: Material(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _queryController,
                              onSubmitted: (_) => _load(),
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
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _isLoading ? null : _load,
                            child: const Text('Ara'),
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
                      ? Center(child: Text(_errorMessage!))
                      : _items.isEmpty
                      ? const Center(child: Text('Sonuç bulunamadı'))
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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

class _ProductLookupSheet extends StatefulWidget {
  const _ProductLookupSheet({
    required this.repository,
    required this.accessToken,
    required this.warehouseNo,
  });

  final WarehouseOrdersRepository repository;
  final String accessToken;
  final String warehouseNo;

  @override
  State<_ProductLookupSheet> createState() => _ProductLookupSheetState();
}

class _ProductLookupSheetState extends State<_ProductLookupSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  List<ProductLookupItem> _items = [];

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
    if (_queryController.text.trim().length < 2) {
      setState(() {
        _errorMessage = 'En az 2 karakter girin';
        _items = [];
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
        query: _queryController.text,
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: Material(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ürün Ara',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Depo: ${widget.warehouseNo}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _queryController,
                              onSubmitted: (_) => _load(),
                              decoration: const InputDecoration(
                                hintText: 'Stok adı, kodu veya barkod',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _isLoading ? null : _load,
                            child: const Text('Ara'),
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
                      ? Center(child: Text(_errorMessage!))
                      : _items.isEmpty
                      ? const Center(child: Text('Sonuç bulunamadı'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return ListTile(
                              tileColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withAlpha(40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              title: Text(
                                item.displayLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Birim: ${item.unitName} | Fiyat: ${AppFormatters.currency(item.price)}',
                              ),
                              trailing: item.isOrderBlocked
                                  ? const Icon(Icons.warning_amber_rounded)
                                  : null,
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

// ==================== DATA MODEL ====================

class _CreateLineDraft {
  _CreateLineDraft()
    : stockCodeController = TextEditingController(),
      barcodeController = TextEditingController(),
      quantityController = TextEditingController();

  final TextEditingController stockCodeController;
  final TextEditingController barcodeController;
  final TextEditingController quantityController;
  ProductLookupItem? selectedProduct;

  void applyProduct(ProductLookupItem product) {
    selectedProduct = product;
    stockCodeController.text = product.stockCode;
    barcodeController.text = product.barcode;
    if (quantityController.text.trim().isEmpty) {
      quantityController.text = '1';
    }
  }

  void dispose() {
    stockCodeController.dispose();
    barcodeController.dispose();
    quantityController.dispose();
  }
}
