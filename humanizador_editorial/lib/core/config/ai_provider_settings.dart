/// Proveedores de IA soportados mediante adaptadores independientes.
enum AiProviderType {
  demo(
    label: 'Demostración local (sin IA)',
    description: 'Reglas locales deterministas. No envía datos a ningún '
        'servicio. Útil para probar la interfaz.',
    defaultEndpoint: '',
    requiresApiKey: false,
    implemented: true,
  ),
  openAiCompatible(
    label: 'Compatible OpenAI (OpenAI, Ollama, LM Studio, vLLM)',
    description: 'Endpoint /v1/chat/completions. Para Ollama use '
        'http://localhost:11434/v1/chat/completions sin clave.',
    defaultEndpoint: 'https://api.openai.com/v1/chat/completions',
    requiresApiKey: false,
    implemented: true,
  ),
  anthropic(
    label: 'Anthropic (Messages API)',
    description: 'Endpoint /v1/messages de Anthropic.',
    defaultEndpoint: 'https://api.anthropic.com/v1/messages',
    requiresApiKey: true,
    implemented: true,
  ),
  gemini(
    label: 'Google Gemini',
    description: 'Endpoint generateContent. {model} se sustituye por el '
        'modelo configurado.',
    defaultEndpoint: 'https://generativelanguage.googleapis.com/v1beta/'
        'models/{model}:generateContent',
    requiresApiKey: true,
    implemented: true,
  ),
  backendProxy(
    label: 'Backend intermedio (recomendado en producción)',
    description: 'Su propio servidor guarda la clave del proveedor. Ver '
        'docs/backend_contract.md.',
    defaultEndpoint: '',
    requiresApiKey: false,
    implemented: true,
  ),
  localModel(
    label: 'Modo local (futura funcionalidad)',
    description: 'Modelos ejecutados en el dispositivo. Abstracción '
        'preparada; no disponible en esta versión.',
    defaultEndpoint: '',
    requiresApiKey: false,
    implemented: false,
  );

  const AiProviderType({
    required this.label,
    required this.description,
    required this.defaultEndpoint,
    required this.requiresApiKey,
    required this.implemented,
  });

  final String label;
  final String description;
  final String defaultEndpoint;
  final bool requiresApiKey;
  final bool implemented;

  static AiProviderType fromName(String? name) => AiProviderType.values
      .firstWhere((t) => t.name == name, orElse: () => AiProviderType.demo);
}

/// Configuración no secreta del proveedor. La clave API se guarda aparte en
/// almacenamiento seguro y nunca forma parte de este objeto.
class AiProviderSettings {
  const AiProviderSettings({
    this.providerType = AiProviderType.demo,
    this.endpoint = '',
    this.model = '',
    this.temperature = defaultTemperature,
    this.maxOutputTokens = defaultMaxOutputTokens,
    this.jsonMode = false,
    this.segmentationEnabled = true,
    this.saveHistory = true,
  });

  /// Temperatura base para reescritura. Se usa 0.3 porque en textos técnicos
  /// prima la estabilidad: valores bajos reducen la variación y el riesgo de
  /// alterar datos, y 0.3 conserva variedad léxica suficiente para mejorar
  /// la naturalidad. El análisis y las recomendaciones usan como máximo
  /// [analysisTemperatureCap].
  static const double defaultTemperature = 0.3;

  /// Tope de temperatura para tareas de diagnóstico (no creativas).
  static const double analysisTemperatureCap = 0.2;

  /// Tokens de salida: el JSON incluye el texto completo reescrito más el
  /// análisis; 4096 cubre un segmento de [AppLimits.maxCharsPerRequest].
  static const int defaultMaxOutputTokens = 4096;

  final AiProviderType providerType;
  final String endpoint;
  final String model;
  final double temperature;
  final int maxOutputTokens;

  /// Solicita salida JSON nativa cuando el proveedor lo admite.
  final bool jsonMode;
  final bool segmentationEnabled;
  final bool saveHistory;

  String get effectiveEndpoint =>
      endpoint.trim().isEmpty ? providerType.defaultEndpoint : endpoint.trim();

  /// Un proveedor es remoto si el texto sale del dispositivo hacia un host
  /// distinto de localhost.
  bool get isRemote {
    if (providerType == AiProviderType.demo ||
        providerType == AiProviderType.localModel) {
      return false;
    }
    final host = Uri.tryParse(effectiveEndpoint)?.host ?? '';
    return !(host == 'localhost' || host == '127.0.0.1' || host == '::1');
  }

  String get endpointHost => Uri.tryParse(effectiveEndpoint)?.host ?? '';

  AiProviderSettings copyWith({
    AiProviderType? providerType,
    String? endpoint,
    String? model,
    double? temperature,
    int? maxOutputTokens,
    bool? jsonMode,
    bool? segmentationEnabled,
    bool? saveHistory,
  }) =>
      AiProviderSettings(
        providerType: providerType ?? this.providerType,
        endpoint: endpoint ?? this.endpoint,
        model: model ?? this.model,
        temperature: temperature ?? this.temperature,
        maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
        jsonMode: jsonMode ?? this.jsonMode,
        segmentationEnabled: segmentationEnabled ?? this.segmentationEnabled,
        saveHistory: saveHistory ?? this.saveHistory,
      );

  Map<String, dynamic> toJson() => {
        'providerType': providerType.name,
        'endpoint': endpoint,
        'model': model,
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
        'jsonMode': jsonMode,
        'segmentationEnabled': segmentationEnabled,
        'saveHistory': saveHistory,
      };

  factory AiProviderSettings.fromJson(Map<String, dynamic> json) {
    double temp = (json['temperature'] as num?)?.toDouble() ??
        defaultTemperature;
    temp = temp.clamp(0.0, 1.0);
    int tokens = (json['maxOutputTokens'] as num?)?.toInt() ??
        defaultMaxOutputTokens;
    tokens = tokens.clamp(256, 32000);
    return AiProviderSettings(
      providerType: AiProviderType.fromName(json['providerType'] as String?),
      endpoint: json['endpoint'] as String? ?? '',
      model: json['model'] as String? ?? '',
      temperature: temp,
      maxOutputTokens: tokens,
      jsonMode: json['jsonMode'] as bool? ?? false,
      segmentationEnabled: json['segmentationEnabled'] as bool? ?? true,
      saveHistory: json['saveHistory'] as bool? ?? true,
    );
  }
}
