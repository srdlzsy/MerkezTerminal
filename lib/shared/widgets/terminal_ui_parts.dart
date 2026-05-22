import 'package:flutter/material.dart';

class TerminalListHeaderCard extends StatelessWidget {
  const TerminalListHeaderCard({
    super.key,
    required this.title,
    required this.filters,
    this.subtitle,
    this.infoChips = const <Widget>[],
    this.actions = const <Widget>[],
    this.footer,
  });

  final String title;
  final String? subtitle;
  final List<Widget> infoChips;
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
        final spacing = isCompact ? 8.0 : 10.0;
        final buttonHeight = isCompact ? 44.0 : 48.0;
        final buttonHorizontalPadding = isCompact ? 8.0 : 12.0;

        return Container(
          padding: EdgeInsets.all(isCompact ? 10 : 12),
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
                    vertical: isCompact ? 9 : 12,
                  ),
                  iconSize: isCompact ? 18 : 20,
                  tapTargetSize: MaterialTapTargetSize.padded,
                  visualDensity: VisualDensity.standard,
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
                    vertical: isCompact ? 9 : 12,
                  ),
                  iconSize: isCompact ? 18 : 20,
                  tapTargetSize: MaterialTapTargetSize.padded,
                  visualDensity: VisualDensity.standard,
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
                      height: 1.2,
                      color: theme.colorScheme.onSurface.withAlpha(168),
                    ),
                  ),
                ],
                if (infoChips.isNotEmpty ||
                    filters.isNotEmpty ||
                    actions.isNotEmpty ||
                    footer != null)
                  SizedBox(height: spacing),
                if (infoChips.isNotEmpty)
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: infoChips,
                  ),
                if (infoChips.isNotEmpty && filters.isNotEmpty)
                  SizedBox(height: spacing),
                if (filters.isNotEmpty)
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: filters,
                  ),
                if ((infoChips.isNotEmpty || filters.isNotEmpty) &&
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
        if (!constraints.hasBoundedWidth) {
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          );
        }

        if (constraints.maxWidth < 320 && children.length > 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var index = 0; index < children.length; index += 1)
                Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : spacing),
                  child: SizedBox(
                    width: double.infinity,
                    child: children[index],
                  ),
                ),
            ],
          );
        }

        final rowSizes = _balancedRowSizes(children.length);
        var childOffset = 0;
        final rows = <Widget>[];

        for (var rowIndex = 0; rowIndex < rowSizes.length; rowIndex += 1) {
          final rowSize = rowSizes[rowIndex];
          final widthSlots = rowSize == 1 ? 3 : rowSize;
          final itemWidth =
              (constraints.maxWidth - (spacing * (widthSlots - 1))) /
              widthSlots;
          final rowChildren = <Widget>[];

          for (var index = 0; index < rowSize; index += 1) {
            if (index > 0) {
              rowChildren.add(SizedBox(width: spacing));
            }

            rowChildren.add(
              SizedBox(width: itemWidth, child: children[childOffset + index]),
            );
          }

          rows.add(
            Padding(
              padding: EdgeInsets.only(top: rowIndex == 0 ? 0 : spacing),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: rowChildren,
              ),
            ),
          );
          childOffset += rowSize;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        );
      },
    );
  }

  List<int> _balancedRowSizes(int count) {
    final rows = <int>[];
    var remaining = count;

    while (remaining > 0) {
      if (remaining == 4) {
        rows
          ..add(2)
          ..add(2);
        break;
      }

      final rowSize = remaining >= 3 ? 3 : remaining;
      rows.add(rowSize);
      remaining -= rowSize;
    }

    return rows;
  }
}

class TerminalResponsiveLookupRow extends StatelessWidget {
  const TerminalResponsiveLookupRow({
    super.key,
    required this.field,
    required this.action,
    this.trailingAction,
    this.breakpoint = 430,
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
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
    this.padding = const EdgeInsets.fromLTRB(20, 16, 12, 12),
    this.elevated = false,
  });

  final String title;
  final String? subtitle;
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
        crossAxisAlignment: subtitle == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
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
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 26),
            tooltip: 'Kapat',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 38, height: 38),
          ),
        ],
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
      width: 142,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(142, 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          tapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.calendar_month_rounded, size: 19),
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
                fontSize: 15,
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
      padding: const EdgeInsets.all(12),
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
