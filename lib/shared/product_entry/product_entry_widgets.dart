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
    this.labelText = 'Barkod / stok / urun',
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
    this.informationLabels = const <String>[],
    this.confirmLabel = 'Ekle',
    this.quantityLabel = 'Miktar',
    this.quantityStep = 1,
    this.maximumQuantity = terminalCreateMaximumQuantity,
    this.quantityInputFormatters = const <TextInputFormatter>[],
    this.quantityValidator,
    this.onQuantityChanged,
    this.secondaryQuantityController,
    this.secondaryQuantityLabel = 'Fiili Miktar',
    this.secondaryQuantityStep = 1,
    this.secondaryMaximumQuantity = terminalCreateMaximumQuantity,
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
  final List<String> informationLabels;
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

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): onCancel,
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final keyboardHeight = mediaQuery.viewInsets.bottom;
          final usableHeight = mediaQuery.size.height - keyboardHeight;
          final isCompact =
              mediaQuery.size.width < 380 ||
              usableHeight < 700 ||
              keyboardHeight > 0 ||
              (constraints.hasBoundedHeight && constraints.maxHeight < 360);
          final isTightHeight =
              constraints.hasBoundedHeight && constraints.maxHeight <= 240;
          final body = _buildBody(
            context,
            isCompact: isCompact,
            isTightHeight: isTightHeight,
            includeActions: true,
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
            sourceLabel: _sourceTypeLabel,
            isTightHeight: isTightHeight,
            child: body,
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isCompact,
    required bool isTightHeight,
    required bool includeActions,
  }) {
    final effectiveScanRow = _scanRowFor(isCompact: isCompact);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (effectiveScanRow != null) ...<Widget>[
          effectiveScanRow,
          SizedBox(height: isTightHeight ? 3 : (isCompact ? 5 : 10)),
        ],
        if (!isCompact)
          TerminalPdaInfoGrid(minTileWidth: 92, spacing: 6, items: _infoItems),
        if (isCompact && _compactInfoItems.isNotEmpty) ...<Widget>[
          _CompactProductInfoStrip(
            items: _compactInfoItems,
            singleRowScaleDown: isTightHeight,
          ),
          SizedBox(height: isTightHeight ? 2 : 4),
        ],
        if (!isCompact) const SizedBox(height: 10),
        _buildQuantityInputs(isCompact: isCompact),
        _buildQuantityAdvisory(context, isCompact: isCompact),
        if (includeActions) ...<Widget>[
          SizedBox(height: isTightHeight ? 4 : (isCompact ? 6 : 10)),
          _buildActionButtons(
            isCompact: isCompact,
            isTightHeight: isTightHeight,
          ),
        ],
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
      if (_sourceTypeLabel.isNotEmpty)
        TerminalPdaInfo(label: 'Kaynak', value: _sourceTypeLabel),
      ...extraInfo,
    ];
  }

  String get _compactMetaSummary {
    return <String>[
      stockCode,
      if ((unitLabel ?? '').trim().isNotEmpty) unitLabel!,
    ].where((part) => part.trim().isNotEmpty).join(' | ');
  }

  List<_CompactProductInfo> get _compactInfoItems {
    return <_CompactProductInfo>[
      if ((packageLabel ?? '').trim().isNotEmpty)
        _CompactProductInfo(
          label: 'Koli ici',
          value: _packageInfoValue,
          isPackage: true,
        ),
      if ((barcode ?? '').trim().isNotEmpty)
        _CompactProductInfo(label: 'Barkod', value: barcode!.trim()),
      if ((priceLabel ?? '').trim().isNotEmpty)
        _CompactProductInfo(label: 'Fiyat', value: priceLabel!.trim()),
      for (final item in extraInfo)
        if (item.value.trim().isNotEmpty)
          _CompactProductInfo(label: item.label, value: item.value),
    ];
  }

  String get _sourceTypeLabel {
    final normalizedLabels = informationLabels
        .map((label) => label.trim().toLowerCase())
        .where((label) => label.isNotEmpty);
    if (normalizedLabels.contains('karisik kaynak') ||
        normalizedLabels.contains('mixed')) {
      return 'KARISIK';
    }
    if (normalizedLabels.contains('firma urunu') ||
        normalizedLabels.contains('company')) {
      return 'FIRMA';
    }
    if (normalizedLabels.contains('depo urunu') ||
        normalizedLabels.contains('warehouse')) {
      return 'DEPO';
    }
    if (normalizedLabels.contains('kaynak atanmamis') ||
        normalizedLabels.contains('unassigned')) {
      return 'ATANMAMIS';
    }
    return '';
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

  Widget _buildActionButtons({
    required bool isCompact,
    bool isTightHeight = false,
  }) {
    if (isCompact) {
      final buttonHeight = isTightHeight ? 38.0 : 42.0;
      return Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded, size: 17),
              label: const Text(
                'Vazgec',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, buttonHeight),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.standard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 5,
            child: FilledButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: Text(
                confirmLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                minimumSize: Size(0, buttonHeight),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.standard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final cancelButton = OutlinedButton.icon(
      onPressed: onCancel,
      icon: const Icon(Icons.close_rounded, size: 18),
      label: const Text('Vazgec'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        visualDensity: VisualDensity.standard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    final confirmButton = FilledButton.icon(
      onPressed: onConfirm,
      icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
      label: Text(confirmLabel),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        visualDensity: VisualDensity.standard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
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
        const stackedBreakpoint = 420.0;
        if (constraints.maxWidth < stackedBreakpoint) {
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

class _CompactProductInfo {
  const _CompactProductInfo({
    required this.label,
    required this.value,
    this.isPackage = false,
  });

  final String label;
  final String value;
  final bool isPackage;
}

class _CompactProductInfoStrip extends StatelessWidget {
  const _CompactProductInfoStrip({
    required this.items,
    this.singleRowScaleDown = false,
  });

  final List<_CompactProductInfo> items;
  final bool singleRowScaleDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[
      for (final item in items)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: item.isPackage
                ? const Color(0xFFFFF4D6)
                : theme.colorScheme.surface.withAlpha(200),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: item.isPackage
                  ? const Color(0xFFE5B84F).withAlpha(150)
                  : theme.colorScheme.outlineVariant.withAlpha(95),
            ),
          ),
          child: Text(
            '${item.label}: ${item.value}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              letterSpacing: 0,
              height: 1.1,
              color: item.isPackage
                  ? const Color(0xFF7A4A00)
                  : const Color(0xFF4B5F73),
              fontWeight: item.isPackage ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ),
    ];

    if (singleRowScaleDown) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var i = 0; i < chips.length; i += 1) ...<Widget>[
                if (i > 0) const SizedBox(width: 4),
                chips[i],
              ],
            ],
          ),
        ),
      );
    }

    return Wrap(spacing: 4, runSpacing: 3, children: chips);
  }
}

class _CompactDraftEntryCard extends StatelessWidget {
  const _CompactDraftEntryCard({
    required this.title,
    required this.subtitle,
    required this.sourceLabel,
    required this.child,
    this.isTightHeight = false,
  });

  final String title;
  final String subtitle;
  final String sourceLabel;
  final Widget child;
  final bool isTightHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isTightHeight ? 2 : 6),
      padding: EdgeInsets.fromLTRB(
        7,
        isTightHeight ? 4 : 6,
        7,
        isTightHeight ? 4 : 6,
      ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: 17,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: isTightHeight ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 13.5,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (sourceLabel.isNotEmpty ||
                        subtitle.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          if (sourceLabel.isNotEmpty) ...<Widget>[
                            _CompactProductSourceBadge(label: sourceLabel),
                            const SizedBox(width: 5),
                          ],
                          if (subtitle.trim().isNotEmpty)
                            Expanded(
                              child: Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontSize: 11.5,
                                  height: 1.05,
                                  color: theme.colorScheme.onSurface.withAlpha(
                                    165,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTightHeight ? 4 : 6),
          child,
        ],
      ),
    );
  }
}

class _CompactProductSourceBadge extends StatelessWidget {
  const _CompactProductSourceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompany = label == 'FIRMA';
    final isMixed = label == 'KARISIK';
    final backgroundColor = isCompany
        ? theme.colorScheme.tertiaryContainer
        : isMixed
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.primaryContainer;
    final foregroundColor = isCompany
        ? theme.colorScheme.onTertiaryContainer
        : isMixed
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onPrimaryContainer;

    return Container(
      key: const ValueKey<String>('product-source-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          height: 1,
          color: foregroundColor,
          fontWeight: FontWeight.w900,
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
    if (oldWidget.enabled && !widget.enabled) {
      TerminalLineAccordionScope.unregisterScanFocusNode(_effectiveFocusNode);
    }
    if (oldWidget.focusNode == widget.focusNode) {
      return;
    }

    final oldFocusNode = oldWidget.focusNode ?? _ownedFocusNode;
    TerminalLineAccordionScope.unregisterScanFocusNode(oldFocusNode);
    oldFocusNode?.removeListener(_handleFocusChanged);
    if (widget.focusNode != null) {
      _ownedFocusNode?.dispose();
      _ownedFocusNode = null;
    }
    _effectiveFocusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    TerminalLineAccordionScope.unregisterScanFocusNode(_effectiveFocusNode);
    _effectiveFocusNode.removeListener(_handleFocusChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enabled) {
      TerminalLineAccordionScope.registerScanFocusNode(_effectiveFocusNode);
    }
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
          labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          hintText: widget.hintText,
          isDense: true,
          constraints: const BoxConstraints(minHeight: 42, maxHeight: 42),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
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
    }

    _moveCursorToEnd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _effectiveFocusNode.requestFocus();
      if (widget.suppressSoftKeyboard) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      }
      _moveCursorToEnd();
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
