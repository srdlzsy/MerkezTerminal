import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:furpa_merkez_terminal/shared/utils/create_form_validation.dart';

class WarehouseReturnEDespatchSheet extends StatefulWidget {
  const WarehouseReturnEDespatchSheet({
    super.key,
    required this.documentNoLabel,
    this.initialPlaque = '',
    this.initialDriverNameSurname = '',
    this.initialDriverTckn = '',
  });

  final String documentNoLabel;
  final String initialPlaque;
  final String initialDriverNameSurname;
  final String initialDriverTckn;

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

  @override
  void initState() {
    super.initState();
    _plaqueController = TextEditingController(text: widget.initialPlaque);
    _driverController = TextEditingController(
      text: widget.initialDriverNameSurname,
    );
    _tcknController = TextEditingController(text: widget.initialDriverTckn);
  }

  @override
  void dispose() {
    _plaqueController.dispose();
    _driverController.dispose();
    _tcknController.dispose();
    super.dispose();
  }

  void _submit() {
    final form = _formKey.currentState;

    if (form == null || !validateCreateForm(_formKey)) {
      return;
    }

    Navigator.of(context).pop(
      EDespatchSendRequest(
        plaque: _plaqueController.text,
        driverNameSurname: _driverController.text,
        driverTckn: _tcknController.text,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'E-Irsaliyeye Cevir',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.documentNoLabel} icin tasima bilgilerini girip gonderimi baslatin.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _plaqueController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Plaka',
                hintText: '16 ABC 123',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
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
                if ((value ?? '').trim().isEmpty) {
                  return 'Sofor adi soyadi zorunludur.';
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

                if (normalized.isEmpty) {
                  return 'Sofor TCKN zorunludur.';
                }

                if (normalized.length != 11) {
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
                'Dokumana gore bu alanlar create ekraninda degil, tam gonderim aninda zorunlu alinmali.',
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
    );
  }
}
