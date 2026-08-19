import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TerminalListHeaderCard extends StatelessWidget {
  const TerminalListHeaderCard({
    super.key,
    required this.title,
    required this.filters,
    this.subtitle,
    this.infoChips = const <Widget>[],
    this.showInfoChips = false,
    this.actions = const <Widget>[],
    this.footer,
  });

  final String title;
  final String? subtitle;
  final List<Widget> infoChips;
  final bool showInfoChips;
  final List<Widget> filters;
  final List<Widget> actions;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonTextStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final spacing = isCompact ? 5.0 : 7.0;
        final buttonHeight = isCompact ? 38.0 : 42.0;
        final buttonHorizontalPadding = isCompact ? 8.0 : 10.0;
        final visibleInfoChips = showInfoChips ? infoChips : const <Widget>[];

        return Container(
          padding: EdgeInsets.all(isCompact ? 7 : 9),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withAlpha(88),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withAlpha(4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Theme(
            data: theme.copyWith(
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  minimumSize: Size(0, buttonHeight),
                  padding: EdgeInsets.symmetric(
                    horizontal: buttonHorizontalPadding,
                    vertical: isCompact ? 6 : 8,
                  ),
                  iconSize: isCompact ? 18 : 20,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: buttonTextStyle,
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, buttonHeight),
                  padding: EdgeInsets.symmetric(
                    horizontal: buttonHorizontalPadding,
                    vertical: isCompact ? 6 : 8,
                  ),
                  iconSize: isCompact ? 18 : 20,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: buttonTextStyle,
                ),
              ),
              chipTheme: theme.chipTheme.copyWith(
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.12,
                      color: theme.colorScheme.onSurface.withAlpha(168),
                    ),
                  ),
                ],
                if (visibleInfoChips.isNotEmpty ||
                    filters.isNotEmpty ||
                    actions.isNotEmpty ||
                    footer != null)
                  SizedBox(height: spacing),
                if (visibleInfoChips.isNotEmpty)
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: visibleInfoChips,
                  ),
                if (visibleInfoChips.isNotEmpty && filters.isNotEmpty)
                  SizedBox(height: spacing),
                if (filters.isNotEmpty)
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: filters,
                  ),
                if ((visibleInfoChips.isNotEmpty || filters.isNotEmpty) &&
                    actions.isNotEmpty)
                  SizedBox(height: spacing),
                if (actions.isNotEmpty)
                  _TerminalActionGrid(spacing: spacing, children: actions),
                if (footer != null) ...<Widget>[
                  SizedBox(height: spacing),
                  footer!,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TerminalActionGrid extends StatelessWidget {
  const _TerminalActionGrid({required this.children, required this.spacing});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actionChildren = constraints.maxWidth < 420
            ? children.map(_compactAction).toList(growable: false)
            : children;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: actionChildren,
        );
      },
    );
  }

  Widget _compactAction(Widget action) {
    final data = _TerminalHeaderActionData.from(action);
    if (data == null) {
      return action;
    }

    final tooltip = data.label ?? 'Islem';
    final icon = data.icon ?? _fallbackActionIcon(tooltip);

    return switch (data.style) {
      _TerminalHeaderActionStyle.primary => IconButton.filled(
        onPressed: data.onPressed,
        tooltip: tooltip,
        icon: icon,
      ),
      _TerminalHeaderActionStyle.tonal => IconButton.filledTonal(
        onPressed: data.onPressed,
        tooltip: tooltip,
        icon: icon,
      ),
      _TerminalHeaderActionStyle.outlined => IconButton.outlined(
        onPressed: data.onPressed,
        tooltip: tooltip,
        icon: icon,
      ),
    };
  }

  Widget _fallbackActionIcon(String label) {
    final normalized = label.toLowerCase();
    final icon = switch (normalized) {
      final value when value.contains('temizle') => Icons.restart_alt_rounded,
      final value when value.contains('yenile') => Icons.refresh_rounded,
      final value when value.contains('offline') => Icons.cloud_off_rounded,
      final value when value.contains('yeni') => Icons.add_rounded,
      final value when value.contains('liste') => Icons.search_rounded,
      _ => Icons.more_horiz_rounded,
    };

    return Icon(icon);
  }
}

enum _TerminalHeaderActionStyle { primary, tonal, outlined }

class _TerminalHeaderActionData {
  const _TerminalHeaderActionData({
    required this.onPressed,
    required this.style,
    this.icon,
    this.label,
  });

  final VoidCallback? onPressed;
  final _TerminalHeaderActionStyle style;
  final Widget? icon;
  final String? label;

  static _TerminalHeaderActionData? from(Widget action) {
    final button = action is ButtonStyleButton ? action : null;
    if (button == null) {
      return null;
    }

    final label = _extractLabel(button.child);

    return _TerminalHeaderActionData(
      onPressed: button.onPressed,
      style: _styleForButton(button, label),
      icon: _extractIcon(button.child),
      label: label,
    );
  }

  static _TerminalHeaderActionStyle _styleForButton(
    ButtonStyleButton button,
    String? label,
  ) {
    if (button is OutlinedButton) {
      return _TerminalHeaderActionStyle.outlined;
    }

    final normalized = label?.toLowerCase() ?? '';
    if (normalized.contains('yeni') || normalized.contains('offline')) {
      return _TerminalHeaderActionStyle.tonal;
    }

    return _TerminalHeaderActionStyle.primary;
  }

  static Widget? _extractIcon(Widget? widget) {
    if (widget == null) {
      return null;
    }

    if (widget is Icon) {
      return widget;
    }

    final icon = _readDynamicWidgetProperty(widget, 'icon');
    if (icon != null) {
      return icon;
    }

    if (widget is Row) {
      for (final child in widget.children) {
        final icon = _extractIcon(child);
        if (icon != null) {
          return icon;
        }
      }
    }

    if (widget is Flexible) {
      return _extractIcon(widget.child);
    }

    if (widget is Padding) {
      return _extractIcon(widget.child);
    }

    return null;
  }

  static String? _extractLabel(Widget? widget) {
    if (widget == null) {
      return null;
    }

    if (widget is Text) {
      return widget.data;
    }

    final label = _readDynamicWidgetProperty(widget, 'label');
    if (label != null) {
      return _extractLabel(label);
    }

    if (widget is Row) {
      for (final child in widget.children) {
        final label = _extractLabel(child);
        if (label != null && label.isNotEmpty) {
          return label;
        }
      }
    }

    if (widget is Flexible) {
      return _extractLabel(widget.child);
    }

    if (widget is Padding) {
      return _extractLabel(widget.child);
    }

    return null;
  }

  static Widget? _readDynamicWidgetProperty(Widget widget, String property) {
    try {
      final dynamic dynamicWidget = widget;
      final value = switch (property) {
        'icon' => dynamicWidget.icon,
        'label' => dynamicWidget.label,
        _ => null,
      };
      return value is Widget ? value : null;
    } on NoSuchMethodError {
      return null;
    }
  }
}

class TerminalResponsiveLookupRow extends StatelessWidget {
  const TerminalResponsiveLookupRow({
    super.key,
    required this.field,
    required this.action,
    this.trailingAction,
    this.breakpoint = 280,
    this.spacing = 8,
  });

  final Widget field;
  final Widget action;
  final Widget? trailingAction;
  final double breakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trailing = trailingAction;

        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              field,
              SizedBox(height: spacing),
              if (trailing == null)
                action
              else
                Row(
                  children: <Widget>[
                    Expanded(child: action),
                    SizedBox(width: spacing),
                    trailing,
                  ],
                ),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: field),
            SizedBox(width: spacing + 4),
            action,
            if (trailing != null) ...<Widget>[
              SizedBox(width: spacing),
              trailing,
            ],
          ],
        );
      },
    );
  }
}

class TerminalLookupSearchField extends StatefulWidget {
  const TerminalLookupSearchField({
    super.key,
    required this.controller,
    required this.onSearch,
    this.decoration,
    this.labelText,
    this.hintText = 'Ara...',
    this.enabled = true,
    this.autofocus = true,
    this.selectTextOnFocus = true,
    this.suppressSoftKeyboard = true,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;
  final InputDecoration? decoration;
  final String? labelText;
  final String? hintText;
  final bool enabled;
  final bool autofocus;
  final bool selectTextOnFocus;
  final bool suppressSoftKeyboard;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  State<TerminalLookupSearchField> createState() =>
      _TerminalLookupSearchFieldState();
}

class _TerminalLookupSearchFieldState extends State<TerminalLookupSearchField> {
  final FocusNode _focusNode = FocusNode();
  bool _softKeyboardEnabledByTap = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: _effectiveKeyboardType,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: widget.onChanged,
      onSubmitted: (_) => widget.onSearch(),
      onTap: _handleTap,
      decoration:
          widget.decoration ??
          InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
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
    if (!_focusNode.hasFocus) {
      if (_softKeyboardEnabledByTap && mounted) {
        setState(() => _softKeyboardEnabledByTap = false);
      }
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _selectAll();
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

        _focusNode.requestFocus();
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

  void _selectAll() {
    if (!mounted || !widget.selectTextOnFocus) {
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

class TerminalSubmitOnTab extends StatefulWidget {
  const TerminalSubmitOnTab({
    super.key,
    required this.onSubmit,
    required this.child,
    this.enabled = true,
  });

  final VoidCallback onSubmit;
  final Widget child;
  final bool enabled;

  @override
  State<TerminalSubmitOnTab> createState() => _TerminalSubmitOnTabState();
}

class _TerminalSubmitOnTabState extends State<TerminalSubmitOnTab> {
  DateTime? _lastSubmitAt;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Focus(
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent || !_isScannerSubmitKey(event.logicalKey)) {
          return KeyEventResult.ignored;
        }

        _submitOnce();
        return KeyEventResult.handled;
      },
      child: widget.child,
    );
  }

  bool _isScannerSubmitKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.tab ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
  }

  void _submitOnce() {
    final now = DateTime.now();
    final lastSubmitAt = _lastSubmitAt;
    if (lastSubmitAt != null &&
        now.difference(lastSubmitAt) < const Duration(milliseconds: 120)) {
      return;
    }

    _lastSubmitAt = now;
    widget.onSubmit();
  }
}

class TerminalSectionToolbar extends StatelessWidget {
  const TerminalSectionToolbar({
    super.key,
    required this.title,
    required this.actions,
    this.breakpoint = 360,
    this.spacing = 8,
  });

  final String title;
  final List<Widget> actions;
  final double breakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, height: 1),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              titleWidget,
              if (actions.isNotEmpty) ...<Widget>[
                SizedBox(height: spacing),
                Wrap(spacing: spacing, runSpacing: spacing, children: actions),
              ],
            ],
          );
        }

        return Row(
          children: <Widget>[
            titleWidget,
            const Spacer(),
            for (var index = 0; index < actions.length; index += 1) ...<Widget>[
              if (index > 0) SizedBox(width: spacing),
              actions[index],
            ],
          ],
        );
      },
    );
  }
}

class TerminalPdaInfo {
  const TerminalPdaInfo({required this.label, required this.value});

  final String label;
  final String value;
}

class TerminalPdaInfoGrid extends StatelessWidget {
  const TerminalPdaInfoGrid({
    super.key,
    required this.items,
    this.minTileWidth = 132,
    this.spacing = 6,
  });

  final List<TerminalPdaInfo> items;
  final double minTileWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = constraints.hasBoundedWidth
            ? ((maxWidth + spacing) / (minTileWidth + spacing)).floor().clamp(
                1,
                3,
              )
            : 1;
        final tileWidth = constraints.hasBoundedWidth
            ? (maxWidth - (spacing * (columns - 1))) / columns
            : minTileWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: tileWidth,
                  child: TerminalPdaInfoTile(
                    label: item.label,
                    value: item.value,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class TerminalPdaInfoTile extends StatelessWidget {
  const TerminalPdaInfoTile({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(44),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(72),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF5F6C7B),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              height: 1.05,
              color: const Color(0xFF1C2D40),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class TerminalPdaRecordCard extends StatelessWidget {
  const TerminalPdaRecordCard({
    super.key,
    required this.child,
    required this.onTap,
    this.isSelected = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? theme.colorScheme.primary.withAlpha(150)
        : theme.colorScheme.outlineVariant.withAlpha(118);
    final stripeColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withAlpha(92);
    final backgroundColor = isSelected
        ? theme.colorScheme.primaryContainer.withAlpha(70)
        : const Color(0xFFF8FAFD);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 66),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: isSelected ? 1.4 : 1),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withAlpha(isSelected ? 18 : 10),
                blurRadius: isSelected ? 11 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                right: null,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: stripeColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 8, 8, 8),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TerminalPdaCardHeader extends StatelessWidget {
  const TerminalPdaCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
                  height: 1.08,
                  color: const Color(0xFF182230),
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.15,
                    color: const Color(0xFF536171),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[const SizedBox(width: 6), trailing!],
      ],
    );
  }
}

class TerminalPdaDetailPanel extends StatelessWidget {
  const TerminalPdaDetailPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(56),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(86),
        ),
      ),
      child: child,
    );
  }
}

class TerminalPdaLineCard extends StatelessWidget {
  const TerminalPdaLineCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.trailing,
    this.isEntryLine = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;
  final bool isEntryLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isEntryLine
            ? theme.colorScheme.primaryContainer.withAlpha(42)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEntryLine
              ? theme.colorScheme.primary.withAlpha(102)
              : theme.colorScheme.outlineVariant.withAlpha(96),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 6, 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  IconTheme.merge(
                    data: const IconThemeData(size: 18),
                    child: leading!,
                  ),
                  const SizedBox(width: 6),
                ],
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
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            subtitle!,
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
                    ],
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: 6),
                  IconButtonTheme(
                    data: IconButtonThemeData(
                      style: IconButton.styleFrom(
                        minimumSize: const Size(38, 38),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    child: trailing!,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(5), child: child),
        ],
      ),
    );
  }
}

class TerminalCompactProductLineCard extends StatelessWidget {
  const TerminalCompactProductLineCard({
    super.key,
    required this.lineNo,
    required this.stockCode,
    required this.stockName,
    required this.quantityController,
    this.unitLabel,
    this.priceLabel,
    this.barcode,
    this.packageLabel,
    this.warningLabel,
    this.canDelete = true,
    this.onDelete,
    this.onMinimumReached,
    this.quantityStep = 1,
    this.maximumQuantity,
    this.quantityInputFormatters = const <TextInputFormatter>[],
    this.quantityValidator,
  });

  final int lineNo;
  final String stockCode;
  final String stockName;
  final TextEditingController quantityController;
  final String? unitLabel;
  final String? priceLabel;
  final String? barcode;
  final String? packageLabel;
  final String? warningLabel;
  final bool canDelete;
  final VoidCallback? onDelete;
  final VoidCallback? onMinimumReached;
  final double quantityStep;
  final double? maximumQuantity;
  final List<TextInputFormatter> quantityInputFormatters;
  final FormFieldValidator<String>? quantityValidator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 7, 7, 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(96),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTight = constraints.maxWidth < 350;
          final details = _TerminalCompactProductLineDetails(
            lineNo: lineNo,
            stockCode: stockCode,
            stockName: stockName,
            unitLabel: unitLabel,
            priceLabel: priceLabel,
            barcode: barcode,
            packageLabel: packageLabel,
            warningLabel: warningLabel,
            showLineLabel: true,
          );
          final controls = Row(
            mainAxisSize: isTight ? MainAxisSize.max : MainAxisSize.min,
            children: <Widget>[
              if (isTight)
                Expanded(
                  child: _TerminalCompactQuantityControl(
                    controller: quantityController,
                    step: quantityStep,
                    maximum: maximumQuantity,
                    inputFormatters: quantityInputFormatters,
                    validator: quantityValidator,
                    onMinimumReached: onMinimumReached,
                  ),
                )
              else
                SizedBox(
                  width: 150,
                  child: _TerminalCompactQuantityControl(
                    controller: quantityController,
                    step: quantityStep,
                    maximum: maximumQuantity,
                    inputFormatters: quantityInputFormatters,
                    validator: quantityValidator,
                    onMinimumReached: onMinimumReached,
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: canDelete ? onDelete : null,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                tooltip: 'Satiri sil',
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
            ],
          );

          if (isTight) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[details, const SizedBox(height: 6), controls],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: details),
              const SizedBox(width: 8),
              controls,
            ],
          );
        },
      ),
    );
  }
}

class TerminalCompactProductLineSummary extends StatelessWidget {
  const TerminalCompactProductLineSummary({
    super.key,
    required this.lineNo,
    required this.stockCode,
    required this.stockName,
    this.unitLabel,
    this.priceLabel,
    this.barcode,
    this.packageLabel,
    this.warningLabel,
    this.trailing,
  });

  final int lineNo;
  final String stockCode;
  final String stockName;
  final String? unitLabel;
  final String? priceLabel;
  final String? barcode;
  final String? packageLabel;
  final String? warningLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 7, 7, 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(96),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: _TerminalCompactProductLineDetails(
              lineNo: lineNo,
              stockCode: stockCode,
              stockName: stockName,
              unitLabel: unitLabel,
              priceLabel: priceLabel,
              barcode: barcode,
              packageLabel: packageLabel,
              warningLabel: warningLabel,
              showLineLabel: false,
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 6),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _TerminalCompactProductLineDetails extends StatelessWidget {
  const _TerminalCompactProductLineDetails({
    required this.lineNo,
    required this.stockCode,
    required this.stockName,
    required this.unitLabel,
    required this.priceLabel,
    required this.barcode,
    required this.packageLabel,
    required this.warningLabel,
    required this.showLineLabel,
  });

  final int lineNo;
  final String stockCode;
  final String stockName;
  final String? unitLabel;
  final String? priceLabel;
  final String? barcode;
  final String? packageLabel;
  final String? warningLabel;
  final bool showLineLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(92),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '$lineNo',
            style: theme.textTheme.labelLarge?.copyWith(
              height: 1,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                stockName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.08,
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 5,
                runSpacing: 3,
                children: <Widget>[
                  if (showLineLabel)
                    _TerminalMiniLineMeta(text: 'Satir $lineNo'),
                  if (stockCode.trim().isNotEmpty)
                    _TerminalMiniLineMeta(text: stockCode),
                  if ((unitLabel ?? '').trim().isNotEmpty)
                    _TerminalMiniLineMeta(text: unitLabel!),
                  if ((packageLabel ?? '').trim().isNotEmpty)
                    _TerminalMiniLineMeta(text: 'Koli $packageLabel'),
                  if ((priceLabel ?? '').trim().isNotEmpty)
                    _TerminalMiniLineMeta(text: priceLabel!),
                  if ((barcode ?? '').trim().isNotEmpty)
                    _TerminalMiniLineMeta(text: barcode!),
                  if ((warningLabel ?? '').trim().isNotEmpty)
                    _TerminalMiniLineMeta(
                      text: warningLabel!,
                      color: theme.colorScheme.error,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TerminalMiniLineMeta extends StatelessWidget {
  const _TerminalMiniLineMeta({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        height: 1.05,
        color: color ?? const Color(0xFF607080),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TerminalCompactQuantityControl extends StatelessWidget {
  const _TerminalCompactQuantityControl({
    required this.controller,
    required this.step,
    this.maximum,
    this.inputFormatters = const <TextInputFormatter>[],
    this.validator,
    required this.onMinimumReached,
  });

  final TextEditingController controller;
  final double step;
  final double? maximum;
  final List<TextInputFormatter> inputFormatters;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onMinimumReached;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _TerminalCompactQuantityButton(
          icon: Icons.remove_rounded,
          tooltip: 'Azalt',
          isPrimary: false,
          onPressed: () => _changeBy(context, -step),
        ),
        Expanded(
          child: SizedBox(
            height: 34,
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                ...inputFormatters,
              ],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 7,
                ),
              ),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                height: 1,
                fontWeight: FontWeight.w900,
              ),
              validator:
                  validator ??
                  (value) {
                    if (_readQuantity(value ?? '') <= 0) {
                      return '';
                    }
                    final max = maximum;
                    if (max != null && _readQuantity(value ?? '') > max) {
                      return '';
                    }

                    return null;
                  },
            ),
          ),
        ),
        _TerminalCompactQuantityButton(
          icon: Icons.add_rounded,
          tooltip: 'Artir',
          isPrimary: true,
          onPressed: () => _changeBy(context, step),
        ),
      ],
    );
  }

  Future<void> _changeBy(BuildContext context, double delta) async {
    final current = _readQuantity(controller.text);
    var next = current + delta;
    if (next < 0) {
      next = 0;
    }
    final max = maximum;
    if (max != null && next > max) {
      next = max;
    }

    final reachesMinimum = delta < 0 && next <= 0 && onMinimumReached != null;
    if (reachesMinimum) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Kalem silinsin mi?'),
            content: const Text(
              'Miktar 0 olacak. Bu kalemi listeden silmek istiyor musunuz?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Vazgec'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Sil'),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !context.mounted) {
        return;
      }
    }

    controller.text = _formatCompactQuantity(next);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    if (reachesMinimum) {
      onMinimumReached?.call();
    }
  }

  static double _readQuantity(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return 0;
    }
    return double.tryParse(normalized) ?? 0;
  }

  static String _formatCompactQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '')
        .replaceAll('.', ',');
  }
}

class _TerminalCompactQuantityButton extends StatelessWidget {
  const _TerminalCompactQuantityButton({
    required this.icon,
    required this.tooltip,
    required this.isPrimary,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isPrimary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = IconButton.styleFrom(
      tapTargetSize: MaterialTapTargetSize.padded,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    );

    if (isPrimary) {
      return IconButton.filled(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        tooltip: tooltip,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        padding: EdgeInsets.zero,
        style: buttonStyle,
      );
    }

    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      style: buttonStyle,
    );
  }
}

class TerminalQuantityStepper extends StatelessWidget {
  const TerminalQuantityStepper({
    super.key,
    required this.controller,
    this.label = 'Miktar*',
    this.step = 1,
    this.minimum = 0,
    this.maximum,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onMinimumReached,
    this.inputFormatters = const <TextInputFormatter>[],
    this.dense = false,
  });

  final TextEditingController controller;
  final String label;
  final double step;
  final double minimum;
  final double? maximum;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final VoidCallback? onMinimumReached;
  final List<TextInputFormatter> inputFormatters;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonSize = dense ? 36.0 : 44.0;
    final iconSize = dense ? 18.0 : 20.0;
    final gap = dense ? 3.0 : 6.0;
    final verticalPadding = dense ? 5.0 : 8.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        IconButton.filledTonal(
          onPressed: enabled ? () => _changeBy(context, -step) : null,
          icon: Icon(Icons.remove_rounded, size: iconSize),
          tooltip: 'Azalt',
          constraints: BoxConstraints.tightFor(
            width: buttonSize,
            height: buttonSize,
          ),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Builder(
            builder: (fieldContext) {
              return TextFormField(
                controller: controller,
                enabled: enabled,
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.done,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                scrollPadding: EdgeInsets.only(
                  left: 24,
                  top: 24,
                  right: 24,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 180,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                  ...inputFormatters,
                ],
                decoration: InputDecoration(
                  labelText: label,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: verticalPadding,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: validator,
                onTap: () => _keepQuantityFieldVisible(fieldContext),
                onChanged: (value) {
                  _keepQuantityFieldVisible(fieldContext);
                  onChanged?.call(value);
                },
                onFieldSubmitted: (_) => onSubmitted?.call(),
              );
            },
          ),
        ),
        SizedBox(width: gap),
        IconButton.filled(
          onPressed: enabled ? () => _changeBy(context, step) : null,
          icon: Icon(Icons.add_rounded, size: iconSize),
          tooltip: 'Artir',
          constraints: BoxConstraints.tightFor(
            width: buttonSize,
            height: buttonSize,
          ),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  void _keepQuantityFieldVisible(BuildContext context) {
    void ensureVisible() {
      if (!context.mounted) {
        return;
      }

      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: 0.28,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => ensureVisible());
    Future<void>.delayed(const Duration(milliseconds: 320), ensureVisible);
  }

  Future<void> _changeBy(BuildContext context, double delta) async {
    final current = _readQuantity(controller.text);
    var next = current + delta;
    if (next < minimum) {
      next = minimum;
    }
    final max = maximum;
    if (max != null && next > max) {
      next = max;
    }
    final reachesMinimum =
        delta < 0 && next <= minimum && onMinimumReached != null;
    if (reachesMinimum) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Kalem silinsin mi?'),
            content: const Text(
              'Miktar 0 olacak. Bu kalemi listeden silmek istiyor musunuz?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Vazgec'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Sil'),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !context.mounted) {
        return;
      }
    }
    controller.text = _formatQuantity(next);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    onChanged?.call(controller.text);
    if (reachesMinimum) {
      onMinimumReached?.call();
    }
  }

  static double _readQuantity(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return 0;
    }
    return double.tryParse(normalized) ?? 0;
  }

  static String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class TerminalFormActionRow extends StatelessWidget {
  const TerminalFormActionRow({
    super.key,
    required this.cancel,
    required this.submit,
    this.breakpoint = 360,
    this.spacing = 12,
    this.submitFlex = 1,
  });

  final Widget cancel;
  final Widget submit;
  final double breakpoint;
  final double spacing;
  final int submitFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              cancel,
              SizedBox(height: spacing),
              submit,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: cancel),
            SizedBox(width: spacing),
            Expanded(flex: submitFlex, child: submit),
          ],
        );
      },
    );
  }
}

class TerminalCreateInputDock extends StatelessWidget {
  const TerminalCreateInputDock({
    super.key,
    required this.children,
    this.preferBottomVisible = true,
    this.padding = const EdgeInsets.fromLTRB(10, 4, 10, 4),
    this.compactHeightFactor = 0.42,
    this.regularHeightFactor = 0.46,
    this.compactMaxHeight = 380,
    this.regularMaxHeight = 460,
  });

  final List<Widget> children;
  final bool preferBottomVisible;
  final EdgeInsetsGeometry padding;
  final double compactHeightFactor;
  final double regularHeightFactor;
  final double compactMaxHeight;
  final double regularMaxHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class TerminalTitleBadgeRow extends StatelessWidget {
  const TerminalTitleBadgeRow({
    super.key,
    required this.title,
    required this.badges,
    this.breakpoint = 360,
    this.spacing = 8,
  });

  final String title;
  final List<Widget> badges;
  final double breakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              titleWidget,
              if (badges.isNotEmpty) ...<Widget>[
                SizedBox(height: spacing),
                Wrap(spacing: spacing, runSpacing: spacing, children: badges),
              ],
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: titleWidget),
            for (var index = 0; index < badges.length; index += 1) ...<Widget>[
              if (index > 0) SizedBox(width: spacing),
              badges[index],
            ],
          ],
        );
      },
    );
  }
}

class TerminalSheetHeader extends StatelessWidget {
  const TerminalSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.badges = const <Widget>[],
    this.padding = const EdgeInsets.fromLTRB(10, 4, 6, 4),
    this.elevated = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> badges;
  final EdgeInsetsGeometry padding;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: elevated ? theme.colorScheme.surface : null,
        boxShadow: elevated
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
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
                    if (badges.isNotEmpty) ...<Widget>[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: badges,
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.15),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: 'Kapat',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          ),
        ],
      ),
    );
  }
}

class TerminalLineCountBadge extends StatelessWidget {
  const TerminalLineCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(44)),
      ),
      child: Text(
        '$count kalem',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          height: 1,
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class TerminalInfoChip extends StatelessWidget {
  const TerminalInfoChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112, minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(90),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF5C6B80),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              height: 1.1,
              color: const Color(0xFF10233D),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class TerminalSummaryTile extends StatelessWidget {
  const TerminalSummaryTile({
    super.key,
    required this.label,
    required this.value,
    this.width = 170,
  });

  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(82),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF231C17),
            ),
          ),
        ],
      ),
    );
  }
}

class TerminalFilterButton extends StatelessWidget {
  const TerminalFilterButton({
    super.key,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(120, 38),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.calendar_month_rounded, size: 16),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TerminalMessageBlock extends StatelessWidget {
  const TerminalMessageBlock.error({super.key, required this.message})
    : backgroundColor = const Color(0xFFFFE5E5),
      borderColor = const Color(0xFFEAA3A3),
      foregroundColor = const Color(0xFF7A1818),
      isLoading = false;

  const TerminalMessageBlock.info({super.key, required this.message})
    : backgroundColor = const Color(0xFFF7F9FD),
      borderColor = const Color(0xFFD8DFEC),
      foregroundColor = const Color(0xFF35506D),
      isLoading = false;

  const TerminalMessageBlock.loading({super.key, required this.message})
    : backgroundColor = const Color(0xFFF7F9FD),
      borderColor = const Color(0xFFD8DFEC),
      foregroundColor = const Color(0xFF35506D),
      isLoading = true;

  final String message;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: isLoading
          ? Row(
              children: <Widget>[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: foregroundColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TerminalMessageText(
                    message: message,
                    foregroundColor: foregroundColor,
                  ),
                ),
              ],
            )
          : _TerminalMessageText(
              message: message,
              foregroundColor: foregroundColor,
            ),
    );
  }
}

class _TerminalMessageText extends StatelessWidget {
  const _TerminalMessageText({
    required this.message,
    required this.foregroundColor,
  });

  final String message;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: foregroundColor),
    );
  }
}

class TerminalEmptyState extends StatelessWidget {
  const TerminalEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class TerminalBadge extends StatelessWidget {
  const TerminalBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: foregroundColor ?? theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class TerminalLabeledValue extends StatelessWidget {
  const TerminalLabeledValue({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF6B5A4A),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: const Color(0xFF231C17),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
