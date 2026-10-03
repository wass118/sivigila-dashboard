import 'package:flutter/material.dart';

import '../models/editorial_index.dart';

/// Tabla del índice editorial (antes/después), con fórmulas explicadas.
class EditorialIndexTable extends StatelessWidget {
  const EditorialIndexTable({super.key, required this.before, this.after});

  final EditorialIndex before;
  final EditorialIndex? after;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    String fmt(double v) => v == v.roundToDouble() || v.abs() >= 10
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _ScoreBox(label: 'Original', score: before.score),
            if (after != null) _ScoreBox(label: 'Resultado', score: after!.score),
          ],
        ),
        const SizedBox(height: 12),
        for (final m in before.metrics)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(m.name, style: theme.textTheme.bodyMedium)),
                    Text('${fmt(m.value)} ${m.unit}', style: muted),
                    if (after?.metric(m.name) case final a?) ...[
                      const Icon(Icons.arrow_right_alt, size: 18),
                      Text(fmt(a.value),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
                Text(m.explanation, style: muted),
              ],
            ),
          ),
        Text(
          'Indicador interno de calidad de redacción calculado con variables '
          'observables. No mide autoría ni estima si un texto fue generado '
          'por IA.',
          style: muted?.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.label, required this.score});
  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          Text('${score.toStringAsFixed(0)}/100',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
