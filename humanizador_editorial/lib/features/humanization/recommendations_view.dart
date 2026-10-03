import 'package:flutter/material.dart';

import '../../models/recommendation.dart';
import '../../widgets/empty_state.dart';

/// Módulo "Recomendaciones de redacción": por qué una frase puede mejorar y
/// qué tipo de problema presenta. Filtrable por categoría.
class RecommendationsView extends StatefulWidget {
  const RecommendationsView({super.key, required this.items});
  final List<Recommendation> items;

  @override
  State<RecommendationsView> createState() => _RecommendationsViewState();
}

class _RecommendationsViewState extends State<RecommendationsView> {
  RecommendationCategory? _filter;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const EmptyState(
        icon: Icons.lightbulb_outline,
        title: 'Sin recomendaciones',
        message: 'No se generaron recomendaciones para este texto.',
      );
    }
    final counts = <RecommendationCategory, int>{};
    for (final r in widget.items) {
      counts[r.category] = (counts[r.category] ?? 0) + 1;
    }
    final visible = _filter == null
        ? widget.items
        : widget.items.where((r) => r.category == _filter).toList();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: Text('Todas (${widget.items.length})'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            for (final c in RecommendationCategory.values)
              if (counts[c] != null)
                FilterChip(
                  label: Text('${c.label} (${counts[c]})'),
                  selected: _filter == c,
                  onSelected: (_) => setState(() => _filter = c),
                ),
          ],
        ),
        const SizedBox(height: 12),
        for (final r in visible)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.category.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(r.problem, style: theme.textTheme.bodyMedium),
                  if (r.excerpt != null && r.excerpt!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('«${r.excerpt}»',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic)),
                    ),
                  ],
                  if (r.suggestion.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Sugerencia: ${r.suggestion}',
                        style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
