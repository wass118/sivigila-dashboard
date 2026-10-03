import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_scope.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/phase_stepper.dart';
import '../analysis/analysis_view.dart';
import '../humanization/humanized_view.dart';
import '../humanization/recommendations_view.dart';
import 'audit_view.dart';
import 'diff_view.dart';

/// Resultado: prioriza versión humanizada y auditoría; recomendaciones y
/// diagnóstico quedan a una pestaña de distancia.
class ResultsPanel extends StatefulWidget {
  const ResultsPanel({super.key, this.onShowInput});

  /// En móvil, vuelve a la vista de entrada (p. ej., tras cargar el ejemplo).
  final VoidCallback? onShowInput;

  @override
  State<ResultsPanel> createState() => _ResultsPanelState();
}

class _ResultsPanelState extends State<ResultsPanel>
    with SingleTickerProviderStateMixin {
  static const tabs = [
    (Icons.auto_fix_high, 'Humanizado'),
    (Icons.difference_outlined, 'Cambios'),
    (Icons.fact_check_outlined, 'Auditoría'),
    (Icons.lightbulb_outline, 'Recomendaciones'),
    (Icons.manage_search, 'Diagnóstico'),
    (Icons.article_outlined, 'Original'),
  ];
  static const int _diagnosisTab = 4;

  late final TabController _tabs =
      TabController(length: tabs.length, vsync: this);
  int _seenRevision = -1;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _syncTab(int revision, bool hasResult) {
    if (revision == _seenRevision) return;
    _seenRevision = revision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tabs.animateTo(hasResult ? 0 : _diagnosisTab);
    });
  }

  @override
  Widget build(BuildContext context) {
    final editor = AppScope.of(context).editor;
    return ListenableBuilder(
      listenable: editor,
      builder: (context, _) {
        final analysis = editor.analysis;
        final current = editor.current;
        if (analysis == null && !editor.isBusy) {
          return EmptyState(
            icon: Icons.edit_document,
            title: 'Sin resultados todavía',
            message: 'Escriba o pegue un texto, elija la configuración y '
                'pulse Analizar o Humanizar. También puede cargar el ejemplo '
                'de demostración desde el menú del texto original.',
            action: OutlinedButton.icon(
              onPressed: () {
                editor.loadDemo();
                widget.onShowInput?.call();
              },
              icon: const Icon(Icons.science_outlined),
              label: const Text('Cargar ejemplo'),
            ),
          );
        }
        _syncTab(editor.revision, current != null);
        final output = current?.output;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: PhaseStepper(phases: editor.phases),
            ),
            if (editor.versions.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _VersionSelector(),
              ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final (icon, label) in tabs)
                  Tab(icon: Icon(icon, size: 18), text: label, height: 56),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  output == null
                      ? const _PendingResult()
                      : HumanizedView(output: output),
                  output == null
                      ? const _PendingResult()
                      : DiffView(diff: output.audit.diff),
                  output == null
                      ? const _PendingResult()
                      : AuditView(report: output.audit),
                  output == null
                      ? const _PendingResult()
                      : RecommendationsView(
                          items: output.result.recommendations),
                  analysis == null
                      ? const Center(child: CircularProgressIndicator())
                      : AnalysisView(outcome: analysis),
                  _OriginalView(
                      text: output?.originalText ??
                          analysis?.analyzedText ??
                          ''),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PendingResult extends StatelessWidget {
  const _PendingResult();

  @override
  Widget build(BuildContext context) {
    final editor = AppScope.of(context).editor;
    if (editor.isBusy) {
      return const Center(child: CircularProgressIndicator());
    }
    return const EmptyState(
      icon: Icons.hourglass_empty,
      title: 'Diagnóstico listo',
      message: 'Revise el diagnóstico y pulse Humanizar (o Generar '
          'recomendaciones) para obtener el resultado y la auditoría.',
    );
  }
}

class _VersionSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final editor = AppScope.of(context).editor;
    final fmt = DateFormat.Hms();
    return Row(
      children: [
        const Icon(Icons.history, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButton<int>(
            isExpanded: true,
            value: editor.currentVersionIndex,
            underline: const SizedBox.shrink(),
            onChanged: editor.isBusy
                ? null
                : (v) {
                    if (v != null) editor.selectVersion(v);
                  },
            items: [
              for (var i = 0; i < editor.versions.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(
                    'Versión ${editor.versions[i].number} · '
                    '${editor.versions[i].label} · '
                    '${fmt.format(editor.versions[i].createdAt)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OriginalView extends StatelessWidget {
  const _OriginalView({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(text,
            style: Theme.of(context).textTheme.bodyLarge),
      );
}
