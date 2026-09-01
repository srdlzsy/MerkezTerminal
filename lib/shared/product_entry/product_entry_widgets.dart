import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class ProductLookupField extends StatefulWidget {
  const ProductLookupField({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.focusNode,
    this.autofocus = false,
    this.selectTextOnFocus = true,
    this.suppressSoftKeyboard = true,
    this.enabled = true,
    this.labelText = 'Barkod / stok kodu / urun adi',
    this.hintText,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSubmit;
  final bool autofocus;
  final bool selectTextOnFocus;
  final bool suppressSoftKeyboard;
  final bool enabled;
  final String labelText;
  final String? hintText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;

  @override
  State<ProductLookupField> createState() => _ProductLookupFieldState();
}

class ProductDraftEntryPanel extends StatelessWidget {
  const ProductDraftEntryPanel({
    super.key,
    required this.stockCode,
    required this.stockName,
    required this.quantityController,
    required this.onConfirm,
    required this.onCancel,
    this.title = 'Secilen urun',
    this.unitLabel,
    this.barcode,
    this.packageLabel,
    this.packageFactor,
    this.priceLabel,
    this.warningLabel,
    this.confirmLabel = 'Kaleme Ekle',
    this.quantityLabel = 'Miktar',
    this.quantityStep = 1,
    this.maximumQuantity,
    this.quantityInputFormatters = const <TextInputFormatter>[],
    this.quantityValidator,
    this.onQuantityChanged,
    this.secondaryQuantityController,
    this.secondaryQuantityLabel = 'Fiili Miktar',
    this.secondaryQuantityStep = 1,
    this.secondaryMaximumQuantity,
    this.secondaryQuantityInputFormatters = const <TextInputFormatter>[],
    this.secondaryQuantityValidator,
    this.onSecondaryQuantityChanged,
    this.extraInfo = const <TerminalPdaInfo>[],
    this.scanRow,
  });

  final String title;
  final String stockCode;
  final String stockName;
  final String? unitLabel;
  final String? barcode;
  final String? packageLabel;
  final double? packageFactor;
  final String? priceLabel;
  final String? warningLabel;
  final TextEditingController quantityController;
  final String confirmLabel;
  final String quantityLabel;
  final double quantityStep;
  final double? maximumQuantity;
  final List<TextInputFormatter> quantityInputFormatters;
  final FormFieldValidator<String>? quantityValidator;
  final ValueChanged<String>? onQuantityChanged;
  final TextEditingController? secondaryQuantityController;
  final String secondaryQuantityLabel;
  final double secondaryQuantityStep;
  final double? secondaryMaximumQuantity;
  final List<TextInputFormatter> secondaryQuantityInputFormatters;
  final FormFieldValidator<String>? secondaryQuantityValidator;
  final ValueChanged<String>? onSecondaryQuantityChanged;
  final List<TerminalPdaInfo> extraInfo;
  final Widget? scanRow;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboardHeight = mediaQuery.viewInsets.bottom;
        final usableHeight = mediaQuery.size.height - keyboardHeight;
        final isCompact =
            mediaQuery.size.width < 380 ||
            usableHeight < 700 ||
            keyboardHeight > 0 ||
            (constraints.hasBoundedHeight && constraints.maxHeight < 360);
        final body = _buildBody(
          context,
          isCompact: isCompact,
          includeActions: !isCompact,
        );

        if (!isCompact) {
          return TerminalPdaLineCard(
            title: title,
            subtitle: stockName,
            isEntryLine: true,
            leading: const Icon(Icons.inventory_2_rounded),
            trailing: IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Secimi temizle',
            ),
            child: body,
          );
        }

        return _CompactDraftEntryCard(
          title: stockName,
          subtitle: _compactMetaSummary,
          actions: _buildActionButtons(isCompact: true),
          child: body,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isCompact,
    required bool includeActions,
  }) {
    final effectiveScanRow = _scanRowFor(isCompact: isCompact);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (effectiveScanRow != null) ...<Widget>[
          effectiveScanRow,
          SizedBox(height: isCompact ? 4 : 10),
        ],
        if (!isCompact)
          TerminalPdaInfoGrid(minTileWidth: 92, spacing: 6, items: _infoItems),
        SizedBox(height: isCompact ? 3 : 10),
        _buildQuantityInputs(isCompact: isCompact),
        _buildQuantityAdvisory(context, isCompact: isCompact),
        SizedBox(height: isCompact ? 3 : 10),
        if (includeActions) _buildActionButtons(isCompact: isCompact),
      ],
    );
  }

  Widget? _scanRowFor({required bool isCompact}) {
    final row = scanRow;
    if (row == null || !isCompact) {
      return row;
    }

    if (row is TerminalResponsiveLookupRow) {
      return TerminalResponsiveLookupRow(
        field: row.field,
        action: row.action,
        trailingAction: row.trailingAction,
        breakpoint: 0,
        spacing: 4,
      );
    }

    return row;
  }

  List<TerminalPdaInfo> get _infoItems {
    return <TerminalPdaInfo>[
      TerminalPdaInfo(label: 'Kod', value: stockCode),
      if ((unitLabel ?? '').trim().isNotEmpty)
        TerminalPdaInfo(label: 'Birim', value: unitLabel!),
      if ((barcode ?? '').trim().isNotEmpty)
        TerminalPdaInfo(label: 'Barkod', value: barcode!),
      if ((packageLabel ?? '').trim().isNotEmpty)
        TerminalPdaInfo(label: 'Koli ici', value: _packageInfoValue),
      if ((priceLabel ?? '').trim().isNotEmpty)
        TerminalPdaInfo(label: 'Fiyat', value: priceLabel!),
      ...extraInfo,
    ];
  }

  String get _compactMetaSummary {
    return <String>[
      stockCode,
      if ((unitLabel ?? '').trim().isNotEmpty) unitLabel!,
      if ((packageLabel ?? '').trim().isNotEmpty) 'Koli ici $_packageInfoValue',
    ].where((part) => part.trim().isNotEmpty).join(' | ');
  }

  String get _packageInfoValue {
    final label = packageLabel?.trim() ?? '';
    if (label.isEmpty) {
      return '';
    }

    if (label.contains(RegExp(r'[A-Za-z]'))) {
      return label;
    }

    final unit = unitLabel?.trim() ?? '';
    return unit.isEmpty ? label : '$label $unit';
  }

  Widget _buildQuantityAdvisory(
    BuildContext context, {
    required bool isCompact,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: quantityController,
      builder: (context, value, _) {
        final messages = <_ProductDraftEntryAdvisory>[
          if ((warningLabel ?? '').trim().isNotEmpty)
            _ProductDraftEntryAdvisory.error(warningLabel!.trim()),
        ];
        final packageWarning = _packageMultipleWarning(value.text);
        if (packageWarning != null) {
          messages.add(_ProductDraftEntryAdvisory.warning(packageWarning));
        }

        if (messages.isEmpty) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.only(top: isCompact ? 4 : 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final message in messages)
                Text(
                  message.text,
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: message.isError
                        ? theme.colorScheme.error
                        : const Color(0xFF8A5A00),
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String? _packageMultipleWarning(String rawQuantity) {
    final factor = _effectivePackageFactor;
    if (factor <= 1) {
      return null;
    }

    final quantity = double.tryParse(rawQuantity.trim().replaceAll(',', '.'));
    if (quantity == null || quantity <= 0) {
      return null;
    }

    final nearestMultiple = (quantity / factor).roundToDouble() * factor;
    if ((quantity - nearestMultiple).abs() < 0.000001) {
      return null;
    }

    final unit = (unitLabel ?? '').trim();
    final factorLabel = _formatQuantity(factor);
    final unitSuffix = unit.isEmpty ? '' : ' $unit';
    return 'Koli ici $factorLabel$unitSuffix; girilen miktar koli kati degil.';
  }

  double get _effectivePackageFactor {
    final explicitFactor = packageFactor;
    if (explicitFactor != null && explicitFactor > 1) {
      return explicitFactor;
    }

    final label = packageLabel?.trim() ?? '';
    if (label.isEmpty) {
      return 0;
    }

    final match = RegExp(r'\d+(?:[,.]\d+)?').firstMatch(label);
    if (match == null) {
      return 0;
    }

    return double.tryParse(match.group(0)!.replaceAll(',', '.')) ?? 0;
  }

  static String _formatQuantity(double value) {
    final fixed = value.toStringAsFixed(6);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '').replaceAll('.', ',');
  }

  Widget _buildActionButtons({required bool isCompact}) {
    if (isCompact) {
      return Row(
        children: <Widget>[
          SizedBox(
            width: 40,
            height: 38,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 38),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Icon(Icons.clear_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FilledButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.playlist_add_rounded, size: 18),
              label: Text(
                confirmLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(38),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      );
    }

    final cancelButton = OutlinedButton.icon(
      onPressed: onCancel,
      icon: const Icon(Icons.clear_rounded),
      label: const Text('Vazgec'),
    );
    final confirmButton = FilledButton.icon(
      onPressed: onConfirm,
      icon: const Icon(Icons.playlist_add_rounded),
      label: Text(confirmLabel),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 330) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              confirmButton,
              const SizedBox(height: 8),
              cancelButton,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: cancelButton),
            const SizedBox(width: 8),
            Expanded(child: confirmButton),
          ],
        );
      },
    );
  }

  Widget _buildQuantityInputs({required bool isCompact}) {
    final primaryQuantity = TerminalQuantityStepper(
      controller: quantityController,
      label: quantityLabel,
      step: quantityStep,
      maximum: maximumQuantity,
      inputFormatters: quantityInputFormatters,
      validator: quantityValidator,
      onChanged: onQuantityChanged,
      onSubmitted: onConfirm,
      dense: isCompact,
    );
    final secondaryController = secondaryQuantityController;
    if (secondaryController == null) {
      return primaryQuantity;
    }

    final secondaryQuantity = TerminalQuantityStepper(
      controller: secondaryController,
      label: secondaryQuantityLabel,
      step: secondaryQuantityStep,
      maximum: secondaryMaximumQuantity,
      inputFormatters: secondaryQuantityInputFormatters,
      validator: secondaryQuantityValidator,
      onChanged: onSecondaryQuantityChanged,
      onSubmitted: onConfirm,
      dense: isCompact,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: <Widget>[
              primaryQuantity,
              SizedBox(height: isCompact ? 6 : 8),
              secondaryQuantity,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: primaryQuantity),
            const SizedBox(width: 10),
            Expanded(child: secondaryQuantity),
          ],
        );
      },
    );
  }
}

class _ProductDraftEntryAdvisory {
  const _ProductDraftEntryAdvisory._({
    required this.text,
    required this.isError,
  });

  const _ProductDraftEntryAdvisory.error(String text)
    : this._(text: text, isError: true);

  const _ProductDraftEntryAdvisory.warning(String text)
    : this._(text: text, isError: false);

  final String text;
  final bool isError;
}

class _CompactDraftEntryCard extends StatelessWidget {
  const _CompactDraftEntryCard({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(102)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.inventory_2_rounded, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          height: 1,
                          color: theme.colorScheme.onSurface.withAlpha(150),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(width: 142, child: actions),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _ProductLookupFieldState extends State<ProductLookupField> {
  FocusNode? _ownedFocusNode;
  bool _softKeyboardEnabledByTap = false;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(ProductLookupField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) {
      return;
    }

    final oldFocusNode = oldWidget.focusNode ?? _ownedFocusNode;
    oldFocusNode?.removeListener(_handleFocusChanged);
    if (widget.focusNode != null) {
      _ownedFocusNode?.dispose();
      _ownedFocusNode = null;
    }
    _effectiveFocusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TerminalSubmitOnTab(
      enabled: widget.enabled,
      onSubmit: widget.onSubmit,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _effectiveFocusNode,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        keyboardType: _effectiveKeyboardType,
        textInputAction: TextInputAction.search,
        onFieldSubmitted: (_) => widget.onSubmit(),
        onTap: _handleTap,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          suffixIcon: widget.suffixIcon,
        ),
        validator: widget.validator,
      ),
    );
  }

  TextInputType get _effectiveKeyboardType {
    final keyboardType = widget.keyboardType;
    if (keyboardType != null) {
      return keyboardType;
    }

    return TextInputType.text;
  }

  void _handleFocusChanged() {
    if (!_effectiveFocusNode.hasFocus) {
      if (_softKeyboardEnabledByTap && mounted) {
        setState(() => _softKeyboardEnabledByTap = false);
      }
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _applyFocusSelection();
      if (widget.suppressSoftKeyboard && !_softKeyboardEnabledByTap) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      }
    });
  }

  void _handleTap() {
    if (widget.suppressSoftKeyboard && !_softKeyboardEnabledByTap) {
      setState(() => _softKeyboardEnabledByTap = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _effectiveFocusNode.requestFocus();
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
        _moveCursorToEnd();
      });
    }

    _moveCursorToEnd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _moveCursorToEnd();
      }
    });
  }

  void _applyFocusSelection() {
    if (widget.selectTextOnFocus) {
      _selectAll();
      return;
    }

    _moveCursorToEnd();
  }

  void _selectAll() {
    if (!mounted) {
      return;
    }

    final text = widget.controller.text;
    if (text.isEmpty) {
      return;
    }

    widget.controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );
  }

  void _moveCursorToEnd() {
    if (!mounted) {
      return;
    }

    final text = widget.controller.text;
    widget.controller.selection = TextSelection.collapsed(offset: text.length);
  }
}
