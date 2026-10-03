import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_scope.dart';
import '../../models/editorial_document.dart';
import '../../widgets/clipboard_helper.dart';
import '../../widgets/empty_state.dart';

/// Historial local (últimos documentos procesados). Sin almacenamiento
/// remoto.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.onOpenInEditor});

  final VoidCallback onOpenInEditor;

  Future<bool> _confirm(BuildContext context, String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar')),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final history = scope.history;
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          ListenableBuilder(
            listenable: history,
            builder: (context, _) => IconButton(
              tooltip: 'Eliminar todo el historial',
              onPressed: history.items.isEmpty
                  ? null
                  : () async {
                      if (await _confirm(context, 'Eliminar historial',
                          'Se borrarán todos los documentos guardados en este '
                              'dispositivo.')) {
                        await history.clear();
                      }
                    },
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: history,
        builder: (context, _) {
          if (history.items.isEmpty) {
            return EmptyState(
              icon: Icons.history,
              title: 'Historial vacío',
              message: scope.settings.settings.saveHistory
                  ? 'Los documentos procesados se guardarán aquí, solo en '
                      'este dispositivo.'
                  : 'El guardado del historial está desactivado en Ajustes.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: history.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final doc = history.items[i];
              final domain = scope.services.domains.byId(doc.domainId).label;
              final goal = scope.services.goals.byId(doc.goalId).label;
              return ListTile(
                title: Text(doc.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${fmt.format(doc.createdAt)} · $domain · $goal'
                  '${doc.auditStatus != null ? ' · ${doc.auditStatus}' : ''}'
                  '${doc.isDemo ? ' · demostración' : ''}',
                  maxLines: 2,
                ),
                onTap: () => _openDetail(context, doc),
                trailing: IconButton(
                  tooltip: 'Eliminar registro',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await _confirm(context, 'Eliminar registro',
                        '¿Eliminar "${doc.title}" del historial?')) {
                      await history.delete(doc.id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, EditorialDocument doc) {
    final editor = AppScope.of(context).editor;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DefaultTabController(
        length: 2,
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(doc.title,
                    style: Theme.of(sheetContext).textTheme.titleMedium),
              ),
              const TabBar(tabs: [Tab(text: 'Original'), Tab(text: 'Generado')]),
              Expanded(
                child: TabBarView(children: [
                  _TextPane(text: doc.originalText),
                  _TextPane(
                      text: doc.generatedText ??
                          'Sin versión generada (solo recomendaciones).'),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    if (doc.generatedText != null)
                      OutlinedButton.icon(
                        onPressed: () => copyToClipboard(
                            sheetContext, doc.generatedText!,
                            confirmation: 'Texto generado copiado'),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar generado'),
                      ),
                    FilledButton.icon(
                      onPressed: () {
                        editor.loadFromHistory(doc);
                        Navigator.pop(sheetContext);
                        onOpenInEditor();
                      },
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Abrir original en el editor'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextPane extends StatelessWidget {
  const _TextPane({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(text),
      );
}
