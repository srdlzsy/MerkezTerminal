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
    final theme = Theme.of(context);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (scanRow != null) ...<Widget>[
            scanRow!,
            const SizedBox(height: 10),
          ],
          TerminalPdaInfoGrid(
            minTileWidth: 92,
            items: <TerminalPdaInfo>[
              TerminalPdaInfo(label: 'Kod', value: stockCode),
              if ((unitLabel ?? '').trim().isNotEmpty)
                TerminalPdaInfo(label: 'Birim', value: unitLabel!),
              if ((barcode ?? '').trim().isNotEmpty)
                TerminalPdaInfo(label: 'Barkod', value: barcode!),
              if ((packageLabel ?? '').trim().isNotEmpty)
                TerminalPdaInfo(label: 'Koli', value: packageLabel!),
              if ((priceLabel ?? '').trim().isNotEmpty)
                TerminalPdaInfo(label: 'Fiyat', value: priceLabel!),
              ...extraInfo,
            ],
          ),
          if ((warningLabel ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              warningLabel!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _buildQuantityInputs(),
          const SizedBox(height: 10),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
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

  Widget _buildQuantityInputs() {
    final primaryQuantity = TerminalQuantityStepper(
      controller: quantityController,
      label: quantityLabel,
      step: quantityStep,
      maximum: maximumQuantity,
      inputFormatters: quantityInputFormatters,
      validator: quantityValidator,
      onChanged: onQuantityChanged,
      onSubmitted: onConfirm,
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
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: <Widget>[
              primaryQuantity,
              const SizedBox(height: 8),
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
            horizontal: 12,
            vertical: 10,
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
        _applyFocusSelection();
      });
    }

    _applyFocusSelection();
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
