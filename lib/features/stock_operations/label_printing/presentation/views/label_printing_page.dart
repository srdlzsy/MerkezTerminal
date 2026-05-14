import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/label_documents/data/label_documents_repository.dart';
import 'package:furpa_merkez_terminal/features/stock_operations/label_documents/data/models/label_document_models.dart';
import 'package:furpa_merkez_terminal/shared/formatters/app_formatters.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

enum _LabelPrintingMode { kunyeTags, priceChanged }

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

class LabelPrintingPage extends StatefulWidget {
  const LabelPrintingPage({
    super.key,
    required this.repository,
    required this.accessToken,
    required this.defaultWarehouseNo,
    required this.userWarehouseName,
  });

  final LabelDocumentsRepository repository;
  final String accessToken;
  final String defaultWarehouseNo;
  final String userWarehouseName;

  @override
  State<LabelPrintingPage> createState() => _LabelPrintingPageState();
}

class _LabelPrintingPageState extends State<LabelPrintingPage> {
  _LabelPrintingMode _mode = _LabelPrintingMode.kunyeTags;
  DateTime _selectedDate = _today();
  DateTime _priceChangedAt = _today();
  bool _isLoading = false;
  String? _errorMessage;
  List<LabelTag> _tags = const <LabelTag>[];
  List<LabelPriceChangedProduct> _priceChangedProducts =
      const <LabelPriceChangedProduct>[];

  @override
  void initState() {
    super.initState();
    unawaited(_loadCurrentMode());
  }

  Future<void> _loadCurrentMode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      switch (_mode) {
        case _LabelPrintingMode.kunyeTags:
          _tags = await widget.repository.fetchTags(
            accessToken: widget.accessToken,
            dateToGet: _selectedDate,
          );
          break;
        case _LabelPrintingMode.priceChanged:
          _priceChangedProducts = await widget.repository
              .fetchPriceChangedProducts(
                accessToken: widget.accessToken,
                dateTimeFilter: _priceChangedAt,
              );
          break;
      }

      if (!mounted) {
        return;
      }

      setState(() {
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

  Future<void> _pickDate({required bool forTags}) async {
    final initialDate = forTags ? _selectedDate : _priceChangedAt;
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
      if (forTags) {
        _selectedDate = pickedDate;
      } else {
        _priceChangedAt = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _priceChangedAt.hour,
          _priceChangedAt.minute,
          _priceChangedAt.second,
        );
      }
    });

    await _loadCurrentMode();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
          _buildHeader(),
          const SizedBox(height: 16),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return TerminalListHeaderCard(
      title: 'Kunye Etiket Yazdirma',
      subtitle:
          'Kunye etiketi ve fiyat degisen urunlerin etiket basim hazirligi bu ekranda ayri akista yonetilir.',
      infoChips: <Widget>[
        TerminalInfoChip(
          label: 'Varsayilan depo',
          value: '${widget.defaultWarehouseNo} - ${widget.userWarehouseName}',
        ),
        TerminalInfoChip(
          label: 'Kaynak',
          value: switch (_mode) {
            _LabelPrintingMode.kunyeTags => 'VwKunyeNet',
            _LabelPrintingMode.priceChanged => 'Fiyat Degisimi',
          },
        ),
      ],
      filters: <Widget>[
        ChoiceChip(
          label: const Text('Kunye Etiketleri'),
          selected: _mode == _LabelPrintingMode.kunyeTags,
          onSelected: (_) {
            setState(() => _mode = _LabelPrintingMode.kunyeTags);
            unawaited(_loadCurrentMode());
          },
        ),
        ChoiceChip(
          label: const Text('Fiyat Degisenler'),
          selected: _mode == _LabelPrintingMode.priceChanged,
          onSelected: (_) {
            setState(() => _mode = _LabelPrintingMode.priceChanged);
            unawaited(_loadCurrentMode());
          },
        ),
        if (_mode == _LabelPrintingMode.kunyeTags)
          TerminalFilterButton(
            label: 'Kunye Tarihi',
            value: AppFormatters.date(_selectedDate),
            onPressed: () => _pickDate(forTags: true),
          ),
        if (_mode == _LabelPrintingMode.priceChanged)
          TerminalFilterButton(
            label: 'Fiyat Degisim Baslangici',
            value: AppFormatters.dateTime(_priceChangedAt),
            onPressed: () => _pickDate(forTags: false),
          ),
      ],
      actions: <Widget>[
        FilledButton.icon(
          onPressed: _isLoading ? null : _loadCurrentMode,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Yenile'),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return SectionCard(
        title: 'Etiket Basim Verisi',
        subtitle: 'Islem sirasinda hata olustu.',
        child: TerminalMessageBlock.error(message: _errorMessage!),
      );
    }

    if (_isLoading) {
      return const SectionCard(
        title: 'Etiket Basim Verisi',
        subtitle: 'Yukleniyor...',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return SectionCard(
      title: 'Etiket Basim Verisi',
      subtitle: switch (_mode) {
        _LabelPrintingMode.kunyeTags => '${_tags.length} kunye bulundu.',
        _LabelPrintingMode.priceChanged =>
          '${_priceChangedProducts.length} urun bulundu.',
      },
      child: switch (_mode) {
        _LabelPrintingMode.kunyeTags => _buildTagsView(),
        _LabelPrintingMode.priceChanged => _buildPriceChangedView(),
      },
    );
  }

  Widget _buildTagsView() {
    if (_tags.isEmpty) {
      return const TerminalEmptyState(message: 'Kunye etiketi bulunamadi.');
    }

    return Column(
      children: _tags
          .map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withAlpha(82),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.productName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.branchName} | Tag ${item.takenTag} | ${AppFormatters.quantity(item.quantity)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.goodsType} / ${item.goodsGenus} | Uretim ${AppFormatters.dateOrDash(item.productionDate)} | Sevk ${AppFormatters.dateOrDash(item.shippingDate)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uretici ${item.manufacturer} | Alici ${item.buyer} | Alis ${AppFormatters.currency(item.buyingPrice)}',
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildPriceChangedView() {
    if (_priceChangedProducts.isEmpty) {
      return const TerminalEmptyState(
        message: 'Fiyati degisen etiket urunu bulunamadi.',
      );
    }

    return Column(
      children: _priceChangedProducts
          .map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withAlpha(82),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.productName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kod ${item.productCode} | Barkod ${item.barcode.isEmpty ? '-' : item.barcode}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Yeni ${AppFormatters.currency(item.price)} | Eski ${AppFormatters.currency(item.oldPrice)} | Birim ${item.unitName}',
                    ),
                    const SizedBox(height: 4),
                    Text('Degisim: ${item.priceChangeDate}'),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
