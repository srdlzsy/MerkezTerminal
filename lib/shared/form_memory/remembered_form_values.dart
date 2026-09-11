import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RememberedFormField {
  deliverer('deliverer'),
  receiver('receiver'),
  creator('creator'),
  acceptor('acceptor');

  const RememberedFormField(this.storageKey);

  final String storageKey;
}

class RememberedFormValuesRepository {
  RememberedFormValuesRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const int maxValuesPerField = 5;
  static const String _keyPrefix = 'remembered_form_values.v1';

  final SharedPreferencesAsync? _preferences;

  Future<List<String>> read({
    required String warehouseNo,
    required RememberedFormField field,
  }) async {
    try {
      final preferences = _preferences ?? SharedPreferencesAsync();
      final values = await preferences.getStringList(
        _storageKey(warehouseNo: warehouseNo, field: field),
      );
      return normalize(values ?? const <String>[]);
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> remember({
    required String warehouseNo,
    required RememberedFormField field,
    required String value,
  }) async {
    final normalizedValue = value.trim();
    if (normalizedValue.isEmpty) {
      return;
    }

    try {
      final preferences = _preferences ?? SharedPreferencesAsync();
      final currentValues = await read(warehouseNo: warehouseNo, field: field);
      final updatedValues = normalize(<String>[
        normalizedValue,
        ...currentValues,
      ]);
      await preferences.setStringList(
        _storageKey(warehouseNo: warehouseNo, field: field),
        updatedValues,
      );
    } catch (_) {
      // Form submission must not fail when optional local memory is unavailable.
    }
  }

  Future<void> rememberAll({
    required String warehouseNo,
    required Map<RememberedFormField, String> values,
  }) async {
    for (final entry in values.entries) {
      await remember(
        warehouseNo: warehouseNo,
        field: entry.key,
        value: entry.value,
      );
    }
  }

  static List<String> normalize(Iterable<String> values) {
    final result = <String>[];
    final seen = <String>{};

    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || !seen.add(trimmed.toLowerCase())) {
        continue;
      }
      result.add(trimmed);
      if (result.length == maxValuesPerField) {
        break;
      }
    }

    return List<String>.unmodifiable(result);
  }

  String _storageKey({
    required String warehouseNo,
    required RememberedFormField field,
  }) {
    final normalizedWarehouse = warehouseNo.trim().toLowerCase();
    return '$_keyPrefix.$normalizedWarehouse.${field.storageKey}';
  }
}

class RememberedTextFormField extends StatefulWidget {
  const RememberedTextFormField({
    super.key,
    required this.warehouseNo,
    required this.field,
    required this.controller,
    required this.decoration,
    this.validator,
    this.textInputAction,
    this.maxLength,
    this.maxLengthEnforcement,
    this.inputFormatters,
    this.repository,
  });

  final String warehouseNo;
  final RememberedFormField field;
  final TextEditingController controller;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final List<TextInputFormatter>? inputFormatters;
  final RememberedFormValuesRepository? repository;

  @override
  State<RememberedTextFormField> createState() =>
      _RememberedTextFormFieldState();
}

class _RememberedTextFormFieldState extends State<RememberedTextFormField> {
  late RememberedFormValuesRepository _repository;
  final FocusNode _focusNode = FocusNode();
  List<String> _values = const <String>[];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? RememberedFormValuesRepository();
    _loadValues();
  }

  @override
  void didUpdateWidget(covariant RememberedTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.warehouseNo != widget.warehouseNo ||
        oldWidget.field != widget.field ||
        oldWidget.repository != widget.repository) {
      _repository = widget.repository ?? RememberedFormValuesRepository();
      _loadValues();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadValues() async {
    final values = await _repository.read(
      warehouseNo: widget.warehouseNo,
      field: widget.field,
    );
    if (mounted) {
      setState(() => _values = values);
    }
  }

  void _select(String value) {
    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<String>(
        textEditingController: widget.controller,
        focusNode: _focusNode,
        displayStringForOption: (value) => value,
        optionsBuilder: (textEditingValue) {
          final query = textEditingValue.text.trim().toLowerCase();
          if (query.isEmpty) {
            return _values;
          }
          return _values.where((value) => value.toLowerCase().contains(query));
        },
        onSelected: _select,
        fieldViewBuilder: (context, controller, focusNode, _) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: widget.decoration,
            validator: widget.validator,
            textInputAction: widget.textInputAction,
            maxLength: widget.maxLength,
            maxLengthEnforcement: widget.maxLengthEnforcement,
            inputFormatters: widget.inputFormatters,
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          final optionList = options.toList(growable: false);
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(6),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: constraints.maxWidth,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: optionList.length,
                    itemBuilder: (context, index) {
                      final value = optionList[index];
                      return InkWell(
                        onTap: () => onSelected(value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
