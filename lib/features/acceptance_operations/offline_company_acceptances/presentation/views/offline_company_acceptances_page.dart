import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/company_acceptances/data/company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/models/offline_company_acceptance_models.dart';
import 'package:furpa_merkez_terminal/features/acceptance_operations/offline_company_acceptances/data/offline_company_acceptances_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/given_company_orders_repository.dart';
import 'package:furpa_merkez_terminal/features/order_operations/given_company_orders/data/models/given_company_order_models.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_record_status.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_service.dart';
import 'package:furpa_merkez_terminal/shared/utils/client_request_id.dart';
import 'package:furpa_merkez_terminal/shared/widgets/barcode_camera_scan_page.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class OfflineCompanyAcceptancesPage extends StatefulWidget {
  const OfflineCompanyAcceptancesPage({
    super.key,
    required this.offlineRepository,
    required this.onlineRepository,
    required this.ordersRepository,
    required this.accessToken,
    required this.offlineSyncService,
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
    final draft = await showModalBottomSheet<OfflineCompanyAcceptanceDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return _OfflineCompanyAcceptanceCreateSheet(
          repository: widget.onlineRepository,
          ordersRepository: widget.ordersRepository,
          accessToken: widget.accessToken,
          currentUserId: widget.currentUserId,
          defaultWarehouseNo: widget.defaultWarehouseNo,
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
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
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
                                      title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  TerminalBadge(
                                    label: offlineRecordStatusLabel(
                                      draft.status,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TerminalBadge(
                                    label: '${draft.lines.length} satir',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$customerLabel | Belge ${AppFormatters.date(draft.documentDate)} | Hareket ${AppFormatters.date(draft.movementDate)}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Olusturma ${AppFormatters.dateTime(draft.createdAt)}',
                              ),
                              if (draft.lastSyncAttemptAt != null)
                                Text(
                                  'Son deneme ${AppFormatters.dateTime(draft.lastSyncAttemptAt!)}',
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
                                  AppFormatters.quantity(line.quantity),
                                  if ((line.orderGuid ?? '').trim().isNotEmpty)
                                    'Siparisli',
                                ].join(' | ');

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text('$label | $extras'),
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
  });

  final CompanyAcceptancesRepository repository;
  final GivenCompanyOrdersRepository ordersRepository;
  final String accessToken;
  final String currentUserId;
  final String defaultWarehouseNo;

  @override
  State<_OfflineCompanyAcceptanceCreateSheet> createState() =>
      _OfflineCompanyAcceptanceCreateSheetState();
}

class _OfflineCompanyAcceptanceCreateSheetState
    extends State<_OfflineCompanyAcceptanceCreateSheet> {
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
  CustomerLookupItem? _selectedCustomer;
  String? _validationMessage;

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

    final customers = await widget.repository.searchCustomers(
      accessToken: widget.accessToken,
      query: query,
    );

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
      _selectedCustomer = selected;
      _customerSearchController.text = selected.displayLabel;
      _customerCodeController.text = selected.customerCode;
      _validationMessage = null;
    });
  }

  Future<void> _searchProduct(_OfflineCompanyAcceptanceLineDraft line) async {
    final query = line.lookupController.text.trim();

    if (query.length < 2) {
      setState(() {
        _validationMessage =
            'Urun aramak icin en az 2 karakter veya barkod girilmeli.';
      });
      return;
    }

    final customerCode = _customerCodeController.text.trim();
    final products = await widget.repository.searchProducts(
      accessToken: widget.accessToken,
      warehouseNo: widget.defaultWarehouseNo,
      query: query,
      customerCode: customerCode.isEmpty ? null : customerCode,
    );

    if (!mounted) {
      return;
    }

    if (products.isEmpty) {
      setState(() {
        _validationMessage = 'Bu aramaya uygun urun bulunamadi.';
      });
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

    setState(() {
      line.applyProduct(selected);
      _validationMessage = null;
    });
  }

  Future<void> _scanProductWithCamera(
    _OfflineCompanyAcceptanceLineDraft line,
  ) async {
    if (!supportsCameraBarcodeScanning) {
      setState(() {
        _validationMessage =
            'Bu cihazda kamera ile barkod okutma desteklenmiyor.';
      });
      return;
    }

    final barcode = await openBarcodeCameraScanner(
      context,
      title: 'Offline Mal Kabul Kamerasi',
      subtitle: 'Barkodu okutun; bulunan urun satira aktarilacak.',
    );

    if (barcode == null || !mounted) {
      return;
    }

    setState(() {
      line.lookupController.text = barcode;
      _validationMessage = null;
    });

    await _searchProduct(line);
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
      _validationMessage = null;
    });
  }

  void _submit() {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final customerCode = _customerCodeController.text.trim();
    final documentNo = _documentNoController.text.trim();

    if (customerCode.isEmpty) {
      setState(() {
        _validationMessage = 'Cari kodu zorunludur.';
      });
      return;
    }

    if (!_looksLikeDocumentNo(documentNo)) {
      setState(() {
        _validationMessage =
            'Belge No bosluksuz seri + 9 haneli sayisal sira formatinda olmali.';
      });
      return;
    }

    if (_lines.isEmpty) {
      setState(() {
        _validationMessage = 'En az bir satir girilmeli.';
      });
      return;
    }

    for (var index = 0; index < _lines.length; index += 1) {
      final line = _lines[index];
      if (line.stockCodeController.text.trim().isEmpty) {
        setState(() {
          _validationMessage = '${index + 1}. satir icin stok kodu zorunlu.';
        });
        return;
      }
      if (line.quantity <= 0) {
        setState(() {
          _validationMessage =
              '${index + 1}. satir icin miktar sifirdan buyuk olmali.';
        });
        return;
      }
      if (line.unitPointer <= 0) {
        setState(() {
          _validationMessage =
              '${index + 1}. satir icin unitPointer sifirdan buyuk olmali.';
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
        deliverer: _delivererController.text.trim(),
        receiver: _receiverController.text.trim(),
        description: _descriptionController.text.trim(),
        allowOrderOverReceiving: _allowOrderOverReceiving,
        createdAt: DateTime.now(),
        status: OfflineRecordStatus.pending,
        lastSyncAttemptAt: null,
        lastError: null,
        lines: _lines
            .map(
              (line) => OfflineCompanyAcceptanceLine(
                stockCode: line.stockCodeController.text.trim(),
                stockName: line.stockNameController.text.trim(),
                barcode: line.barcodeController.text.trim(),
                quantity: line.quantity,
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
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              const TerminalSheetHeader(
                title: 'Yeni Offline Firma Mal Kabul',
                subtitle:
                    'Taslak ilk kayitta clientRequestId ile saklanir. Online arama ve siparis baglama yardimcidir; gerekirse cari kodu ve stok kodu manuel de girilebilir.',
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _customerSearchController,
                      decoration: const InputDecoration(
                        labelText: 'Cari ara',
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
                decoration: const InputDecoration(labelText: 'Cari Kodu*'),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Cari kodu zorunlu.';
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
                decoration: const InputDecoration(labelText: 'Belge No*'),
                validator: (value) {
                  if (!_looksLikeDocumentNo((value ?? '').trim())) {
                    return 'Seri + 9 haneli sira';
                  }
                  return null;
                },
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
                      decoration: const InputDecoration(
                        labelText: 'Teslim Eden',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextFormField(
                      controller: _receiverController,
                      decoration: const InputDecoration(
                        labelText: 'Teslim Alan',
                      ),
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
                    onPressed: () {
                      setState(() {
                        _lines.add(_OfflineCompanyAcceptanceLineDraft());
                      });
                    },
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
                            if ((line.orderGuid ?? '').trim().isNotEmpty)
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
                              child: TextField(
                                controller: line.lookupController,
                                decoration: const InputDecoration(
                                  labelText: 'Barkod / stok kodu / urun adi',
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
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            SizedBox(
                              width: 160,
                              child: TextFormField(
                                controller: line.stockCodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Stok Kodu*',
                                ),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Zorunlu';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(
                              width: 220,
                              child: TextField(
                                controller: line.stockNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Stok Adi',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: TextField(
                                controller: line.barcodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Barkod',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
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
                          decoration: const InputDecoration(
                            labelText: 'Miktar*',
                          ),
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
              if (_validationMessage != null) ...<Widget>[
                TerminalMessageBlock.error(message: _validationMessage!),
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
                      label: const Text('Taslagi Kaydet'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineCompanyAcceptanceLineDraft {
  _OfflineCompanyAcceptanceLineDraft()
    : lookupController = TextEditingController(),
      stockCodeController = TextEditingController(),
      stockNameController = TextEditingController(),
      barcodeController = TextEditingController(),
      quantityController = TextEditingController(text: '1'),
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
      quantityController = TextEditingController(
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
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final TextEditingController unitPointerController;
  final TextEditingController descriptionController;
  final TextEditingController partyCodeController;
  final TextEditingController lotNoController;
  final TextEditingController projectCodeController;
  final TextEditingController lastConsumingDateController;

  SearchProductLookupItem? selectedProduct;
  String? orderGuid;

  double get quantity => _readDouble(quantityController.text, fallback: 0);
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
    lookupController.text = product.displayLabel;
    stockCodeController.text = product.stockCode;
    stockNameController.text = product.stockName;
    barcodeController.text = product.barcode;
    unitPriceController.text = product.price.toString();
  }

  void dispose() {
    lookupController.dispose();
    stockCodeController.dispose();
    stockNameController.dispose();
    barcodeController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    unitPointerController.dispose();
    descriptionController.dispose();
    partyCodeController.dispose();
    lotNoController.dispose();
    projectCodeController.dispose();
    lastConsumingDateController.dispose();
  }
}

bool _looksLikeDocumentNo(String value) {
  if (value.isEmpty || value.contains(RegExp(r'\s')) || value.length <= 9) {
    return false;
  }

  final suffix = value.substring(value.length - 9);
  return RegExp(r'^\d{9}$').hasMatch(suffix);
}

double _readDouble(String value, {required double fallback}) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
}

int _readInt(String value, {required int fallback}) {
  return int.tryParse(value.trim()) ?? fallback;
}
