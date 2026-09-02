import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/network/api_exception.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/models/offline_company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/offline_company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/given_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/mobile_customer_catalog_repository.dart';
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

class OfflineCompanyAcceptancesPage extends StatefulWidget {
  const OfflineCompanyAcceptancesPage({
    super.key,
    required this.offlineRepository,
    required this.onlineRepository,
    required this.ordersRepository,
    required this.accessToken,
    required this.offlineSyncService,
    required this.mobileCustomerCatalogRepository,
    required this.mobileProductCatalogRepository,
    required this.currentUserId,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
    this.standalone = false,
  });

  final OfflineCompanyAcceptancesRepository offlineRepository;
  final CompanyAcceptancesRepository onlineRepository;
  final GivenCompanyOrdersRepository ordersRepository;
  final String accessToken;
  final OfflineSyncService offlineSyncService;
  final MobileCustomerCatalogLocalRepository mobileCustomerCatalogRepository;
  final MobileProductCatalogLocalRepository mobileProductCatalogRepository;
  final String currentUserId;
  final String defaultWarehouseNo;
  final String userWarehouseName;
  final bool standalone;

  @override
  State<OfflineCompanyAcceptancesPage> createState() =>
      _OfflineCompanyAcceptancesPageState();
}

class _OfflineCompanyAcceptancesPageState
    extends State<OfflineCompanyAcceptancesPage> {
  List<OfflineCompanyAcceptanceDraft> _drafts =
      const <OfflineCompanyAcceptanceDraft>[];
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
    final draft = await openTerminalCreatePage<OfflineCompanyAcceptanceDraft>(
      context: context,
      title: 'Yeni Offline Mal Kabul',
      builder: (context) {
        return _OfflineCompanyAcceptanceCreateSheet(
          repository: widget.onlineRepository,
          ordersRepository: widget.ordersRepository,
          accessToken: widget.accessToken,
          currentUserId: widget.currentUserId,
          defaultWarehouseNo: widget.defaultWarehouseNo,
          mobileCustomerCatalogRepository:
              widget.mobileCustomerCatalogRepository,
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

  Future<void> _syncDraft(OfflineCompanyAcceptanceDraft draft) async {
    setState(() {
      _syncingIds = <String>{..._syncingIds, draft.id};
      _errorMessage = null;
    });

    try {
      final result = await widget.offlineSyncService.syncCompanyAcceptanceDraft(
        accessToken: widget.accessToken,
        draft: draft,
      );
      await _loadDrafts();

      if (!mounted) {
        return;
      }

      final message = switch (result.status) {
        OfflineDraftSyncResultStatus.synced =>
          draft.documentNo.isEmpty
              ? 'Offline firma mal kabul taslagi sunucuya aktarildi.'
              : '${draft.documentNo} sunucuya aktarildi.',
        OfflineDraftSyncResultStatus.processing =>
          result.message ?? 'Kayit arka planda isleniyor.',
        OfflineDraftSyncResultStatus.deferred =>
          result.message ??
              'Baglanti yok; kayit kuyrukta beklemeye devam ediyor.',
        OfflineDraftSyncResultStatus.failed =>
          result.message ?? 'Kayit senkronize edilemedi.',
      };

      if (result.status == OfflineDraftSyncResultStatus.failed) {
        setState(() {
          _errorMessage = message;
        });
      } else {
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

  Widget _buildDraftTitleRow({
    required OfflineCompanyAcceptanceDraft draft,
    required String title,
  }) {
    final titleText = Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
    );

    final statusBadge = TerminalBadge(
      label: offlineRecordStatusLabel(draft.status),
    );
    final lineCountBadge = TerminalBadge(label: '${draft.lines.length} satir');

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              titleText,
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[statusBadge, lineCountBadge],
              ),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: titleText),
            statusBadge,
            const SizedBox(width: 8),
            lineCountBadge,
          ],
        );
      },
    );
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
              title: 'Offline Firma Mal Kabul',
              subtitle:
                  'Taslak firma mal kabullerini cihazda saklar; baglanti geri geldiginde ayni clientRequestId ile senkronize eder.',
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
                  label: const Text('Yeni Offline Mal Kabul'),
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
                      message: 'Bekleyen offline firma mal kabul taslagi yok.',
                    )
                  else
                    ..._drafts.map((draft) {
                      final isSyncing =
                          _syncingIds.contains(draft.id) ||
                          draft.status == OfflineRecordStatus.syncing;
                      final title = draft.documentNo.trim().isEmpty
                          ? draft.customerCode
                          : draft.documentNo;
                      final customerLabel =
                          draft.customerDisplayName.trim().isEmpty
                          ? draft.customerCode
                          : draft.customerDisplayName;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TerminalPdaDetailPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _buildDraftTitleRow(draft: draft, title: title),
                              const SizedBox(height: 8),
                              TerminalPdaInfoGrid(
                                items: <TerminalPdaInfo>[
                                  TerminalPdaInfo(
                                    label: 'Cari',
                                    value: customerLabel,
                                  ),
                                  TerminalPdaInfo(
                                    label: 'Belge',
                                    value: AppFormatters.date(
                                      draft.documentDate,
                                    ),
                                  ),
                                  TerminalPdaInfo(
                                    label: 'Hareket',
                                    value: AppFormatters.date(
                                      draft.movementDate,
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
                              if (draft.description
                                  .trim()
                                  .isNotEmpty) ...<Widget>[
                                const SizedBox(height: 8),
                                TerminalMessageBlock.info(
                                  message: draft.description,
                                ),
                              ],
                              const SizedBox(height: 12),
                              ...draft.lines.take(5).map((line) {
                                final label = line.stockName.trim().isEmpty
                                    ? line.stockCode
                                    : '${line.stockCode} - ${line.stockName}';
                                final extras = <String>[
                                  'Irsaliye ${AppFormatters.quantity(line.dispatchQuantity)}',
                                  'Sayilan ${AppFormatters.quantity(line.acceptedQuantity)}',
                                  if (line.returnQuantity > 0)
                                    'Iade ${AppFormatters.quantity(line.returnQuantity)}',
                                  if ((line.orderGuid ?? '').trim().isNotEmpty)
                                    'Siparisli',
                                ].join(' | ');

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: TerminalPdaDetailPanel(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          label,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(extras),
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
      appBar: AppBar(title: const Text('Offline Firma Mal Kabul')),
      body: content,
    );
  }
}

class _OfflineCompanyAcceptanceCreateSheet extends StatefulWidget {
  const _OfflineCompanyAcceptanceCreateSheet({
    required this.repository,
    required this.ordersRepository,
    required this.accessToken,
    required this.currentUserId,
    required this.defaultWarehouseNo,
    required this.mobileCustomerCatalogRepository,
    required this.mobileProductCatalogRepository,
  });

  final CompanyAcceptancesRepository repository;
  final GivenCompanyOrdersRepository ordersRepository;
  final String accessToken;
  final String currentUserId;
  final String defaultWarehouseNo;
  final MobileCustomerCatalogLocalRepository mobileCustomerCatalogRepository;
  final MobileProductCatalogLocalRepository mobileProductCatalogRepository;

  @override
  State<_OfflineCompanyAcceptanceCreateSheet> createState() =>
      _OfflineCompanyAcceptanceCreateSheetState();
}

enum _OfflineCompanyAcceptanceCreateStep { document, lines }

class _OfflineCompanyAcceptanceCreateSheetState
    extends State<_OfflineCompanyAcceptanceCreateSheet>
    with CreateFormValidation {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<_OfflineCompanyAcceptanceLineDraft> _lines =
      <_OfflineCompanyAcceptanceLineDraft>[];
  late final TextEditingController _customerSearchController;
  late final TextEditingController _customerCodeController;
  late final TextEditingController _documentNoController;
  late final TextEditingController _delivererController;
  late final TextEditingController _receiverController;
  late final TextEditingController _descriptionController;
  DateTime _movementDate = DateTime.now();
  DateTime _documentDate = DateTime.now();
  bool _allowOrderOverReceiving = false;
  bool _autoCreateReturnForPartialAcceptance = true;
  CustomerLookupItem? _selectedCustomer;
  String? _validationMessage;
  String? _lastAddedProductKey;
  _OfflineCompanyAcceptanceCreateStep _step =
      _OfflineCompanyAcceptanceCreateStep.document;

  @override
  void initState() {
    super.initState();
    _customerSearchController = TextEditingController();
    _customerCodeController = TextEditingController();
    _documentNoController = TextEditingController();
    _delivererController = TextEditingController();
    _receiverController = TextEditingController();
    _descriptionController = TextEditingController();
    _lines.add(_OfflineCompanyAcceptanceLineDraft());
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
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
    final query = _customerSearchController.text.trim();

    if (query.length < 2) {
      setState(() {
        _validationMessage = 'Cari aramak icin en az 2 karakter girilmeli.';
      });
      return;
    }

    List<CustomerLookupItem> customers;
    try {
      customers = await widget.repository.searchCustomers(
        accessToken: widget.accessToken,
        query: query,
      );
    } on ApiException {
      final catalogItems = await widget.mobileCustomerCatalogRepository
          .searchCustomers(query: query);
      customers = catalogItems
          .map((item) => item.toCustomerLookupItem())
          .toList(growable: false);
    }

    if (!mounted) {
      return;
    }

    final selected = await showModalBottomSheet<CustomerLookupItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        if (customers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: TerminalEmptyState(message: 'Cari bulunamadi.'),
          );
        }

        return FractionallySizedBox(
          heightFactor: 0.82,
          child: ListView.separated(
            itemCount: customers.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = customers[index];
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                isThreeLine: item.lookupDetailParts.length > 3,
                title: Text(
                  item.lookupTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item.lookupDetailLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(context).pop(item),
              );
            },
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedCustomer = selected;
      _customerSearchController.text = selected.displayLabel;
      _customerCodeController.text = selected.customerCode;
      _validationMessage = null;
    });
    _focusFreshEntryLine();
  }

  Future<void> _searchProduct(_OfflineCompanyAcceptanceLineDraft line) async {
    final query = line.lookupController.text.trim();

    if (query.length < 2) {
      setState(() {
        _validationMessage =
            'Urun aramak icin en az 2 karakter veya barkod girilmeli.';
      });
      _refocusLine(line.lookupFocusNode);
      return;
    }

    final products = await _searchProductsWithCatalogFallback(query);

    if (!mounted) {
      return;
    }

    if (products.isEmpty) {
      setState(() {
        _validationMessage = 'Bu aramaya uygun urun bulunamadi.';
      });
      _showFeedback('Bu aramaya uygun urun bulunamadi.');
      _refocusLine(line.lookupFocusNode);
      return;
    }

    SearchProductLookupItem? selected;
    if (products.length == 1) {
      selected = products.single;
    } else {
      selected = await showModalBottomSheet<SearchProductLookupItem>(
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
                    '${item.unitName} | ${AppFormatters.currency(item.price)}',
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
      entryLine.applyProduct(pickedProduct);
      entryLine.lookupController.clear();
      _validationMessage = null;
    });
    unawaited(TerminalFeedback.success());
    _refocusLine(entryLine.lookupFocusNode);
  }

  Future<List<SearchProductLookupItem>> _searchProductsWithCatalogFallback(
    String query,
  ) async {
    final customerCode = _customerCodeController.text.trim();
    try {
      return await widget.repository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        query: query,
        customerCode: customerCode.isEmpty ? null : customerCode,
      );
    } on ApiException {
      final catalogItems = await widget.mobileProductCatalogRepository
          .searchProducts(warehouseNo: widget.defaultWarehouseNo, query: query);
      if (catalogItems.isNotEmpty) {
        return catalogItems
            .map((item) => item.toSearchProductLookupItem())
            .toList(growable: false);
      }
      rethrow;
    }
  }

  Future<void> _scanProductWithCamera(
    _OfflineCompanyAcceptanceLineDraft line,
  ) async {
    if (!supportsCameraBarcodeScanning) {
      setState(() {
        _validationMessage =
            'Bu cihazda kamera ile barkod okutma desteklenmiyor.';
      });
      _refocusLine(line.lookupFocusNode);
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Offline Mal Kabul Kamerasi',
      subtitle: 'Barkodu okutun; bulunan urun satira aktarilacak.',
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
      _validationMessage = null;
    });

    await _searchProduct(line);
  }

  bool _increasePendingQuantityIfSameProduct(
    _OfflineCompanyAcceptanceLineDraft line,
    SearchProductLookupItem product,
  ) {
    final selectedProduct = line.selectedProduct;
    if (selectedProduct == null || !_isSameProduct(selectedProduct, product)) {
      return false;
    }

    final increment = _unitMultiplierQuantity(product.unitMultiplier);
    setState(() {
      line.dispatchQuantityController.text = _formatQuantity(
        line.dispatchQuantity + increment,
      );
      line.acceptedQuantityController.text = _formatQuantity(
        line.acceptedQuantity + increment,
      );
      line.lookupController.clear();
      _validationMessage = null;
    });
    unawaited(TerminalFeedback.success());
    return true;
  }

  Future<_OfflineCompanyAcceptanceLineDraft?>
  _commitPendingEntryBeforeNextProduct(
    _OfflineCompanyAcceptanceLineDraft line,
  ) async {
    if (line.selectedProduct == null) {
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
    SearchProductLookupItem first,
    SearchProductLookupItem second,
  ) {
    return productEntryController.isSameProduct(
      firstStockCode: first.stockCode,
      firstBarcode: first.barcode,
      secondStockCode: second.stockCode,
      secondBarcode: second.barcode,
    );
  }

  Future<bool> _confirmDuplicateIncrease(
    _OfflineCompanyAcceptanceLineDraft line,
    SearchProductLookupItem product,
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
          existingQuantityText: existingLine.acceptedQuantityController.text,
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

  void _rememberAddedProduct(SearchProductLookupItem product) {
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

  Future<void> _commitEntryLine(_OfflineCompanyAcceptanceLineDraft line) async {
    final product = line.selectedProduct;
    if (product == null) {
      _refocusLine(line.lookupFocusNode);
      return;
    }

    if (line.dispatchQuantity <= 0 || line.acceptedQuantity < 0) {
      setState(() {
        _validationMessage =
            'Irsaliye miktari sifirdan buyuk, sayilan miktar negatif olmamali.';
      });
      return;
    }

    if (!await _confirmDuplicateIncrease(line, product)) {
      return;
    }

    var mergedIntoExisting = false;
    setState(() {
      mergedIntoExisting = _applyProductToLine(line, product);
      _ensureFreshEntryLine();
      _validationMessage = null;
    });
    _focusFreshEntryLine();
    _rememberAddedProduct(product);
    unawaited(TerminalFeedback.success());
    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  void _cancelPendingEntryLine(_OfflineCompanyAcceptanceLineDraft line) {
    setState(() {
      line.clear();
      _validationMessage = null;
    });
    _refocusLine(line.lookupFocusNode);
  }

  List<_OfflineCompanyAcceptanceLineDraft> _committedLines() {
    return <_OfflineCompanyAcceptanceLineDraft>[
      for (var index = 0; index < _lines.length; index++)
        if (index != 0 && !_isBlankLine(_lines[index])) _lines[index],
    ];
  }

  bool _applyProductToLine(
    _OfflineCompanyAcceptanceLineDraft line,
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

    existingLine.dispatchQuantityController.text = _formatQuantity(
      _readDouble(existingLine.dispatchQuantityController.text, fallback: 0) +
          _quantityInputOrUnitMultiplier(
            line.dispatchQuantityController.text,
            product.unitMultiplier,
          ),
    );
    existingLine.acceptedQuantityController.text = _formatQuantity(
      _readDouble(existingLine.acceptedQuantityController.text, fallback: 0) +
          _quantityInputOrUnitMultiplier(
            line.acceptedQuantityController.text,
            product.unitMultiplier,
          ),
    );

    if (_readDouble(existingLine.unitPriceController.text, fallback: 0) <= 0) {
      line.applyProduct(product);
      existingLine.unitPriceController.text = line.unitPriceController.text;
    }

    _recycleMergedLine(line);
    return true;
  }

  _OfflineCompanyAcceptanceLineDraft? _findDuplicateLine({
    required _OfflineCompanyAcceptanceLineDraft currentLine,
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

  void _recycleMergedLine(_OfflineCompanyAcceptanceLineDraft line) {
    final lineIndex = _lines.indexOf(line);
    line.dispose();

    if (lineIndex == 0) {
      _lines[lineIndex] = _OfflineCompanyAcceptanceLineDraft();
      return;
    }

    _lines.removeAt(lineIndex);
  }

  void _ensureFreshEntryLine() {
    if (_lines.isEmpty || !_isBlankLine(_lines.first)) {
      _lines.insert(0, _OfflineCompanyAcceptanceLineDraft());
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

  bool _isBlankLine(_OfflineCompanyAcceptanceLineDraft line) {
    return line.selectedProduct == null &&
        line.stockCodeController.text.trim().isEmpty;
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

  void _goToLinesStep() {
    if (!_validateDocumentStep()) {
      return;
    }

    setState(() {
      _step = _OfflineCompanyAcceptanceCreateStep.lines;
      _validationMessage = null;
    });
    _focusFreshEntryLine();
  }

  void _goToDocumentStep() {
    setState(() {
      _step = _OfflineCompanyAcceptanceCreateStep.document;
      _validationMessage = null;
    });
  }

  bool _validateDocumentStep() {
    final form = _formKey.currentState;
    if (form != null && !validateCreateForm(_formKey)) {
      return false;
    }

    if (_customerCodeController.text.trim().isEmpty) {
      setState(() {
        _step = _OfflineCompanyAcceptanceCreateStep.document;
        _validationMessage = 'Cari kodu zorunludur.';
      });
      return false;
    }

    if (_documentDate.isAfter(_movementDate)) {
      setState(() {
        _step = _OfflineCompanyAcceptanceCreateStep.document;
        _validationMessage = 'Belge tarihi hareket tarihinden sonra olamaz.';
      });
      return false;
    }

    return true;
  }

  Future<void> _addLinesFromOpenOrders() async {
    final customerCode = _customerCodeController.text.trim();

    if (customerCode.isEmpty) {
      setState(() {
        _validationMessage = 'Siparis baglamak icin once cari kodu girilmeli.';
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
        _validationMessage = error.toString().replaceFirst('Exception: ', '');
      });
      return;
    }

    if (!mounted) {
      return;
    }

    final selectedOrder = await showModalBottomSheet<CompanyOrderListItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        if (orders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: TerminalEmptyState(message: 'Acik siparis bulunamadi.'),
          );
        }

        return FractionallySizedBox(
          heightFactor: 0.82,
          child: ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = orders[index];
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                title: Text(
                  item.documentNoLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${item.customerDisplayName} | Kalan ${AppFormatters.quantity(item.totalRemainingQuantity)}',
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

    if (selectedOrder == null) {
      return;
    }

    final detail = await widget.ordersRepository.fetchOrderDetail(
      accessToken: widget.accessToken,
      documentSerie: selectedOrder.documentSerie,
      documentOrderNo: selectedOrder.documentOrderNo,
      warehouseNo: widget.defaultWarehouseNo,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      for (final item in detail.items) {
        if (item.remainingQuantity <= 0) {
          continue;
        }

        _lines.add(_OfflineCompanyAcceptanceLineDraft.fromOrderItem(item));
      }
      _ensureFreshEntryLine();
      _validationMessage = null;
    });
  }

  void _submit() {
    final form = _formKey.currentState;

    if (form == null || !validateCreateForm(_formKey)) {
      return;
    }

    final customerCode = _customerCodeController.text.trim();
    final documentNo = _documentNoController.text.trim();

    if (customerCode.isEmpty) {
      setState(() {
        _step = _OfflineCompanyAcceptanceCreateStep.document;
        _validationMessage = 'Cari kodu zorunludur.';
      });
      return;
    }

    if (_documentDate.isAfter(_movementDate)) {
      setState(() {
        _step = _OfflineCompanyAcceptanceCreateStep.document;
        _validationMessage = 'Belge tarihi hareket tarihinden sonra olamaz.';
      });
      return;
    }

    if (_hasPendingEntryLine) {
      setState(() {
        _step = _OfflineCompanyAcceptanceCreateStep.lines;
        _validationMessage = 'Secilen urunu once Kaleme Ekle ile listeye alin.';
      });
      return;
    }

    final activeLines = _committedLines();

    if (activeLines.isEmpty) {
      setState(() {
        _step = _OfflineCompanyAcceptanceCreateStep.lines;
        _validationMessage = 'En az bir urun satiri ekleyin.';
      });
      return;
    }

    final usedOrderGuids = <String>{};
    for (var index = 0; index < activeLines.length; index += 1) {
      final line = activeLines[index];
      if (line.stockCodeController.text.trim().isEmpty) {
        setState(() {
          _step = _OfflineCompanyAcceptanceCreateStep.lines;
          _validationMessage = '${index + 1}. satir icin stok kodu zorunlu.';
        });
        return;
      }
      if (line.dispatchQuantity <= 0) {
        setState(() {
          _step = _OfflineCompanyAcceptanceCreateStep.lines;
          _validationMessage =
              '${index + 1}. satir icin irsaliye miktari sifirdan buyuk olmali.';
        });
        return;
      }
      if (line.acceptedQuantity < 0) {
        setState(() {
          _step = _OfflineCompanyAcceptanceCreateStep.lines;
          _validationMessage =
              '${index + 1}. satir icin sayilan miktar negatif olamaz.';
        });
        return;
      }
      if (line.acceptedQuantity > line.dispatchQuantity) {
        setState(() {
          _step = _OfflineCompanyAcceptanceCreateStep.lines;
          _validationMessage =
              '${index + 1}. satirda sayilan miktar irsaliye miktarini gecemez.';
        });
        return;
      }
      if (line.unitPointer <= 0 || line.unitPointer > 255) {
        setState(() {
          _step = _OfflineCompanyAcceptanceCreateStep.lines;
          _validationMessage =
              '${index + 1}. satir icin unitPointer 1-255 olmali.';
        });
        return;
      }
      if (line.lotNo < 0) {
        setState(() {
          _step = _OfflineCompanyAcceptanceCreateStep.lines;
          _validationMessage =
              '${index + 1}. satir icin lot no negatif olamaz.';
        });
        return;
      }
      final orderGuid = line.orderGuid?.trim() ?? '';
      if (orderGuid.isNotEmpty && !usedOrderGuids.add(orderGuid)) {
        setState(() {
          _step = _OfflineCompanyAcceptanceCreateStep.lines;
          _validationMessage =
              '${index + 1}. satirda ayni siparis satiri tekrar kullanilamaz.';
        });
        return;
      }
    }

    Navigator.of(context).pop(
      OfflineCompanyAcceptanceDraft(
        id: generateClientRequestId(),
        userId: widget.currentUserId,
        warehouseNo: widget.defaultWarehouseNo,
        customerCode: customerCode,
        customerDisplayName:
            _selectedCustomer?.customerDisplayName ??
            _customerSearchController.text.trim(),
        movementDate: _movementDate,
        documentDate: _documentDate,
        documentNo: documentNo,
        officialDocumentKind: null,
        officialDocumentNo: null,
        officialDocumentDate: null,
        officialDocumentEttn: null,
        deliverer: _delivererController.text.trim(),
        receiver: _receiverController.text.trim(),
        description: _descriptionController.text.trim(),
        allowOrderOverReceiving: _allowOrderOverReceiving,
        autoCreateReturnForPartialAcceptance:
            _autoCreateReturnForPartialAcceptance,
        createdAt: DateTime.now(),
        status: OfflineRecordStatus.pending,
        lastSyncAttemptAt: null,
        lastError: null,
        lines: activeLines
            .map(
              (line) => OfflineCompanyAcceptanceLine(
                stockCode: line.stockCodeController.text.trim(),
                stockName: line.stockNameController.text.trim(),
                barcode: line.barcodeController.text.trim(),
                dispatchQuantity: line.dispatchQuantity,
                acceptedQuantity: line.acceptedQuantity,
                unitPrice: line.unitPrice,
                unitPointer: line.unitPointer,
                lastConsumingDate: line.lastConsumingDate,
                orderGuid: line.orderGuid,
                description: line.descriptionController.text.trim(),
                partyCode: line.partyCodeController.text.trim(),
                lotNo: line.lotNo,
                projectCode: line.projectCodeController.text.trim(),
                customerResponsibilityCenter: '',
                productResponsibilityCenter: '',
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDocumentStep =
        _step == _OfflineCompanyAcceptanceCreateStep.document;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Form(
          key: _formKey,
          autovalidateMode: createFormAutovalidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TerminalSheetHeader(
                title: 'Yeni Offline Firma Mal Kabul',
                badges: <Widget>[
                  TerminalLineCountBadge(count: _filledLineIndexes().length),
                ],
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 4),
              _buildStepSelector(),
              const SizedBox(height: 5),
              Expanded(
                child: isDocumentStep
                    ? _buildDocumentStep()
                    : _buildLinesStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepSelector() {
    return SizedBox(
      height: 36,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<_OfflineCompanyAcceptanceCreateStep>(
          showSelectedIcon: false,
          selected: <_OfflineCompanyAcceptanceCreateStep>{_step},
          style: const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(0, 34)),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 8),
            ),
            visualDensity: VisualDensity(horizontal: -3, vertical: -3),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          segments: const <ButtonSegment<_OfflineCompanyAcceptanceCreateStep>>[
            ButtonSegment<_OfflineCompanyAcceptanceCreateStep>(
              value: _OfflineCompanyAcceptanceCreateStep.document,
              icon: Icon(Icons.assignment_outlined, size: 18),
              label: Text('Belge'),
            ),
            ButtonSegment<_OfflineCompanyAcceptanceCreateStep>(
              value: _OfflineCompanyAcceptanceCreateStep.lines,
              icon: Icon(Icons.playlist_add_check_rounded, size: 18),
              label: Text('Kalemler'),
            ),
          ],
          onSelectionChanged: (selection) {
            final nextStep = selection.first;
            if (nextStep == _OfflineCompanyAcceptanceCreateStep.lines) {
              _goToLinesStep();
              return;
            }

            _goToDocumentStep();
          },
        ),
      ),
    );
  }

  Widget _buildDocumentStep() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_validationMessage != null) ...<Widget>[
            TerminalMessageBlock.error(message: _validationMessage!),
            const SizedBox(height: 6),
          ],
          _buildCustomerLookupRow(),
          const SizedBox(height: 4),
          _buildCustomerCodeField(),
          const SizedBox(height: 4),
          _buildDocumentDetailsSection(),
          const SizedBox(height: 8),
          _buildDocumentStepActions(),
        ],
      ),
    );
  }

  Widget _buildLinesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TerminalCreateInputDock(
          padding: const EdgeInsets.only(bottom: 4),
          children: <Widget>[
            _buildLineStepSummary(),
            if (_validationMessage != null) ...<Widget>[
              const SizedBox(height: 4),
              TerminalMessageBlock.error(message: _validationMessage!),
            ],
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
                    const SizedBox(height: 4),
                    _buildLineStepActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerCodeField() {
    return TextFormField(
      controller: _customerCodeController,
      decoration: const InputDecoration(
        labelText: 'Cari Kodu*',
        hintText: 'Internet yoksa elle girin',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onChanged: (_) => setState(() {}),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return 'Cari kodu zorunlu';
        }

        return null;
      },
    );
  }

  Widget _buildDocumentStepActions() {
    final cancelButton = OutlinedButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Vazgec'),
    );

    final nextButton = FilledButton.icon(
      onPressed: _goToLinesStep,
      icon: const Icon(Icons.arrow_forward_rounded),
      label: const Text('Kalemlere Gec'),
    );

    return TerminalFormActionRow(cancel: cancelButton, submit: nextButton);
  }

  Widget _buildLineStepActions() {
    final documentButton = OutlinedButton.icon(
      onPressed: _goToDocumentStep,
      icon: const Icon(Icons.assignment_outlined),
      label: const Text('Belge'),
    );

    final submitButton = FilledButton.icon(
      onPressed: _submit,
      icon: const Icon(Icons.save_alt_rounded),
      label: const Text('Taslagi Kaydet'),
    );

    return TerminalFormActionRow(cancel: documentButton, submit: submitButton);
  }

  Widget _buildLineStepSummary() {
    final theme = Theme.of(context);
    final customerText = _customerSearchController.text.trim();
    final customerCode = _customerCodeController.text.trim();
    final documentNo = _documentNoController.text.trim();
    final lineCount = _filledLineIndexes().length;
    final dispatchTotal = _totalDispatchQuantity();
    final acceptedTotal = _totalAcceptedQuantity();
    final returnTotal = _totalReturnQuantity();
    final title = customerText.isNotEmpty
        ? customerText
        : customerCode.isNotEmpty
        ? customerCode
        : 'Cari secilmedi';
    final totalsLabel = <String>[
      '$lineCount kalem',
      'Irs ${AppFormatters.quantity(dispatchTotal)}',
      'Kabul ${AppFormatters.quantity(acceptedTotal)}',
      if (returnTotal > 0) 'Fark ${AppFormatters.quantity(returnTotal)}',
      if (documentNo.isNotEmpty) documentNo,
    ].join(' | ');
    final orderButton = IconButton.outlined(
      visualDensity: VisualDensity.compact,
      tooltip: 'Siparis bagla',
      onPressed: _customerCodeController.text.trim().isEmpty
          ? null
          : _addLinesFromOpenOrders,
      icon: const Icon(Icons.link_rounded),
    );
    final documentButton = IconButton.outlined(
      visualDensity: VisualDensity.compact,
      tooltip: 'Belge bilgileri',
      onPressed: _goToDocumentStep,
      icon: const Icon(Icons.edit_note_rounded),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(88),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalsLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: returnTotal > 0
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.onSurface.withAlpha(160),
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          orderButton,
          const SizedBox(width: 4),
          documentButton,
        ],
      ),
    );
  }

  double _totalDispatchQuantity() {
    return _committedLines().fold<double>(
      0,
      (total, line) => total + line.dispatchQuantity,
    );
  }

  double _totalAcceptedQuantity() {
    return _committedLines().fold<double>(
      0,
      (total, line) => total + line.acceptedQuantity,
    );
  }

  double _totalReturnQuantity() {
    return _committedLines().fold<double>(
      0,
      (total, line) => total + line.returnQuantity,
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
    final selectedProduct = line.selectedProduct;

    if (isPendingEntry && selectedProduct != null) {
      return ProductDraftEntryPanel(
        stockCode: selectedProduct.stockCode,
        stockName: selectedProduct.stockName,
        quantityController: line.dispatchQuantityController,
        title: 'Secilen urun',
        quantityLabel: 'Irsaliye Miktari*',
        unitLabel: selectedProduct.unitName,
        barcode: line.barcodeController.text.trim(),
        packageLabel: selectedProduct.unitMultiplier > 1
            ? AppFormatters.quantity(selectedProduct.unitMultiplier)
            : null,
        priceLabel: line.unitPrice > 0
            ? AppFormatters.currency(line.unitPrice)
            : null,
        onConfirm: () => _commitEntryLine(line),
        onCancel: () => _cancelPendingEntryLine(line),
        scanRow: _buildProductLookupRow(line),
        quantityValidator: (_) {
          if (line.dispatchQuantity <= 0) {
            return 'Miktar > 0';
          }
          return null;
        },
        onQuantityChanged: (_) => setState(() {}),
        secondaryQuantityController: line.acceptedQuantityController,
        secondaryQuantityLabel: 'Fiili Kabul*',
        secondaryMaximumQuantity: line.dispatchQuantity,
        onSecondaryQuantityChanged: (_) => setState(() {}),
        secondaryQuantityValidator: (_) {
          if (line.acceptedQuantity < 0) {
            return 'Negatif olamaz';
          }
          if (line.acceptedQuantity > line.dispatchQuantity) {
            return 'Irsaliyeyi gecemez';
          }
          return null;
        },
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if ((line.orderGuid ?? '').trim().isNotEmpty)
            const TerminalBadge(label: 'Siparisli'),
          if (!isFreshEntry && _lines.length > 1)
            IconButton(
              onPressed: () => _removeLineAt(index),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Satiri sil',
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (isFreshEntry)
            _buildProductLookupRow(line)
          else ...<Widget>[
            TerminalCompactProductLineSummary(
              lineNo: displayLineNo,
              stockCode: line.stockCodeController.text.trim(),
              stockName: line.stockNameController.text.trim(),
              unitLabel: line.selectedProduct?.unitName,
              packageLabel:
                  line.selectedProduct != null &&
                      line.selectedProduct!.unitMultiplier > 1
                  ? AppFormatters.quantity(line.selectedProduct!.unitMultiplier)
                  : null,
              barcode: line.barcodeController.text.trim(),
              priceLabel: line.unitPrice > 0
                  ? AppFormatters.currency(line.unitPrice)
                  : null,
            ),
            const SizedBox(height: 10),
            _buildQuantityFields(line),
          ],
          if (line.returnQuantity > 0) ...<Widget>[
            const SizedBox(height: 8),
            TerminalMessageBlock.info(
              message:
                  'Iade farki ${AppFormatters.quantity(line.returnQuantity)}. ${_autoCreateReturnForPartialAcceptance ? 'Firma iadesi olusur, e-irsaliye manuel gonderilir.' : 'Otomatik iade kapali; fark manuel iade bekler.'}',
            ),
          ],
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

  Widget _buildDocumentDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 6,
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
        const SizedBox(height: 6),
        TextFormField(
          controller: _documentNoController,
          decoration: const InputDecoration(
            labelText: 'Belge No / Seri',
            hintText: 'Bos birakilabilir veya ULK gibi seri girilebilir',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final twoColumn = maxWidth >= 300;
            final fieldWidth = twoColumn ? (maxWidth - 8) / 2 : maxWidth;

            return Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                SizedBox(
                  width: fieldWidth,
                  child: TextFormField(
                    controller: _delivererController,
                    decoration: const InputDecoration(
                      labelText: 'Teslim Eden',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: TextFormField(
                    controller: _receiverController,
                    decoration: const InputDecoration(
                      labelText: 'Teslim Alan',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descriptionController,
          minLines: 1,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Aciklama',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
        const SizedBox(height: 6),
        CheckboxListTile(
          value: _allowOrderOverReceiving,
          title: const Text('Siparis kalanindan fazla kabul etmeye izin ver'),
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
        CheckboxListTile(
          value: _autoCreateReturnForPartialAcceptance,
          title: const Text('Eksik kabul farki icin firma iadesi olustur'),
          subtitle: const Text(
            'E-irsaliye otomatik gonderilmez; iade evragindan manuel gonderilir.',
          ),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            setState(() {
              _autoCreateReturnForPartialAcceptance = value ?? true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCustomerLookupRow() {
    final lookupField = TextField(
      controller: _customerSearchController,
      decoration: const InputDecoration(
        labelText: 'Cari ara',
        hintText: 'Cari adi veya kodu',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );

    final searchButton = FilledButton.icon(
      onPressed: _searchCustomer,
      icon: const Icon(Icons.search_rounded),
      label: const Text('Bul'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              lookupField,
              const SizedBox(height: 8),
              searchButton,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: lookupField),
            const SizedBox(width: 12),
            searchButton,
          ],
        );
      },
    );
  }

  Widget _buildProductLookupRow(_OfflineCompanyAcceptanceLineDraft line) {
    final lookupField = ProductLookupField(
      controller: line.lookupController,
      focusNode: line.lookupFocusNode,
      selectTextOnFocus: line.selectedProduct == null,
      onSubmit: () => _searchProduct(line),
    );

    final searchButton = FilledButton.icon(
      onPressed: () => _searchProduct(line),
      icon: const Icon(Icons.search_rounded),
      label: const Text('Urun'),
    );

    final scanButton = IconButton.filledTonal(
      onPressed: () => _scanProductWithCamera(line),
      tooltip: 'Kamera ile oku',
      icon: const Icon(Icons.photo_camera_back_rounded),
    );

    return TerminalResponsiveLookupRow(
      field: lookupField,
      action: searchButton,
      trailingAction: scanButton,
    );
  }

  Widget _buildQuantityFields(_OfflineCompanyAcceptanceLineDraft line) {
    Widget dispatchField() {
      return TerminalQuantityStepper(
        controller: line.dispatchQuantityController,
        label: 'Irsaliye Miktari*',
        onMinimumReached: () {
          final index = _lines.indexOf(line);
          if (index < 0 || _lines.length <= 1) {
            return;
          }
          setState(() {
            line.dispose();
            _lines.removeAt(index);
          });
        },
        onChanged: (_) => setState(() {}),
        validator: (_) {
          if (line.dispatchQuantity <= 0) {
            return 'Miktar > 0';
          }
          return null;
        },
      );
    }

    Widget acceptedField() {
      return TerminalQuantityStepper(
        controller: line.acceptedQuantityController,
        label: 'Sayilan Miktar*',
        maximum: line.dispatchQuantity,
        onChanged: (_) => setState(() {}),
        validator: (_) {
          if (line.acceptedQuantity < 0) {
            return 'Negatif olamaz';
          }
          if (line.acceptedQuantity > line.dispatchQuantity) {
            return 'Irsaliyeyi gecemez';
          }
          return null;
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: <Widget>[
              dispatchField(),
              const SizedBox(height: 10),
              acceptedField(),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: dispatchField()),
            const SizedBox(width: 12),
            Expanded(child: acceptedField()),
          ],
        );
      },
    );
  }
}

class _OfflineCompanyAcceptanceLineDraft {
  _OfflineCompanyAcceptanceLineDraft()
    : lookupController = TextEditingController(),
      stockCodeController = TextEditingController(),
      stockNameController = TextEditingController(),
      barcodeController = TextEditingController(),
      dispatchQuantityController = TextEditingController(),
      acceptedQuantityController = TextEditingController(),
      unitPriceController = TextEditingController(text: '0'),
      unitPointerController = TextEditingController(text: '1'),
      descriptionController = TextEditingController(),
      partyCodeController = TextEditingController(),
      lotNoController = TextEditingController(text: '0'),
      projectCodeController = TextEditingController(),
      lastConsumingDateController = TextEditingController();

  _OfflineCompanyAcceptanceLineDraft.fromOrderItem(CompanyOrderDetailItem item)
    : lookupController = TextEditingController(
        text: '${item.stockCode} - ${item.stockName}',
      ),
      stockCodeController = TextEditingController(text: item.stockCode),
      stockNameController = TextEditingController(text: item.stockName),
      barcodeController = TextEditingController(),
      dispatchQuantityController = TextEditingController(
        text: item.remainingQuantity.toString(),
      ),
      acceptedQuantityController = TextEditingController(
        text: item.remainingQuantity.toString(),
      ),
      unitPriceController = TextEditingController(
        text: item.unitPrice.toString(),
      ),
      unitPointerController = TextEditingController(
        text: '${item.unitPointer}',
      ),
      descriptionController = TextEditingController(text: item.description),
      partyCodeController = TextEditingController(),
      lotNoController = TextEditingController(text: '0'),
      projectCodeController = TextEditingController(text: item.projectCode),
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
  }

  final TextEditingController lookupController;
  final TextEditingController stockCodeController;
  final TextEditingController stockNameController;
  final TextEditingController barcodeController;
  final TextEditingController dispatchQuantityController;
  final TextEditingController acceptedQuantityController;
  final TextEditingController unitPriceController;
  final TextEditingController unitPointerController;
  final TextEditingController descriptionController;
  final TextEditingController partyCodeController;
  final TextEditingController lotNoController;
  final TextEditingController projectCodeController;
  final TextEditingController lastConsumingDateController;
  final FocusNode lookupFocusNode = FocusNode();

  SearchProductLookupItem? selectedProduct;
  String? orderGuid;

  double get dispatchQuantity =>
      _readDouble(dispatchQuantityController.text, fallback: 0);
  double get acceptedQuantity =>
      _readDouble(acceptedQuantityController.text, fallback: 0);
  double get returnQuantity {
    final value = dispatchQuantity - acceptedQuantity;
    return value > 0 ? value : 0;
  }

  double get unitPrice => _readDouble(unitPriceController.text, fallback: 0);
  int get unitPointer => _readInt(unitPointerController.text, fallback: 1);
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
    lookupController.clear();
    stockCodeController.text = product.stockCode;
    stockNameController.text = product.stockName;
    barcodeController.text = product.barcode;
    if (dispatchQuantityController.text.trim().isEmpty) {
      dispatchQuantityController.text = _formatQuantity(
        _unitMultiplierQuantity(product.unitMultiplier),
      );
    }
    if (acceptedQuantityController.text.trim().isEmpty) {
      acceptedQuantityController.text = _formatQuantity(
        _unitMultiplierQuantity(product.unitMultiplier),
      );
    }
    unitPriceController.text = _formatQuantity(
      product.companyAcceptanceUnitPrice,
    );
  }

  void clear() {
    lookupController.clear();
    stockCodeController.clear();
    stockNameController.clear();
    barcodeController.clear();
    dispatchQuantityController.clear();
    acceptedQuantityController.clear();
    unitPriceController.text = '0';
    unitPointerController.text = '1';
    descriptionController.clear();
    partyCodeController.clear();
    lotNoController.text = '0';
    projectCodeController.clear();
    lastConsumingDateController.clear();
    selectedProduct = null;
    orderGuid = null;
  }

  void dispose() {
    lookupFocusNode.dispose();
    lookupController.dispose();
    stockCodeController.dispose();
    stockNameController.dispose();
    barcodeController.dispose();
    dispatchQuantityController.dispose();
    acceptedQuantityController.dispose();
    unitPriceController.dispose();
    unitPointerController.dispose();
    descriptionController.dispose();
    partyCodeController.dispose();
    lotNoController.dispose();
    projectCodeController.dispose();
    lastConsumingDateController.dispose();
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

double _quantityInputOrUnitMultiplier(String raw, double unitMultiplier) {
  return productEntryController.quantityInputOrUnitMultiplier(
    raw,
    unitMultiplier,
  );
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
