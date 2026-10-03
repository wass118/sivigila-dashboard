import 'editorial_request.dart';

/// Configuración frecuente guardada (dominio, audiencia, objetivo,
/// intensidad, perfil de autor y reglas de estilo).
class EditorialPreset {
  const EditorialPreset({
    required this.id,
    required this.name,
    required this.options,
    this.builtIn = false,
  });

  final String id;
  final String name;
  final EditorialOptions options;

  /// Los presets de fábrica no se pueden eliminar.
  final bool builtIn;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'options': options.toJson(),
        'builtIn': builtIn,
      };

  factory EditorialPreset.fromJson(Map<String, dynamic> json) =>
      EditorialPreset(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Preset',
        options: EditorialOptions.fromJson(
            (json['options'] as Map?)?.cast<String, dynamic>() ?? const {}),
        builtIn: json['builtIn'] as bool? ?? false,
      );
}
