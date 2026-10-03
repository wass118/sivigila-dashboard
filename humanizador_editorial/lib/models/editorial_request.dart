import 'intensity.dart';

/// Parámetros editoriales elegidos por el usuario.
class EditorialOptions {
  const EditorialOptions({
    this.domainId = 'auto',
    this.audienceId = 'general',
    this.goalId = 'naturalidad',
    this.intensity = Intensity.moderate,
    this.authorProfileId = 'ninguno',
    this.extraStyleRules = const [],
  });

  final String domainId;
  final String audienceId;
  final String goalId;
  final Intensity intensity;
  final String authorProfileId;

  /// Reglas de estilo adicionales (p. ej., provenientes de un preset).
  final List<String> extraStyleRules;

  /// El objetivo "revisar técnicamente sin reescribir" implica no generar
  /// versión nueva, aunque la intensidad elegida sea otra.
  static const String reviewOnlyGoalId = 'revision_tecnica';

  Intensity get effectiveIntensity => goalId == reviewOnlyGoalId
      ? Intensity.recommendationsOnly
      : intensity;

  EditorialOptions copyWith({
    String? domainId,
    String? audienceId,
    String? goalId,
    Intensity? intensity,
    String? authorProfileId,
    List<String>? extraStyleRules,
  }) =>
      EditorialOptions(
        domainId: domainId ?? this.domainId,
        audienceId: audienceId ?? this.audienceId,
        goalId: goalId ?? this.goalId,
        intensity: intensity ?? this.intensity,
        authorProfileId: authorProfileId ?? this.authorProfileId,
        extraStyleRules: extraStyleRules ?? this.extraStyleRules,
      );

  Map<String, dynamic> toJson() => {
        'domainId': domainId,
        'audienceId': audienceId,
        'goalId': goalId,
        'intensity': intensity.name,
        'authorProfileId': authorProfileId,
        'extraStyleRules': extraStyleRules,
      };

  factory EditorialOptions.fromJson(Map<String, dynamic> json) =>
      EditorialOptions(
        domainId: json['domainId'] as String? ?? 'auto',
        audienceId: json['audienceId'] as String? ?? 'general',
        goalId: json['goalId'] as String? ?? 'naturalidad',
        intensity: Intensity.fromName(json['intensity'] as String?),
        authorProfileId: json['authorProfileId'] as String? ?? 'ninguno',
        extraStyleRules: (json['extraStyleRules'] as List?)
                ?.whereType<String>()
                .toList() ??
            const [],
      );
}

/// Petición completa: texto + opciones.
class EditorialRequest {
  const EditorialRequest({required this.text, required this.options});

  final String text;
  final EditorialOptions options;
}
