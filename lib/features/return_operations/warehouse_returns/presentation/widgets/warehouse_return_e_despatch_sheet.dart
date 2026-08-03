import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/shared/data/despatch_drivers_repository.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';

typedef DespatchDriverSearchCallback =
    Future<List<DespatchDriverLookupItem>> Function(String query);

class WarehouseReturnEDespatchSheet extends StatefulWidget {
  const WarehouseReturnEDespatchSheet({
    super.key,
    required this.documentNoLabel,
    this.initialPlaque = '',
    this.initialDriverNameSurname = '',
    this.initialDriverTckn = '',
    this.onSearchDrivers,
  });

  final String documentNoLabel;
  final String initialPlaque;
  final String initialDriverNameSurname;
  final String initialDriverTckn;
  final DespatchDriverSearchCallback? onSearchDrivers;

  @override
  State<WarehouseReturnEDespatchSheet> createState() =>
      _WarehouseReturnEDespatchSheetState();
}

class _WarehouseReturnEDespatchSheetState
    extends State<WarehouseReturnEDespatchSheet>
    with CreateFormValidation {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _plaqueController;
  late final TextEditingController _driverController;
  late final TextEditingController _tcknController;
  late final TextEditingController _driverSearchController;

  Timer? _driverSearchDebounce;
  int _driverSearchRequestId = 0;
  DespatchDriverLookupItem? _selectedDriver;
  List<DespatchDriverLookupItem> _driverResults =
      const <DespatchDriverLookupItem>[];
  bool _isSearchingDrivers = false;
  String? _driverSearchError;

  bool get _requiresManualDriverFields => _selectedDriver == null;

  @override
  void initState() {
    super.initState();
    _plaqueController = TextEditingController(text: widget.initialPlaque);
    _driverController = TextEditingController(
      text: widget.initialDriverNameSurname,
    );
    _tcknController = TextEditingController(text: widget.initialDriverTckn);
    _driverSearchController = TextEditingController();

    if (widget.onSearchDrivers != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_searchDrivers(''));
        }
      });
    }
  }

  @override
  void dispose() {
    _driverSearchDebounce?.cancel();
    _plaqueController.dispose();
    _driverController.dispose();
    _tcknController.dispose();
    _driverSearchController.dispose();
    super.dispose();
  }

  void _queueDriverSearch(String query) {
    _driverSearchDebounce?.cancel();
    setState(() {
      _selectedDriver = null;
    });
    _driverSearchDebounce = Timer(const Duration(milliseconds: 320), () {
      unawaited(_searchDrivers(query));
    });
  }

  Future<void> _searchDrivers(String query) async {
    final searchCallback = widget.onSearchDrivers;

    if (searchCallback == null) {
      return;
    }

    final requestId = ++_driverSearchRequestId;
    setState(() {
      _isSearchingDrivers = true;
      _driverSearchError = null;
    });

    try {
      final drivers = await searchCallback(query);

      if (!mounted || requestId != _driverSearchRequestId) {
        return;
      }

      setState(() {
        _driverResults = drivers.where((item) => item.isActive).toList();
        _isSearchingDrivers = false;
      });
    } on Object {
      if (!mounted || requestId != _driverSearchRequestId) {
        return;
      }

      setState(() {
        _driverResults = const <DespatchDriverLookupItem>[];
        _isSearchingDrivers = false;
        _driverSearchError = 'Sofor listesi alinamadi.';
      });
    }
  }

  void _selectDriver(DespatchDriverLookupItem driver) {
    _driverSearchDebounce?.cancel();
    _driverSearchController.text = driver.displayName;
    _plaqueController.text = driver.plateNumber;
    _driverController.text = driver.displayName;
    _tcknController.text = driver.tckn;

    setState(() {
      _selectedDriver = driver;
      _driverResults = const <DespatchDriverLookupItem>[];
      _driverSearchError = null;
    });
  }

  void _clearSelectedDriver() {
    _driverSearchDebounce?.cancel();
    _driverSearchController.clear();

    setState(() {
      _selectedDriver = null;
      _driverResults = const <DespatchDriverLookupItem>[];
      _driverSearchError = null;
    });

    unawaited(_searchDrivers(''));
  }

  void _submit() {
    final form = _formKey.currentState;

    if (form == null || !validateCreateForm(_formKey)) {
      return;
    }

    Navigator.of(context).pop(
      EDespatchSendRequest(
        driverId: _selectedDriver?.id,
        plaque: _plaqueController.text,
        driverNameSurname: _driverController.text,
        driverTckn: _tcknController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        autovalidateMode: createFormAutovalidateMode,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'E-Irsaliyeye Cevir',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.documentNoLabel} icin tasima bilgilerini girip gonderimi baslatin.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                if (widget.onSearchDrivers != null) ...<Widget>[
                  const SizedBox(height: 18),
                  _buildDriverSearchSection(context),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: _plaqueController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Plaka',
                    hintText: '16 ABC 123',
                  ),
                  validator: (value) {
                    if (_requiresManualDriverFields &&
                        (value ?? '').trim().isEmpty) {
                      return 'Plaka zorunludur.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _driverController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Sofor Adi Soyadi',
                    hintText: 'Ad Soyad',
                  ),
                  validator: (value) {
                    final normalized = (value ?? '').trim();

                    if (_requiresManualDriverFields && normalized.isEmpty) {
                      return 'Sofor adi soyadi zorunludur.';
                    }

                    if (normalized.isNotEmpty &&
                        normalized.split(RegExp(r'\s+')).length < 2) {
                      return 'Ad soyad formatinda girilmeli.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _tcknController,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Sofor TCKN',
                    hintText: '11111111111',
                  ),
                  validator: (value) {
                    final normalized = (value ?? '').trim();

                    if (_requiresManualDriverFields && normalized.isEmpty) {
                      return 'Sofor TCKN zorunludur.';
                    }

                    if (normalized.isNotEmpty && normalized.length != 11) {
                      return 'TCKN 11 haneli olmali.';
                    }

                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F1EA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    widget.onSearchDrivers == null
                        ? 'Dokumana gore bu alanlar create ekraninda degil, tam gonderim aninda zorunlu alinmali.'
                        : 'Kayitli sofor secilirse driverId gonderilir. Secmeden devam edilirse manuel plaka, sofor ve TCKN bilgileri kullanilir.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
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
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Gonder'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverSearchSection(BuildContext context) {
    final searchText = _driverSearchController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _driverSearchController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Kayitli Sofor',
            hintText: 'Ad, plaka veya TCKN ara',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _selectedDriver != null || searchText.isNotEmpty
                ? IconButton(
                    tooltip: 'Secimi temizle',
                    onPressed: _clearSelectedDriver,
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
          ),
          onChanged: _queueDriverSearch,
        ),
        if (_isSearchingDrivers) ...<Widget>[
          const SizedBox(height: 8),
          const LinearProgressIndicator(minHeight: 2),
        ],
        if (_selectedDriver case final driver?) ...<Widget>[
          const SizedBox(height: 10),
          _SelectedDriverCard(driver: driver, onClear: _clearSelectedDriver),
        ] else ...<Widget>[
          if (_driverSearchError case final error?) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
            ),
          ],
          if (!_isSearchingDrivers &&
              _driverSearchError == null &&
              searchText.isNotEmpty &&
              _driverResults.isEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Uygun kayitli sofor bulunamadi.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_driverResults.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            ..._driverResults
                .take(5)
                .map(
                  (driver) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DriverResultTile(
                      driver: driver,
                      onSelected: () => _selectDriver(driver),
                    ),
                  ),
                ),
          ],
        ],
      ],
    );
  }
}

class _SelectedDriverCard extends StatelessWidget {
  const _SelectedDriverCard({required this.driver, required this.onClear});

  final DespatchDriverLookupItem driver;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB8DAC7)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.badge_rounded, color: Color(0xFF236443)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  driver.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (driver.summary.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    driver.summary,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Secimi temizle',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _DriverResultTile extends StatelessWidget {
  const _DriverResultTile({required this.driver, required this.onSelected});

  final DespatchDriverLookupItem driver;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7FAF8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              const Icon(Icons.person_search_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      driver.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (driver.summary.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        driver.summary,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
