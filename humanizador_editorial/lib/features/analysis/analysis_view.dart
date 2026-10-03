import 'package:flutter/material.dart';

import '../../models/pipeline_models.dart';
import '../../models/protected_element.dart';
import '../../widgets/editorial_index_table.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chips.dart';

/// Resumen de las fases 1 (análisis) y 2 (protección de contenido).
class AnalysisView extends StatelessWidget {
  const AnalysisView({super.key, required this.outcome});
  final AnalysisOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final a = outcome.analysis;
    final theme = Theme.of(context);
    final grouped = <ProtectedType, List<String>>{};
    for (final p in outcome.protectedElements) {
      final list = grouped.putIfAbsent(p.type, () => []);
      if (!list.contains(p.value)) list.add(p.value);
    }

    Widget field(String label, String value) => value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: 130,
                    child: Text(label,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant))),
                Expanded(child: Text(value)),
              ],
            ),
          );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Diagnóstico',
          icon: Icons.manage_search,
          actions: [if (a.isDemo) const DemoBadge()],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              field('Dominio aplicado', outcome.effectiveDomain.label),
              field('Dominio detectado', a.detectedDomain),
              field('Audiencia', a.detectedAudience),
              field('Tono', a.detectedTone),
              field('Formalidad', a.formality),
              field('Propósito', a.purpose),
              field('Nivel técnico', a.technicalLevel),
              if (outcome.segmentCount > 1)
                field('Segmentos', '${outcome.segmentCount}'),
              for (final o in a.observations)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(o, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Problemas identificados (${a.problems.length})',
          icon: Icons.report_gmailerrorred_outlined,
          child: a.problems.isEmpty
              ? const Text('No se identificaron problemas relevantes.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final p in a.problems)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.category,
                                style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary)),
                            Text(p.description),
                            if (p.excerpt != null && p.excerpt!.isNotEmpty)
                              Text('«${p.excerpt}»',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Contenido protegido (${outcome.protectedElements.length})',
          icon: Icons.shield_outlined,
          subtitle: 'Elementos que deben conservarse exactamente. Detección '
              'automática por reglas: revise si falta alguno.',
          child: grouped.isEmpty
              ? const Text('No se detectaron elementos protegidos.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in grouped.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${entry.key.label}'
                                '${entry.key.critical ? ' · crítico' : ''}',
                                style: theme.textTheme.labelMedium),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final v in entry.value)
                                  Chip(
                                    label: Text(v),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Índice editorial del original',
          icon: Icons.analytics_outlined,
          child: EditorialIndexTable(before: outcome.local.index),
        ),
      ],
    );
  }
}
