import 'package:flutter/material.dart';

import '../comparison/results_panel.dart';
import 'widgets/input_panel.dart';

/// Pantalla principal. Escritorio (≥ 1100 px): dos columnas, entrada a la
/// izquierda y resultado a la derecha. Móvil/tableta: vistas apiladas con
/// selector Entrada/Resultado.
class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  static const double wideBreakpoint = 1100;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

enum _NarrowView { input, result }

class _EditorPageState extends State<EditorPage> {
  _NarrowView _view = _NarrowView.input;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Humanizador Editorial Técnico')),
      body: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= EditorPage.wideBreakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: InputPanel(onResultReady: () {})),
              const VerticalDivider(width: 1),
              const Expanded(flex: 6, child: ResultsPanel()),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SegmentedButton<_NarrowView>(
                segments: const [
                  ButtonSegment(
                      value: _NarrowView.input,
                      icon: Icon(Icons.edit_note),
                      label: Text('Entrada')),
                  ButtonSegment(
                      value: _NarrowView.result,
                      icon: Icon(Icons.fact_check_outlined),
                      label: Text('Resultado')),
                ],
                selected: {_view},
                onSelectionChanged: (s) => setState(() => _view = s.first),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _view.index,
                children: [
                  InputPanel(
                      onResultReady: () =>
                          setState(() => _view = _NarrowView.result)),
                  ResultsPanel(
                      onShowInput: () =>
                          setState(() => _view = _NarrowView.input)),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
