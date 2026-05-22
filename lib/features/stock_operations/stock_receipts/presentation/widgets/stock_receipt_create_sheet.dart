import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/models/stock_receipt_models.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/stock_receipts/data/stock_receipts_repository.dart';
import 'package:furpa_merkez_terminal/shared/data/search_lookup_models.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class StockReceiptCreateSheet extends StatefulWidget {
  const StockReceiptCreateSheet({
    super.key,
    required this.repository,
    required this.kind,
    required this.accessToken,
    required this.defaultWarehouseNo,
  });

  final StockReceiptsRepository repository;
  final StockReceiptKind kind;
  final String accessToken;
  final String defaultWarehouseNo;

  @override
  State<StockReceiptCreateSheet> createState() =>
      _StockReceiptCreateSheetState();
}

class _StockReceiptCreateSheetState extends State<StockReceiptCreateSheet>
    with CreateFormValidation {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<_StockReceiptLineDraft> _lines = <_StockReceiptLineDraft>[];
  late final TextEditingController _creatorController;
  late final TextEditingController _acceptorController;
  late final TextEditingController _documentNoController;
  late final TextEditingController _descriptionController;
  DateTime _movementDate = DateTime.now();
  DateTime _documentDate = DateTime.now();
  String? _lookupError;

  bool get _showDocumentNoField => widget.kind != StockReceiptKind.expense;

  @override
  void initState() {
    super.initState();
    _creatorController = TextEditingController();
    _acceptorController = TextEditingController();
    _documentNoController = TextEditingController();
    _descriptionController = TextEditingController();
    _lines.add(_StockReceiptLineDraft());
  }

  @override
  void dispose() {
    _creatorController.dispose();
    _acceptorController.dispose();
    _documentNoController.dispose();
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

  Future<void> _searchProduct(_StockReceiptLineDraft line) async {
    final query = line.lookupController.text.trim();

    if (query.length < 2) {
      setState(() {
        line.setLookupStatus(
          'Urun aramak icin en az 2 karakter veya barkod girilmeli.',
          isError: true,
        );
        _lookupError = null;
      });
      return;
    }

    List<SearchProductLookupItem> products;
    try {
      setState(() {
        line.setLookupStatus('API araniyor: $query', isLoading: true);
        _lookupError = null;
      });

      products = await widget.repository.searchProducts(
        accessToken: widget.accessToken,
        warehouseNo: widget.defaultWarehouseNo,
        query: query,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        line.setLookupStatus(
          'API hata dondu: ${error.toString().replaceFirst('Exception: ', '').trim()}',
          isError: true,
        );
        _lookupError = null;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    if (products.isEmpty) {
      setState(() {
        line.setLookupStatus(
          'API cevap verdi ama urun bulunamadi: $query',
          isError: true,
        );
      });
      return;
    }

    setState(() {
      line.setLookupStatus(
        '${products.length} urun bulundu. Listeden secim bekleniyor.',
      );
    });

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
      if (mounted) {
        setState(() {
          line.setLookupStatus(
            '${products.length} sonuc geldi, secim yapilmadi.',
          );
        });
      }
      return;
    }

    var mergedIntoExisting = false;
    setState(() {
      mergedIntoExisting = _applyProductToLine(line, selected);
      if (!mergedIntoExisting) {
        line.setLookupStatus(
          'Secildi: ${selected.stockCode} | ${selected.stockName}',
        );
      }
      _lookupError = null;
    });

    if (mergedIntoExisting) {
      _showFeedback('Ayni barkod mevcut satira eklendi; miktar artirildi.');
    }
  }

  bool _applyProductToLine(
    _StockReceiptLineDraft line,
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
    _recycleMergedLine(line, createReplacement: _StockReceiptLineDraft.new);
    return true;
  }

  _StockReceiptLineDraft? _findDuplicateLine({
    required _StockReceiptLineDraft currentLine,
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
    _StockReceiptLineDraft line, {
    required _StockReceiptLineDraft Function() createReplacement,
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
      _lines.insert(0, _StockReceiptLineDraft());
      _lookupError = null;
    });
  }

  void _submit() {
    final form = _formKey.currentState;

    if (form == null || !validateCreateForm(_formKey)) {
      return;
    }

    if (_lines.any((line) => line.selectedProduct == null)) {
      setState(() {
        _lookupError = 'Tum satirlarda urun secimi tamamlanmali.';
      });
      return;
    }

    Navigator.of(context).pop(
      StockReceiptCreateRequest(
        creator: _creatorController.text.trim(),
        acceptor: _acceptorController.text.trim(),
        movementDate: _movementDate,
        documentDate: _documentDate,
        documentNo: _showDocumentNoField
            ? _documentNoController.text.trim()
            : '',
        description: _descriptionController.text.trim(),
        lines: _lines
            .map(
              (line) => StockReceiptCreateLine(
                stockCode: line.selectedProduct!.stockCode,
                quantity: line.quantity,
                unitPointer: line.unitPointer,
                description: line.descriptionController.text.trim(),
                partyCode: line.partyCodeController.text.trim(),
                lotNo: line.lotNo,
                projectCode: line.projectCodeController.text.trim(),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        autovalidateMode: createFormAutovalidateMode,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            TerminalSheetHeader(
              title: widget.kind.createTitle,
              subtitle:
                  'Creator ve acceptor alanlari evrak notu gibi calisir. Satirlar yalnizca secilen kullanici deposu icin cikis hareketine doner.',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    controller: _creatorController,
                    decoration: const InputDecoration(labelText: 'Creator'),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    controller: _acceptorController,
                    decoration: const InputDecoration(labelText: 'Acceptor'),
                  ),
                ),
              ],
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
            if (_showDocumentNoField) ...<Widget>[
              TextFormField(
                controller: _documentNoController,
                decoration: const InputDecoration(labelText: 'Belge No'),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Aciklama'),
            ),
            const SizedBox(height: 12),
            TerminalSectionToolbar(
              title: 'Satirlar',
              actions: <Widget>[
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
                      TerminalResponsiveLookupRow(
                        field: TextFormField(
                          controller: line.lookupController,
                          decoration: const InputDecoration(
                            labelText: 'Barkod / stok kodu / urun adi',
                          ),
                          validator: (_) {
                            if (line.selectedProduct == null) {
                              return 'Urun secilmeli.';
                            }

                            return null;
                          },
                        ),
                        action: FilledButton.icon(
                          onPressed: line.isLookupStatusLoading
                              ? null
                              : () => _searchProduct(line),
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('Urun'),
                        ),
                      ),
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
                      if (line.selectedProduct != null) ...<Widget>[
                        const SizedBox(height: 8),
                        TerminalMessageBlock.info(
                          message:
                              '${line.selectedProduct!.stockCode} | ${line.selectedProduct!.stockName} | ${line.selectedProduct!.unitName}',
                        ),
                      ],
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
            TerminalFormActionRow(
              cancel: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Vazgec'),
              ),
              submit: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_alt_rounded),
                label: const Text('Kaydet'),
              ),
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

class _StockReceiptLineDraft {
  _StockReceiptLineDraft()
    : lookupController = TextEditingController(),
      quantityController = TextEditingController(text: '1'),
      unitPointerController = TextEditingController(text: '1'),
      descriptionController = TextEditingController(),
      partyCodeController = TextEditingController(),
      lotNoController = TextEditingController(text: '0'),
      projectCodeController = TextEditingController();

  final TextEditingController lookupController;
  final TextEditingController quantityController;
  final TextEditingController unitPointerController;
  final TextEditingController descriptionController;
  final TextEditingController partyCodeController;
  final TextEditingController lotNoController;
  final TextEditingController projectCodeController;

  SearchProductLookupItem? selectedProduct;
  String? lookupStatusMessage;
  bool isLookupStatusLoading = false;
  bool isLookupStatusError = false;

  double get quantity => _readDouble(quantityController.text, fallback: 0);
  int get unitPointer => _readInt(unitPointerController.text, fallback: 1);
  int get lotNo => _readInt(lotNoController.text, fallback: 0);

  void applyProduct(SearchProductLookupItem product) {
    selectedProduct = product;
    lookupController.text = product.displayLabel;
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
    lookupController.dispose();
    quantityController.dispose();
    unitPointerController.dispose();
    descriptionController.dispose();
    partyCodeController.dispose();
    lotNoController.dispose();
    projectCodeController.dispose();
  }
}

double _readDouble(String value, {required double fallback}) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
}

int _readInt(String value, {required int fallback}) {
  return int.tryParse(value.trim()) ?? fallback;
}
