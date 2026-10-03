import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/pipeline_models.dart';

/// Resumen visual de las cuatro fases lógicas.
class PhaseStepper extends StatelessWidget {
  const PhaseStepper({super.key, required this.phases});

  final Map<PipelinePhase, PhaseState> phases;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 560;
      final tiles = [
        for (final phase in PipelinePhase.values)
          _PhaseTile(
              index: phase.index + 1,
              phase: phase,
              state: phases[phase] ?? PhaseState.pending),
      ];
      if (narrow) {
        // Móvil: indicadores compactos; el resumen queda en el tooltip.
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final phase in PipelinePhase.values)
              _CompactPhase(
                  index: phase.index + 1,
                  phase: phase,
                  state: phases[phase] ?? PhaseState.pending),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            Expanded(child: tiles[i]),
            if (i < tiles.length - 1) const SizedBox(width: 8),
          ],
        ],
      );
    });
  }
}

class _CompactPhase extends StatelessWidget {
  const _CompactPhase(
      {required this.index, required this.phase, required this.state});

  final int index;
  final PipelinePhase phase;
  final PhaseState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = SemanticColors.of(context);
    final (IconData icon, Color color) = switch (state.status) {
      PhaseStatus.pending => (Icons.radio_button_unchecked, scheme.outline),
      PhaseStatus.running => (Icons.timelapse, scheme.primary),
      PhaseStatus.done => (Icons.check_circle_outline, c.ok),
      PhaseStatus.skipped => (Icons.remove_circle_outline, scheme.outline),
      PhaseStatus.failed => (Icons.error_outline, c.high),
    };
    return Tooltip(
      message: state.summary.isEmpty ? phase.label : state.summary,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text('$index. ${phase.label}',
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _PhaseTile extends StatelessWidget {
  const _PhaseTile(
      {required this.index, required this.phase, required this.state});

  final int index;
  final PipelinePhase phase;
  final PhaseState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = SemanticColors.of(context);
    final scheme = theme.colorScheme;
    final (Widget leading, Color color) = switch (state.status) {
      PhaseStatus.pending => (
          Text('$index', style: theme.textTheme.labelSmall),
          scheme.outline
        ),
      PhaseStatus.running => (
          const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2)),
          scheme.primary
        ),
      PhaseStatus.done => (Icon(Icons.check, size: 16, color: c.ok), c.ok),
      PhaseStatus.skipped => (
          Icon(Icons.remove, size: 16, color: scheme.outline),
          scheme.outline
        ),
      PhaseStatus.failed => (Icon(Icons.close, size: 16, color: c.high), c.high),
    };
    return Semantics(
      label: '${phase.label}: ${state.summary}',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 20, child: Center(child: leading)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phase.label,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (state.summary.isNotEmpty)
                    Text(state.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
