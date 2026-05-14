import 'package:flutter/material.dart';

class OperationFlowCard extends StatelessWidget {
  const OperationFlowCard({
    super.key,
    required this.title,
    required this.steps,
    this.note,
  });

  final String title;
  final List<String> steps;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(84),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF231C17),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(
              steps.length,
              (index) => _StepPill(
                number: index + 1,
                label: steps[index],
              ),
            ),
          ),
          if (note != null && note!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF5B4738),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.number,
    required this.label,
  });

  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(84),
        ),
      ),
      child: Text(
        '$number. $label',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2A211B),
        ),
      ),
    );
  }
}
