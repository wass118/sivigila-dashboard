import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/fidelity_warning.dart';
import '../../models/pipeline_models.dart';
import '../../services/pipeline/editorial_pipeline.dart';
import '../../widgets/clipboard_helper.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chips.dart';
import '../shared/report_export.dart';

/// Pestaña principal del resultado: texto humanizado por párrafos (con
/// regeneración contextual), "Qué mejoró" y "Qué debes revisar".
class HumanizedView extends StatelessWidget {
  const HumanizedView({super.key, required this.output});
  final PipelineOutput output;

  @override
  Widget build(BuildContext context) {
    final editor = AppScope.of(context).editor;
    final result = output.result;
    final theme = Theme.of(context);
    final text = result.rewrittenText;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AuditStatusChip(status: output.audit.status),
            if (result.isDemo) const DemoBadge(),
            if (output.segmentCount > 1)
              Chip(label: Text('${output.segmentCount} segmentos')),
          ],
        ),
        const SizedBox(height: 12),
        _CopyActions(output: output),
        const SizedBox(height: 12),
        if (text == null)
          const SectionCard(
            title: 'Solo recomendaciones',
            icon: Icons.checklist,
            child: Text('En este modo no se genera una nueva versión. '
                'Consulte la pestaña Recomendaciones y el Diagnóstico.'),
          )
        else
          SectionCard(
            title: 'Texto humanizado',
            icon: Icons.auto_fix_high,
            subtitle: 'Use el menú de cada párrafo para regenerarlo o copiarlo.',
            child: _Paragraphs(text: text, busy: editor.isBusy),
          ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Qué mejoró',
          icon: Icons.trending_up,
          child: result.improvements.isEmpty
              ? Text('El proveedor no describió los cambios. Revise la '
                  'pestaña Cambios.', style: theme.textTheme.bodyMedium)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final i in result.improvements) _Bullet(text: i),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _ReviewSection(output: output),
      ],
    );
  }
}

class _CopyActions extends StatelessWidget {
  const _CopyActions({required this.output});
  final PipelineOutput output;

  @override
  Widget build(BuildContext context) {
    final editor = AppScope.of(context).editor;
    final text = output.result.rewrittenText;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (text != null)
          FilledButton.tonalIcon(
            onPressed: () => copyToClipboard(context, text,
                confirmation: 'Resultado copiado'),
            icon: const Icon(Icons.copy),
            label: const Text('Copiar resultado'),
          ),
        OutlinedButton.icon(
          onPressed: () => copyToClipboard(
              context, ReportExport.recommendations(output.result.recommendations),
              confirmation: 'Recomendaciones copiadas'),
          icon: const Icon(Icons.lightbulb_outline),
          label: const Text('Copiar recomendaciones'),
        ),
        OutlinedButton.icon(
          onPressed: () => copyToClipboard(
              context,
              ReportExport.fullAnalysis(
                  analysis: editor.analysis, output: output),
              confirmation: 'Análisis completo copiado'),
          icon: const Icon(Icons.summarize_outlined),
          label: const Text('Copiar análisis completo'),
        ),
        if (text != null)
          TextButton.icon(
            onPressed: editor.isBusy
                ? null
                : () {
                    editor.acceptResult();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('El resultado es ahora el texto de '
                          'trabajo. "Restaurar original" lo revierte.'),
                    ));
                  },
            icon: const Icon(Icons.done_all),
            label: const Text('Aceptar como texto de trabajo'),
          ),
      ],
    );
  }
}

class _Paragraphs extends StatelessWidget {
  const _Paragraphs({required this.text, required this.busy});
  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final editor = AppScope.of(context).editor;
    final paragraphs = ParagraphSplit.of(text).paragraphs;
    final style = Theme.of(context).textTheme.bodyLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < paragraphs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SelectableText(paragraphs[i], style: style)),
                PopupMenuButton<String>(
                  tooltip: 'Acciones del párrafo ${i + 1}',
                  enabled: !busy,
                  icon: const Icon(Icons.more_horiz, size: 20),
                  onSelected: (value) async {
                    if (value == 'copy') {
                      await copyToClipboard(context, paragraphs[i],
                          confirmation: 'Párrafo copiado');
                    } else if (value == 'regen') {
                      final ok = await editor.regenerateParagraph(i);
                      if (!ok && context.mounted && editor.failure != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(editor.failure!.userMessage)));
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                        value: 'regen',
                        child: ListTile(
                            dense: true,
                            leading: Icon(Icons.refresh),
                            title: Text('Regenerar este párrafo'))),
                    PopupMenuItem(
                        value: 'copy',
                        child: ListTile(
                            dense: true,
                            leading: Icon(Icons.copy),
                            title: Text('Copiar párrafo'))),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.output});
  final PipelineOutput output;

  @override
  Widget build(BuildContext context) {
    final warnings = output.audit.warnings
        .where((w) => w.severity != WarningSeverity.low)
        .toList();
    final technical = output.result.recommendations
        .where((r) => r.category.name == 'technicalAccuracy')
        .toList();
    return SectionCard(
      title: 'Qué debes revisar',
      icon: Icons.rule,
      subtitle: '${output.audit.warnings.length} alertas en total · detalle en '
          'la pestaña Auditoría',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (warnings.isEmpty && technical.isEmpty)
            const Text('La auditoría automática no encontró alertas de '
                'prioridad alta o media. Aun así, lea el texto completo antes '
                'de usarlo: la verificación final es humana.'),
          for (final w in warnings.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SeverityBadge(severity: w.severity),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${w.category}: ${w.message}'
                      '${w.originalValue != null ? ' Original: «${w.originalValue}».' : ''}'
                      '${w.foundValue != null ? ' Encontrado: «${w.foundValue}».' : ''}'
                      '${w.origin == WarningOrigin.model ? ' (reportado por el modelo)' : ''}',
                    ),
                  ),
                ],
              ),
            ),
          if (warnings.length > 8)
            Text('… y ${warnings.length - 8} alertas más en Auditoría.'),
          for (final r in technical.take(4))
            _Bullet(text: 'Precisión técnica: ${r.problem}'),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 7, right: 8),
              child: Icon(Icons.circle, size: 6),
            ),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
