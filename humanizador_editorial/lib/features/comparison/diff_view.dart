import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/text_diff.dart';
import '../../widgets/empty_state.dart';

/// Vista tipo diff: borrados tachados en rojo, inserciones en verde.
class DiffView extends StatelessWidget {
  const DiffView({super.key, required this.diff});
  final TextDiffResult diff;

  @override
  Widget build(BuildContext context) {
    if (diff.paragraphs.isEmpty) {
      return const EmptyState(
        icon: Icons.difference_outlined,
        title: 'Sin comparación',
        message: 'No hay versión generada que comparar.',
      );
    }
    final theme = Theme.of(context);
    final c = SemanticColors.of(context);
    final s = diff.stats;
    final base = theme.textTheme.bodyLarge!;

    TextSpan span(DiffSegment seg) => switch (seg.operation) {
          DiffOperation.equal => TextSpan(text: seg.text),
          DiffOperation.insert => TextSpan(
              text: seg.text,
              style: TextStyle(
                  backgroundColor: c.insertBackground,
                  color: c.insertForeground)),
          DiffOperation.delete => TextSpan(
              text: seg.text,
              style: TextStyle(
                  backgroundColor: c.deleteBackground,
                  color: c.deleteForeground,
                  decoration: TextDecoration.lineThrough)),
        };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Stat('+${s.wordsInserted} palabras', c.insertForeground),
            _Stat('−${s.wordsDeleted} palabras', c.deleteForeground),
            _Stat('${s.paragraphsModified} párrafos modificados',
                theme.colorScheme.primary),
            if (s.paragraphsAdded > 0)
              _Stat('${s.paragraphsAdded} añadidos', c.insertForeground),
            if (s.paragraphsRemoved > 0)
              _Stat('${s.paragraphsRemoved} eliminados', c.deleteForeground),
            _Stat('${s.paragraphsUnchanged} sin cambios', c.low),
          ],
        ),
        const SizedBox(height: 8),
        Text('Todos los cambios se muestran; ninguno se oculta ni se aplica '
            'automáticamente.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        for (final p in diff.paragraphs)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            // Borde solo a la izquierda: Flutter no admite radio con bordes
            // no uniformes.
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  width: 3,
                  color: switch (p.change) {
                    ParagraphChange.unchanged => Colors.transparent,
                    ParagraphChange.modified => theme.colorScheme.primary,
                    ParagraphChange.added => c.insertForeground,
                    ParagraphChange.removed => c.deleteForeground,
                  },
                ),
              ),
            ),
            child: SelectableText.rich(
              TextSpan(style: base, children: p.segments.map(span).toList()),
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: color)),
      );
}
