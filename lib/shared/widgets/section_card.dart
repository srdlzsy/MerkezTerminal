import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.dense = false,
    this.framed = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool dense;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;

        final padding = framed
            ? EdgeInsets.all(dense ? 6 : (isCompact ? 8 : 10))
            : EdgeInsets.zero;

        return Container(
          width: double.infinity,
          padding: padding,
          decoration: framed
              ? BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withAlpha(100),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: isCompact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (dense
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.titleMedium)
                        ?.copyWith(height: 1.08, fontWeight: FontWeight.w800),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: isCompact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.16,
                    color: theme.colorScheme.onSurface.withAlpha(168),
                  ),
                ),
              ],
              SizedBox(height: dense ? 4 : (isCompact ? 6 : 8)),
              child,
            ],
          ),
        );
      },
    );
  }
}
