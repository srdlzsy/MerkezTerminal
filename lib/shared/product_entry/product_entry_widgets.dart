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

        final baseHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : usableHeight;
        final maxPanelHeight = (baseHeight * (keyboardHeight > 0 ? 0.48 : 0.58))
            .clamp(keyboardHeight > 0 ? 156.0 : 196.0, 360.0)
            .toDouble();

        return _ScrollableDraftEntryCard(
          title: title,
          subtitle: stockName,
          maxHeight: maxPanelHeight,
          onCancel: onCancel,
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
    final theme = Theme.of(context);
    final warning = warningLabel?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (scanRow != null) ...<Widget>[
          scanRow!,
          SizedBox(height: isCompact ? 6 : 10),
        ],
        TerminalPdaInfoGrid(
          minTileWidth: isCompact ? 74 : 92,
          spacing: isCompact ? 4 : 6,
          items: _infoItems,
        ),
        if (warning.isNotEmpty) ...<Widget>[
          SizedBox(height: isCompact ? 5 : 8),
          Text(
            warning,
            maxLines: isCompact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        SizedBox(height: isCompact ? 7 : 10),
        _buildQuantityInputs(isCompact: isCompact),
        SizedBox(height: isCompact ? 7 : 10),
        if (includeActions) _buildActionButtons(isCompact: isCompact),
      ],
    );
  }

  List<TerminalPdaInfo> get _infoItems {
    return <TerminalPdaInfo>[
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
    ];
  }

  Widget _buildActionButtons({required bool isCompact}) {
    if (isCompact) {
      return Row(
        children: <Widget>[
          SizedBox(
            width: 44,
            height: 40,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 40),
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
                minimumSize: const Size.fromHeight(40),
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

class _ScrollableDraftEntryCard extends StatelessWidget {
  const _ScrollableDraftEntryCard({
    required this.title,
    required this.subtitle,
    required this.maxHeight,
    required this.onCancel,
    required this.actions,
    required this.child,
  });

  final String title;
  final String subtitle;
  final double maxHeight;
  final VoidCallback onCancel;
  final Widget actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
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
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 6, 3),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.inventory_2_rounded, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              height: 1.05,
                              color: theme.colorScheme.onSurface.withAlpha(150),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Secimi temizle',
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(6),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: child,
              ),
            ),
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(6), child: actions),
          ],
        ),
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
