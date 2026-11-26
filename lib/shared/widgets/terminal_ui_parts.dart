import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

const double terminalCreateMaximumQuantity = 100000;

class TerminalLineAccordionController extends ValueNotifier<Object?> {
  TerminalLineAccordionController([super.value]);

  void expand(Object key) {
    if (value != key) {
      value = key;
    }
  }

  void collapse() {
    if (value != null) {
      value = null;
    }
  }
}

class TerminalLineAccordionScope extends InheritedWidget {
  const TerminalLineAccordionScope({
    super.key,
    required this.expandedKeyNotifier,
    required super.child,
  });

  final ValueNotifier<Object?> expandedKeyNotifier;
  static FocusNode? _lastScanFocusNode;

  static void registerScanFocusNode(FocusNode? focusNode) {
    if (focusNode != null) {
      _lastScanFocusNode = focusNode;
    }
  }

  static void unregisterScanFocusNode(FocusNode? focusNode) {
    if (identical(_lastScanFocusNode, focusNode)) {
      _lastScanFocusNode = null;
    }
  }

  static void returnFocusToScanner() {
    final node = _lastScanFocusNode;
    if (node != null && node.canRequestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (node.canRequestFocus) {
          node.requestFocus();
        }
      });
    }
  }

  static TerminalLineAccordionScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TerminalLineAccordionScope>();
  }

  void toggle(Object key) {
    expandedKeyNotifier.value = expandedKeyNotifier.value == key ? null : key;
  }

  void expand(Object key) {
    if (expandedKeyNotifier.value != key) {
      expandedKeyNotifier.value = key;
    }
  }

  void collapseAndReturnFocus(Object key) {
    if (expandedKeyNotifier.value == key) {
      expandedKeyNotifier.value = null;
    }
    returnFocusToScanner();
  }

  @override
  bool updateShouldNotify(TerminalLineAccordionScope oldWidget) {
    return oldWidget.expandedKeyNotifier != expandedKeyNotifier;
  }
}

class _TerminalAccordionItemScope extends InheritedWidget {
  const _TerminalAccordionItemScope({
    required this.onValidationInvalid,
    required this.onQuantitySubmitted,
    required super.child,
  });

  final VoidCallback onValidationInvalid;
  final VoidCallback onQuantitySubmitted;

  static _TerminalAccordionItemScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_TerminalAccordionItemScope>();
  }

  @override
  bool updateShouldNotify(_TerminalAccordionItemScope oldWidget) => false;
}

class TerminalSearchableLineSliver<T> extends StatefulWidget {
  const TerminalSearchableLineSliver({
    super.key,
    required this.items,
    required this.searchText,
    required this.itemBuilder,
    this.accordionController,
    this.searchThreshold = 8,
    this.hintText = 'Kalemlerde ara',
  });

  final List<T> items;
  final String Function(T item) searchText;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final TerminalLineAccordionController? accordionController;
  final int searchThreshold;
  final String hintText;

  @override
  State<TerminalSearchableLineSliver<T>> createState() =>
      _TerminalSearchableLineSliverState<T>();
}

class _TerminalSearchableLineSliverState<T>
    extends State<TerminalSearchableLineSliver<T>> {
  final TextEditingController _controller = TextEditingController();
  final ValueNotifier<Object?> _internalExpandedKeyNotifier =
      ValueNotifier<Object?>(null);
  String _query = '';

  ValueNotifier<Object?> get _expandedKeyNotifier =>
      widget.accordionController ?? _internalExpandedKeyNotifier;

  @override
  void dispose() {
    _internalExpandedKeyNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showSearch =
        widget.items.length >= widget.searchThreshold || _query.isNotEmpty;
    final normalizedQuery = _normalize(_query);
    final visibleItems = normalizedQuery.isEmpty
        ? widget.items
        : widget.items
              .where(
                (item) => _normalize(
                  widget.searchText(item),
                ).contains(normalizedQuery),
              )
              .toList(growable: false);
    final showEmpty = showSearch && visibleItems.isEmpty;
    final offset = showSearch ? 1 : 0;
    final childCount = offset + (showEmpty ? 1 : visibleItems.length);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (showSearch && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Aramayi temizle',
                              onPressed: () {
                                _controller.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.clear_rounded, size: 19),
                            ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 46),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '${visibleItems.length}/${widget.items.length}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (showEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: Text('Eslesen kalem bulunamadi.')),
          );
        }

        return TerminalLineAccordionScope(
          expandedKeyNotifier: _expandedKeyNotifier,
          child: widget.itemBuilder(context, visibleItems[index - offset]),
        );
      }, childCount: childCount),
    );
  }

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
}

EdgeInsets terminalPdaListPagePadding(
  BuildContext context, {
  double bottom = 20,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final horizontal = width <= 360 ? 8.0 : (width <= 420 ? 12.0 : 16.0);
  final top = width <= 360 ? 8.0 : 12.0;

  return EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    bottom + MediaQuery.paddingOf(context).bottom,
  );
}

Future<T?> showTerminalProductSelectionSheet<T>({
  required BuildContext context,
  required List<T> items,
  required Future<List<T>> Function({required bool includeDelisted})
  reloadItems,
  required Widget Function(BuildContext context, T item, VoidCallback onSelect)
  itemBuilder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _TerminalProductSelectionSheet<T>(
      items: items,
      reloadItems: reloadItems,
      itemBuilder: itemBuilder,
    ),
  );
}

class _TerminalProductSelectionSheet<T> extends StatefulWidget {
  const _TerminalProductSelectionSheet({
    required this.items,
    required this.reloadItems,
    required this.itemBuilder,
  });

  final List<T> items;
  final Future<List<T>> Function({required bool includeDelisted}) reloadItems;
  final Widget Function(BuildContext context, T item, VoidCallback onSelect)
  itemBuilder;

  @override
  State<_TerminalProductSelectionSheet<T>> createState() =>
      _TerminalProductSelectionSheetState<T>();
}

class _TerminalProductSelectionSheetState<T>
    extends State<_TerminalProductSelectionSheet<T>> {
  bool _hideDelistedProducts = false;
  bool _isLoading = false;
  String? _errorMessage;
  late List<T> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
  }

  Future<void> _setHideDelisted(bool selected) async {
    setState(() {
      _hideDelistedProducts = selected;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.reloadItems(includeDelisted: !selected);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '').trim();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${_items.length} urun',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                FilterChip(
                  label: const Text('Pasif/DLS gizle'),
                  avatar: Icon(
                    _hideDelistedProducts
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                  ),
                  selected: _hideDelistedProducts,
                  onSelected: _isLoading ? null : _setHideDelisted,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _items.isEmpty
                ? const Center(child: Text('Urun bulunamadi.'))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return widget.itemBuilder(
                        context,
                        item,
                        () => Navigator.of(context).pop(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class TerminalProductLookupTile extends StatelessWidget {
  const TerminalProductLookupTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.informationLabels = const <String>[],
    this.showWarning = false,
    this.showFullText = false,
  });

  final String title;
  final String subtitle;
  final List<String> informationLabels;
  final bool showWarning;
  final bool showFullText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = informationLabels
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      title: Text(
        title,
        maxLines: showFullText ? null : 2,
        overflow: showFullText ? TextOverflow.visible : TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            subtitle,
            maxLines: showFullText ? null : 1,
            overflow: showFullText
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
          if (labels.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 3,
              children: <Widget>[
                for (final label in labels)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withAlpha(95),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: theme.colorScheme.secondary.withAlpha(70),
                      ),
                    ),
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
      trailing: showWarning
          ? Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error)
          : null,
      onTap: onTap,
    );
  }
}

class TerminalListHeaderCard extends StatelessWidget {
  const TerminalListHeaderCard({
    super.key,
    required this.title,
    required this.filters,
    this.subtitle,
    this.showSubtitleOnCompact = false,
    this.infoChips = const <Widget>[],
    this.showInfoChips = false,
    this.actions = const <Widget>[],
    this.footer,
  });

  final String title;
  final String? subtitle;
  final bool showSubtitleOnCompact;
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
                if (subtitle != null &&
                    subtitle!.trim().isNotEmpty &&
                    (!isCompact || showSubtitleOnCompact)) ...<Widget>[
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
            ? children
                  .map(
                    (action) => _compactAction(
                      action,
                      allowOptionalLabel: children.length <= 2,
                    ),
                  )
                  .toList(growable: false)
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

  Widget _compactAction(Widget action, {required bool allowOptionalLabel}) {
    final data = _TerminalHeaderActionData.from(action);
    if (data == null) {
      return action;
    }

    final tooltip = data.label ?? 'Islem';
    final icon = data.icon ?? _fallbackActionIcon(tooltip);
    final compactLabel = _compactActionLabel(
      tooltip,
      allowOptionalLabel: allowOptionalLabel,
    );

    if (compactLabel != null) {
      final showIcon = _isCriticalCompactAction(tooltip);
      final button = switch (data.style) {
        _TerminalHeaderActionStyle.primary =>
          showIcon
              ? FilledButton.icon(
                  onPressed: data.onPressed,
                  icon: icon,
                  label: Text(compactLabel),
                  style: _compactFilledButtonStyle(),
                )
              : FilledButton(
                  onPressed: data.onPressed,
                  style: _compactFilledButtonStyle(),
                  child: Text(compactLabel),
                ),
        _TerminalHeaderActionStyle.tonal =>
          showIcon
              ? FilledButton.tonalIcon(
                  onPressed: data.onPressed,
                  icon: icon,
                  label: Text(compactLabel),
                  style: _compactFilledButtonStyle(),
                )
              : FilledButton.tonal(
                  onPressed: data.onPressed,
                  style: _compactFilledButtonStyle(),
                  child: Text(compactLabel),
                ),
        _TerminalHeaderActionStyle.outlined =>
          showIcon
              ? OutlinedButton.icon(
                  onPressed: data.onPressed,
                  icon: icon,
                  label: Text(compactLabel),
                  style: _compactOutlinedButtonStyle(),
                )
              : OutlinedButton(
                  onPressed: data.onPressed,
                  style: _compactOutlinedButtonStyle(),
                  child: Text(compactLabel),
                ),
      };
      return Tooltip(message: tooltip, child: button);
    }

    final iconStyle = IconButton.styleFrom(
      minimumSize: const Size(40, 40),
      fixedSize: const Size(40, 40),
      padding: EdgeInsets.zero,
      iconSize: 20,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    return switch (data.style) {
      _TerminalHeaderActionStyle.primary => IconButton.filled(
        onPressed: data.onPressed,
        tooltip: tooltip,
        icon: icon,
        style: iconStyle,
      ),
      _TerminalHeaderActionStyle.tonal => IconButton.filledTonal(
        onPressed: data.onPressed,
        tooltip: tooltip,
        icon: icon,
        style: iconStyle,
      ),
      _TerminalHeaderActionStyle.outlined => IconButton.outlined(
        onPressed: data.onPressed,
        tooltip: tooltip,
        icon: icon,
        style: iconStyle,
      ),
    };
  }

  String? _compactActionLabel(
    String label, {
    required bool allowOptionalLabel,
  }) {
    final normalized = label.toLowerCase();
    if (RegExp(r'(^|\s)yeni(\s|$)').hasMatch(normalized)) {
      return 'Yeni';
    }
    if (normalized.contains('kaydet')) {
      return 'Kaydet';
    }
    if (normalized.contains('gonder')) {
      return 'Gonder';
    }
    if (normalized.contains('kabul')) {
      return 'Kabul';
    }
    if (normalized.contains('olustur')) {
      return 'Olustur';
    }
    if (!allowOptionalLabel) {
      return null;
    }
    if (normalized.contains('yenile')) {
      return 'Yenile';
    }
    if (normalized.contains('detay')) {
      return 'Detay';
    }
    if (normalized.contains('kontrol') || normalized.contains('dogrula')) {
      return 'Kontrol';
    }
    if (normalized.contains('tekrar')) {
      return 'Tekrar';
    }
    if (normalized.contains('ara')) {
      return 'Ara';
    }
    return null;
  }

  bool _isCriticalCompactAction(String label) {
    final normalized = label.toLowerCase();
    return RegExp(r'(^|\s)yeni(\s|$)').hasMatch(normalized) ||
        normalized.contains('kaydet') ||
        normalized.contains('gonder') ||
        normalized.contains('kabul') ||
        normalized.contains('olustur');
  }

  ButtonStyle _compactFilledButtonStyle() {
    return FilledButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  ButtonStyle _compactOutlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
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
    this.breakpoint = 250,
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
        final isUltraNarrow = constraints.maxWidth < 250;
        final trailing = trailingAction == null
            ? null
            : _readableTrailingAction(trailingAction!, compact: isUltraNarrow);

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

        final theme = Theme.of(context);
        final rowTheme = theme.copyWith(
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
              iconSize: 18,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.standard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
              iconSize: 18,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.standard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
              minimumSize: const Size(42, 42),
              fixedSize: const Size(42, 42),
              padding: EdgeInsets.zero,
              iconSize: 20,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.standard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );

        final primaryAction = constraints.maxWidth < 230
            ? _compactPrimaryAction(action)
            : action;

        return Theme(
          data: rowTheme,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: field),
              SizedBox(width: isUltraNarrow ? 4 : 6),
              primaryAction,
              if (trailing != null) ...<Widget>[
                SizedBox(width: isUltraNarrow ? 4 : 6),
                trailing,
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _compactPrimaryAction(Widget action) {
    final data = _TerminalHeaderActionData.from(action);
    if (data == null || data.icon == null) {
      return action;
    }

    final tooltip = data.label ?? 'Ara';
    final style = IconButton.styleFrom(
      minimumSize: const Size(44, 44),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    return switch (data.style) {
      _TerminalHeaderActionStyle.primary => IconButton.filled(
        onPressed: data.onPressed,
        tooltip: tooltip,
        icon: data.icon!,
        style: style,
      ),
      _TerminalHeaderActionStyle.tonal => IconButton.filledTonal(
        onPressed: data.onPressed,
        tooltip: tooltip,
        icon: data.icon!,
        style: style,
      ),
      _TerminalHeaderActionStyle.outlined => IconButton.outlined(
        onPressed: data.onPressed,
        tooltip: tooltip,
        icon: data.icon!,
        style: style,
      ),
    };
  }

  Widget _readableTrailingAction(Widget action, {required bool compact}) {
    if (action is! IconButton) {
      return action;
    }

    final tooltip = action.tooltip?.trim() ?? '';
    final normalized = tooltip.toLowerCase();
    if (!normalized.contains('oku') &&
        !normalized.contains('kamera') &&
        !normalized.contains('qr')) {
      return action;
    }

    if (compact) {
      return IconButton.filledTonal(
        onPressed: action.onPressed,
        tooltip: tooltip.isEmpty ? 'Kamera ile oku' : tooltip,
        icon: IconTheme.merge(
          data: const IconThemeData(size: 18),
          child: action.icon,
        ),
        style: IconButton.styleFrom(
          minimumSize: const Size(42, 42),
          fixedSize: const Size(42, 42),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.standard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return Tooltip(
      message: tooltip.isEmpty ? 'Kamera ile oku' : tooltip,
      child: FilledButton.tonalIcon(
        onPressed: action.onPressed,
        icon: IconTheme.merge(
          data: const IconThemeData(size: 17),
          child: action.icon,
        ),
        label: const Text('Oku'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(54, 42),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.standard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
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
    }

    _moveCursorToEnd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _focusNode.requestFocus();
      if (widget.suppressSoftKeyboard) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      }
      _moveCursorToEnd();
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
            Expanded(child: titleWidget),
            if (actions.isNotEmpty) SizedBox(width: spacing),
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
    this.compact = false,
  });

  final List<TerminalPdaInfo> items;
  final double minTileWidth;
  final double spacing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : double.infinity;
          return Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: items
                .map(
                  (item) => _TerminalCompactInfoChip(
                    label: item.label,
                    value: item.value,
                    maxWidth: maxWidth,
                  ),
                )
                .toList(growable: false),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final effectiveMinTileWidth =
            constraints.hasBoundedWidth && maxWidth < 280
            ? minTileWidth.clamp(108.0, 124.0)
            : minTileWidth;
        final maxColumns = items.length.clamp(1, 3);
        final columns = constraints.hasBoundedWidth
            ? ((maxWidth + spacing) / (effectiveMinTileWidth + spacing))
                  .floor()
                  .clamp(1, maxColumns)
            : 1;
        final tileWidth = constraints.hasBoundedWidth
            ? (maxWidth - (spacing * (columns - 1))) / columns
            : effectiveMinTileWidth;

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
                    compact: compact,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _TerminalCompactInfoChip extends StatelessWidget {
  const _TerminalCompactInfoChip({
    required this.label,
    required this.value,
    required this.maxWidth,
  });

  final String label;
  final String value;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPackageInfo = label.trim().toLowerCase() == 'koli ici';

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10.5,
            letterSpacing: 0,
            height: 1.1,
            color: isPackageInfo
                ? const Color(0xFF7A4A00)
                : const Color(0xFF5F6C7B),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              letterSpacing: 0,
              height: 1.12,
              color: isPackageInfo
                  ? const Color(0xFF553600)
                  : const Color(0xFF1C2D40),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );

    final bounded = maxWidth.isFinite
        ? ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: content,
          )
        : content;

    if (!isPackageInfo) {
      return bounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5B84F).withAlpha(150)),
      ),
      child: bounded,
    );
  }
}

class TerminalPdaInfoTile extends StatelessWidget {
  const TerminalPdaInfoTile({
    super.key,
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPackageInfo = label.trim().toLowerCase() == 'koli ici';

    return Container(
      constraints: BoxConstraints(minHeight: compact ? 28 : 34),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: isPackageInfo
            ? const Color(0xFFFFF8E5)
            : theme.colorScheme.surfaceContainerHighest.withAlpha(44),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPackageInfo
              ? const Color(0xFFE5B84F).withAlpha(150)
              : theme.colorScheme.outlineVariant.withAlpha(72),
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
              fontSize: 11,
              color: isPackageInfo
                  ? const Color(0xFF7A4A00)
                  : const Color(0xFF5F6C7B),
              fontWeight: isPackageInfo ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 13,
              height: 1.12,
              color: isPackageInfo
                  ? const Color(0xFF553600)
                  : const Color(0xFF1C2D40),
              fontWeight: isPackageInfo ? FontWeight.w900 : FontWeight.w800,
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
          constraints: const BoxConstraints(minHeight: 50),
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
                padding: const EdgeInsets.fromLTRB(11, 6, 8, 6),
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

final RegExp _terminalTechnicalUuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Filtrelenmis kullanici aciklamasi dondurur; bos veya ham teknik GUID/UUID
/// iceren kayitlari depo operatorunun ekranindan gizler.
String? terminalDisplayableNote(String? raw) {
  final trimmed = (raw ?? '').trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (_terminalTechnicalUuidPattern.hasMatch(trimmed)) {
    return null;
  }
  return trimmed;
}

/// 0 tabanli veya eksik gelen satir numaralarini her zaman 1 tabanli gosterir.
int terminalDisplayLineNo(
  int rawLineNo,
  int index, {
  bool zeroBasedList = false,
}) {
  if (zeroBasedList) {
    return rawLineNo + 1;
  }
  return rawLineNo <= 0 ? index + 1 : rawLineNo;
}

/// Liste kartlarinda durum rozet(ler)ini ve acma okunu tek yatay satirda
/// hizalayarak baslik altindaki olu dikey boslugu kaldirir.
class TerminalPdaCardTrailing extends StatelessWidget {
  const TerminalPdaCardTrailing({
    super.key,
    this.badges = const <Widget>[],
    this.isExpanded = false,
    this.isLoading = false,
    this.showChevron = true,
  });

  final List<Widget> badges;
  final bool isExpanded;
  final bool isLoading;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailingIndicator = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          )
        : showChevron
        ? Icon(
            isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.chevron_right_rounded,
            size: 22,
            color: theme.colorScheme.primary,
          )
        : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        for (var i = 0; i < badges.length; i += 1) ...<Widget>[
          if (i > 0) const SizedBox(width: 4),
          badges[i],
        ],
        if (trailingIndicator != null) ...<Widget>[
          if (badges.isNotEmpty) const SizedBox(width: 4),
          trailingIndicator,
        ],
      ],
    );
  }
}

/// Detay sayfalarindaki urun kalemleri icin sifir-'...' 2 satirli kompakt kart.
/// Ustte satir no + urun adi + vurgulu miktar; altta kod/barkod/fiyat/ek bilgi
/// Wrap ile tam okunur; ham UUID aciklamalari otomatik filtrelenir.
class TerminalDetailLineCard extends StatelessWidget {
  const TerminalDetailLineCard({
    super.key,
    required this.lineNo,
    required this.stockName,
    this.stockCode,
    this.barcode,
    this.quantityLabel,
    this.badgeLabel,
    this.secondaryFacts = const <String>[],
    this.priceFacts = const <String>[],
    this.note,
  });

  final int lineNo;
  final String stockName;
  final String? stockCode;
  final String? barcode;
  final String? quantityLabel;
  final String? badgeLabel;
  final List<String> secondaryFacts;
  final List<String> priceFacts;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = (stockCode ?? '').trim();
    final codeBarcode = (barcode ?? '').trim();
    final qty = (quantityLabel ?? '').trim();
    final badge = (badgeLabel ?? '').trim();
    final cleanNote = terminalDisplayableNote(note);
    final visibleSecondary = secondaryFacts
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final visiblePrices = priceFacts
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final baseStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 11.5,
      height: 1.18,
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final codeStyle = baseStyle?.copyWith(
      color: theme.colorScheme.onSurface.withAlpha(215),
      fontWeight: FontWeight.w800,
    );
    final priceStyle = baseStyle?.copyWith(
      color: const Color(0xFF1C2D40),
      fontWeight: FontWeight.w800,
    );
    final dotStyle = baseStyle?.copyWith(
      color: theme.colorScheme.onSurfaceVariant.withAlpha(140),
    );

    final metaSegments = <Widget>[];
    void addMeta(Widget widget) {
      if (metaSegments.isNotEmpty) {
        metaSegments.add(Text(' · ', style: dotStyle));
      }
      metaSegments.add(widget);
    }

    if (code.isNotEmpty) {
      addMeta(Text(code, style: codeStyle));
    }
    if (codeBarcode.isNotEmpty) {
      addMeta(Text(codeBarcode, style: baseStyle));
    }
    for (final fact in visibleSecondary) {
      addMeta(Text(fact, style: baseStyle));
    }
    for (final price in visiblePrices) {
      addMeta(Text(price, style: priceStyle));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(96),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withAlpha(110),
                  ),
                ),
                child: Text(
                  lineNo.toString().padLeft(2, '0'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    height: 1,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  stockName.trim().isEmpty ? 'Urun adi bulunamadi' : stockName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 13.5,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF182230),
                  ),
                ),
              ),
              if (qty.isNotEmpty || badge.isNotEmpty) ...<Widget>[
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (qty.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withAlpha(
                            165,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          qty,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 12,
                            height: 1.05,
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    if (badge.isNotEmpty) ...<Widget>[
                      if (qty.isNotEmpty) const SizedBox(height: 3),
                      TerminalBadge(label: badge),
                    ],
                  ],
                ),
              ],
            ],
          ),
          if (metaSegments.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurface.withAlpha(185),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Wrap(
                    spacing: 0,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: metaSegments,
                  ),
                ),
              ],
            ),
          ],
          if (cleanNote != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              cleanNote,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                height: 1.2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Detay ekranlarinda E-Irsaliye aksiyonlarini kompakt tek seritte sunar.
class TerminalEDespatchActionStrip extends StatelessWidget {
  const TerminalEDespatchActionStrip({
    super.key,
    required this.canSendEDespatch,
    required this.canViewEDespatchPdf,
    required this.isSendingEDespatch,
    required this.isLoadingPdf,
    required this.onSendEDespatch,
    required this.onShowPdf,
  });

  final bool canSendEDespatch;
  final bool canViewEDespatchPdf;
  final bool isSendingEDespatch;
  final bool isLoadingPdf;
  final VoidCallback onSendEDespatch;
  final VoidCallback onShowPdf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1F4369), Color(0xFF315D8D)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'E-Irsaliye Islemleri',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (canSendEDespatch) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              'Plaka, sofor ve TCKN bilgileri gonderim aninda istenir.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                color: Colors.white.withAlpha(220),
                height: 1.2,
              ),
            ),
          ],
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              if (canSendEDespatch)
                FilledButton.icon(
                  onPressed: isSendingEDespatch || isLoadingPdf
                      ? null
                      : onSendEDespatch,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: const Color(0xFFF7C948),
                    foregroundColor: const Color(0xFF1E2C3A),
                  ),
                  icon: isSendingEDespatch
                      ? const SizedBox(
                          height: 15,
                          width: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 17),
                  label: Text(
                    isSendingEDespatch
                        ? 'Gonderiliyor...'
                        : 'E-Irsaliyeye Cevir',
                  ),
                ),
              if (canViewEDespatchPdf)
                OutlinedButton.icon(
                  onPressed: isSendingEDespatch || isLoadingPdf
                      ? null
                      : onShowPdf,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withAlpha(110)),
                  ),
                  icon: isLoadingPdf
                      ? const SizedBox(
                          height: 15,
                          width: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded, size: 17),
                  label: Text(isLoadingPdf ? 'Hazirlaniyor...' : 'PDF Goster'),
                ),
            ],
          ),
        ],
      ),
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
    this.showFullTitle = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;
  final bool isEntryLine;
  final bool showFullTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedSubtitle = subtitle?.trim() ?? '';
    final promoteSubtitle =
        !isEntryLine && !showFullTitle && normalizedSubtitle.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: isEntryLine ? EdgeInsets.zero : const EdgeInsets.only(bottom: 6),
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
            padding: isEntryLine
                ? const EdgeInsets.fromLTRB(8, 3, 6, 1)
                : const EdgeInsets.fromLTRB(8, 4, 6, 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  IconTheme.merge(
                    data: IconThemeData(size: isEntryLine ? 15 : 18),
                    child: leading!,
                  ),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: promoteSubtitle
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              normalizedSubtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                height: 1,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                title,
                                maxLines: showFullTitle ? null : 1,
                                overflow: showFullTitle
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: isEntryLine
                                    ? theme.textTheme.labelSmall?.copyWith(
                                        height: 1.05,
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w900,
                                      )
                                    : theme.textTheme.titleSmall?.copyWith(
                                        height: 1.05,
                                        fontWeight: FontWeight.w900,
                                      ),
                              ),
                            ),
                            if (normalizedSubtitle.isNotEmpty) ...<Widget>[
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  normalizedSubtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    height: 1.05,
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(150),
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
                        minimumSize: const Size(42, 42),
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
          if (!isEntryLine) const Divider(height: 1),
          Padding(
            padding: isEntryLine
                ? const EdgeInsets.fromLTRB(5, 2, 5, 5)
                : const EdgeInsets.all(5),
            child: child,
          ),
        ],
      ),
    );
  }
}

enum _TerminalProductCardDensity { ultraNarrow, narrow, medium, wide }

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
    this.packageFactor,
    this.warningLabel,
    this.highlightOnMount = false,
    this.canDelete = true,
    this.onDelete,
    this.onMinimumReached,
    this.quantityStep = 1,
    this.maximumQuantity = terminalCreateMaximumQuantity,
    this.quantityInputFormatters = const <TextInputFormatter>[],
    this.quantityValidator,
    this.allowEmptyQuantity = false,
    this.collapsible = true,
    this.expandedExtraChild,
    this.collapsedPillPrefix,
    this.collapsedPillBackgroundColor,
    this.collapsedPillBorderColor,
    this.collapsedPillForegroundColor,
  });

  final int lineNo;
  final String stockCode;
  final String stockName;
  final TextEditingController quantityController;
  final String? unitLabel;
  final String? priceLabel;
  final String? barcode;
  final String? packageLabel;
  final double? packageFactor;
  final String? warningLabel;
  final bool highlightOnMount;
  final bool canDelete;
  final VoidCallback? onDelete;
  final VoidCallback? onMinimumReached;
  final double quantityStep;
  final double? maximumQuantity;
  final List<TextInputFormatter> quantityInputFormatters;
  final FormFieldValidator<String>? quantityValidator;
  final bool allowEmptyQuantity;
  final bool collapsible;
  final Widget? expandedExtraChild;
  final String? collapsedPillPrefix;
  final Color? collapsedPillBackgroundColor;
  final Color? collapsedPillBorderColor;
  final Color? collapsedPillForegroundColor;

  Object get _accordionKey => key ?? '$lineNo-$stockCode-$stockName';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accordionScope = collapsible
        ? TerminalLineAccordionScope.maybeOf(context)
        : null;

    if (accordionScope == null) {
      return _buildCardContent(
        context,
        theme: theme,
        isAccordion: false,
        isExpanded: true,
        onToggleAccordion: null,
        onQuantitySubmitted: null,
        onValidationInvalid: null,
      );
    }

    final cardKey = _accordionKey;
    return ValueListenableBuilder<Object?>(
      valueListenable: accordionScope.expandedKeyNotifier,
      builder: (context, expandedKey, _) {
        final isExpanded = expandedKey == cardKey;
        return _buildCardContent(
          context,
          theme: theme,
          isAccordion: true,
          isExpanded: isExpanded,
          onToggleAccordion: () => accordionScope.toggle(cardKey),
          onQuantitySubmitted: () =>
              accordionScope.collapseAndReturnFocus(cardKey),
          onValidationInvalid: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              accordionScope.expand(cardKey);
            });
          },
        );
      },
    );
  }

  Widget _buildCardContent(
    BuildContext context, {
    required ThemeData theme,
    required bool isAccordion,
    required bool isExpanded,
    required VoidCallback? onToggleAccordion,
    required VoidCallback? onQuantitySubmitted,
    required VoidCallback? onValidationInvalid,
  }) {
    final hasExplicitWarning = (warningLabel ?? '').trim().isNotEmpty;

    return TweenAnimationBuilder<double>(
      key: const ValueKey<String>('terminal-product-line-highlight'),
      tween: Tween<double>(begin: highlightOnMount ? 1 : 0, end: 0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, emphasis, child) {
        final baseColor = isAccordion && isExpanded
            ? (hasExplicitWarning
                  ? const Color(0xFFFFF5F4)
                  : theme.colorScheme.primaryContainer.withAlpha(32))
            : theme.colorScheme.surface;
        final baseBorderColor = isAccordion && isExpanded
            ? (hasExplicitWarning
                  ? theme.colorScheme.error.withAlpha(140)
                  : theme.colorScheme.primary.withAlpha(145))
            : theme.colorScheme.outlineVariant.withAlpha(115);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.fromLTRB(7, 4, 7, 4),
          decoration: BoxDecoration(
            color: Color.lerp(
              baseColor,
              theme.colorScheme.secondaryContainer,
              emphasis * 0.7,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Color.lerp(
                baseBorderColor,
                theme.colorScheme.secondary,
                emphasis,
              )!,
              width: (isAccordion && isExpanded ? 1.2 : 1) + (emphasis * 0.5),
            ),
          ),
          child: child,
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final density = _resolveDensity(constraints.maxWidth);
          final isDesktopRow = !isAccordion && constraints.maxWidth >= 560;
          final deleteButton = TerminalLineDeleteButton(
            enabled: canDelete,
            onPressed: onDelete,
            compactIconOnly: true,
          );
          final accordionTrailing = isAccordion
              ? _buildAccordionQuantityPill(
                  theme: theme,
                  isExpanded: isExpanded,
                  maxWidth: constraints.maxWidth,
                )
              : (isDesktopRow ? null : deleteButton);
          final details = _TerminalCompactProductLineDetails(
            lineNo: lineNo,
            stockCode: stockCode,
            stockName: stockName,
            unitLabel: unitLabel,
            priceLabel: priceLabel,
            barcode: barcode,
            packageLabel: packageLabel,
            density: density,
            showUnitInMeta: false,
            trailing: accordionTrailing,
          );
          final headerWidget = isAccordion
              ? InkWell(
                  key: const ValueKey<String>(
                    'terminal-product-line-accordion-toggle',
                  ),
                  onTap: onToggleAccordion,
                  borderRadius: BorderRadius.circular(8),
                  child: details,
                )
              : details;
          final quantityControl = _TerminalCompactQuantityControl(
            controller: quantityController,
            unitLabel: unitLabel,
            step: quantityStep,
            maximum: maximumQuantity,
            inputFormatters: quantityInputFormatters,
            validator: quantityValidator,
            allowEmptyQuantity: allowEmptyQuantity,
            onMinimumReached: onMinimumReached,
            onSubmitted: onQuantitySubmitted,
            onInvalid: onValidationInvalid,
          );

          final Widget content;
          if (isDesktopRow) {
            content = Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(child: headerWidget),
                const SizedBox(width: 8),
                SizedBox(width: 196, child: quantityControl),
                const SizedBox(width: 4),
                deleteButton,
              ],
            );
          } else if (isAccordion) {
            content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                headerWidget,
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (expandedExtraChild != null) ...<Widget>[
                          expandedExtraChild!,
                          const SizedBox(height: 6),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Expanded(child: quantityControl),
                            if (canDelete && onDelete != null) ...<Widget>[
                              const SizedBox(width: 6),
                              deleteButton,
                            ],
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  FormField<String>(
                    validator: (_) {
                      final text = quantityController.text;
                      if (allowEmptyQuantity && text.trim().isEmpty) {
                        return null;
                      }
                      final customError = quantityValidator?.call(text);
                      if (customError != null) {
                        onValidationInvalid?.call();
                        return customError;
                      }
                      final qty =
                          _TerminalCompactQuantityControlState._readQuantity(
                            text,
                          );
                      if (qty <= 0 ||
                          (maximumQuantity != null && qty > maximumQuantity!)) {
                        onValidationInvalid?.call();
                        return '';
                      }
                      return null;
                    },
                    builder: (_) => const SizedBox.shrink(),
                  ),
              ],
            );
          } else {
            content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                headerWidget,
                const SizedBox(height: 4),
                quantityControl,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[content, _buildWarningBanner(context)],
          );
        },
      ),
    );
  }

  Widget _buildAccordionQuantityPill({
    required ThemeData theme,
    required bool isExpanded,
    required double maxWidth,
  }) {
    final unit = (unitLabel ?? '').trim();
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: quantityController,
      builder: (context, value, _) {
        final rawText = value.text.trim();
        final displayQty = rawText.isEmpty ? '0' : rawText;
        final hasWarning =
            (warningLabel ?? '').trim().isNotEmpty ||
            _packageMultipleWarning(rawText) != null;
        final pillBg = hasWarning
            ? const Color(0xFFFFF1E6)
            : (collapsedPillBackgroundColor ?? const Color(0xFFE6F5EA));
        final pillBorder = hasWarning
            ? const Color(0xFFE5A93C)
            : (collapsedPillBorderColor ?? const Color(0xFFA8D9B5));
        final pillFg = hasWarning
            ? const Color(0xFF8A4B00)
            : (collapsedPillForegroundColor ?? const Color(0xFF186A3B));
        final rawPrefix = (collapsedPillPrefix ?? '').trim();
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final compactPill = maxWidth < 260 || textScale > 1.25;
        final prefix = rawPrefix.isEmpty
            ? ''
            : compactPill
            ? rawPrefix.split(' ').first
            : rawPrefix;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compactPill ? 5 : 7,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: pillBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (prefix.isNotEmpty) ...<Widget>[
                    Text(
                      prefix,
                      style: theme.textTheme.labelSmall?.copyWith(
                        height: 1.05,
                        color: pillFg,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    displayQty,
                    style: theme.textTheme.labelMedium?.copyWith(
                      height: 1.05,
                      color: pillFg,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (unit.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: theme.textTheme.labelSmall?.copyWith(
                        height: 1.05,
                        color: pillFg,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        );
      },
    );
  }

  static _TerminalProductCardDensity _resolveDensity(double maxWidth) {
    if (maxWidth < 250) {
      return _TerminalProductCardDensity.ultraNarrow;
    }
    if (maxWidth < 312) {
      return _TerminalProductCardDensity.narrow;
    }
    if (maxWidth < 350) {
      return _TerminalProductCardDensity.medium;
    }
    return _TerminalProductCardDensity.wide;
  }

  Widget _buildWarningBanner(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: quantityController,
      builder: (context, value, _) {
        final explicitWarning = (warningLabel ?? '').trim();
        final packageWarning = _packageMultipleWarning(value.text);
        final message = explicitWarning.isNotEmpty
            ? explicitWarning
            : packageWarning;
        if (message == null || message.isEmpty) {
          return const SizedBox.shrink();
        }

        final isError = explicitWarning.isNotEmpty;
        final theme = Theme.of(context);
        final background = isError
            ? theme.colorScheme.errorContainer.withAlpha(155)
            : const Color(0xFFFFF4DE);
        final borderColor = isError
            ? theme.colorScheme.error.withAlpha(80)
            : const Color(0xFFE5B84F).withAlpha(135);
        final foreground = isError
            ? theme.colorScheme.error
            : const Color(0xFF8A5A00);

        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.warning_amber_rounded, size: 14, color: foreground),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      height: 1.05,
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
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
    this.highlightOnMount = false,
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
  final bool highlightOnMount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      key: const ValueKey<String>('terminal-product-line-summary-highlight'),
      tween: Tween<double>(begin: highlightOnMount ? 1 : 0, end: 0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, emphasis, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
          decoration: BoxDecoration(
            color: Color.lerp(
              theme.colorScheme.surface,
              theme.colorScheme.secondaryContainer,
              emphasis * 0.7,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Color.lerp(
                theme.colorScheme.outlineVariant.withAlpha(115),
                theme.colorScheme.secondary,
                emphasis,
              )!,
              width: 1 + (emphasis * 0.5),
            ),
          ),
          child: child,
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final density = TerminalCompactProductLineCard._resolveDensity(
            constraints.maxWidth,
          );
          final warning = (warningLabel ?? '').trim();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _TerminalCompactProductLineDetails(
                lineNo: lineNo,
                stockCode: stockCode,
                stockName: stockName,
                unitLabel: unitLabel,
                priceLabel: priceLabel,
                barcode: barcode,
                packageLabel: packageLabel,
                density: density,
                showUnitInMeta: true,
                trailing: trailing,
              ),
              if (warning.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    warning,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      height: 1.05,
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class TerminalDualQuantityProductLineCard extends StatelessWidget {
  const TerminalDualQuantityProductLineCard({
    super.key,
    required this.lineNo,
    required this.stockCode,
    required this.stockName,
    required this.primaryQuantity,
    required this.secondaryQuantity,
    this.primaryQuantityController,
    this.secondaryQuantityController,
    this.unitLabel,
    this.priceLabel,
    this.barcode,
    this.packageLabel,
    this.statusBadge,
    this.footerBanner,
    this.highlightOnMount = false,
    this.canDelete = true,
    this.onDelete,
    this.collapsible = true,
  });

  final int lineNo;
  final String stockCode;
  final String stockName;
  final Widget primaryQuantity;
  final Widget secondaryQuantity;
  final TextEditingController? primaryQuantityController;
  final TextEditingController? secondaryQuantityController;
  final String? unitLabel;
  final String? priceLabel;
  final String? barcode;
  final String? packageLabel;
  final Widget? statusBadge;
  final Widget? footerBanner;
  final bool highlightOnMount;
  final bool canDelete;
  final VoidCallback? onDelete;
  final bool collapsible;

  Object get _accordionKey => key ?? 'dual-$lineNo-$stockCode-$stockName';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accordionScope =
        collapsible &&
            primaryQuantityController != null &&
            secondaryQuantityController != null
        ? TerminalLineAccordionScope.maybeOf(context)
        : null;

    if (accordionScope == null) {
      return _buildDualCardContent(
        context,
        theme: theme,
        isAccordion: false,
        isExpanded: true,
        onToggleAccordion: null,
      );
    }

    final cardKey = _accordionKey;
    return ValueListenableBuilder<Object?>(
      valueListenable: accordionScope.expandedKeyNotifier,
      builder: (context, expandedKey, _) {
        final isExpanded = expandedKey == cardKey;
        return _TerminalAccordionItemScope(
          onValidationInvalid: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              accordionScope.expand(cardKey);
            });
          },
          onQuantitySubmitted: () =>
              accordionScope.collapseAndReturnFocus(cardKey),
          child: _buildDualCardContent(
            context,
            theme: theme,
            isAccordion: true,
            isExpanded: isExpanded,
            onToggleAccordion: () => accordionScope.toggle(cardKey),
          ),
        );
      },
    );
  }

  Widget _buildDualCardContent(
    BuildContext context, {
    required ThemeData theme,
    required bool isAccordion,
    required bool isExpanded,
    required VoidCallback? onToggleAccordion,
  }) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey<String>('terminal-dual-product-line-highlight'),
      tween: Tween<double>(begin: highlightOnMount ? 1 : 0, end: 0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, emphasis, child) {
        final baseColor = isAccordion && isExpanded
            ? theme.colorScheme.primaryContainer.withAlpha(32)
            : theme.colorScheme.surface;
        final baseBorderColor = isAccordion && isExpanded
            ? theme.colorScheme.primary.withAlpha(145)
            : theme.colorScheme.outlineVariant.withAlpha(115);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
          decoration: BoxDecoration(
            color: Color.lerp(
              baseColor,
              theme.colorScheme.secondaryContainer,
              emphasis * 0.7,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Color.lerp(
                baseBorderColor,
                theme.colorScheme.secondary,
                emphasis,
              )!,
              width: (isAccordion && isExpanded ? 1.2 : 1) + (emphasis * 0.5),
            ),
          ),
          child: child,
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final density = TerminalCompactProductLineCard._resolveDensity(
            constraints.maxWidth,
          );
          final deleteButton = canDelete && onDelete != null
              ? TerminalLineDeleteButton(
                  enabled: canDelete,
                  onPressed: onDelete,
                  compactIconOnly: !isAccordion,
                )
              : null;
          final trailingWidgets = <Widget>[
            if (!isAccordion) ?statusBadge,
            if (isAccordion)
              _buildDualComparisonPill(
                theme: theme,
                isExpanded: isExpanded,
                maxWidth: constraints.maxWidth,
              )
            else
              ?deleteButton,
          ];
          final trailing = trailingWidgets.isEmpty
              ? null
              : trailingWidgets.length == 1
              ? trailingWidgets.first
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (
                      var i = 0;
                      i < trailingWidgets.length;
                      i += 1
                    ) ...<Widget>[
                      if (i > 0) const SizedBox(width: 4),
                      trailingWidgets[i],
                    ],
                  ],
                );
          final useSideBySide = constraints.maxWidth >= 420;
          final details = _TerminalCompactProductLineDetails(
            lineNo: lineNo,
            stockCode: stockCode,
            stockName: stockName,
            unitLabel: unitLabel,
            priceLabel: priceLabel,
            barcode: barcode,
            packageLabel: packageLabel,
            density: density,
            showUnitInMeta: true,
            trailing: trailing,
          );
          final headerWidget = isAccordion
              ? InkWell(
                  key: const ValueKey<String>(
                    'terminal-dual-line-accordion-toggle',
                  ),
                  onTap: onToggleAccordion,
                  borderRadius: BorderRadius.circular(8),
                  child: details,
                )
              : details;

          final steppersBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 6),
              if (useSideBySide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: primaryQuantity),
                    const SizedBox(width: 10),
                    Expanded(child: secondaryQuantity),
                    if (isAccordion && deleteButton != null) ...<Widget>[
                      const SizedBox(width: 6),
                      deleteButton,
                    ],
                  ],
                )
              else ...<Widget>[
                primaryQuantity,
                const SizedBox(height: 6),
                secondaryQuantity,
                if (isAccordion && deleteButton != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerRight, child: deleteButton),
                ],
              ],
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              headerWidget,
              if (isAccordion)
                Visibility(
                  visible: isExpanded,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: false,
                  child: steppersBlock,
                )
              else
                steppersBlock,
              if (footerBanner != null) ...<Widget>[
                const SizedBox(height: 5),
                footerBanner!,
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildDualComparisonPill({
    required ThemeData theme,
    required bool isExpanded,
    required double maxWidth,
  }) {
    final pCtrl = primaryQuantityController!;
    final sCtrl = secondaryQuantityController!;

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[pCtrl, sCtrl]),
      builder: (context, _) {
        final primaryRaw = pCtrl.text.trim();
        final secondaryRaw = sCtrl.text.trim();
        final primaryVal =
            double.tryParse(primaryRaw.replaceAll(',', '.')) ?? 0;
        final secondaryVal =
            double.tryParse(secondaryRaw.replaceAll(',', '.')) ?? 0;
        final diff = secondaryVal - primaryVal;
        final hasDiff = diff.abs() > 0.0001;
        final diffText = diff > 0
            ? '+${TerminalCompactProductLineCard._formatQuantity(diff)}'
            : TerminalCompactProductLineCard._formatQuantity(diff);

        final badgeBg = hasDiff
            ? const Color(0xFFFDECEA)
            : const Color(0xFFE6F5EA);
        final badgeFg = hasDiff
            ? const Color(0xFFB71C1C)
            : const Color(0xFF186A3B);
        final pLabel = primaryRaw.isEmpty ? '0' : primaryRaw;
        final sLabel = secondaryRaw.isEmpty ? '0' : secondaryRaw;
        final useLabeledText = maxWidth >= 310;
        final pillText = useLabeledText
            ? 'Irs:$pLabel F:$sLabel${hasDiff ? ' ($diffText)' : ''}'
            : '$pLabel/$sLabel${hasDiff ? ' ($diffText)' : ''}';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                pillText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  height: 1.05,
                  color: badgeFg,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        );
      },
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
    required this.density,
    required this.showUnitInMeta,
    this.trailing,
  });

  final int lineNo;
  final String stockCode;
  final String stockName;
  final String? unitLabel;
  final String? priceLabel;
  final String? barcode;
  final String? packageLabel;
  final _TerminalProductCardDensity density;
  final bool showUnitInMeta;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedName = stockName.trim().isEmpty
        ? 'Urun adi bulunamadi'
        : stockName;
    final lineBadge = Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(110),
        ),
      ),
      child: Text(
        lineNo.toString().padLeft(2, '0'),
        style: theme.textTheme.labelMedium?.copyWith(
          height: 1,
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    final nameWidget = GestureDetector(
      onLongPress: () => _showFullProductDetails(context, normalizedName),
      child: Text(
        normalizedName,
        key: const ValueKey<String>('terminal-product-line-name'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontSize: 13.5,
          height: 1.12,
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    final metaBlock = _buildMetadataBlock(theme);
    final useFullWidthMeta =
        density == _TerminalProductCardDensity.ultraNarrow ||
        density == _TerminalProductCardDensity.narrow ||
        (priceLabel ?? '').trim().isNotEmpty;
    final stackTrailing =
        density == _TerminalProductCardDensity.ultraNarrow ||
        (density == _TerminalProductCardDensity.narrow &&
            MediaQuery.textScalerOf(context).scale(1) > 1.15);

    if (useFullWidthMeta) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              lineBadge,
              const SizedBox(width: 6),
              Expanded(child: nameWidget),
              if (trailing != null && !stackTrailing) ...<Widget>[
                const SizedBox(width: 4),
                trailing!,
              ],
            ],
          ),
          if (trailing != null && stackTrailing) ...<Widget>[
            const SizedBox(height: 2),
            Align(alignment: Alignment.centerRight, child: trailing!),
          ],
          if (metaBlock != null) ...<Widget>[
            const SizedBox(height: 2),
            metaBlock,
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  lineBadge,
                  const SizedBox(width: 6),
                  Expanded(child: nameWidget),
                ],
              ),
              if (metaBlock != null) ...<Widget>[
                const SizedBox(height: 3),
                metaBlock,
              ],
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[const SizedBox(width: 4), trailing!],
      ],
    );
  }

  Future<void> _showFullProductDetails(
    BuildContext context,
    String displayName,
  ) {
    final code = stockCode.trim();
    final codeBarcode = (barcode ?? '').trim();
    final unit = (unitLabel ?? '').trim();
    final packageInfo = _packageInfoValue;
    final price = (priceLabel ?? '').trim();

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(displayName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (code.isNotEmpty) Text('Stok kodu: $code'),
              if (codeBarcode.isNotEmpty) Text('Barkod: $codeBarcode'),
              if (unit.isNotEmpty) Text('Birim: $unit'),
              if (packageInfo.isNotEmpty) Text('Koli ici: $packageInfo'),
              if (price.isNotEmpty) Text('Fiyat: $price'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
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

  Widget? _buildMetadataBlock(ThemeData theme) {
    final code = stockCode.trim();
    final codeBarcode = (barcode ?? '').trim();
    final unit = (unitLabel ?? '').trim();
    final packageInfo = _packageInfoValue;
    final price = (priceLabel ?? '').trim();

    final baseStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: density == _TerminalProductCardDensity.narrow ? 10.8 : 11.2,
      letterSpacing: 0,
      height: 1.15,
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final codeStyle = baseStyle?.copyWith(
      color: theme.colorScheme.onSurface.withAlpha(215),
      fontWeight: FontWeight.w800,
    );
    final packageStyle = baseStyle?.copyWith(
      color: const Color(0xFF7A4A00),
      fontWeight: FontWeight.w800,
    );
    final separatorStyle = baseStyle?.copyWith(
      color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
    );
    final codeIconColor = theme.colorScheme.onSurface.withAlpha(200);
    final packageIconColor = packageInfo.isNotEmpty
        ? const Color(0xFF8A5A00)
        : codeIconColor;

    Widget dot() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text('·', style: separatorStyle),
    );

    // Normal terminal widths keep operational identity on one line. Values
    // scale down only when needed, so none of them turn into an ellipsis.
    if (density != _TerminalProductCardDensity.ultraNarrow) {
      final identitySegments = <Widget>[];
      void addIdentity(Widget widget) {
        if (identitySegments.isNotEmpty) {
          identitySegments.add(dot());
        }
        identitySegments.add(widget);
      }

      if (code.isNotEmpty) {
        addIdentity(Text(code, style: codeStyle));
      }
      if (codeBarcode.isNotEmpty) {
        addIdentity(Text(codeBarcode, style: baseStyle));
      }
      if (showUnitInMeta && unit.isNotEmpty) {
        addIdentity(Text(unit, style: codeStyle));
      }
      if (packageInfo.isNotEmpty) {
        addIdentity(Text('Koli ici $packageInfo', style: packageStyle));
      }

      if (identitySegments.isEmpty && price.isEmpty) {
        return null;
      }

      Widget fittedLine({
        required IconData icon,
        required Color iconColor,
        required List<Widget> children,
      }) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(mainAxisSize: MainAxisSize.min, children: children),
              ),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (identitySegments.isNotEmpty)
            fittedLine(
              icon: Icons.qr_code_scanner_rounded,
              iconColor: codeIconColor,
              children: identitySegments,
            ),
          if (price.isNotEmpty) ...<Widget>[
            if (identitySegments.isNotEmpty) const SizedBox(height: 2),
            fittedLine(
              icon: Icons.payments_outlined,
              iconColor: packageIconColor,
              children: <Widget>[Text(price, style: baseStyle)],
            ),
          ],
        ],
      );
    }

    final canUseSingleLine =
        density == _TerminalProductCardDensity.wide &&
        price.isEmpty &&
        !(showUnitInMeta && unit.isNotEmpty && packageInfo.isNotEmpty);

    // Genis duzen (>= 400 dp ekran / >= 350 dp kart): yalniz fiyat yoksa ve
    // alan sayisi sigiyorsa tek satirda goster; barkod/koli/fiyat asla kesilmez.
    if (canUseSingleLine) {
      final hasAny =
          code.isNotEmpty ||
          codeBarcode.isNotEmpty ||
          packageInfo.isNotEmpty ||
          (showUnitInMeta && unit.isNotEmpty);
      if (!hasAny) {
        return null;
      }

      final segments = <Widget>[];
      void addSegment(Widget widget) {
        if (segments.isNotEmpty) {
          segments.add(dot());
        }
        segments.add(widget);
      }

      if (code.isNotEmpty) {
        addSegment(Text(code, style: codeStyle));
      }
      if (codeBarcode.isNotEmpty) {
        addSegment(Text(codeBarcode, style: baseStyle));
      }
      if (showUnitInMeta && unit.isNotEmpty) {
        addSegment(Text(unit, style: codeStyle));
      }
      if (packageInfo.isNotEmpty) {
        addSegment(Text('Koli ici $packageInfo', style: packageStyle));
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.qr_code_scanner_rounded, size: 14, color: codeIconColor),
          const SizedBox(width: 5),
          Expanded(
            child: Wrap(
              spacing: 0,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: segments,
            ),
          ),
        ],
      );
    }

    // 2 satirli temiz duzen (dar/orta veya fiyat+koli iceren genis kartlar):
    // Satir 1: Stok kodu · Barkod (genis/orta kartta birim de eklenebilir)
    // Satir 2: Koli ici ve fiyat Wrap ile tam okunur; hicbir deger '...' olmaz.
    final lines = <Widget>[];
    final includeUnitOnLine1 =
        (density == _TerminalProductCardDensity.medium ||
            density == _TerminalProductCardDensity.wide) &&
        showUnitInMeta &&
        unit.isNotEmpty;

    if (code.isNotEmpty || codeBarcode.isNotEmpty) {
      final line1Segments = <Widget>[];
      void addLine1(Widget widget) {
        if (line1Segments.isNotEmpty) {
          line1Segments.add(dot());
        }
        line1Segments.add(widget);
      }

      if (code.isNotEmpty) {
        addLine1(Text(code, style: codeStyle));
      }
      if (codeBarcode.isNotEmpty) {
        addLine1(Text(codeBarcode, style: baseStyle));
      }
      if (includeUnitOnLine1) {
        addLine1(Text(unit, style: codeStyle));
      }

      lines.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.qr_code_scanner_rounded, size: 14, color: codeIconColor),
            const SizedBox(width: 5),
            Expanded(
              child: Wrap(
                spacing: 0,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: line1Segments,
              ),
            ),
          ],
        ),
      );
    }

    final includeUnitOnLine2 =
        showUnitInMeta && !includeUnitOnLine1 && unit.isNotEmpty;
    final needsSecondLine =
        packageInfo.isNotEmpty || price.isNotEmpty || includeUnitOnLine2;

    if (needsSecondLine) {
      final line2Segments = <Widget>[];
      void addLine2(Widget widget) {
        if (line2Segments.isNotEmpty) {
          line2Segments.add(dot());
        }
        line2Segments.add(widget);
      }

      if (includeUnitOnLine2) {
        addLine2(Text(unit, style: codeStyle));
        if (packageInfo.isNotEmpty) {
          addLine2(Text('Koli ici $packageInfo', style: packageStyle));
        }
        if (price.isNotEmpty) {
          addLine2(Text(price, style: baseStyle));
        }
      } else {
        if (!showUnitInMeta &&
            density != _TerminalProductCardDensity.medium &&
            density != _TerminalProductCardDensity.wide &&
            unit.isNotEmpty &&
            packageInfo.isNotEmpty) {
          addLine2(Text('$unit · Koli ici $packageInfo', style: packageStyle));
        } else if (packageInfo.isNotEmpty) {
          addLine2(Text('Koli ici $packageInfo', style: packageStyle));
        }
        if (price.isNotEmpty) {
          addLine2(Text(price, style: baseStyle));
        }
      }

      if (line2Segments.isNotEmpty) {
        lines.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.inventory_2_outlined,
                size: 14,
                color: packageIconColor,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Wrap(
                  spacing: 0,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: line2Segments,
                ),
              ),
            ],
          ),
        );
      }
    }

    if (lines.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < lines.length; i += 1) ...<Widget>[
          if (i > 0) const SizedBox(height: 2),
          lines[i],
        ],
      ],
    );
  }
}

class TerminalLineDeleteButton extends StatelessWidget {
  const TerminalLineDeleteButton({
    super.key,
    this.enabled = true,
    required this.onPressed,
    this.compactIconOnly = false,
  });

  final bool enabled;
  final VoidCallback? onPressed;
  final bool compactIconOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (compactIconOnly) {
      return IconButton(
        onPressed: enabled ? onPressed : null,
        tooltip: 'Satiri sil',
        icon: const Icon(Icons.delete_outline_rounded, size: 20),
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          backgroundColor: theme.colorScheme.errorContainer.withAlpha(85),
          disabledForegroundColor: theme.colorScheme.onSurface.withAlpha(70),
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: enabled
                  ? theme.colorScheme.error.withAlpha(70)
                  : theme.colorScheme.outlineVariant.withAlpha(70),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: 'Satiri sil',
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.delete_outline_rounded, size: 16),
        label: const Text('Sil'),
        style: FilledButton.styleFrom(
          foregroundColor: theme.colorScheme.onErrorContainer,
          backgroundColor: theme.colorScheme.errorContainer,
          disabledForegroundColor: theme.colorScheme.onSurface.withAlpha(70),
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
          minimumSize: const Size(58, 34),
          padding: const EdgeInsets.symmetric(horizontal: 7),
          tapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

class _TerminalCompactQuantityControl extends StatefulWidget {
  const _TerminalCompactQuantityControl({
    required this.controller,
    required this.step,
    this.unitLabel,
    this.maximum,
    this.inputFormatters = const <TextInputFormatter>[],
    this.validator,
    this.allowEmptyQuantity = false,
    required this.onMinimumReached,
    this.onSubmitted,
    this.onInvalid,
  });

  final TextEditingController controller;
  final String? unitLabel;
  final double step;
  final double? maximum;
  final List<TextInputFormatter> inputFormatters;
  final FormFieldValidator<String>? validator;
  final bool allowEmptyQuantity;
  final VoidCallback? onMinimumReached;
  final VoidCallback? onSubmitted;
  final VoidCallback? onInvalid;

  @override
  State<_TerminalCompactQuantityControl> createState() =>
      _TerminalCompactQuantityControlState();
}

class _TerminalCompactQuantityControlState
    extends State<_TerminalCompactQuantityControl> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus && widget.controller.text.isNotEmpty) {
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = (widget.unitLabel ?? '').trim();

    return SizedBox(
      height: 48,
      child: Row(
        children: <Widget>[
          _TerminalCompactQuantityButton(
            icon: Icons.remove_rounded,
            tooltip: 'Azalt',
            isPrimary: false,
            onPressed: () => _changeBy(context, -widget.step),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _focusNode.requestFocus(),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(115),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(50),
                  ),
                ),
                alignment: Alignment.center,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: widget.controller,
                      builder: (context, value, _) {
                        final qtyStyle = theme.textTheme.titleMedium?.copyWith(
                          fontSize: 19,
                          height: 1.05,
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w900,
                        );
                        final unitStyle = theme.textTheme.labelMedium?.copyWith(
                          fontSize: 11.5,
                          height: 1,
                          color: theme.colorScheme.onPrimaryContainer.withAlpha(
                            210,
                          ),
                          fontWeight: FontWeight.w900,
                        );

                        Widget buildQuantityField() => TextFormField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          textAlign: TextAlign.center,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            _focusNode.unfocus();
                            widget.onSubmitted?.call();
                          },
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9,\.]'),
                            ),
                            ...widget.inputFormatters,
                          ],
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            hintText: widget.allowEmptyQuantity ? '0' : null,
                            hintStyle: qtyStyle?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withAlpha(90),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 10,
                            ),
                          ),
                          style: qtyStyle,
                          validator: (value) {
                            if (widget.allowEmptyQuantity &&
                                (value ?? '').trim().isEmpty) {
                              return null;
                            }
                            final customError = widget.validator?.call(value);
                            if (customError != null) {
                              widget.onInvalid?.call();
                              return customError;
                            }
                            final quantity = _readQuantity(value ?? '');
                            if (quantity <= 0) {
                              widget.onInvalid?.call();
                              return '';
                            }
                            final max = widget.maximum;
                            if (max != null && quantity > max) {
                              widget.onInvalid?.call();
                              return '';
                            }
                            return null;
                          },
                        );

                        if (unit.isEmpty || constraints.maxWidth < 64.0) {
                          return buildQuantityField();
                        }

                        final textScaler = MediaQuery.textScalerOf(context);
                        final textDirection = Directionality.of(context);
                        final sample = value.text.trim().isEmpty
                            ? '0'
                            : value.text.trim();
                        final qtyPainter = TextPainter(
                          text: TextSpan(text: sample, style: qtyStyle),
                          maxLines: 1,
                          textDirection: textDirection,
                          textScaler: textScaler,
                        )..layout();
                        final unitPainter = TextPainter(
                          text: TextSpan(text: unit, style: unitStyle),
                          maxLines: 1,
                          textDirection: textDirection,
                          textScaler: textScaler,
                        )..layout();

                        const gap = 5.0;
                        final maxAvailable = constraints.maxWidth;
                        final maxUnitWidth = (maxAvailable * 0.42).clamp(
                          24.0,
                          maxAvailable,
                        );
                        final effectiveUnitWidth = unitPainter.width.clamp(
                          0.0,
                          maxUnitWidth,
                        );
                        final maxQtyWidth =
                            (maxAvailable - effectiveUnitWidth - gap).clamp(
                              28.0,
                              maxAvailable,
                            );
                        final desiredQtyWidth = (qtyPainter.width + 12.0).clamp(
                          28.0,
                          maxQtyWidth,
                        );

                        return Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: desiredQtyWidth,
                                child: buildQuantityField(),
                              ),
                              const SizedBox(width: gap),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: maxUnitWidth,
                                ),
                                child: Text(
                                  unit,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: unitStyle,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _TerminalCompactQuantityButton(
            icon: Icons.add_rounded,
            tooltip: 'Artir',
            isPrimary: true,
            onPressed: () => _changeBy(context, widget.step),
          ),
        ],
      ),
    );
  }

  Future<void> _changeBy(BuildContext context, double delta) async {
    final current = _readQuantity(widget.controller.text);
    var next = current + delta;
    if (next < 0) {
      next = 0;
    }
    final max = widget.maximum;
    if (max != null && next > max) {
      next = max;
    }

    final reachesMinimum =
        delta < 0 && next <= 0 && widget.onMinimumReached != null;
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

    widget.controller.text = _formatCompactQuantity(next);
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
    if (reachesMinimum) {
      widget.onMinimumReached?.call();
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
    final theme = Theme.of(context);
    final buttonStyle = IconButton.styleFrom(
      foregroundColor: isPrimary
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurface,
      backgroundColor: isPrimary
          ? theme.colorScheme.primary
          : theme.colorScheme.surface,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isPrimary
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
    );

    if (isPrimary) {
      return IconButton.filled(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        tooltip: tooltip,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        padding: EdgeInsets.zero,
        style: buttonStyle,
      );
    }

    return IconButton.outlined(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      padding: EdgeInsets.zero,
      style: buttonStyle,
    );
  }
}

class TerminalQuantityStepper extends StatefulWidget {
  const TerminalQuantityStepper({
    super.key,
    required this.controller,
    this.label = 'Miktar*',
    this.step = 1,
    this.minimum = 0,
    this.maximum = terminalCreateMaximumQuantity,
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
  State<TerminalQuantityStepper> createState() =>
      _TerminalQuantityStepperState();
}

class _TerminalQuantityStepperState extends State<TerminalQuantityStepper> {
  final GlobalKey<FormFieldState<String>> _fieldKey =
      GlobalKey<FormFieldState<String>>();
  final ValueNotifier<String?> _errorNotifier = ValueNotifier<String?>(null);
  Timer? _ensureVisibleTimer;

  @override
  void didUpdateWidget(covariant TerminalQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maximum == widget.maximum &&
        oldWidget.minimum == widget.minimum &&
        oldWidget.controller == widget.controller) {
      return;
    }

    if (_errorNotifier.value != null ||
        _fieldKey.currentState?.hasError == true) {
      _setErrorText(_resolveError(widget.controller.text));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _fieldKey.currentState?.hasError == true) {
          _fieldKey.currentState?.validate();
        }
      });
    }
  }

  @override
  void dispose() {
    _ensureVisibleTimer?.cancel();
    _errorNotifier.dispose();
    super.dispose();
  }

  void _setErrorText(String? error) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final latest = _resolveError(widget.controller.text);
        if (_errorNotifier.value != latest) {
          _errorNotifier.value = latest;
        }
      });
      return;
    }
    if (_errorNotifier.value != error) {
      _errorNotifier.value = error;
    }
  }

  String? _resolveError(String? value) {
    final customError = widget.validator?.call(value);
    if (customError != null) {
      return customError;
    }
    final max = widget.maximum;
    final quantity = _readQuantity(value ?? '');
    if (max != null && quantity > max) {
      return 'En fazla ${_formatQuantity(max)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonSize = widget.dense ? 42.0 : 44.0;
    final iconSize = widget.dense ? 19.0 : 20.0;
    final gap = widget.dense ? 4.0 : 6.0;
    final verticalPadding = widget.dense ? 7.0 : 9.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconButton.filledTonal(
              onPressed: widget.enabled
                  ? () => _changeBy(context, -widget.step)
                  : null,
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
                    key: _fieldKey,
                    controller: widget.controller,
                    enabled: widget.enabled,
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
                      ...widget.inputFormatters,
                    ],
                    decoration: InputDecoration(
                      labelText: widget.label,
                      isDense: true,
                      errorStyle: const TextStyle(height: 0.01, fontSize: 0),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: verticalPadding,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    validator: (value) {
                      final error = _resolveError(value);
                      _setErrorText(error);
                      if (error != null) {
                        _TerminalAccordionItemScope.maybeOf(
                          fieldContext,
                        )?.onValidationInvalid();
                      }
                      return error == null ? null : '';
                    },
                    onTap: () => _keepQuantityFieldVisible(fieldContext),
                    onChanged: (value) {
                      _keepQuantityFieldVisible(fieldContext);
                      if (_errorNotifier.value != null) {
                        _setErrorText(_resolveError(value));
                      }
                      widget.onChanged?.call(value);
                    },
                    onFieldSubmitted: (_) {
                      if (widget.onSubmitted != null) {
                        widget.onSubmitted!();
                        return;
                      }
                      _TerminalAccordionItemScope.maybeOf(
                        fieldContext,
                      )?.onQuantitySubmitted();
                    },
                  );
                },
              ),
            ),
            SizedBox(width: gap),
            IconButton.filled(
              onPressed: widget.enabled
                  ? () => _changeBy(context, widget.step)
                  : null,
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
        ),
        ValueListenableBuilder<String?>(
          valueListenable: _errorNotifier,
          builder: (context, errorText, _) {
            if (errorText == null || errorText.trim().isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.error_outline_rounded,
                    size: 13,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      errorText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        height: 1.1,
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
    _ensureVisibleTimer?.cancel();
    _ensureVisibleTimer = Timer(
      const Duration(milliseconds: 320),
      ensureVisible,
    );
  }

  Future<void> _changeBy(BuildContext context, double delta) async {
    final current = _readQuantity(widget.controller.text);
    var next = current + delta;
    if (next < widget.minimum) {
      next = widget.minimum;
    }
    final max = widget.maximum;
    if (max != null && next > max) {
      next = max;
    }
    final reachesMinimum =
        delta < 0 && next <= widget.minimum && widget.onMinimumReached != null;
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
    widget.controller.text = _formatQuantity(next);
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
    if (_errorNotifier.value != null) {
      _setErrorText(_resolveError(widget.controller.text));
    }
    widget.onChanged?.call(widget.controller.text);
    if (reachesMinimum) {
      widget.onMinimumReached?.call();
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
    this.breakpoint = 260,
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
    final mediaQuery = MediaQuery.of(context);
    final usableHeight = mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final buttonTheme = Theme.of(context);

    Widget wrapCompactButtons(Widget child) {
      return Theme(
        data: buttonTheme.copyWith(
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.standard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.standard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        child: child,
      );
    }

    if (usableHeight < 430) {
      return wrapCompactButtons(SizedBox(height: 48, child: submit));
    }

    return wrapCompactButtons(
      LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < breakpoint) {
            return SizedBox(height: 48, child: submit);
          }

          return Row(
            children: <Widget>[
              Expanded(child: cancel),
              SizedBox(width: spacing),
              Expanded(flex: submitFlex, child: submit),
            ],
          );
        },
      ),
    );
  }
}

class TerminalCollapsibleHeaderSummary extends StatelessWidget {
  const TerminalCollapsibleHeaderSummary({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel = 'Duzenle',
    this.expanded = false,
    required this.onTap,
    this.trailingActions = const <Widget>[],
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final bool expanded;
  final VoidCallback onTap;
  final List<Widget> trailingActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.fromLTRB(9, 5, 7, 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: expanded
                  ? theme.colorScheme.primary.withAlpha(110)
                  : theme.colorScheme.outlineVariant.withAlpha(110),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showActionText =
                  constraints.maxWidth >= (trailingActions.isEmpty ? 200 : 280);

              return Row(
                children: <Widget>[
                  Icon(icon, size: 17, color: theme.colorScheme.primary),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (hasSubtitle)
                          Text(
                            subtitle!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10.5,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (trailingActions.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 4),
                    ...trailingActions,
                  ],
                  const SizedBox(width: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (showActionText)
                        Text(
                          expanded ? 'Gizle' : actionLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class TerminalCreateInputDock extends StatefulWidget {
  const TerminalCreateInputDock({
    super.key,
    required this.children,
    required this.compactChild,
    this.padding = const EdgeInsets.fromLTRB(10, 4, 10, 4),
  });

  final List<Widget> children;
  final Widget compactChild;
  final EdgeInsetsGeometry padding;

  @override
  State<TerminalCreateInputDock> createState() =>
      _TerminalCreateInputDockState();
}

class _TerminalCreateInputDockState extends State<TerminalCreateInputDock> {
  bool _headerHasFocus = false;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final usableHeight = mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final heightCompact = usableHeight < 430;
    final showHeader = !heightCompact || _headerHasFocus;

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showHeader && widget.children.isNotEmpty)
            Focus(
              skipTraversal: true,
              onFocusChange: (hasFocus) {
                if (_headerHasFocus != hasFocus) {
                  setState(() => _headerHasFocus = hasFocus);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: widget.children,
              ),
            ),
          widget.compactChild,
        ],
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
    this.padding = const EdgeInsets.fromLTRB(10, 2, 4, 2),
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
    final mediaQuery = MediaQuery.of(context);
    final usableHeight = mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final compactHeight =
        usableHeight < 500 || mediaQuery.textScaler.scale(1) > 1.2;

    return Container(
      padding: compactHeight ? const EdgeInsets.fromLTRB(8, 0, 4, 0) : padding,
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
                if (!compactHeight && subtitle != null) ...<Widget>[
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
            icon: const Icon(Icons.close_rounded, size: 19),
            tooltip: 'Kapat',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
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
          minimumSize: const Size(120, 44),
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
      canCopySupportCode = true,
      isLoading = false;

  const TerminalMessageBlock.info({super.key, required this.message})
    : backgroundColor = const Color(0xFFF7F9FD),
      borderColor = const Color(0xFFD8DFEC),
      foregroundColor = const Color(0xFF35506D),
      canCopySupportCode = false,
      isLoading = false;

  const TerminalMessageBlock.loading({super.key, required this.message})
    : backgroundColor = const Color(0xFFF7F9FD),
      borderColor = const Color(0xFFD8DFEC),
      foregroundColor = const Color(0xFF35506D),
      canCopySupportCode = false,
      isLoading = true;

  final String message;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final bool canCopySupportCode;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final supportCode = canCopySupportCode
        ? RegExp(r'Destek kodu:\s*([^\s]+)').firstMatch(message)?.group(1)
        : null;
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
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: _TerminalMessageText(
                    message: message,
                    foregroundColor: foregroundColor,
                  ),
                ),
                if (supportCode != null) ...<Widget>[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Destek kodunu kopyala',
                    child: TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: supportCode),
                        );
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                          const SnackBar(
                            content: Text('Destek kodu kopyalandi.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 17,
                        color: foregroundColor,
                      ),
                      label: Text(
                        'Kopyala',
                        style: TextStyle(color: foregroundColor),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ],
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
    this.icon,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              icon,
              size: 16,
              color: foregroundColor ?? theme.colorScheme.primary,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: foregroundColor ?? theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
