import 'package:flutter/material.dart';

import '../../models/audit_report.dart';
import '../../models/fidelity_warning.dart';
import '../../widgets/editorial_index_table.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chips.dart';

/// Auditoría de fidelidad: estado, alertas con valor original/encontrado e
/// índice editorial antes/después.
class AuditView extends StatelessWidget {
  const AuditView({super.key, required this.report});
  final AuditReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Estado de la auditoría',
          icon: Icons.fact_check_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuditStatusChip(status: report.status),
              const SizedBox(height: 8),
              Text(report.status.explanation),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text('Entidades verificadas: ${report.checkedEntities}',
                      style: muted),
                  Text('Alta: ${report.count(WarningSeverity.high)}',
                      style: muted),
                  Text('Media: ${report.count(WarningSeverity.medium)}',
                      style: muted),
                  Text('Informativa: ${report.count(WarningSeverity.low)}',
                      style: muted),
                ],
              ),
              for (final n in report.notes) ...[
                const SizedBox(height: 6),
                Text(n, style: muted),
              ],
              const SizedBox(height: 8),
              Text(AuditReport.disclaimer,
                  style: muted?.copyWith(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Alertas de fidelidad',
          icon: Icons.rule,
          child: report.warnings.isEmpty
              ? const Text('No se detectaron diferencias en los elementos '
                  'verificados.')
              : Column(
                  children: [
                    for (final w in report.warnings) _WarningTile(warning: w),
                  ],
                ),
        ),
        if (report.indexBefore != null) ...[
          const SizedBox(height: 12),
          SectionCard(
            title: 'Índice editorial',
            icon: Icons.analytics_outlined,
            child: EditorialIndexTable(
                before: report.indexBefore!, after: report.indexAfter),
          ),
        ],
      ],
    );
  }
}

class _WarningTile extends StatelessWidget {
  const _WarningTile({required this.warning});
  final FidelityWarning warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SeverityBadge(severity: warning.severity),
              const SizedBox(width: 8),
              Expanded(
                child: Text(warning.category,
                    style: theme.textTheme.labelLarge),
              ),
              Text(
                  warning.origin == WarningOrigin.model
                      ? 'Reportado por el modelo'
                      : 'Auditoría local',
                  style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(warning.message),
          if (warning.originalValue != null || warning.foundValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 16,
                children: [
                  if (warning.originalValue != null)
                    SelectableText('Original: ${warning.originalValue}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontFamily: 'monospace')),
                  SelectableText(
                      'Encontrado: ${warning.foundValue ?? '(ausente)'}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontFamily: 'monospace')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
