import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/config/app_limits.dart';
import '../../../core/utils/text_utils.dart';
import '../../../widgets/info_banner.dart';
import '../../../widgets/section_card.dart';
import '../editor_controller.dart';
import 'options_panel.dart';

/// Columna de entrada: aviso de proveedor/privacidad, texto original,
/// configuración y acciones principales.
class InputPanel extends StatelessWidget {
  const InputPanel({super.key, required this.onResultReady});

  /// Se invoca cuando hay un análisis o resultado nuevo (en móvil, cambia a
  /// la vista de resultados).
  final VoidCallback onResultReady;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final editor = scope.editor;
    return ListenableBuilder(
      listenable: Listenable.merge([editor, scope.settings]),
      builder: (context, _) {
        final descriptor = scope.settings.descriptor;
        final domain = editor.effectiveDomain;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProviderNotice(
                      label: descriptor.label,
                      host: descriptor.endpointHost,
                      isRemote: descriptor.isRemote,
                      isDemo: descriptor.isDemo),
                  if (domain.privacyNotice != null) ...[
                    const SizedBox(height: 8),
                    InfoBanner(
                      tone: BannerTone.warning,
                      title: 'Privacidad · ${domain.label}',
                      message: domain.privacyNotice!,
                    ),
                  ],
                  const SizedBox(height: 12),
                  const _TextInputCard(),
                  const SizedBox(height: 12),
                  const OptionsPanel(),
                ],
              ),
            ),
            // Barra de acción fija: la acción principal siempre visible.
            Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (editor.failure != null) ...[
                      InfoBanner(
                        tone: BannerTone.error,
                        title: editor.failure!.title,
                        message: editor.failure!.userMessage,
                        onClose: editor.dismissFailure,
                      ),
                      const SizedBox(height: 8),
                    ],
                    _ActionsRow(onResultReady: onResultReady),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProviderNotice extends StatelessWidget {
  const _ProviderNotice({
    required this.label,
    required this.host,
    required this.isRemote,
    required this.isDemo,
  });

  final String label;
  final String host;
  final bool isRemote;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    if (isDemo) {
      return const InfoBanner(
        tone: BannerTone.neutral,
        icon: Icons.science_outlined,
        title: 'Modo demostración',
        message: 'Los resultados se generan con reglas locales y se marcan '
            'como demostración. El texto no sale del dispositivo. Configure '
            'un proveedor de IA en Ajustes para resultados reales.',
      );
    }
    if (isRemote) {
      return InfoBanner(
        tone: BannerTone.info,
        icon: Icons.cloud_upload_outlined,
        title: 'Proveedor remoto: $label',
        message: 'Al pulsar Analizar o Humanizar, el texto se enviará a '
            '$host. No se envía nada antes de esa acción.',
      );
    }
    return InfoBanner(
      tone: BannerTone.neutral,
      icon: Icons.computer_outlined,
      title: 'Proveedor local: $label',
      message: 'El texto se procesa en $host (este equipo).',
    );
  }
}

class _TextInputCard extends StatelessWidget {
  const _TextInputCard();

  @override
  Widget build(BuildContext context) {
    final editor = AppScope.of(context).editor;
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Texto original',
      icon: Icons.article_outlined,
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Más acciones',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'demo':
                editor.loadDemo();
              case 'restore':
                editor.restoreOriginal();
              case 'clear':
                editor.clearText();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'demo',
                child: ListTile(
                    leading: Icon(Icons.science_outlined),
                    title: Text('Cargar ejemplo (demostración)'),
                    dense: true)),
            PopupMenuItem(
                value: 'restore',
                enabled: editor.originalSnapshot != null,
                child: const ListTile(
                    leading: Icon(Icons.restore),
                    title: Text('Restaurar original'),
                    dense: true)),
            const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                    leading: Icon(Icons.delete_sweep_outlined),
                    title: Text('Limpiar'),
                    dense: true)),
          ],
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: editor.textController,
            minLines: 10,
            maxLines: 22,
            enabled: !editor.isBusy,
            keyboardType: TextInputType.multiline,
            style: theme.textTheme.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'Pegue o escriba aquí el texto que desea revisar…',
              alignLabelWithHint: true,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: editor.textController,
            builder: (context, value, _) {
              final chars = value.text.length;
              final words = TextUtils.countWords(value.text);
              final over = chars > AppLimits.maxDocumentChars;
              final segmented = chars > AppLimits.maxCharsPerRequest;
              final style = theme.textTheme.bodySmall?.copyWith(
                  color: over
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant);
              return Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text('$chars caracteres', style: style),
                  Text('$words palabras', style: style),
                  Text('Límite: ${AppLimits.maxDocumentChars} caracteres',
                      style: style),
                  if (segmented && !over)
                    Text('Se procesará por segmentos', style: style),
                  if (editor.analysisIsStale)
                    Text('El texto cambió desde el último análisis',
                        style: style?.copyWith(
                            color: theme.colorScheme.tertiary)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.onResultReady});
  final VoidCallback onResultReady;

  Future<bool> _confirmRemote(BuildContext context) async {
    final scope = AppScope.of(context);
    final editor = scope.editor;
    if (!editor.needsRemoteConsent) return true;
    final d = scope.settings.descriptor;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cloud_upload_outlined),
        title: const Text('Envío a proveedor remoto'),
        content: Text(
            'El texto se enviará a ${d.label} (${d.endpointHost}) para su '
            'procesamiento. Verifique que no contiene datos personales '
            'identificables o que el entorno está autorizado para '
            'procesarlos.\n\nEsta confirmación se solicita una vez por '
            'sesión.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enviar')),
        ],
      ),
    );
    if (ok == true) editor.grantRemoteConsent();
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final editor = AppScope.of(context).editor;
    final producesRewrite =
        editor.options.effectiveIntensity.producesRewrite;
    final busy = editor.busy;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (editor.isBusy)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              Text(switch (busy) {
                EditorBusy.analyzing => 'Analizando…',
                EditorBusy.humanizing => 'Procesando…',
                EditorBusy.regenerating => 'Regenerando párrafo…',
                EditorBusy.idle => '',
              }),
            ],
          ),
        OutlinedButton.icon(
          onPressed: editor.isBusy
              ? null
              : () async {
                  if (!await _confirmRemote(context)) return;
                  if (await editor.analyze()) onResultReady();
                },
          icon: const Icon(Icons.manage_search),
          label: const Text('Analizar'),
        ),
        FilledButton.icon(
          onPressed: editor.isBusy
              ? null
              : () async {
                  if (!await _confirmRemote(context)) return;
                  if (await editor.humanize()) onResultReady();
                },
          icon: Icon(producesRewrite ? Icons.auto_fix_high : Icons.checklist),
          label: Text(producesRewrite ? 'Humanizar' : 'Generar recomendaciones'),
        ),
      ],
    );
  }
}
