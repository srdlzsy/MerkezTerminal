import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/order_operations/received_warehouse_orders/data/received_warehouse_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/shared/data/models/warehouse_order_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/models/outgoing_warehouse_shipment_models.dart';
import 'package:furpa_merkez_terminal/features/shipping_operations/outgoing_warehouse_shipments/data/outgoing_warehouse_shipments_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_session.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_warehouse_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_controller.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

enum _ShipmentCreateMode { manual, orderLinked }

class OutgoingWarehouseShipmentCreateSheet extends StatefulWidget {
  const OutgoingWarehouseShipmentCreateSheet({
    super.key,
    required this.repository,
    required this.receivedWarehouseOrdersRepository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.mobileWarehouseCatalogRepository,
    this.draft,
    this.draftRepository,
  });

  final OutgoingWarehouseShipmentsRepository repository;
  final ReceivedWarehouseOrdersRepository receivedWarehouseOrdersRepository;
  final String accessToken;
  final String defaultWarehouseNo;
  final MobileWarehouseCatalogLocalRepository mobileWarehouseCatalogRepository;
  final CreateDraft? draft;
  final CreateDraftRepository? draftRepository;

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
  late List<_ManualShipmentLineDraft> _manualLines;
  List<_LinkedShipmentLineDraft> _linkedLines = <_LinkedShipmentLineDraft>[];
  WarehouseLookupItem? _selectedTargetWarehouse;
  _SelectedWarehouseOrder? _selectedOrder;
  String? _validationMessage;
  final ScrollController _scrollController = ScrollController();
  late final CreateDraftSession _draftSession;

  bool get _hasTargetWarehouseSelection {
    return _selectedTargetWarehouse != null ||
        (int.tryParse(_targetWarehouseNoController.text.trim()) ?? 0) > 0;
  }

  @override
  void initState() {
    super.initState();
    final payload = widget.draft?.payload ?? const <String, dynamic>{};
    _targetWarehouseNoController = TextEditingController(
      text: payload['targetWarehouseNo']?.toString() ?? '',
    );
    _transitWarehouseNoController = TextEditingController(
      text: payload['transitWarehouseNo']?.toString() ?? '60',
    );
    _documentNoController = TextEditingController(
      text: payload['documentNo']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: payload['description']?.toString() ?? '',
    );
    _movementDate =
        DateTime.tryParse(payload['movementDate']?.toString() ?? '') ??
        _normalizedDate(DateTime.now());
    _documentDate =
        DateTime.tryParse(payload['documentDate']?.toString() ?? '') ??
        _normalizedDate(DateTime.now());
    _mode = payload['mode']?.toString() == 'orderLinked'
        ? _ShipmentCreateMode.orderLinked
        : _ShipmentCreateMode.manual;
    final warehouseJson = _shipmentDraftMap(payload['selectedTargetWarehouse']);
    if (warehouseJson != null) {
      _selectedTargetWarehouse = WarehouseLookupItem.fromJson(warehouseJson);
    }
    final selectedOrderJson = _shipmentDraftMap(payload['selectedOrder']);
    if (selectedOrderJson != null) {
      _selectedOrder = _SelectedWarehouseOrder.fromDraftJson(selectedOrderJson);
    }
    _draftSession = CreateDraftSession(
      draft: widget.draft,
      repository: widget.draftRepository,
      hasContent: _hasDraftContent,
      buildPayload: _buildDraftPayload,
      buildTitle: () => _selectedTargetWarehouse == null
          ? 'Yeni Giden Depolar Arasi Sevk'
          : 'Depo Sevk - ${_selectedTargetWarehouse!.warehouseName}',
    );
    final rawManualLines = payload['manualLines'];
    _manualLines = rawManualLines is List
        ? rawManualLines
              .map(_shipmentDraftMap)
              .whereType<Map<String, dynamic>>()
              .map(_createManualLine)
              .toList(growable: true)
        : <_ManualShipmentLineDraft>[];
    _ensureFreshManualEntryLine();
    final rawLinkedLines = payload['linkedLines'];
    _linkedLines = rawLinkedLines is List
        ? rawLinkedLines
              .map(_shipmentDraftMap)
              .whereType<Map<String, dynamic>>()
              .map(
                (line) => _LinkedShipmentLineDraft.fromDraftJson(
                  line,
                  onChanged: _draftSession.scheduleSave,
                ),
              )
              .toList(growable: true)
        : <_LinkedShipmentLineDraft>[];
    if (_mode == _ShipmentCreateMode.orderLinked && _selectedOrder != null) {
      _ensureFreshLinkedEntryLine();
    }
    _draftSession.listenTo(<TextEditingController>[
      _targetWarehouseNoController,
      _transitWarehouseNoController,
      _documentNoController,
      _descriptionController,
    ]);
  }

  @override
  void dispose() {
    _draftSession.dispose();
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

  _ManualShipmentLineDraft _createManualLine([Map<String, dynamic>? draft]) {
    return _ManualShipmentLineDraft(
      draft: draft,
      onChanged: _draftSession.scheduleSave,
    );
  }

  bool _hasDraftContent() {
    return _selectedTargetWarehouse != null ||
        _selectedOrder != null ||
        _targetWarehouseNoController.text.trim().isNotEmpty ||
        _transitWarehouseNoController.text.trim() != '60' ||
        _documentNoController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _manualLines.any((line) => line.hasContent) ||
        _linkedLines.any((line) => line.hasContent);
  }

  Map<String, dynamic> _buildDraftPayload() {
    return <String, dynamic>{
      'targetWarehouseNo': _targetWarehouseNoController.text,
      'transitWarehouseNo': _transitWarehouseNoController.text,
      'documentNo': _documentNoController.text,
      'description': _descriptionController.text,
      'movementDate': _movementDate.toIso8601String(),
      'documentDate': _documentDate.toIso8601String(),
      'mode': _mode == _ShipmentCreateMode.orderLinked
          ? 'orderLinked'
          : 'manual',
      'selectedTargetWarehouse': _selectedTargetWarehouse == null
          ? null
          : _shipmentWarehouseJson(_selectedTargetWarehouse!),
      'selectedOrder': _selectedOrder?.toDraftJson(),
      'manualLines': _manualLines
          .where((line) => line.hasContent)
          .map((line) => line.toDraftJson())
          .toList(growable: false),
      'linkedLines': _linkedLines
          .where((line) => line.hasContent)
          .map((line) => line.toDraftJson())
          .toList(growable: false),
    };
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
          mobileWarehouseCatalogRepository:
              widget.mobileWarehouseCatalogRepository,
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
      _linkedLines = <_LinkedShipmentLineDraft>[];
      _validationMessage = null;
    });
    _draftSession.scheduleSave();

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
        .map(
          (item) => _LinkedShipmentLineDraft.fromOrderItem(
            item,
            onChanged: _draftSession.scheduleSave,
          ),
        )
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
      _ensureFreshLinkedEntryLine();
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
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
          initialQuery: line.barcodeController.text,
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
      _ensureFreshManualEntryLine();
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
    _focusFreshManualEntryLine();

    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  Future<void> _pickLinkedProduct(_LinkedShipmentLineDraft line) async {
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
          initialQuery: line.barcodeController.text,
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
      mergedIntoExisting = _applyProductToLinkedLine(line, product);
      if (!mergedIntoExisting) {
        line.setLookupStatus(
          'Secildi: ${product.stockCode} | ${product.stockName}',
        );
      }
      _ensureFreshLinkedEntryLine();
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
    _focusFreshLinkedEntryLine();

    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
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
    await _pickProduct(line);
  }

  Future<void> _scanLinkedProductWithCamera(
    _LinkedShipmentLineDraft line,
  ) async {
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
    await _pickLinkedProduct(line);
  }

  bool _applyProductToManualLine(
    _ManualShipmentLineDraft line,
    ProductLookupItem product,
  ) {
    final existingLine = productEntryController.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<_ManualShipmentLineDraft>(
        currentLine: line,
        targetBarcode: product.barcode,
        targetStockCode: product.stockCode,
        lines: _manualLines,
        lineBarcode: (line) => line.selectedProduct?.barcode ?? '',
        lineStockCode: (line) => line.selectedProduct?.stockCode ?? '',
        canMergeLine: (line) => line.selectedProduct != null,
      ),
    );

    if (existingLine == null) {
      line.applyProduct(product);
      return false;
    }

    existingLine.quantityController.text = productEntryController
        .formatQuantity(
          productEntryController.readQuantity(
                existingLine.quantityController.text,
                fallback: 0,
              ) +
              productEntryController.quantityInputOrUnitMultiplier(
                line.quantityController.text,
                product.unitMultiplier,
              ),
        );
    _recycleMergedManualLine(line, createReplacement: _createManualLine);
    return true;
  }

  bool _applyProductToLinkedLine(
    _LinkedShipmentLineDraft line,
    ProductLookupItem product,
  ) {
    final existingLine = productEntryController.findDuplicateLine(
      ProductEntryDuplicateMergePolicy<_LinkedShipmentLineDraft>(
        currentLine: line,
        targetBarcode: product.barcode,
        targetStockCode: product.stockCode,
        lines: _linkedLines,
        lineBarcode: (line) => line.selectedProduct?.barcode ?? '',
        lineStockCode: (line) => line.stockCode,
        canMergeLine: (line) =>
            !line.isOrderLinked && line.selectedProduct != null,
      ),
    );

    if (existingLine == null) {
      line.applyProduct(product);
      return false;
    }

    existingLine.quantityController.text = productEntryController
        .formatQuantity(
          productEntryController.readQuantity(
                existingLine.quantityController.text,
                fallback: 0,
              ) +
              productEntryController.quantityInputOrUnitMultiplier(
                line.quantityController.text,
                product.unitMultiplier,
              ),
        );
    _recycleMergedLinkedLine(line, createReplacement: _createLinkedLine);
    return true;
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

  void _recycleMergedLinkedLine(
    _LinkedShipmentLineDraft line, {
    required _LinkedShipmentLineDraft Function() createReplacement,
  }) {
    final lineIndex = _linkedLines.indexOf(line);
    line.dispose();

    if (lineIndex == 0) {
      _linkedLines[lineIndex] = createReplacement();
      return;
    }

    _linkedLines = _linkedLines.where((item) => item != line).toList();
  }

  void _switchMode(_ShipmentCreateMode mode) {
    setState(() {
      _mode = mode;
      _validationMessage = null;
      if (_mode == _ShipmentCreateMode.manual && _manualLines.isEmpty) {
        _manualLines = <_ManualShipmentLineDraft>[_createManualLine()];
      }
      if (_mode == _ShipmentCreateMode.manual) {
        _ensureFreshManualEntryLine();
      }
      if (_mode == _ShipmentCreateMode.orderLinked && _selectedOrder != null) {
        _ensureFreshLinkedEntryLine();
      }
    });
    _draftSession.scheduleSave();
    if (_mode == _ShipmentCreateMode.manual) {
      _focusFreshManualEntryLine();
    } else if (_selectedOrder != null) {
      _focusFreshLinkedEntryLine();
    }
  }

  void _ensureFreshManualEntryLine() {
    if (_manualLines.isEmpty || !_isBlankManualLine(_manualLines.first)) {
      _manualLines = <_ManualShipmentLineDraft>[
        _createManualLine(),
        ..._manualLines,
      ];
    }
  }

  _LinkedShipmentLineDraft _createLinkedLine([Map<String, dynamic>? draft]) {
    if (draft != null) {
      return _LinkedShipmentLineDraft.fromDraftJson(
        draft,
        onChanged: _draftSession.scheduleSave,
      );
    }

    return _LinkedShipmentLineDraft.empty(
      onChanged: _draftSession.scheduleSave,
    );
  }

  void _ensureFreshLinkedEntryLine() {
    if (_linkedLines.isEmpty || !_isBlankLinkedLine(_linkedLines.first)) {
      _linkedLines = <_LinkedShipmentLineDraft>[
        _createLinkedLine(),
        ..._linkedLines,
      ];
    }
  }

  void _focusFreshLinkedEntryLine() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _linkedLines.isEmpty) {
        return;
      }

      final firstLine = _linkedLines.first;
      if (_isBlankLinkedLine(firstLine)) {
        firstLine.barcodeFocusNode.requestFocus();
      }
    });
  }

  bool _isBlankLinkedLine(_LinkedShipmentLineDraft line) {
    return !line.isOrderLinked &&
        line.selectedProduct == null &&
        line.stockCode.trim().isEmpty &&
        line.barcodeController.text.trim().isEmpty;
  }

  void _focusFreshManualEntryLine() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _manualLines.isEmpty) {
        return;
      }

      final firstLine = _manualLines.first;
      if (_isBlankManualLine(firstLine)) {
        firstLine.barcodeFocusNode.requestFocus();
      }
    });
  }

  bool _isBlankManualLine(_ManualShipmentLineDraft line) {
    return line.selectedProduct == null &&
        line.stockCodeController.text.trim().isEmpty &&
        line.barcodeController.text.trim().isEmpty;
  }

  void _removeManualLine(_ManualShipmentLineDraft line) {
    if (_manualLines.length == 1) {
      line.clear();
      setState(() {
        _validationMessage = null;
      });
      _draftSession.scheduleSave();
      return;
    }

    setState(() {
      _manualLines = _manualLines.where((item) => item != line).toList();
      line.dispose();
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
  }

  void _removeLinkedLine(_LinkedShipmentLineDraft line) {
    if (_isBlankLinkedLine(line) && _linkedLines.length == 1) {
      line.clear();
      setState(() {
        _validationMessage = null;
      });
      _draftSession.scheduleSave();
      return;
    }

    setState(() {
      _linkedLines = _linkedLines.where((item) => item != line).toList();
      line.dispose();
      _ensureFreshLinkedEntryLine();
      _validationMessage = null;
    });
    _draftSession.scheduleSave();
  }

  Future<void> _submit() async {
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

    final request = WarehouseShipmentCreateRequest(
      targetWarehouseNo: targetWarehouseNo,
      transitWarehouseNo: transitWarehouseNo,
      movementDate: _movementDate,
      documentDate: _documentDate,
      documentNo: _documentNoController.text.trim(),
      description: _descriptionController.text.trim(),
      lines: requestLines,
    );

    await _draftSession.complete();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(request);
  }

  List<WarehouseShipmentCreateLine>? _buildManualRequestLines() {
    final lines = <WarehouseShipmentCreateLine>[];

    final activeLines = _manualLines
        .where((line) => !_isBlankManualLine(line))
        .toList(growable: false);

    if (activeLines.isEmpty) {
      setState(() {
        _validationMessage = 'En az bir urun satiri ekleyin.';
      });
      return null;
    }

    for (var index = 0; index < activeLines.length; index += 1) {
      final line = activeLines[index];
      final stockCode = line.stockCodeController.text.trim();
      final quantity = productEntryController.readQuantity(
        line.quantityController.text,
        fallback: 0,
      );

      if (stockCode.isEmpty) {
        setState(() {
          _validationMessage = '${index + 1}. satir icin urun secin.';
        });
        return null;
      }

      if (quantity <= 0) {
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

    final activeLines = _linkedLines
        .where((line) => !_isBlankLinkedLine(line))
        .toList(growable: false);

    for (var index = 0; index < activeLines.length; index += 1) {
      final line = activeLines[index];
      final stockCode = line.stockCode.trim();
      final quantity = productEntryController.readQuantity(
        line.quantityController.text,
        fallback: 0,
      );

      if (stockCode.isEmpty) {
        setState(() {
          _validationMessage = '${index + 1}. satir icin urun secin.';
        });
        return null;
      }

      if (quantity <= 0) {
        setState(() {
          _validationMessage =
              '${index + 1}. siparis satiri icin miktar sifirdan buyuk olmali.';
        });
        return null;
      }

      if (line.isOrderLinked && quantity > line.maxQuantity) {
        setState(() {
          _validationMessage =
              '${index + 1}. satir icin miktar kalan siparis miktarini asamaz.';
        });
        return null;
      }

      lines.add(
        WarehouseShipmentCreateLine(
          warehouseOrderLineGuid: line.lineGuid,
          stockCode: stockCode,
          quantity: quantity,
          unitPrice: line.selectedProduct?.price ?? line.unitPrice,
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
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _ShipmentModeButton(
                                      label: 'Siparissiz',
                                      icon: Icons.edit_note_rounded,
                                      selected:
                                          _mode == _ShipmentCreateMode.manual,
                                      onTap: () => _switchMode(
                                        _ShipmentCreateMode.manual,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _ShipmentModeButton(
                                      label: 'Siparisli',
                                      icon: Icons.fact_check_outlined,
                                      selected:
                                          _mode ==
                                          _ShipmentCreateMode.orderLinked,
                                      onTap: () => _switchMode(
                                        _ShipmentCreateMode.orderLinked,
                                      ),
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
                .map((entry) {
                  final isFreshEntry =
                      entry.key == 0 && _isBlankManualLine(entry.value);
                  final displayLineNo = _manualLines
                      .take(entry.key + 1)
                      .where((item) => !_isBlankManualLine(item))
                      .length;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == _manualLines.length - 1 ? 0 : 10,
                    ),
                    child: _ManualShipmentLineCard(
                      lineNumber: displayLineNo,
                      isFreshEntry: isFreshEntry,
                      line: entry.value,
                      isReadyForScanning: _hasTargetWarehouseSelection,
                      canRemove: !isFreshEntry && _manualLines.length > 1,
                      onPickProduct: () => _pickProduct(entry.value),
                      onScanWithCamera: () =>
                          _scanProductWithCamera(entry.value),
                      onRemove: () => _removeManualLine(entry.value),
                    ),
                  );
                })
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
            Column(
              children: _linkedLines
                  .asMap()
                  .entries
                  .map((entry) {
                    final isFreshEntry =
                        entry.key == 0 && _isBlankLinkedLine(entry.value);
                    final displayLineNo = _linkedLines
                        .take(entry.key + 1)
                        .where((item) => !_isBlankLinkedLine(item))
                        .length;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == _linkedLines.length - 1 ? 0 : 8,
                      ),
                      child: _LinkedShipmentLineCard(
                        lineNumber: displayLineNo,
                        isFreshEntry: isFreshEntry,
                        line: entry.value,
                        isReadyForScanning: _hasTargetWarehouseSelection,
                        canRemove: !isFreshEntry,
                        onPickProduct: () => _pickLinkedProduct(entry.value),
                        onScanWithCamera: () =>
                            _scanLinkedProductWithCamera(entry.value),
                        onRemove: () => _removeLinkedLine(entry.value),
                      ),
                    );
                  })
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
    required this.isFreshEntry,
    required this.line,
    required this.isReadyForScanning,
    required this.canRemove,
    required this.onPickProduct,
    required this.onScanWithCamera,
    required this.onRemove,
  });

  final int lineNumber;
  final bool isFreshEntry;
  final _ManualShipmentLineDraft line;
  final bool isReadyForScanning;
  final bool canRemove;
  final VoidCallback onPickProduct;
  final VoidCallback onScanWithCamera;
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
                  isFreshEntry ? 'Giris satiri' : 'Satir $lineNumber',
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
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: ProductLookupField(
                    controller: line.barcodeController,
                    focusNode: line.barcodeFocusNode,
                    enabled: isReadyForScanning && !line.isLookupStatusLoading,
                    onSubmit: onPickProduct,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: isReadyForScanning && !line.isLookupStatusLoading
                      ? onPickProduct
                      : null,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Urun'),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: isReadyForScanning && !line.isLookupStatusLoading
                      ? onScanWithCamera
                      : null,
                  tooltip: 'Kamera ile oku',
                  icon: const Icon(Icons.photo_camera_back_rounded),
                ),
              ],
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
          if (product != null)
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
              if (isFreshEntry) {
                return null;
              }

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

class _LinkedShipmentLineCard extends StatelessWidget {
  const _LinkedShipmentLineCard({
    required this.lineNumber,
    required this.isFreshEntry,
    required this.line,
    required this.isReadyForScanning,
    required this.canRemove,
    required this.onPickProduct,
    required this.onScanWithCamera,
    required this.onRemove,
  });

  final int lineNumber;
  final bool isFreshEntry;
  final _LinkedShipmentLineDraft line;
  final bool isReadyForScanning;
  final bool canRemove;
  final VoidCallback onPickProduct;
  final VoidCallback onScanWithCamera;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = line.selectedProduct;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(84),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  isFreshEntry ? 'Giris satiri' : 'Satir $lineNumber',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (line.isOrderLinked)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: _InfoPill(label: 'Bagli', value: 'Siparis'),
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
          if (isFreshEntry)
            Row(
              children: <Widget>[
                Expanded(
                  child: ProductLookupField(
                    controller: line.barcodeController,
                    focusNode: line.barcodeFocusNode,
                    enabled: isReadyForScanning && !line.isLookupStatusLoading,
                    onSubmit: onPickProduct,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: isReadyForScanning && !line.isLookupStatusLoading
                      ? onPickProduct
                      : null,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Urun'),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: isReadyForScanning && !line.isLookupStatusLoading
                      ? onScanWithCamera
                      : null,
                  tooltip: 'Kamera ile oku',
                  icon: const Icon(Icons.photo_camera_back_rounded),
                ),
              ],
            )
          else ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${line.stockName} | Kod ${line.stockCode} | Birim ${line.unitName}${product?.barcode.trim().isNotEmpty == true ? ' | Barkod ${product!.barcode}' : ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF2A211B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (line.isOrderLinked) ...<Widget>[
                  _InfoPill(
                    label: 'Sip. miktar',
                    value: AppFormatters.quantity(line.orderQuantity),
                  ),
                  _InfoPill(
                    label: 'Kalan',
                    value: AppFormatters.quantity(line.maxQuantity),
                  ),
                ],
                SizedBox(
                  width: 150,
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
                      if (line.isOrderLinked && parsed > line.maxQuantity) {
                        return 'Kalan asildi';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
          if (line.lookupStatusMessage != null) ...<Widget>[
            const SizedBox(height: 8),
            if (line.isLookupStatusLoading)
              TerminalMessageBlock.loading(message: line.lookupStatusMessage!)
            else if (line.isLookupStatusError)
              TerminalMessageBlock.error(message: line.lookupStatusMessage!)
            else
              TerminalMessageBlock.info(message: line.lookupStatusMessage!),
          ],
          if (!isFreshEntry &&
              !line.isOrderLinked &&
              product == null) ...<Widget>[
            const SizedBox(height: 8),
            TerminalMessageBlock.error(message: 'Bu satir icin urun secin.'),
          ],
        ],
      ),
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
    required this.mobileWarehouseCatalogRepository,
  });

  final OutgoingWarehouseShipmentsRepository repository;
  final String accessToken;
  final MobileWarehouseCatalogLocalRepository mobileWarehouseCatalogRepository;

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
        _errorMessage = error.toString();
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
    required this.initialQuery,
  });

  final OutgoingWarehouseShipmentsRepository repository;
  final String accessToken;
  final String warehouseNo;
  final String initialQuery;

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
    _queryController = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
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
  _ManualShipmentLineDraft({Map<String, dynamic>? draft, this.onChanged})
    : stockCodeController = TextEditingController(),
      barcodeController = TextEditingController(),
      quantityController = TextEditingController() {
    if (draft != null) {
      stockCodeController.text = draft['stockCode']?.toString() ?? '';
      barcodeController.text = draft['barcode']?.toString() ?? '';
      quantityController.text = draft['quantity']?.toString() ?? '';
      final productJson = _shipmentDraftMap(draft['selectedProduct']);
      if (productJson != null) {
        selectedProduct = ProductLookupItem.fromJson(productJson);
      }
    }
    for (final controller in _controllers) {
      controller.addListener(_notifyChanged);
    }
  }

  final TextEditingController stockCodeController;
  final TextEditingController barcodeController;
  final TextEditingController quantityController;
  final FocusNode barcodeFocusNode = FocusNode();
  final VoidCallback? onChanged;
  ProductLookupItem? selectedProduct;
  String? lookupStatusMessage;
  bool isLookupStatusLoading = false;
  bool isLookupStatusError = false;

  List<TextEditingController> get _controllers => <TextEditingController>[
    stockCodeController,
    barcodeController,
    quantityController,
  ];

  bool get hasContent =>
      selectedProduct != null ||
      stockCodeController.text.trim().isNotEmpty ||
      barcodeController.text.trim().isNotEmpty ||
      quantityController.text.trim().isNotEmpty;

  void applyProduct(ProductLookupItem product) {
    selectedProduct = product;
    stockCodeController.text = product.stockCode;
    barcodeController.text = product.barcode;
    if (quantityController.text.trim().isEmpty) {
      quantityController.text = productEntryController.formatQuantity(
        productEntryController.unitMultiplierQuantity(product.unitMultiplier),
      );
    }
  }

  void clear() {
    barcodeFocusNode.unfocus();
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
    barcodeFocusNode.dispose();
    stockCodeController.dispose();
    barcodeController.dispose();
    quantityController.dispose();
  }

  Map<String, dynamic> toDraftJson() {
    return <String, dynamic>{
      'stockCode': stockCodeController.text,
      'barcode': barcodeController.text,
      'quantity': quantityController.text,
      'selectedProduct': selectedProduct == null
          ? null
          : _shipmentProductJson(selectedProduct!),
    };
  }

  void _notifyChanged() => onChanged?.call();
}

class _LinkedShipmentLineDraft {
  _LinkedShipmentLineDraft({
    required this.lineGuid,
    required String stockCode,
    required String stockName,
    required String unitName,
    required this.unitPointer,
    required this.orderQuantity,
    required this.maxQuantity,
    required this.unitPrice,
    required this.description,
    required this.partyCode,
    required this.lotNo,
    required this.projectCode,
    required this.warehouseOrderNo,
    this.selectedProduct,
    this.onChanged,
  }) : stockCodeController = TextEditingController(text: stockCode),
       barcodeController = TextEditingController(
         text: selectedProduct?.barcode ?? '',
       ),
       stockNameController = TextEditingController(text: stockName),
       unitNameController = TextEditingController(text: unitName),
       quantityController = TextEditingController(
         text: maxQuantity > 0 ? '$maxQuantity' : '',
       ) {
    for (final controller in _controllers) {
      controller.addListener(_notifyChanged);
    }
  }

  final String lineGuid;
  final TextEditingController stockCodeController;
  final TextEditingController barcodeController;
  final TextEditingController stockNameController;
  final TextEditingController unitNameController;
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
  final FocusNode barcodeFocusNode = FocusNode();
  final VoidCallback? onChanged;
  ProductLookupItem? selectedProduct;

  String get stockCode => stockCodeController.text;
  String get stockName => stockNameController.text;
  String get unitName => unitNameController.text;
  bool get isOrderLinked => lineGuid.trim().isNotEmpty;
  bool get hasContent =>
      isOrderLinked ||
      selectedProduct != null ||
      stockCodeController.text.trim().isNotEmpty ||
      barcodeController.text.trim().isNotEmpty ||
      quantityController.text.trim().isNotEmpty;
  bool get isLookupStatusLoading => _isLookupStatusLoading;
  bool get isLookupStatusError => _isLookupStatusError;
  String? get lookupStatusMessage => _lookupStatusMessage;

  String? _lookupStatusMessage;
  bool _isLookupStatusLoading = false;
  bool _isLookupStatusError = false;

  List<TextEditingController> get _controllers => <TextEditingController>[
    stockCodeController,
    barcodeController,
    stockNameController,
    unitNameController,
    quantityController,
  ];

  factory _LinkedShipmentLineDraft.empty({VoidCallback? onChanged}) {
    return _LinkedShipmentLineDraft(
      lineGuid: '',
      stockCode: '',
      stockName: '',
      unitName: '',
      unitPointer: 1,
      orderQuantity: 0,
      maxQuantity: 0,
      unitPrice: 0,
      description: '',
      partyCode: '',
      lotNo: 0,
      projectCode: '',
      warehouseOrderNo: '',
      onChanged: onChanged,
    );
  }

  factory _LinkedShipmentLineDraft.fromOrderItem(
    WarehouseOrderDetailItem item, {
    VoidCallback? onChanged,
  }) {
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
      onChanged: onChanged,
    );
  }

  factory _LinkedShipmentLineDraft.fromDraftJson(
    Map<String, dynamic> json, {
    VoidCallback? onChanged,
  }) {
    final productJson = _shipmentDraftMap(json['selectedProduct']);
    final selectedProduct = productJson == null
        ? null
        : ProductLookupItem.fromJson(productJson);
    final draft = _LinkedShipmentLineDraft(
      lineGuid: json['lineGuid']?.toString() ?? '',
      stockCode: json['stockCode']?.toString() ?? '',
      stockName: json['stockName']?.toString() ?? '',
      unitName: json['unitName']?.toString() ?? '',
      unitPointer: int.tryParse(json['unitPointer']?.toString() ?? '') ?? 1,
      orderQuantity:
          double.tryParse(json['orderQuantity']?.toString() ?? '') ?? 0,
      maxQuantity: double.tryParse(json['maxQuantity']?.toString() ?? '') ?? 0,
      unitPrice: double.tryParse(json['unitPrice']?.toString() ?? '') ?? 0,
      description: json['description']?.toString() ?? '',
      partyCode: json['partyCode']?.toString() ?? '',
      lotNo: int.tryParse(json['lotNo']?.toString() ?? '') ?? 0,
      projectCode: json['projectCode']?.toString() ?? '',
      warehouseOrderNo: json['warehouseOrderNo']?.toString() ?? '',
      selectedProduct: selectedProduct,
      onChanged: onChanged,
    );
    draft.barcodeController.text = json['barcode']?.toString() ?? '';
    draft.quantityController.text = json['quantity']?.toString() ?? '';
    return draft;
  }

  void applyProduct(ProductLookupItem product) {
    selectedProduct = product;
    stockCodeController.text = product.stockCode;
    barcodeController.text = product.barcode;
    stockNameController.text = product.stockName;
    unitNameController.text = product.unitName;
    if (quantityController.text.trim().isEmpty) {
      quantityController.text = productEntryController.formatQuantity(
        productEntryController.unitMultiplierQuantity(product.unitMultiplier),
      );
    }
  }

  void clear() {
    barcodeFocusNode.unfocus();
    stockCodeController.clear();
    barcodeController.clear();
    stockNameController.clear();
    unitNameController.clear();
    quantityController.clear();
    selectedProduct = null;
    _lookupStatusMessage = null;
    _isLookupStatusLoading = false;
    _isLookupStatusError = false;
  }

  void setLookupStatus(
    String message, {
    bool isLoading = false,
    bool isError = false,
  }) {
    _lookupStatusMessage = message;
    _isLookupStatusLoading = isLoading;
    _isLookupStatusError = isError;
  }

  void dispose() {
    barcodeFocusNode.dispose();
    stockCodeController.dispose();
    barcodeController.dispose();
    stockNameController.dispose();
    unitNameController.dispose();
    quantityController.dispose();
  }

  Map<String, dynamic> toDraftJson() {
    return <String, dynamic>{
      'lineGuid': lineGuid,
      'stockCode': stockCode,
      'barcode': barcodeController.text,
      'stockName': stockName,
      'unitName': unitName,
      'unitPointer': unitPointer,
      'orderQuantity': orderQuantity,
      'maxQuantity': maxQuantity,
      'unitPrice': unitPrice,
      'description': description,
      'partyCode': partyCode,
      'lotNo': lotNo,
      'projectCode': projectCode,
      'warehouseOrderNo': warehouseOrderNo,
      'quantity': quantityController.text,
      'selectedProduct': selectedProduct == null
          ? null
          : _shipmentProductJson(selectedProduct!),
    };
  }

  void _notifyChanged() => onChanged?.call();
}

class _SelectedWarehouseOrder {
  const _SelectedWarehouseOrder({required this.item, required this.detail});

  final WarehouseOrderListItem item;
  final WarehouseOrderDetail detail;

  factory _SelectedWarehouseOrder.fromDraftJson(Map<String, dynamic> json) {
    final itemJson = _shipmentDraftMap(json['item']) ?? <String, dynamic>{};
    final detailJson = _shipmentDraftMap(json['detail']) ?? <String, dynamic>{};
    return _SelectedWarehouseOrder(
      item: WarehouseOrderListItem.fromJson(itemJson),
      detail: WarehouseOrderDetail.fromJson(detailJson),
    );
  }

  Map<String, dynamic> toDraftJson() {
    return <String, dynamic>{
      'item': _warehouseOrderItemJson(item),
      'detail': _warehouseOrderDetailJson(detail),
    };
  }
}

Map<String, dynamic>? _shipmentDraftMap(Object? value) {
  return switch (value) {
    final Map<String, dynamic> map => Map<String, dynamic>.from(map),
    final Map map => map.map((key, item) => MapEntry(key.toString(), item)),
    _ => null,
  };
}

Map<String, dynamic> _shipmentWarehouseJson(WarehouseLookupItem item) {
  return <String, dynamic>{
    'warehouseNo': item.warehouseNo,
    'warehouseName': item.warehouseName,
    'address': item.address,
    'district': item.district,
    'province': item.province,
  };
}

Map<String, dynamic> _shipmentProductJson(ProductLookupItem item) {
  return <String, dynamic>{
    'warehouseNo': item.warehouseNo,
    'barcode': item.barcode,
    'stockCode': item.stockCode,
    'stockName': item.stockName,
    'price': item.price,
    'unitName': item.unitName,
    'unitMultiplier': item.unitMultiplier,
    'isOrderBlocked': item.isOrderBlocked,
  };
}

Map<String, dynamic> _warehouseOrderItemJson(WarehouseOrderListItem item) {
  return <String, dynamic>{
    'documentKey': item.documentKey,
    'documentDate': item.documentDate?.toIso8601String(),
    'documentSerie': item.documentSerie,
    'documentOrderNo': item.documentOrderNo,
    'documentNumber': item.documentNumber,
    'warehouseNo': item.warehouseNo,
    'warehouseName': item.warehouseName,
    'relatedWarehouseNo': item.relatedWarehouseNo,
    'relatedWarehouseName': item.relatedWarehouseName,
    'inWarehouseNo': item.inWarehouseNo,
    'inWarehouseName': item.inWarehouseName,
    'outWarehouseNo': item.outWarehouseNo,
    'outWarehouseName': item.outWarehouseName,
    'lineCount': item.lineCount,
    'totalQuantity': item.totalQuantity,
    'totalAmount': item.totalAmount,
    'deliveryDate': item.deliveryDate?.toIso8601String(),
  };
}

Map<String, dynamic> _warehouseOrderDetailJson(WarehouseOrderDetail detail) {
  return <String, dynamic>{
    'header': _warehouseOrderHeaderJson(detail.header),
    'items': detail.items.map(_warehouseOrderDetailItemJson).toList(),
  };
}

Map<String, dynamic> _warehouseOrderHeaderJson(
  WarehouseOrderDetailHeader item,
) {
  return <String, dynamic>{
    'documentKey': item.documentKey,
    'documentDate': item.documentDate?.toIso8601String(),
    'deliveryDate': item.deliveryDate?.toIso8601String(),
    'documentSerie': item.documentSerie,
    'documentOrderNo': item.documentOrderNo,
    'documentNumber': item.documentNumber,
    'warehouseNo': item.warehouseNo,
    'warehouseName': item.warehouseName,
    'relatedWarehouseNo': item.relatedWarehouseNo,
    'relatedWarehouseName': item.relatedWarehouseName,
    'inWarehouseNo': item.inWarehouseNo,
    'inWarehouseName': item.inWarehouseName,
    'outWarehouseNo': item.outWarehouseNo,
    'outWarehouseName': item.outWarehouseName,
    'lineCount': item.lineCount,
    'totalQuantity': item.totalQuantity,
    'totalDeliveredQuantity': item.totalDeliveredQuantity,
    'totalRemainingQuantity': item.totalRemainingQuantity,
    'totalAmount': item.totalAmount,
    'isClosed': item.isClosed,
  };
}

Map<String, dynamic> _warehouseOrderDetailItemJson(
  WarehouseOrderDetailItem item,
) {
  return <String, dynamic>{
    'lineNo': item.lineNo,
    'stockCode': item.stockCode,
    'stockName': item.stockName,
    'unitName': item.unitName,
    'unitPointer': item.unitPointer,
    'quantity': item.quantity,
    'deliveredQuantity': item.deliveredQuantity,
    'remainingQuantity': item.remainingQuantity,
    'unitPrice': item.unitPrice,
    'lineAmount': item.lineAmount,
    'isClosed': item.isClosed,
    'description': item.description,
    'packageCode': item.packageCode,
    'projectCode': item.projectCode,
    'lineGuid': item.lineGuid,
  };
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

class _ShipmentModeButton extends StatelessWidget {
  const _ShipmentModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected ? colorScheme.primaryContainer : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 40,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    icon,
                    size: 16,
                    color: selected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
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
