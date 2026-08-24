import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/inventory_counts/data/models/inventory_count_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/data/models/offline_inventory_count_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/offline_inventory_counts/data/offline_inventory_counts_repository.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_product_catalog_repository.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_record_status.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_service.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_controller.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/utils/client_request_id.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/utils/terminal_feedback.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_create_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class OfflineInventoryCountsPage extends StatefulWidget {
  const OfflineInventoryCountsPage({
    super.key,
    required this.offlineRepository,
    required this.onlineRepository,
    required this.accessToken,
    required this.offlineSyncService,
    required this.mobileProductCatalogRepository,
    required this.currentUserId,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
    this.standalone = false,
  });

  final OfflineInventoryCountsRepository offlineRepository;
  final InventoryCountsRepository onlineRepository;
  final String accessToken;
  final OfflineSyncService offlineSyncService;
  final MobileProductCatalogLocalRepository mobileProductCatalogRepository;
  final String currentUserId;
  final String defaultWarehouseNo;
  final String userWarehouseName;
  final bool standalone;

  @override
  State<OfflineInventoryCountsPage> createState() =>
      _OfflineInventoryCountsPageState();
}

class _OfflineInventoryCountsPageState
    extends State<OfflineInventoryCountsPage> {
  List<OfflineInventoryCountDraft> _drafts =
      const <OfflineInventoryCountDraft>[];
  bool _isLoading = false;
  String? _errorMessage;
  Set<String> _syncingIds = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_loadDrafts());
  }

  Future<void> _loadDrafts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final drafts = await widget.offlineRepository.fetchDrafts(
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openCreateSheet() async {
    final draft = await openTerminalCreatePage<OfflineInventoryCountDraft>(
      context: context,
      title: 'Yeni Offline Sayim',
      builder: (context) {
        return _OfflineInventoryCountCreateSheet(
          onlineRepository: widget.onlineRepository,
          accessToken: widget.accessToken,
          currentUserId: widget.currentUserId,
          defaultWarehouseNo: widget.defaultWarehouseNo,
          mobileProductCatalogRepository: widget.mobileProductCatalogRepository,
        );
      },
    );

    if (draft == null) {
      return;
    }

    await widget.offlineRepository.saveDraft(draft);
    await _loadDrafts();
    unawaited(
      widget.offlineSyncService.syncPending(
        accessToken: widget.accessToken,
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
      ),
    );
  }

  Future<void> _deleteDraft(String id) async {
    await widget.offlineRepository.deleteDraft(id);
    await _loadDrafts();
  }

  Future<void> _syncDraft(OfflineInventoryCountDraft draft) async {
    setState(() {
      _syncingIds = <String>{..._syncingIds, draft.id};
      _errorMessage = null;
    });

    try {
      final result = await widget.offlineSyncService.syncInventoryDraft(
        accessToken: widget.accessToken,
        draft: draft,
      );
      await _loadDrafts();

      if (!mounted) {
        return;
      }

      final message = switch (result.status) {
        OfflineDraftSyncResultStatus.synced =>
          '${draft.name.isEmpty ? 'Offline sayim' : draft.name} sunucuya aktarildi.',
        OfflineDraftSyncResultStatus.processing =>
          result.message ?? 'Kayit arka planda isleniyor.',
        OfflineDraftSyncResultStatus.deferred =>
          result.message ??
              'Baglanti yok; kayit kuyrukta beklemeye devam ediyor.',
        OfflineDraftSyncResultStatus.failed =>
          result.message ?? 'Kayit senkronize edilemedi.',
      };

      if (result.status == OfflineDraftSyncResultStatus.failed) {
        unawaited(TerminalFeedback.error());
        setState(() {
          _errorMessage = message;
        });
      } else {
        unawaited(
          result.status == OfflineDraftSyncResultStatus.deferred
              ? TerminalFeedback.warning()
              : TerminalFeedback.success(),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _syncingIds = _syncingIds.where((item) => item != draft.id).toSet();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
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
            TerminalListHeaderCard(
              title: 'Offline Sayim',
              subtitle:
                  'Baglanti olmasa bile taslak kayit alir. Ag geri geldiginde ayni ekrandan senkronize edilir.',
              infoChips: <Widget>[
                TerminalInfoChip(
                  label: 'Varsayilan depo',
                  value:
                      '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
                ),
                TerminalInfoChip(
                  label: 'Bekleyen taslak',
                  value: '${_drafts.length}',
                ),
              ],
              filters: const <Widget>[],
              actions: <Widget>[
                FilledButton.icon(
                  onPressed: _openCreateSheet,
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Yeni Offline Sayim'),
                ),
                OutlinedButton.icon(
                  onPressed: _loadDrafts,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Listeyi Yenile'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Taslaklar',
              subtitle: _isLoading
                  ? 'Yukleniyor...'
                  : '${_drafts.length} taslak bulundu.',
              child: Column(
                children: <Widget>[
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TerminalMessageBlock.error(
                        message: _errorMessage!,
                      ),
                    ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: CircularProgressIndicator(),
                    )
                  else if (_drafts.isEmpty)
                    const TerminalEmptyState(
                      message: 'Bekleyen offline sayim taslagi bulunamadi.',
                    )
                  else
                    ..._drafts.map((draft) {
                      final isSyncing =
                          _syncingIds.contains(draft.id) ||
                          draft.status == OfflineRecordStatus.syncing;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TerminalPdaDetailPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              TerminalTitleBadgeRow(
                                title: draft.name.isEmpty
                                    ? 'Adsiz Sayim Taslagi'
                                    : draft.name,
                                badges: <Widget>[
                                  TerminalBadge(
                                    label: offlineRecordStatusLabel(
                                      draft.status,
                                    ),
                                  ),
                                  TerminalBadge(
                                    label: '${draft.lines.length} satir',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TerminalPdaInfoGrid(
                                items: <TerminalPdaInfo>[
                                  TerminalPdaInfo(
                                    label: 'Belge Trh',
                                    value: AppFormatters.date(
                                      draft.documentDate,
                                    ),
                                  ),
                                  TerminalPdaInfo(
                                    label: 'Olusturma',
                                    value: AppFormatters.dateTime(
                                      draft.createdAt,
                                    ),
                                  ),
                                  if (draft.lastSyncAttemptAt != null)
                                    TerminalPdaInfo(
                                      label: 'Son deneme',
                                      value: AppFormatters.dateTime(
                                        draft.lastSyncAttemptAt!,
                                      ),
                                    ),
                                ],
                              ),
                              if ((draft.lastError ?? '')
                                  .trim()
                                  .isNotEmpty) ...<Widget>[
                                const SizedBox(height: 8),
                                TerminalMessageBlock.error(
                                  message: draft.lastError!,
                                ),
                              ],
                              const SizedBox(height: 12),
                              ...draft.lines.take(5).map((line) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: TerminalPdaDetailPanel(
                                    child: TerminalPdaInfoGrid(
                                      items: <TerminalPdaInfo>[
                                        TerminalPdaInfo(
                                          label: 'Kod',
                                          value: line.stockCode,
                                        ),
                                        TerminalPdaInfo(
                                          label: 'Urun',
                                          value: line.stockName.isEmpty
                                              ? '-'
                                              : line.stockName,
                                        ),
                                        TerminalPdaInfo(
                                          label: 'Miktar',
                                          value: AppFormatters.quantity(
                                            line.quantity,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              if (draft.lines.length > 5)
                                Text('+ ${draft.lines.length - 5} satir daha'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: <Widget>[
                                  FilledButton.icon(
                                    onPressed: isSyncing
                                        ? null
                                        : () => _syncDraft(draft),
                                    icon: isSyncing
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.cloud_upload_rounded,
                                          ),
                                    label: Text(
                                      isSyncing
                                          ? 'Gonderiliyor...'
                                          : 'Senkronize Et',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: isSyncing
                                        ? null
                                        : () => _deleteDraft(draft.id),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                    label: const Text('Sil'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.standalone) {
      return content;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Offline Sayim')),
      body: content,
    );
  }
}

class _OfflineInventoryCountCreateSheet extends StatefulWidget {
  const _OfflineInventoryCountCreateSheet({
    required this.onlineRepository,
    required this.accessToken,
    required this.currentUserId,
    required this.defaultWarehouseNo,
    required this.mobileProductCatalogRepository,
  });

  final InventoryCountsRepository onlineRepository;
  final String accessToken;
  final String currentUserId;
  final String defaultWarehouseNo;
  final MobileProductCatalogLocalRepository mobileProductCatalogRepository;

  @override
  State<_OfflineInventoryCountCreateSheet> createState() =>
      _OfflineInventoryCountCreateSheetState();
}

class _OfflineInventoryCountCreateSheetState
    extends State<_OfflineInventoryCountCreateSheet>
    with CreateFormValidation {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final List<_OfflineLineDraft> _lines = <_OfflineLineDraft>[];
  DateTime _documentDate = DateTime.now();
  String? _errorMessage;
  String? _lastAddedProductKey;

  @override
  void initState() {
    super.initState();
    _lines.add(_OfflineLineDraft());
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _documentDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _documentDate = pickedDate;
    });
  }

  Future<void> _searchProduct(_OfflineLineDraft line) async {
    final query = line.lookupController.text.trim();

    if (query.length < 2) {
      unawaited(TerminalFeedback.warning());
      setState(() {
        _errorMessage = 'Online urun aramak icin en az 2 karakter girilmeli.';
      });
      _refocusLine(line.lookupFocusNode);
      return;
    }

    final products = await _searchProductsWithCatalogFallback(query);

    if (!mounted) {
      return;
    }

    if (products.isEmpty) {
      unawaited(TerminalFeedback.warning());
      setState(() {
        _errorMessage = 'Bu aramaya uygun urun bulunamadi.';
      });
      _showFeedback('Bu aramaya uygun urun bulunamadi.');
      _refocusLine(line.lookupFocusNode);
      return;
    }

    InventoryCountProductLookupItem? selected;
    if (products.length == 1) {
      selected = products.single;
    } else {
      selected = await showModalBottomSheet<InventoryCountProductLookupItem>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.82,
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = products[index];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  title: Text(
                    item.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    item.barcode.isEmpty ? '-' : item.barcode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(context).pop(item),
                );
              },
            ),
          );
        },
      );
    }

    if (selected == null) {
      _refocusLine(line.lookupFocusNode);
      return;
    }
    final pickedProduct = selected;

    if (_increasePendingQuantityIfSameProduct(line, pickedProduct)) {
      _refocusLine(line.lookupFocusNode);
      return;
    }

    final entryLine = await _commitPendingEntryBeforeNextProduct(line);
    if (entryLine == null) {
      return;
    }

    setState(() {
      entryLine.applyLookup(pickedProduct);
      entryLine.lookupController.clear();
      _errorMessage = null;
    });
    unawaited(TerminalFeedback.success());
    _refocusLine(entryLine.lookupFocusNode);
  }

  Future<List<InventoryCountProductLookupItem>>
  _searchProductsWithCatalogFallback(String query) async {
    try {
      return await widget.onlineRepository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        query: query,
      );
    } on ApiException {
      final catalogItems = await widget.mobileProductCatalogRepository
          .searchProducts(warehouseNo: widget.defaultWarehouseNo, query: query);
      if (catalogItems.isNotEmpty) {
        return catalogItems
            .map((item) => item.toInventoryCountProductLookupItem())
            .toList(growable: false);
      }
      rethrow;
    }
  }

  Future<void> _scanProductWithCamera(_OfflineLineDraft line) async {
    if (!supportsCameraBarcodeScanning) {
      unawaited(TerminalFeedback.warning());
      setState(() {
        _errorMessage = 'Bu cihazda kamera ile barkod okutma desteklenmiyor.';
      });
      _refocusLine(line.lookupFocusNode);
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Offline Sayim Kamerasi',
      subtitle: 'Barkodu okutun; bulunan deger urun aramasina aktarilacak.',
    );

    if (barcode == null) {
      _refocusLine(line.lookupFocusNode);
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      line.lookupController.text = barcode;
      _errorMessage = null;
    });

    await _searchProduct(line);
  }

  bool _applyProductToLine(
    _OfflineLineDraft line,
    InventoryCountProductLookupItem product,
  ) {
    final existingLine = _findDuplicateLine(
      currentLine: line,
      barcode: product.barcode,
      stockCode: product.stockCode,
    );

    if (existingLine == null) {
      line.applyLookup(product);
      return false;
    }

    existingLine.quantityController.text = productEntryController
        .mergedQuantityText(
          existingQuantityText: existingLine.quantityController.text,
          incomingQuantityText: line.quantityController.text,
          unitMultiplier: product.unitMultiplier,
        );
    _recycleMergedLine(line);
    return true;
  }

  _OfflineLineDraft? _findDuplicateLine({
    required _OfflineLineDraft currentLine,
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

      final candidateKey = _productIdentity(
        barcode: candidate.barcodeController.text,
        stockCode: candidate.stockCodeController.text,
      );
      if (candidateKey == targetKey) {
        return candidate;
      }
    }

    return null;
  }

  void _recycleMergedLine(_OfflineLineDraft line) {
    final lineIndex = _lines.indexOf(line);
    line.dispose();

    if (lineIndex == 0) {
      _lines[lineIndex] = _OfflineLineDraft();
      return;
    }

    _lines.removeAt(lineIndex);
  }

  void _ensureFreshEntryLine() {
    if (_lines.isEmpty || !_isBlankLine(_lines.first)) {
      _lines.insert(0, _OfflineLineDraft());
    }
  }

  void _focusFreshEntryLine() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lines.isEmpty) {
        return;
      }

      final firstLine = _lines.first;
      if (_isBlankLine(firstLine)) {
        firstLine.lookupFocusNode.requestFocus();
      }
    });
  }

  void _refocusLine(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focusNode.requestFocus();
      }
    });
  }

  bool _isBlankLine(_OfflineLineDraft line) {
    return line.stockCodeController.text.trim().isEmpty;
  }

  bool _increasePendingQuantityIfSameProduct(
    _OfflineLineDraft line,
    InventoryCountProductLookupItem product,
  ) {
    if (!_isSameProduct(line, product)) {
      return false;
    }

    final increment = _unitMultiplierQuantity(product.unitMultiplier);
    setState(() {
      line.quantityController.text = _formatQuantity(line.quantity + increment);
      line.lookupController.clear();
      _errorMessage = null;
    });
    unawaited(TerminalFeedback.success());
    return true;
  }

  Future<_OfflineLineDraft?> _commitPendingEntryBeforeNextProduct(
    _OfflineLineDraft line,
  ) async {
    if (_isBlankLine(line)) {
      return line;
    }

    await _commitEntryLine(line);
    if (!mounted || _lines.isEmpty) {
      return null;
    }

    final entryLine = _lines.first;
    if (identical(entryLine, line) && !_isBlankLine(entryLine)) {
      return null;
    }

    return entryLine;
  }

  bool _isSameProduct(
    _OfflineLineDraft line,
    InventoryCountProductLookupItem product,
  ) {
    return productEntryController.isSameProduct(
      firstStockCode: line.stockCodeController.text,
      firstBarcode: line.barcodeController.text,
      secondStockCode: product.stockCode,
      secondBarcode: product.barcode,
    );
  }

  Future<bool> _confirmDuplicateIncrease(
    _OfflineLineDraft line,
    InventoryCountProductLookupItem product,
  ) async {
    final existingLine = _findDuplicateLine(
      currentLine: line,
      barcode: product.barcode,
      stockCode: product.stockCode,
    );
    final key = _productIdentity(
      barcode: product.barcode,
      stockCode: product.stockCode,
    );
    if (existingLine == null ||
        key == null ||
        !productEntryController.shouldConfirmDuplicateIncrease(
          existingQuantityText: existingLine.quantityController.text,
          productKey: key,
          lastAddedProductKey: _lastAddedProductKey,
        )) {
      return true;
    }

    unawaited(TerminalFeedback.warning());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Urun listede var'),
          content: Text(
            '${product.stockName} daha once eklenmis. Miktar artirilsin mi?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgec'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Artir'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  void _rememberAddedProduct(InventoryCountProductLookupItem product) {
    final key = _productIdentity(
      barcode: product.barcode,
      stockCode: product.stockCode,
    );
    if (key != null) {
      _lastAddedProductKey = key;
    }
  }

  bool get _hasPendingEntryLine =>
      _lines.isNotEmpty && !_isBlankLine(_lines.first);

  Future<void> _commitEntryLine(_OfflineLineDraft line) async {
    if (_isBlankLine(line)) {
      _refocusLine(line.lookupFocusNode);
      return;
    }

    if (line.quantity <= 0) {
      unawaited(TerminalFeedback.warning());
      setState(() {
        _errorMessage = 'Miktar sifirdan buyuk olmali.';
      });
      return;
    }

    final product = _productFromLine(line);
    if (!await _confirmDuplicateIncrease(line, product)) {
      return;
    }

    var mergedIntoExisting = false;
    setState(() {
      mergedIntoExisting = _applyProductToLine(line, product);
      _ensureFreshEntryLine();
      _errorMessage = null;
    });
    _focusFreshEntryLine();
    _rememberAddedProduct(product);
    unawaited(TerminalFeedback.success());
    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  void _cancelPendingEntryLine(_OfflineLineDraft line) {
    setState(() {
      line.clear();
      _errorMessage = null;
    });
    _refocusLine(line.lookupFocusNode);
  }

  List<_OfflineLineDraft> _committedLines() {
    return <_OfflineLineDraft>[
      for (var index = 0; index < _lines.length; index++)
        if (index != 0 && !_isBlankLine(_lines[index])) _lines[index],
    ];
  }

  InventoryCountProductLookupItem _productFromLine(_OfflineLineDraft line) {
    return InventoryCountProductLookupItem(
      stockCode: line.stockCodeController.text.trim(),
      stockName: line.stockNameController.text.trim(),
      barcode: line.barcodeController.text.trim(),
      unitName: 'Birim ${line.unitPointer}',
      unitMultiplier: line.unitMultiplier,
      warehouseNo: int.tryParse(widget.defaultWarehouseNo) ?? 0,
      price: 0,
      isGoodsAcceptanceBlocked: false,
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

  void _submit() {
    final form = _formKey.currentState;

    if (form == null || !validateCreateForm(_formKey)) {
      return;
    }

    if (_hasPendingEntryLine) {
      unawaited(TerminalFeedback.warning());
      setState(() {
        _errorMessage = 'Secilen urunu once Kaleme Ekle ile listeye alin.';
      });
      return;
    }

    final activeLines = _committedLines();

    if (activeLines.isEmpty) {
      unawaited(TerminalFeedback.warning());
      setState(() {
        _errorMessage = 'En az bir urun satiri ekleyin.';
      });
      return;
    }

    unawaited(TerminalFeedback.success());
    Navigator.of(context).pop(
      OfflineInventoryCountDraft(
        id: generateClientRequestId(),
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        name: _nameController.text.trim(),
        documentDate: _documentDate,
        createdAt: DateTime.now(),
        status: OfflineRecordStatus.pending,
        lastSyncAttemptAt: null,
        lastError: null,
        lines: activeLines
            .map(
              (line) => OfflineInventoryCountLine(
                stockCode: line.stockCodeController.text.trim(),
                stockName: line.stockNameController.text.trim(),
                barcode: line.barcodeController.text.trim(),
                quantity: line.quantity,
                unitPointer: line.unitPointer,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
        child: Form(
          key: _formKey,
          autovalidateMode: createFormAutovalidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TerminalSheetHeader(
                title: 'Yeni Offline Sayim',
                badges: <Widget>[
                  TerminalLineCountBadge(count: _filledLineIndexes().length),
                ],
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 4),
              TerminalCreateInputDock(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final nameField = TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Sayim Adi',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Sayim adi zorunludur.';
                          }
                          return null;
                        },
                      );
                      final dateButton = TerminalFilterButton(
                        label: 'Belge Tarihi',
                        value: AppFormatters.date(_documentDate),
                        onPressed: _pickDate,
                      );

                      if (constraints.maxWidth < 300) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            nameField,
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: dateButton,
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: nameField),
                          const SizedBox(width: 6),
                          dateButton,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  TerminalSectionToolbar(
                    title: 'Satirlar',
                    actions: const <Widget>[],
                  ),
                  const SizedBox(height: 4),
                  _buildEntryLineCard(),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: CustomScrollView(
                  slivers: <Widget>[
                    _buildLazyLineSliver(),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (_errorMessage != null) ...<Widget>[
                            const SizedBox(height: 12),
                            TerminalMessageBlock.error(message: _errorMessage!),
                          ],
                          const SizedBox(height: 12),
                          TerminalFormActionRow(
                            cancel: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Vazgec'),
                            ),
                            submit: FilledButton.icon(
                              onPressed: _submit,
                              icon: const Icon(Icons.save_alt_rounded),
                              label: const Text('Taslagi Kaydet'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryLineCard() {
    return _buildLineCard(0);
  }

  Widget _buildLazyLineSliver() {
    final indexes = _filledLineIndexes();
    if (indexes.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, visibleIndex) {
        final index = indexes[visibleIndex];
        return _buildLineCard(index);
      }, childCount: indexes.length),
    );
  }

  List<int> _filledLineIndexes() {
    return <int>[
      for (var index = 0; index < _lines.length; index++)
        if (index != 0 && !_isBlankLine(_lines[index])) index,
    ];
  }

  Widget _buildLineCard(int index) {
    final line = _lines[index];
    final isEntrySlot = index == 0;
    final isFreshEntry = isEntrySlot && _isBlankLine(line);
    final isPendingEntry = isEntrySlot && !_isBlankLine(line);
    final displayLineNo = _lines
        .take(index + 1)
        .where((item) => _lines.indexOf(item) != 0 && !_isBlankLine(item))
        .length;

    if (isPendingEntry) {
      return ProductDraftEntryPanel(
        stockCode: line.stockCodeController.text.trim(),
        stockName: line.stockNameController.text.trim().isEmpty
            ? 'Urun secilmedi'
            : line.stockNameController.text.trim(),
        quantityController: line.quantityController,
        unitLabel: 'Birim ${line.unitPointer}',
        packageLabel: line.unitMultiplier > 1
            ? AppFormatters.quantity(line.unitMultiplier)
            : null,
        barcode: line.barcodeController.text.trim(),
        onConfirm: () => _commitEntryLine(line),
        onCancel: () => _cancelPendingEntryLine(line),
        scanRow: TerminalResponsiveLookupRow(
          field: TerminalSubmitOnTab(
            onSubmit: () => _searchProduct(line),
            child: TextField(
              controller: line.lookupController,
              focusNode: line.lookupFocusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchProduct(line),
              decoration: const InputDecoration(
                labelText: 'Barkod okut / urun degistir',
              ),
            ),
          ),
          action: FilledButton.icon(
            onPressed: () => _searchProduct(line),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Bul'),
          ),
          trailingAction: IconButton.filledTonal(
            onPressed: () => _scanProductWithCamera(line),
            tooltip: 'Kamera ile oku',
            icon: const Icon(Icons.photo_camera_back_rounded),
          ),
        ),
        quantityValidator: (_) {
          if (line.quantity <= 0) {
            return 'Miktar > 0';
          }
          return null;
        },
      );
    }

    if (!isFreshEntry) {
      return TerminalCompactProductLineCard(
        lineNo: displayLineNo,
        stockCode: line.stockCodeController.text.trim(),
        stockName: line.stockNameController.text.trim().isEmpty
            ? 'Urun secilmedi'
            : line.stockNameController.text.trim(),
        quantityController: line.quantityController,
        unitLabel: 'Birim ${line.unitPointer}',
        packageLabel: line.unitMultiplier > 1
            ? AppFormatters.quantity(line.unitMultiplier)
            : null,
        barcode: line.barcodeController.text.trim(),
        canDelete: _lines.length > 1,
        onDelete: _lines.length > 1 ? () => _removeLineAt(index) : null,
        onMinimumReached: _lines.length > 1 ? () => _removeLineAt(index) : null,
      );
    }

    return TerminalPdaLineCard(
      title: 'Giris satiri',
      subtitle: line.stockNameController.text.trim().isEmpty
          ? 'Okutmaya hazir'
          : line.stockNameController.text.trim(),
      isEntryLine: true,
      leading: Icon(
        Icons.qr_code_scanner_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TerminalResponsiveLookupRow(
            field: TerminalSubmitOnTab(
              onSubmit: () => _searchProduct(line),
              child: TextField(
                controller: line.lookupController,
                focusNode: line.lookupFocusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchProduct(line),
                decoration: const InputDecoration(labelText: 'Online urun ara'),
              ),
            ),
            action: FilledButton.icon(
              onPressed: () => _searchProduct(line),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Bul'),
            ),
            trailingAction: IconButton.filledTonal(
              onPressed: () => _scanProductWithCamera(line),
              tooltip: 'Kamera ile oku',
              icon: const Icon(Icons.photo_camera_back_rounded),
            ),
          ),
        ],
      ),
    );
  }

  void _removeLineAt(int index) {
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
      _ensureFreshEntryLine();
    });
  }
}

class _OfflineLineDraft {
  _OfflineLineDraft()
    : lookupController = TextEditingController(),
      stockCodeController = TextEditingController(),
      stockNameController = TextEditingController(),
      barcodeController = TextEditingController(),
      quantityController = TextEditingController(),
      unitPointerController = TextEditingController(text: '1'),
      unitMultiplierController = TextEditingController(text: '1');

  final TextEditingController lookupController;
  final TextEditingController stockCodeController;
  final TextEditingController stockNameController;
  final TextEditingController barcodeController;
  final TextEditingController quantityController;
  final TextEditingController unitPointerController;
  final TextEditingController unitMultiplierController;
  final FocusNode lookupFocusNode = FocusNode();

  double get quantity => _readDouble(quantityController.text, fallback: 0);
  int get unitPointer => _readInt(unitPointerController.text, fallback: 1);
  double get unitMultiplier =>
      _readDouble(unitMultiplierController.text, fallback: 1);

  void applyLookup(InventoryCountProductLookupItem product) {
    stockCodeController.text = product.stockCode;
    stockNameController.text = product.stockName;
    barcodeController.text = product.barcode;
    unitPointerController.text = '1';
    unitMultiplierController.text = _formatQuantity(
      _unitMultiplierQuantity(product.unitMultiplier),
    );
    lookupController.clear();
    if (quantityController.text.trim().isEmpty) {
      quantityController.text = _formatQuantity(
        _unitMultiplierQuantity(product.unitMultiplier),
      );
    }
  }

  void clear() {
    lookupController.clear();
    stockCodeController.clear();
    stockNameController.clear();
    barcodeController.clear();
    quantityController.clear();
    unitPointerController.text = '1';
    unitMultiplierController.text = '1';
  }

  void dispose() {
    lookupFocusNode.dispose();
    lookupController.dispose();
    stockCodeController.dispose();
    stockNameController.dispose();
    barcodeController.dispose();
    quantityController.dispose();
    unitPointerController.dispose();
    unitMultiplierController.dispose();
  }
}

String? _productIdentity({required String barcode, required String stockCode}) {
  return productEntryController.productIdentity(
    barcode: barcode,
    stockCode: stockCode,
  );
}

double _unitMultiplierQuantity(double unitMultiplier) {
  return productEntryController.unitMultiplierQuantity(unitMultiplier);
}

String _formatQuantity(double value) {
  final fixed = value.toStringAsFixed(6);
  final normalized = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  return normalized.replaceAll('.', ',');
}

double _readDouble(String value, {required double fallback}) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
}

int _readInt(String value, {required int fallback}) {
  return int.tryParse(value.trim()) ?? fallback;
}
