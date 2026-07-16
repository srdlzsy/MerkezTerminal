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

  Future<void> _searchProduct(
    _OfflineLineDraft line, {
    bool autoSelectSingle = false,
  }) async {
    final query = line.lookupController.text.trim();

    if (query.length < 2) {
      unawaited(TerminalFeedback.warning());
      setState(() {
        _errorMessage = 'Online urun aramak icin en az 2 karakter girilmeli.';
      });
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
      return;
    }

    InventoryCountProductLookupItem? selected;
    if (autoSelectSingle && products.length == 1) {
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

    var mergedIntoExisting = false;
    setState(() {
      mergedIntoExisting = _applyProductToLine(line, pickedProduct);
      _ensureFreshEntryLine();
      _errorMessage = null;
    });
    _focusFreshEntryLine();

    if (mergedIntoExisting) {
      unawaited(TerminalFeedback.success());
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    } else {
      unawaited(TerminalFeedback.success());
    }
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
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Offline Sayim Kamerasi',
      subtitle: 'Barkodu okutun; bulunan deger urun aramasina aktarilacak.',
    );

    if (barcode == null || !mounted) {
      return;
    }

    setState(() {
      line.lookupController.text = barcode;
      _errorMessage = null;
    });

    await _searchProduct(line, autoSelectSingle: true);
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

    existingLine.quantityController.text = _formatQuantity(
      _readDouble(existingLine.quantityController.text, fallback: 0) +
          _quantityInputOrUnitMultiplier(
            line.quantityController.text,
            product.unitMultiplier,
          ),
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
    return line.lookupController.text.trim().isEmpty &&
        line.stockCodeController.text.trim().isEmpty &&
        line.barcodeController.text.trim().isEmpty;
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

    final activeLines = _lines
        .where((line) => !_isBlankLine(line))
        .toList(growable: false);

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
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + viewInsets.bottom),
        child: Form(
          key: _formKey,
          autovalidateMode: createFormAutovalidateMode,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              const TerminalSheetHeader(
                title: 'Yeni Offline Sayim',
                subtitle:
                    'Bu ekran internet olmadan da calisir. Taslaklar GUID tabanli clientRequestId ile senkronize edilir; online urun arama ve kamera ile barkod okutma istege baglidir.',
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Sayim Adi'),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Sayim adi zorunludur.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TerminalFilterButton(
                label: 'Belge Tarihi',
                value: AppFormatters.date(_documentDate),
                onPressed: _pickDate,
              ),
              const SizedBox(height: 12),
              TerminalSectionToolbar(
                title: 'Satirlar',
                actions: const <Widget>[],
              ),
              const SizedBox(height: 10),
              ..._lines.asMap().entries.map((entry) {
                final index = entry.key;
                final line = entry.value;
                final isFreshEntry = index == 0 && _isBlankLine(line);
                final displayLineNo = _lines
                    .take(index + 1)
                    .where((item) => !_isBlankLine(item))
                    .length;
                if (!isFreshEntry) {
                  return TerminalCompactProductLineCard(
                    lineNo: displayLineNo,
                    stockCode: line.stockCodeController.text.trim(),
                    stockName: line.stockNameController.text.trim().isEmpty
                        ? 'Urun secilmedi'
                        : line.stockNameController.text.trim(),
                    quantityController: line.quantityController,
                    unitLabel: 'Birim ${line.unitPointer}',
                    barcode: line.barcodeController.text.trim(),
                    canDelete: _lines.length > 1,
                    onDelete: () {
                      setState(() {
                        line.dispose();
                        _lines.removeAt(index);
                      });
                    },
                    onMinimumReached: _lines.length > 1
                        ? () {
                            setState(() {
                              line.dispose();
                              _lines.removeAt(index);
                            });
                          }
                        : null,
                  );
                }
                return TerminalPdaLineCard(
                  title: isFreshEntry ? 'Giris satiri' : 'Satir $displayLineNo',
                  subtitle: line.stockNameController.text.trim().isEmpty
                      ? (isFreshEntry ? 'Okutmaya hazir' : 'Urun secilmedi')
                      : line.stockNameController.text.trim(),
                  isEntryLine: isFreshEntry,
                  leading: Icon(
                    isFreshEntry
                        ? Icons.qr_code_scanner_rounded
                        : Icons.inventory_2_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  trailing: !isFreshEntry && _lines.length > 1
                      ? IconButton(
                          onPressed: () {
                            setState(() {
                              line.dispose();
                              _lines.removeAt(index);
                            });
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          tooltip: 'Satiri sil',
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (isFreshEntry)
                        TerminalResponsiveLookupRow(
                          field: TerminalSubmitOnTab(
                            onSubmit: () => _searchProduct(line),
                            child: TextField(
                              controller: line.lookupController,
                              focusNode: line.lookupFocusNode,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _searchProduct(line),
                              decoration: const InputDecoration(
                                labelText: 'Online urun ara',
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
                        )
                      else ...<Widget>[
                        TerminalPdaInfoGrid(
                          minTileWidth: 92,
                          items: <TerminalPdaInfo>[
                            TerminalPdaInfo(
                              label: 'Kod',
                              value: line.stockCodeController.text.trim(),
                            ),
                            if (line.barcodeController.text.trim().isNotEmpty)
                              TerminalPdaInfo(
                                label: 'Barkod',
                                value: line.barcodeController.text.trim(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TerminalQuantityStepper(
                          controller: line.quantityController,
                          label: 'Miktar',
                          onMinimumReached: !isFreshEntry && _lines.length > 1
                              ? () {
                                  setState(() {
                                    line.dispose();
                                    _lines.removeAt(index);
                                  });
                                }
                              : null,
                          validator: (_) {
                            if (line.quantity <= 0) {
                              return 'Miktar > 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                );
              }),
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
      ),
    );
  }
}

class _OfflineLineDraft {
  _OfflineLineDraft()
    : lookupController = TextEditingController(),
      stockCodeController = TextEditingController(),
      stockNameController = TextEditingController(),
      barcodeController = TextEditingController(),
      quantityController = TextEditingController(),
      unitPointerController = TextEditingController(text: '1');

  final TextEditingController lookupController;
  final TextEditingController stockCodeController;
  final TextEditingController stockNameController;
  final TextEditingController barcodeController;
  final TextEditingController quantityController;
  final TextEditingController unitPointerController;
  final FocusNode lookupFocusNode = FocusNode();

  double get quantity => _readDouble(quantityController.text, fallback: 0);
  int get unitPointer => _readInt(unitPointerController.text, fallback: 1);

  void applyLookup(InventoryCountProductLookupItem product) {
    stockCodeController.text = product.stockCode;
    stockNameController.text = product.stockName;
    barcodeController.text = product.barcode;
    unitPointerController.text = '1';
    lookupController.text = product.displayLabel;
    if (quantityController.text.trim().isEmpty) {
      quantityController.text = _formatQuantity(
        _unitMultiplierQuantity(product.unitMultiplier),
      );
    }
  }

  void dispose() {
    lookupFocusNode.dispose();
    lookupController.dispose();
    stockCodeController.dispose();
    stockNameController.dispose();
    barcodeController.dispose();
    quantityController.dispose();
    unitPointerController.dispose();
  }
}

String? _productIdentity({required String barcode, required String stockCode}) {
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

double _unitMultiplierQuantity(double unitMultiplier) {
  return unitMultiplier > 0 ? unitMultiplier : 1;
}

double _quantityInputOrUnitMultiplier(String raw, double unitMultiplier) {
  final normalized = raw.trim();
  if (normalized.isEmpty) {
    return _unitMultiplierQuantity(unitMultiplier);
  }

  final parsed = double.tryParse(normalized.replaceAll(',', '.'));
  return parsed != null && parsed > 0
      ? parsed
      : _unitMultiplierQuantity(unitMultiplier);
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
