import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/audit_report.dart';
import '../models/fidelity_warning.dart';

class AuditStatusChip extends StatelessWidget {
  const AuditStatusChip({super.key, required this.status});
  final AuditStatus status;

  @override
  Widget build(BuildContext context) {
    final c = SemanticColors.of(context);
    final (color, icon) = switch (status) {
      AuditStatus.noTechnicalChanges => (c.ok, Icons.verified_outlined),
      AuditStatus.editorialChanges => (c.ok, Icons.edit_note),
      AuditStatus.humanReviewRecommended =>
        (c.medium, Icons.visibility_outlined),
      AuditStatus.possibleTechnicalChange => (c.high, Icons.report_outlined),
    };
    return _Pill(color: color, icon: icon, label: status.label);
  }
}

class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.severity});
  final WarningSeverity severity;

  @override
  Widget build(BuildContext context) {
    final c = SemanticColors.of(context);
    final color = switch (severity) {
      WarningSeverity.high => c.high,
      WarningSeverity.medium => c.medium,
      WarningSeverity.low => c.low,
    };
    return _Pill(color: color, label: severity.label, compact: true);
  }
}

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Resultado de reglas locales de demostración, no de un '
            'modelo de IA.',
        child: _Pill(
            color: Theme.of(context).colorScheme.tertiary,
            icon: Icons.science_outlined,
            label: 'Demostración'),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.color,
    required this.label,
    this.icon,
    this.compact = false,
  });

  final Color color;
  final String label;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10, vertical: compact ? 2 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
