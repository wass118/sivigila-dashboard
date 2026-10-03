import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/config/ai_provider_settings.dart';
import '../../core/config/app_environment.dart';
import '../../core/utils/app_logger.dart';
import '../../services/templates/template_service.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/labeled_dropdown.dart';
import '../../widgets/section_card.dart';

/// Configuración del proveedor de IA y de privacidad.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AiProviderSettings _draft;
  final _endpoint = TextEditingController();
  final _model = TextEditingController();
  final _maxTokens = TextEditingController();
  final _apiKey = TextEditingController();
  bool _initialized = false;
  bool _draftHasKey = false;
  bool _dirty = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _load(AppScope.of(context).settings.settings);
  }

  void _load(AiProviderSettings s) {
    _draft = s;
    _endpoint.text = s.endpoint;
    _model.text = s.model;
    _maxTokens.text = '${s.maxOutputTokens}';
    _dirty = false;
    _refreshKeyStatus();
  }

  Future<void> _refreshKeyStatus() async {
    final has = await AppScope.of(context)
        .settings
        .hasKeyFor(_draft.providerType);
    if (mounted) setState(() => _draftHasKey = has);
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _model.dispose();
    _maxTokens.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  void _change(AiProviderSettings next) => setState(() {
        _draft = next;
        _dirty = true;
      });

  Future<void> _save() async {
    final tokens = int.tryParse(_maxTokens.text.trim());
    final next = _draft.copyWith(
      endpoint: _endpoint.text.trim(),
      model: _model.text.trim(),
      maxOutputTokens: (tokens ?? _draft.maxOutputTokens).clamp(256, 32000),
    );
    await AppScope.of(context).settings.save(next);
    if (!mounted) return;
    setState(() {
      _draft = next;
      _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Configuración guardada')));
  }

  Future<void> _saveKey() async {
    final value = _apiKey.text.trim();
    if (value.isEmpty) return;
    await AppScope.of(context).settings.saveApiKey(_draft.providerType, value);
    _apiKey.clear();
    await _refreshKeyStatus();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Clave guardada en almacenamiento seguro')));
  }

  Future<void> _deleteKey() async {
    await AppScope.of(context).settings.deleteApiKey(_draft.providerType);
    await _refreshKeyStatus();
  }

  @override
  Widget build(BuildContext context) {
    final type = _draft.providerType;
    final theme = Theme.of(context);
    final settings = AppScope.of(context).settings;
    final keyLabel = type == AiProviderType.backendProxy
        ? 'Token de sesión del backend (opcional)'
        : 'Clave API${type.requiresApiKey ? '' : ' (opcional)'}';
    final showKey = type != AiProviderType.demo &&
        type != AiProviderType.localModel;
    final showConnection = showKey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _dirty ? _save : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (AppEnvironment.mode != HumanizerMode.auto) ...[
                InfoBanner(
                  tone: BannerTone.warning,
                  title: 'Modo fijado por entorno: '
                      '${AppEnvironment.mode.name.toUpperCase()}',
                  message: AppEnvironment.mode == HumanizerMode.demo
                      ? 'La app se inició con HUMANIZER_MODE=demo: se usa el '
                          'servicio simulado aunque se configure un proveedor.'
                      : 'La app se inició con HUMANIZER_MODE=real: se exige '
                          'un proveedor real.',
                ),
                const SizedBox(height: 12),
              ],
              SectionCard(
                title: 'Proveedor de IA',
                icon: Icons.hub_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LabeledDropdown<AiProviderType>(
                      label: 'Proveedor',
                      value: type,
                      items: [
                        for (final t in AiProviderType.values)
                          DropdownItem(t, t.label),
                      ],
                      onChanged: (t) {
                        _change(_draft.copyWith(providerType: t));
                        _refreshKeyStatus();
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(type.description, style: theme.textTheme.bodySmall),
                    if (!type.implemented) ...[
                      const SizedBox(height: 8),
                      const InfoBanner(
                        tone: BannerTone.neutral,
                        title: 'Funcionalidad futura',
                        message: 'El modo local con modelos en el '
                            'dispositivo aún no está disponible. Si lo '
                            'selecciona, las operaciones informarán el error. '
                            'Alternativa actual: "Compatible OpenAI" con '
                            'Ollama o LM Studio en localhost.',
                      ),
                    ],
                    if (showConnection) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _endpoint,
                        onChanged: (_) => setState(() => _dirty = true),
                        decoration: InputDecoration(
                          labelText: 'URL del endpoint',
                          hintText: type.defaultEndpoint.isEmpty
                              ? 'https://su-backend.ejemplo/api/editorial'
                              : type.defaultEndpoint,
                          helperText: 'Vacío = valor por defecto del proveedor.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _model,
                        onChanged: (_) => setState(() => _dirty = true),
                        decoration: const InputDecoration(
                          labelText: 'Modelo',
                          hintText: 'Identificador exacto indicado por su '
                              'proveedor',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showKey) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Credenciales',
                  icon: Icons.key_outlined,
                  subtitle: 'Se guardan cifradas en el almacenamiento seguro '
                      'del sistema y nunca se muestran de nuevo.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                              _draftHasKey
                                  ? Icons.lock_outline
                                  : Icons.lock_open_outlined,
                              size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_draftHasKey
                                ? 'Clave guardada (oculta)'
                                : 'Sin clave guardada'),
                          ),
                          if (_draftHasKey)
                            TextButton.icon(
                              onPressed: _deleteKey,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Eliminar'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _apiKey,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: _draftHasKey
                              ? 'Reemplazar ${keyLabel.toLowerCase()}'
                              : keyLabel,
                          suffixIcon: IconButton(
                            tooltip: 'Guardar clave',
                            icon: const Icon(Icons.check),
                            onPressed: _saveKey,
                          ),
                        ),
                        onSubmitted: (_) => _saveKey(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'En producción, no distribuya claves en la app: use '
                        'el backend intermedio, que custodia la clave del '
                        'proveedor. En la versión Web, el almacenamiento '
                        'del navegador ofrece menos protección.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SectionCard(
                title: 'Parámetros de generación',
                icon: Icons.tune,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Temperatura: ${_draft.temperature.toStringAsFixed(2)}'),
                    Slider(
                      value: _draft.temperature,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      label: _draft.temperature.toStringAsFixed(2),
                      onChanged: (v) =>
                          _change(_draft.copyWith(temperature: v)),
                    ),
                    Text(
                      'Recomendado: 0,2–0,4. Valores bajos dan estabilidad y '
                      'reducen el riesgo de alterar datos; el diagnóstico usa '
                      'como máximo ${AiProviderSettings.analysisTemperatureCap}.'
                      '${_draft.temperature > 0.6 ? ' Valores altos aumentan la variabilidad y no se recomiendan para textos técnicos.' : ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _maxTokens,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() => _dirty = true),
                      decoration: const InputDecoration(
                        labelText: 'Límite de tokens de salida',
                        helperText: 'Entre 256 y 32000. Por defecto 4096.',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Forzar salida JSON nativa'),
                      subtitle: const Text('Solo si el proveedor lo admite '
                          '(OpenAI, Ollama, Gemini).'),
                      value: _draft.jsonMode,
                      onChanged: (v) => _change(_draft.copyWith(jsonMode: v)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Segmentación automática'),
                      subtitle: const Text('Divide documentos largos por '
                          'párrafos u oraciones sin cortar datos protegidos.'),
                      value: _draft.segmentationEnabled,
                      onChanged: (v) =>
                          _change(_draft.copyWith(segmentationEnabled: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Privacidad',
                icon: Icons.privacy_tip_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Guardar historial en este dispositivo'),
                      subtitle: const Text('Nunca se sincroniza ni se envía '
                          'a servidores.'),
                      value: _draft.saveHistory,
                      onChanged: (v) =>
                          _change(_draft.copyWith(saveHistory: v)),
                    ),
                    Text(
                      'El texto solo se envía al proveedor cuando usted pulsa '
                      'Analizar o Humanizar, y la primera vez en cada sesión '
                      'se pide confirmación si el proveedor es remoto. Al '
                      'modelo solo se envían el texto, los parámetros '
                      'editoriales y la lista de elementos protegidos.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Próximamente',
                icon: Icons.upcoming_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Funciones con interfaces preparadas pero no '
                        'activas en esta versión:'),
                    const SizedBox(height: 6),
                    const Text('• Importación de TXT, DOCX y PDF; OCR.'),
                    const Text('• Anonimización previa de datos personales.'),
                    const Text('• Modo local con modelos en el dispositivo.'),
                    Text('• Plantillas documentales: '
                        '${const TemplateService().available().map((t) => t.name).join(', ')}.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Proveedor activo: ${settings.descriptor.label} · Modo de '
                'entorno: ${AppEnvironment.mode.name} · Logs técnicos: '
                '${AppLogger.enabled ? 'activos (sin datos sensibles)' : 'desactivados'}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
