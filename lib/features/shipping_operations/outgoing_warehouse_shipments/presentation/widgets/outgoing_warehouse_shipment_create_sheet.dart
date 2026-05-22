import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/order_operations/received_warehouse_orders/data/received_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/outgoing_warehouse_shipments_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

enum _ShipmentCreateMode { manual, orderLinked }

enum _ManualProductEntryMode { barcode, search, camera }

class OutgoingWarehouseShipmentCreateSheet extends StatefulWidget {
  const OutgoingWarehouseShipmentCreateSheet({
    super.key,
    required this.repository,
    required this.receivedWarehouseOrdersRepository,
    required this.accessToken,
    required this.defaultWarehouseNo,
  });

  final OutgoingWarehouseShipmentsRepository repository;
  final ReceivedWarehouseOrdersRepository receivedWarehouseOrdersRepository;
  final String accessToken;
  final String defaultWarehouseNo;

  @override
  State<OutgoingWarehouseShipmentCreateSheet> createState() =>
      _OutgoingWarehouseShipmentCreateSheetState();
}

class _OutgoingWarehouseShipmentCreateSheetState
    extends State<OutgoingWarehouseShipmentCreateSheet>
    with CreateFormValidation {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _targetWarehouseNoController;
  late final TextEditingController _transitWarehouseNoController;
  late final TextEditingController _documentNoController;
  late final TextEditingController _descriptionController;
  late DateTime _movementDate;
  late DateTime _documentDate;
  late _ShipmentCreateMode _mode;
  late _ManualProductEntryMode _manualEntryMode;
  late List<_ManualShipmentLineDraft> _manualLines;
  List<_LinkedShipmentLineDraft> _linkedLines =
      const <_LinkedShipmentLineDraft>[];
  WarehouseLookupItem? _selectedTargetWarehouse;
  _SelectedWarehouseOrder? _selectedOrder;
  String? _validationMessage;
  final ScrollController _scrollController = ScrollController();

  bool get _hasTargetWarehouseSelection {
    return _selectedTargetWarehouse != null ||
        (int.tryParse(_targetWarehouseNoController.text.trim()) ?? 0) > 0;
  }

  @override
  void initState() {
    super.initState();
    _targetWarehouseNoController = TextEditingController();
    _transitWarehouseNoController = TextEditingController(text: '60');
    _documentNoController = TextEditingController();
    _descriptionController = TextEditingController();
    _movementDate = _normalizedDate(DateTime.now());
    _documentDate = _normalizedDate(DateTime.now());
    _mode = _ShipmentCreateMode.manual;
    _manualEntryMode = _ManualProductEntryMode.barcode;
    _manualLines = <_ManualShipmentLineDraft>[_ManualShipmentLineDraft()];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _targetWarehouseNoController.dispose();
    _transitWarehouseNoController.dispose();
    _documentNoController.dispose();
    _descriptionController.dispose();
    for (final line in _manualLines) {
      line.dispose();
    }
    for (final line in _linkedLines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool isMovementDate}) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isMovementDate ? _movementDate : _documentDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      if (isMovementDate) {
        _movementDate = pickedDate;
        if (_documentDate.isBefore(_movementDate)) {
          _documentDate = _movementDate;
        }
      } else {
        _documentDate = pickedDate;
        if (_movementDate.isAfter(_documentDate)) {
          _movementDate = _documentDate;
        }
      }
    });
  }

  Future<void> _selectTargetWarehouse() async {
    final warehouse = await showModalBottomSheet<WarehouseLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return _WarehouseLookupSheet(
          repository: widget.repository,
          accessToken: widget.accessToken,
        );
      },
    );

    if (warehouse == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTargetWarehouse = warehouse;
      _targetWarehouseNoController.text = warehouse.warehouseNo.toString();
      _selectedOrder = null;
      for (final line in _linkedLines) {
        line.dispose();
      }
      _linkedLines = const <_LinkedShipmentLineDraft>[];
      _validationMessage = null;
    });

    if (_mode == _ShipmentCreateMode.orderLinked) {
      await _pickWarehouseOrder();
    }
  }

  Future<void> _pickWarehouseOrder() async {
    final targetWarehouseNo = _parseInt(_targetWarehouseNoController.text);

    if (targetWarehouseNo == null || targetWarehouseNo <= 0) {
      setState(() {
        _validationMessage = 'Once gecerli bir hedef depo secin.';
      });
      return;
    }

    final selectedOrder = await showModalBottomSheet<_SelectedWarehouseOrder>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return _WarehouseOrderPickerSheet(
          repository: widget.receivedWarehouseOrdersRepository,
          accessToken: widget.accessToken,
          currentWarehouseNo: widget.defaultWarehouseNo,
          targetWarehouseNo: targetWarehouseNo.toString(),
        );
      },
    );

    if (selectedOrder == null || !mounted) {
      return;
    }

    final linkedLines = selectedOrder.detail.items
        .where((item) => item.remainingQuantity > 0)
        .map(_LinkedShipmentLineDraft.fromOrderItem)
        .toList(growable: false);

    if (linkedLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Secilen sipariste sevke baglanabilecek acik satir bulunamadi.',
          ),
        ),
      );
      return;
    }

    setState(() {
      for (final line in _linkedLines) {
        line.dispose();
      }
      _selectedOrder = selectedOrder;
      _linkedLines = linkedLines;
      _validationMessage = null;
    });
  }

  Future<void> _pickProduct(_ManualShipmentLineDraft line) async {
    if (!_hasTargetWarehouseSelection) {
      setState(() {
        line.setLookupStatus(
          'Urun aramasi icin once hedef depo secilmeli.',
          isError: true,
        );
      });
      _showFeedback('Once hedef depo secin, sonra kalem okutun.');
      return;
    }

    setState(() {
      line.setLookupStatus('Urun arama penceresi aciliyor.');
    });

    final product = await showModalBottomSheet<ProductLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return _ProductLookupSheet(
          repository: widget.repository,
          accessToken: widget.accessToken,
          warehouseNo: widget.defaultWarehouseNo,
        );
      },
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
      mergedIntoExisting = _applyProductToManualLine(line, product);
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

  Future<void> _findProductByBarcode(_ManualShipmentLineDraft line) async {
    if (!_hasTargetWarehouseSelection) {
      setState(() {
        line.setLookupStatus(
          'Barkod aramasi icin once hedef depo secilmeli.',
          isError: true,
        );
      });
      _showFeedback('Once hedef depo secin, sonra barkod okutun.');
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
        mergedIntoExisting = _applyProductToManualLine(line, products.first);
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

  Future<void> _scanProductWithCamera(_ManualShipmentLineDraft line) async {
    if (!_hasTargetWarehouseSelection) {
      setState(() {
        line.setLookupStatus(
          'Kamera ile okuma icin once hedef depo secilmeli.',
          isError: true,
        );
      });
      _showFeedback('Once hedef depo secin, sonra kamera ile okutun.');
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
      title: 'Depolar Arasi Sevk Kamerasi',
      subtitle: 'Barkodu okutun; bulunan urun satira eklenecek.',
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

  bool _applyProductToManualLine(
    _ManualShipmentLineDraft line,
    ProductLookupItem product,
  ) {
    final existingLine = _findDuplicateManualLine(
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
        : (_parseDouble(line.quantityController.text) ?? 0);
    existingLine.quantityController.text = _formatQuantity(
      (_parseDouble(existingLine.quantityController.text) ?? 0) +
          additionalQuantity,
    );
    _recycleMergedManualLine(
      line,
      createReplacement: _ManualShipmentLineDraft.new,
    );
    return true;
  }

  _ManualShipmentLineDraft? _findDuplicateManualLine({
    required _ManualShipmentLineDraft currentLine,
    required String barcode,
    required String stockCode,
  }) {
    final targetKey = _productIdentity(barcode: barcode, stockCode: stockCode);
    if (targetKey == null) {
      return null;
    }

    for (final candidate in _manualLines) {
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

  void _recycleMergedManualLine(
    _ManualShipmentLineDraft line, {
    required _ManualShipmentLineDraft Function() createReplacement,
  }) {
    final lineIndex = _manualLines.indexOf(line);
    line.dispose();

    if (lineIndex == 0) {
      _manualLines[lineIndex] = createReplacement();
      return;
    }

    _manualLines = _manualLines.where((item) => item != line).toList();
  }

  void _switchMode(_ShipmentCreateMode mode) {
    setState(() {
      _mode = mode;
      _validationMessage = null;
      if (_mode == _ShipmentCreateMode.manual && _manualLines.isEmpty) {
        _manualLines = <_ManualShipmentLineDraft>[_ManualShipmentLineDraft()];
      }
    });
  }

  void _addManualLine() {
    setState(() {
      _manualLines = <_ManualShipmentLineDraft>[
        _ManualShipmentLineDraft(),
        ..._manualLines,
      ];
      _validationMessage = null;

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

  void _removeManualLine(_ManualShipmentLineDraft line) {
    if (_manualLines.length == 1) {
      line.clear();
      setState(() {
        _validationMessage = null;
      });
      return;
    }

    setState(() {
      _manualLines = _manualLines.where((item) => item != line).toList();
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

    final targetWarehouseNo = _parseInt(_targetWarehouseNoController.text);
    final currentWarehouseNo = _parseInt(widget.defaultWarehouseNo);
    final transitWarehouseNo = _parseInt(_transitWarehouseNoController.text);

    if (targetWarehouseNo == null || targetWarehouseNo <= 0) {
      setState(() {
        _validationMessage = 'Gecerli bir hedef depo numarasi girin.';
      });
      return;
    }

    if (currentWarehouseNo != null && currentWarehouseNo == targetWarehouseNo) {
      setState(() {
        _validationMessage = 'Hedef depo, kaynak depo ile ayni olamaz.';
      });
      return;
    }

    if (transitWarehouseNo != null && transitWarehouseNo <= 0) {
      setState(() {
        _validationMessage = 'Transit depo numarasi pozitif olmali.';
      });
      return;
    }

    final requestLines = switch (_mode) {
      _ShipmentCreateMode.manual => _buildManualRequestLines(),
      _ShipmentCreateMode.orderLinked => _buildLinkedRequestLines(),
    };

    if (requestLines == null || requestLines.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      WarehouseShipmentCreateRequest(
        targetWarehouseNo: targetWarehouseNo,
        transitWarehouseNo: transitWarehouseNo,
        movementDate: _movementDate,
        documentDate: _documentDate,
        documentNo: _documentNoController.text.trim(),
        description: _descriptionController.text.trim(),
        lines: requestLines,
      ),
    );
  }

  List<WarehouseShipmentCreateLine>? _buildManualRequestLines() {
    final lines = <WarehouseShipmentCreateLine>[];

    for (var index = 0; index < _manualLines.length; index += 1) {
      final line = _manualLines[index];
      final stockCode = line.stockCodeController.text.trim();
      final quantity = _parseDouble(line.quantityController.text);

      if (stockCode.isEmpty) {
        setState(() {
          _validationMessage = '${index + 1}. satir icin urun secin.';
        });
        return null;
      }

      if (quantity == null || quantity <= 0) {
        setState(() {
          _validationMessage =
              '${index + 1}. satir icin miktar sifirdan buyuk olmali.';
        });
        return null;
      }

      lines.add(
        WarehouseShipmentCreateLine(
          stockCode: stockCode,
          quantity: quantity,
          unitPrice: line.selectedProduct?.price ?? 0,
          unitPointer: 1,
          description: '',
          partyCode: '',
          lotNo: 0,
          projectCode: '',
        ),
      );
    }

    return lines;
  }

  List<WarehouseShipmentCreateLine>? _buildLinkedRequestLines() {
    if (_selectedOrder == null) {
      setState(() {
        _validationMessage =
            'Siparise bagli sevk icin once bir depo siparisi secin.';
      });
      return null;
    }

    final lines = <WarehouseShipmentCreateLine>[];

    for (var index = 0; index < _linkedLines.length; index += 1) {
      final line = _linkedLines[index];
      final quantity = _parseDouble(line.quantityController.text);

      if (quantity == null || quantity <= 0) {
        setState(() {
          _validationMessage =
              '${index + 1}. siparis satiri icin miktar sifirdan buyuk olmali.';
        });
        return null;
      }

      if (quantity > line.maxQuantity) {
        setState(() {
          _validationMessage =
              '${index + 1}. satir icin miktar kalan siparis miktarini asamaz.';
        });
        return null;
      }

      lines.add(
        WarehouseShipmentCreateLine(
          warehouseOrderLineGuid: line.lineGuid,
          stockCode: line.stockCode,
          quantity: quantity,
          unitPrice: line.unitPrice,
          unitPointer: line.unitPointer,
          description: line.description,
          partyCode: line.partyCode,
          lotNo: line.lotNo,
          projectCode: line.projectCode,
        ),
      );
    }

    if (lines.isEmpty) {
      setState(() {
        _validationMessage =
            'Secilen sipariste sevke gidecek en az bir satir olmali.';
      });
      return null;
    }

    return lines;
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
              autovalidateMode: createFormAutovalidateMode,
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
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
                                'Yeni Giden Depolar Arasi Sevk',
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
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withAlpha(
                                50,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Sevk tipi',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  _ModeChip(
                                    label: 'Siparissiz Sevk',
                                    selected:
                                        _mode == _ShipmentCreateMode.manual,
                                    onTap: () =>
                                        _switchMode(_ShipmentCreateMode.manual),
                                  ),
                                  _ModeChip(
                                    label: 'Siparise Bagli Sevk',
                                    selected:
                                        _mode ==
                                        _ShipmentCreateMode.orderLinked,
                                    onTap: () => _switchMode(
                                      _ShipmentCreateMode.orderLinked,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildHeaderFieldsSection(theme),
                        const SizedBox(height: 12),
                        if (_mode == _ShipmentCreateMode.manual)
                          _buildManualLinesSection(theme)
                        else
                          _buildOrderLinkedSection(theme),
                        if (_validationMessage != null) ...<Widget>[
                          const SizedBox(height: 12),
                          _ValidationBlock(message: _validationMessage!),
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
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Sevki Hazirla'),
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

  Widget _buildHeaderFieldsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(70),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              final targetWarehouseField = TextFormField(
                controller: _targetWarehouseNoController,
                readOnly: true,
                onTap: _selectTargetWarehouse,
                decoration: InputDecoration(
                  labelText: 'Hedef depo no*',
                  hintText: 'Depo secin',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  suffixIcon: IconButton(
                    onPressed: _selectTargetWarehouse,
                    icon: const Icon(Icons.search_rounded),
                    tooltip: 'Depo sec',
                  ),
                ),
                validator: (value) {
                  final parsed = _parseInt(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Zorunlu';
                  }
                  return null;
                },
              );
              final selectButton = FilledButton.tonal(
                onPressed: _selectTargetWarehouse,
                child: const Text('Sec'),
              );

              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    targetWarehouseField,
                    const SizedBox(height: 8),
                    selectButton,
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: targetWarehouseField),
                  const SizedBox(width: 8),
                  selectButton,
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _DateField(
                label: 'Sevk',
                value: AppFormatters.date(_movementDate),
                onPressed: () => _pickDate(isMovementDate: true),
              ),
              _DateField(
                label: 'Belge',
                value: AppFormatters.date(_documentDate),
                onPressed: () => _pickDate(isMovementDate: false),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final transitField = TextFormField(
                controller: _transitWarehouseNoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Transit depo no',
                  hintText: '60',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
                validator: (value) {
                  final normalized = (value ?? '').trim();
                  if (normalized.isEmpty) {
                    return null;
                  }

                  final parsed = _parseInt(normalized);
                  if (parsed == null || parsed <= 0) {
                    return 'Pozitif olmali';
                  }
                  return null;
                },
              );
              final documentNoField = TextFormField(
                controller: _documentNoController,
                decoration: const InputDecoration(
                  labelText: 'Belge no',
                  hintText: 'Opsiyonel',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
              );

              if (constraints.maxWidth < 360) {
                return Column(
                  children: <Widget>[
                    transitField,
                    const SizedBox(height: 8),
                    documentNoField,
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: transitField),
                  const SizedBox(width: 8),
                  Expanded(child: documentNoField),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            maxLines: 1,
            decoration: const InputDecoration(
              labelText: 'Aciklama',
              hintText: 'Opsiyonel',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
          ),
          if (_selectedTargetWarehouse != null) ...<Widget>[
            const SizedBox(height: 10),
            _InfoPill(
              label: 'Secilen hedef depo',
              value: _selectedTargetWarehouse!.displayLabel,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManualLinesSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(70),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Sevk satirlari',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: const Text('Barkod ile'),
                selected: _manualEntryMode == _ManualProductEntryMode.barcode,
                onSelected: (_) {
                  setState(() {
                    _manualEntryMode = _ManualProductEntryMode.barcode;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Arama ile'),
                selected: _manualEntryMode == _ManualProductEntryMode.search,
                onSelected: (_) {
                  setState(() {
                    _manualEntryMode = _ManualProductEntryMode.search;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Kamera ile'),
                selected: _manualEntryMode == _ManualProductEntryMode.camera,
                onSelected: (_) {
                  setState(() {
                    _manualEntryMode = _ManualProductEntryMode.camera;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _hasTargetWarehouseSelection ? _addManualLine : null,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni Satir Ekle'),
            ),
          ),
          if (!_hasTargetWarehouseSelection) ...<Widget>[
            const SizedBox(height: 10),
            const _ValidationBlock(
              message:
                  'Manuel sevk satirlarina gecmeden once hedef depo secilmelidir.',
            ),
          ],
          const SizedBox(height: 10),
          Column(
            children: _manualLines
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == _manualLines.length - 1 ? 0 : 10,
                    ),
                    child: _ManualShipmentLineCard(
                      lineNumber: entry.key + 1,
                      line: entry.value,
                      entryMode: _manualEntryMode,
                      isReadyForScanning: _hasTargetWarehouseSelection,
                      canRemove: _manualLines.length > 1,
                      onPickProduct: () => _pickProduct(entry.value),
                      onScanWithCamera: () =>
                          _scanProductWithCamera(entry.value),
                      onResolveBarcode: () =>
                          _findProductByBarcode(entry.value),
                      onRemove: () => _removeManualLine(entry.value),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderLinkedSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(70),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickWarehouseOrder,
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(
                _selectedOrder == null
                    ? 'Depo Siparisi Sec'
                    : 'Siparisi Degistir',
              ),
            ),
          ),
          if (_selectedOrder != null) ...<Widget>[
            const SizedBox(height: 10),
            _InfoPill(
              label: 'Secilen siparis',
              value:
                  '${_selectedOrder!.item.documentNoLabel} - ${_selectedOrder!.item.outWarehouseName} -> ${_selectedOrder!.item.inWarehouseName}',
            ),
            const SizedBox(height: 10),
            if (MediaQuery.sizeOf(context).width >= 720)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: _LinkedShipmentTableHeader(),
              ),
            Column(
              children: _linkedLines
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == _linkedLines.length - 1 ? 0 : 8,
                      ),
                      child: _LinkedShipmentLineCard(
                        index: entry.key,
                        line: entry.value,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  static int? _parseInt(String value) {
    return int.tryParse(value.trim());
  }

  static double? _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
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

  static DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  void _showFeedback(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ManualShipmentLineCard extends StatelessWidget {
  const _ManualShipmentLineCard({
    required this.lineNumber,
    required this.line,
    required this.entryMode,
    required this.isReadyForScanning,
    required this.canRemove,
    required this.onPickProduct,
    required this.onScanWithCamera,
    required this.onResolveBarcode,
    required this.onRemove,
  });

  final int lineNumber;
  final _ManualShipmentLineDraft line;
  final _ManualProductEntryMode entryMode;
  final bool isReadyForScanning;
  final bool canRemove;
  final VoidCallback onPickProduct;
  final VoidCallback onScanWithCamera;
  final VoidCallback onResolveBarcode;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = line.selectedProduct;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(90),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Satir $lineNumber',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Satiri sil',
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (!isReadyForScanning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6EFE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Bu satira baslamadan once hedef depo secin.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5B4738),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (entryMode == _ManualProductEntryMode.search)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: line.isLookupStatusLoading ? null : onPickProduct,
                icon: const Icon(Icons.search_rounded),
                label: Text(product == null ? 'Urun Sec' : 'Urun Degistir'),
              ),
            )
          else if (entryMode == _ManualProductEntryMode.camera)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: isReadyForScanning && !line.isLookupStatusLoading
                    ? onScanWithCamera
                    : null,
                icon: const Icon(Icons.photo_camera_back_rounded),
                label: Text(
                  product == null ? 'Kamera ile Oku' : 'Tekrar Kamera Ac',
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final barcodeField = TextField(
                  controller: line.barcodeController,
                  enabled: isReadyForScanning,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    if (!line.isLookupStatusLoading) {
                      onResolveBarcode();
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Barkod',
                    hintText: 'Tarat ya da yaz',
                    suffixIcon: Icon(Icons.qr_code_scanner_rounded),
                  ),
                );
                final searchButton = FilledButton.tonalIcon(
                  onPressed: isReadyForScanning && !line.isLookupStatusLoading
                      ? onResolveBarcode
                      : null,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Bul'),
                );

                if (constraints.maxWidth < 340) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      barcodeField,
                      const SizedBox(height: 8),
                      searchButton,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: barcodeField),
                    const SizedBox(width: 12),
                    searchButton,
                  ],
                );
              },
            ),
          const SizedBox(height: 8),
          if (line.lookupStatusMessage != null) ...<Widget>[
            if (line.isLookupStatusLoading)
              TerminalMessageBlock.loading(message: line.lookupStatusMessage!)
            else if (line.isLookupStatusError)
              TerminalMessageBlock.error(message: line.lookupStatusMessage!)
            else
              TerminalMessageBlock.info(message: line.lookupStatusMessage!),
            const SizedBox(height: 8),
          ],
          if (product == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6EFE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                entryMode == _ManualProductEntryMode.barcode
                    ? 'Barkod okutuldugunda urun bilgisi dolar. Bu satirda sadece miktar girilir.'
                    : entryMode == _ManualProductEntryMode.camera
                    ? 'Kamera ile barkod okutuldugunda urun bilgisi dolar. Bu satirda sadece miktar girilir.'
                    : 'Urun secildiginde kod ve ad otomatik dolar. Bu satirda sadece miktar girilir.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5B4738),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6EFE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${product.stockName} | Kod ${product.stockCode} | Birim ${product.unitName}${product.barcode.trim().isNotEmpty ? ' | Barkod ${product.barcode}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF2A211B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextFormField(
            controller: line.quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Miktar'),
            validator: (value) {
              final parsed = double.tryParse(
                (value ?? '').trim().replaceAll(',', '.'),
              );
              if (parsed == null || parsed <= 0) {
                return 'Miktar > 0';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _LinkedShipmentTableHeader extends StatelessWidget {
  const _LinkedShipmentTableHeader();

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: const Color(0xFF6B5A4A),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: <Widget>[
          SizedBox(width: 120, child: Text('Stok kodu', style: textStyle)),
          const SizedBox(width: 12),
          Expanded(child: Text('Urun', style: textStyle)),
          const SizedBox(width: 12),
          SizedBox(width: 96, child: Text('Sip.', style: textStyle)),
          const SizedBox(width: 12),
          SizedBox(width: 128, child: Text('Sevk', style: textStyle)),
        ],
      ),
    );
  }
}

class _LinkedShipmentLineCard extends StatelessWidget {
  const _LinkedShipmentLineCard({required this.index, required this.line});

  final int index;
  final _LinkedShipmentLineDraft line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9F3),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withAlpha(84),
            ),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${index + 1}. ${line.stockCode}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      line.stockName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5E4A36),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        _InfoPill(
                          label: 'Sip. miktar',
                          value: AppFormatters.quantity(line.orderQuantity),
                        ),
                        _InfoPill(
                          label: 'Kalan',
                          value: AppFormatters.quantity(line.maxQuantity),
                        ),
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            controller: line.quantityController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Sevk miktari',
                            ),
                            validator: (value) {
                              final parsed = double.tryParse(
                                (value ?? '').trim().replaceAll(',', '.'),
                              );
                              if (parsed == null || parsed <= 0) {
                                return 'Miktar > 0';
                              }
                              if (parsed > line.maxQuantity) {
                                return 'Kalan asildi';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: <Widget>[
                    SizedBox(
                      width: 120,
                      child: Text(
                        line.stockCode,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        line.stockName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 96,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            AppFormatters.quantity(line.orderQuantity),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Kalan ${AppFormatters.quantity(line.maxQuantity)}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF6B5A4A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 128,
                      child: TextFormField(
                        controller: line.quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Sevk'),
                        validator: (value) {
                          final parsed = double.tryParse(
                            (value ?? '').trim().replaceAll(',', '.'),
                          );
                          if (parsed == null || parsed <= 0) {
                            return 'Miktar > 0';
                          }
                          if (parsed > line.maxQuantity) {
                            return 'Kalan asildi';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _WarehouseOrderPickerSheet extends StatefulWidget {
  const _WarehouseOrderPickerSheet({
    required this.repository,
    required this.accessToken,
    required this.currentWarehouseNo,
    required this.targetWarehouseNo,
  });

  final ReceivedWarehouseOrdersRepository repository;
  final String accessToken;
  final String currentWarehouseNo;
  final String targetWarehouseNo;

  @override
  State<_WarehouseOrderPickerSheet> createState() =>
      _WarehouseOrderPickerSheetState();
}

class _WarehouseOrderPickerSheetState
    extends State<_WarehouseOrderPickerSheet> {
  late final TextEditingController _queryController;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;
  String? _errorMessage;
  String? _loadingDetailKey;
  List<WarehouseOrderListItem> _items = const <WarehouseOrderListItem>[];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    final today = DateTime.now();
    _startDate = DateTime(today.year, today.month, today.day);
    _endDate = _startDate;
    _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
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

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final targetWarehouseNo = int.tryParse(widget.targetWarehouseNo.trim());
      final items = await widget.repository.fetchOrders(
        accessToken: widget.accessToken,
        filter: WarehouseOrderListFilter(
          startDate: _startDate,
          endDate: _endDate,
          warehouseNo: widget.currentWarehouseNo,
        ),
      );

      final query = _queryController.text.trim().toLowerCase();
      final filtered = items
          .where((item) {
            final matchesTargetWarehouse =
                targetWarehouseNo == null ||
                item.outWarehouseNo == targetWarehouseNo ||
                item.relatedWarehouseNo == targetWarehouseNo;

            if (!matchesTargetWarehouse) {
              return false;
            }

            if (query.isEmpty) {
              return true;
            }

            return item.documentNoLabel.toLowerCase().contains(query) ||
                item.relatedWarehouseName.toLowerCase().contains(query) ||
                item.inWarehouseName.toLowerCase().contains(query) ||
                item.outWarehouseName.toLowerCase().contains(query);
          })
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _items = filtered;
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

  Future<void> _selectItem(WarehouseOrderListItem item) async {
    setState(() {
      _loadingDetailKey = item.documentKey;
      _errorMessage = null;
    });

    try {
      final detail = await widget.repository.fetchOrderDetail(
        accessToken: widget.accessToken,
        documentSerie: item.documentSerie,
        documentOrderNo: item.documentOrderNo,
        warehouseNo: widget.currentWarehouseNo,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pop(_SelectedWarehouseOrder(item: item, detail: detail));
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingDetailKey = null;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: <Widget>[
              SectionCard(
                title: 'Depo Siparisi Sec',
                subtitle:
                    '${widget.targetWarehouseNo} deposunun bu depoya verdigi siparisler listelenir.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        _DateField(
                          label: 'Baslangic',
                          value: AppFormatters.date(_startDate),
                          onPressed: () => _pickDate(isStart: true),
                        ),
                        _DateField(
                          label: 'Bitis',
                          value: AppFormatters.date(_endDate),
                          onPressed: () => _pickDate(isStart: false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ResponsiveSearchRow(
                      textField: TextField(
                        controller: _queryController,
                        decoration: const InputDecoration(
                          labelText: 'Siparis ara',
                          hintText: 'Ornek: D110.1915',
                        ),
                      ),
                      button: FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Listele'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                _ValidationBlock(message: _errorMessage!)
              else if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Secilen depo icin bu depoya verilmis baglanabilir siparis bulunamadi.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Column(
                  children: _items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant.withAlpha(80),
                              ),
                            ),
                            title: Text(
                              item.documentNoLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${item.outWarehouseName} -> ${item.inWarehouseName} | ${item.lineCount} satir | ${AppFormatters.quantity(item.totalQuantity)}',
                            ),
                            trailing: _loadingDetailKey == item.documentKey
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.chevron_right_rounded),
                            onTap: () => _selectItem(item),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarehouseLookupSheet extends StatefulWidget {
  const _WarehouseLookupSheet({
    required this.repository,
    required this.accessToken,
  });

  final OutgoingWarehouseShipmentsRepository repository;
  final String accessToken;

  @override
  State<_WarehouseLookupSheet> createState() => _WarehouseLookupSheetState();
}

class _WarehouseLookupSheetState extends State<_WarehouseLookupSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  List<WarehouseLookupItem> _items = const <WarehouseLookupItem>[];

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
    return _LookupScaffold(
      title: 'Depo Ara',
      subtitle: 'Depo no ya da ad ile arayabilirsiniz.',
      queryController: _queryController,
      hintText: 'Ornek: kestel veya 50',
      onSearch: _load,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      isEmpty: _items.isEmpty,
      emptyMessage: 'Sonuc bulunamadi.',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _items[index];

          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withAlpha(80),
              ),
            ),
            title: Text(
              item.displayLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${item.district} ${item.province}'.trim()),
            onTap: () => Navigator.of(context).pop(item),
          );
        },
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

  final OutgoingWarehouseShipmentsRepository repository;
  final String accessToken;
  final String warehouseNo;

  @override
  State<_ProductLookupSheet> createState() => _ProductLookupSheetState();
}

class _ProductLookupSheetState extends State<_ProductLookupSheet> {
  late final TextEditingController _queryController;
  bool _isLoading = false;
  String? _errorMessage;
  List<ProductLookupItem> _items = const <ProductLookupItem>[];

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
        _errorMessage = 'En az 2 karakter girin.';
        _items = const <ProductLookupItem>[];
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
    return _LookupScaffold(
      title: 'Urun Ara',
      subtitle:
          'Stok adi, stok kodu veya barkod ile arayabilirsiniz. Arama deposu: ${widget.warehouseNo}',
      queryController: _queryController,
      hintText: 'Ornek: sut, 015550 veya 8690000000000',
      onSearch: _load,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      isEmpty: _items.isEmpty,
      emptyMessage: 'Sonuc bulunamadi.',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _items[index];

          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withAlpha(80),
              ),
            ),
            title: Text(
              item.displayLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'Birim: ${item.unitName}  |  Fiyat: ${AppFormatters.currency(item.price)}',
            ),
            trailing: item.isOrderBlocked
                ? const Icon(Icons.warning_amber_rounded)
                : const Icon(Icons.chevron_right_rounded),
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
    required this.hintText,
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
  final String hintText;
  final Future<void> Function() onSearch;
  final bool isLoading;
  final String? errorMessage;
  final bool isEmpty;
  final String emptyMessage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: <Widget>[
                SectionCard(
                  title: title,
                  subtitle: subtitle,
                  child: _ResponsiveSearchRow(
                    textField: TextField(
                      controller: queryController,
                      decoration: InputDecoration(
                        labelText: 'Arama',
                        hintText: hintText,
                      ),
                    ),
                    button: FilledButton.icon(
                      onPressed: onSearch,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Ara'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (errorMessage != null)
                  _ValidationBlock(message: errorMessage!)
                else if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        emptyMessage,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualShipmentLineDraft {
  _ManualShipmentLineDraft()
    : stockCodeController = TextEditingController(),
      barcodeController = TextEditingController(),
      quantityController = TextEditingController();

  final TextEditingController stockCodeController;
  final TextEditingController barcodeController;
  final TextEditingController quantityController;
  ProductLookupItem? selectedProduct;
  String? lookupStatusMessage;
  bool isLookupStatusLoading = false;
  bool isLookupStatusError = false;

  void applyProduct(ProductLookupItem product) {
    selectedProduct = product;
    stockCodeController.text = product.stockCode;
    barcodeController.text = product.barcode;
    if (quantityController.text.trim().isEmpty) {
      quantityController.text = '1';
    }
  }

  void clear() {
    stockCodeController.clear();
    barcodeController.clear();
    quantityController.clear();
    selectedProduct = null;
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
    stockCodeController.dispose();
    barcodeController.dispose();
    quantityController.dispose();
  }
}

class _LinkedShipmentLineDraft {
  _LinkedShipmentLineDraft({
    required this.lineGuid,
    required this.stockCode,
    required this.stockName,
    required this.unitName,
    required this.unitPointer,
    required this.orderQuantity,
    required this.maxQuantity,
    required this.unitPrice,
    required this.description,
    required this.partyCode,
    required this.lotNo,
    required this.projectCode,
    required this.warehouseOrderNo,
  }) : quantityController = TextEditingController(text: '$maxQuantity');

  final String lineGuid;
  final String stockCode;
  final String stockName;
  final String unitName;
  final int unitPointer;
  final double orderQuantity;
  final double maxQuantity;
  final double unitPrice;
  final String description;
  final String partyCode;
  final int lotNo;
  final String projectCode;
  final String warehouseOrderNo;
  final TextEditingController quantityController;

  factory _LinkedShipmentLineDraft.fromOrderItem(
    WarehouseOrderDetailItem item,
  ) {
    return _LinkedShipmentLineDraft(
      lineGuid: item.lineGuid,
      stockCode: item.stockCode,
      stockName: item.stockName,
      unitName: item.unitName,
      unitPointer: item.unitPointer,
      orderQuantity: item.quantity,
      maxQuantity: item.remainingQuantity,
      unitPrice: item.unitPrice,
      description: item.description,
      partyCode: '',
      lotNo: 0,
      projectCode: item.projectCode,
      warehouseOrderNo: '',
    );
  }

  void dispose() {
    quantityController.dispose();
  }
}

class _SelectedWarehouseOrder {
  const _SelectedWarehouseOrder({required this.item, required this.detail});

  final WarehouseOrderListItem item;
  final WarehouseOrderDetail detail;
}

class _ResponsiveSearchRow extends StatelessWidget {
  const _ResponsiveSearchRow({required this.textField, required this.button});

  final Widget textField;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[textField, const SizedBox(height: 8), button],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: textField),
            const SizedBox(width: 12),
            button,
          ],
        );
      },
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(142, 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        icon: const Icon(Icons.calendar_month_rounded, size: 19),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                height: 1.12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(90),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF6B5A4A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF231C17),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(18),
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
