import 'editorial_option.dart';

/// Perfil de dominio: contexto de prompt, vocabulario técnico a preservar,
/// palabras clave para detección automática y avisos de privacidad.
class DomainProfile {
  const DomainProfile({
    required this.id,
    required this.label,
    required this.description,
    required this.promptContext,
    this.keywords = const [],
    this.protectedTerms = const [],
    this.eventNames = const [],
    this.domainRules = const [],
    this.privacyNotice,
  });

  final String id;
  final String label;
  final String description;

  /// Contexto de dominio inyectado en la sección "CONTEXTO DE DOMINIO".
  final String promptContext;

  /// Palabras clave (sin tildes, minúsculas) para detección automática.
  final List<String> keywords;

  /// Términos técnicos que no deben sustituirse por sinónimos coloquiales.
  final List<String> protectedTerms;

  /// Nombres de eventos de interés (p. ej., "dengue grave").
  final List<String> eventNames;

  /// Reglas específicas del dominio (se suman a las restricciones).
  final List<String> domainRules;

  /// Aviso de privacidad que la interfaz muestra al usar este dominio.
  final String? privacyNotice;

  EditorialOption toOption() =>
      EditorialOption(id: id, label: label, promptHint: promptContext);
}

/// Registro extensible de dominios. Para agregar un dominio basta con
/// registrar un [DomainProfile] (ver `DomainCatalog`).
class DomainRegistry {
  DomainRegistry(Iterable<DomainProfile> profiles)
      : _profiles = List.of(profiles) {
    if (_profiles.isEmpty) {
      throw ArgumentError('DomainRegistry requiere al menos un perfil.');
    }
  }

  /// Identificador especial para "Detección automática".
  static const String autoId = 'auto';
  static const String generalId = 'general';

  final List<DomainProfile> _profiles;

  List<DomainProfile> get all => List.unmodifiable(_profiles);

  DomainProfile byId(String? id) => _profiles.firstWhere(
        (p) => p.id == id,
        orElse: () => _profiles.firstWhere((p) => p.id == generalId,
            orElse: () => _profiles.first),
      );

  bool contains(String? id) => _profiles.any((p) => p.id == id);

  void register(DomainProfile profile) {
    _profiles.removeWhere((p) => p.id == profile.id);
    _profiles.add(profile);
  }
}
