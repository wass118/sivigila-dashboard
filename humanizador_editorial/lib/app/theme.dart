import 'package:flutter/material.dart';

/// Colores semánticos adicionales (diff y severidades), definidos para modo
/// claro y oscuro.
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({
    required this.insertBackground,
    required this.insertForeground,
    required this.deleteBackground,
    required this.deleteForeground,
    required this.high,
    required this.medium,
    required this.low,
    required this.ok,
  });

  final Color insertBackground;
  final Color insertForeground;
  final Color deleteBackground;
  final Color deleteForeground;
  final Color high;
  final Color medium;
  final Color low;
  final Color ok;

  static const light = SemanticColors(
    insertBackground: Color(0xFFDCEFE2),
    insertForeground: Color(0xFF1B5E37),
    deleteBackground: Color(0xFFF8DEDC),
    deleteForeground: Color(0xFF8C1D18),
    high: Color(0xFFB3261E),
    medium: Color(0xFF9A6200),
    low: Color(0xFF52606D),
    ok: Color(0xFF2E7D4F),
  );

  static const dark = SemanticColors(
    insertBackground: Color(0xFF1E3B2A),
    insertForeground: Color(0xFFA8DDB8),
    deleteBackground: Color(0xFF4A2220),
    deleteForeground: Color(0xFFF2B8B5),
    high: Color(0xFFF2B8B5),
    medium: Color(0xFFF0C878),
    low: Color(0xFFB0BEC5),
    ok: Color(0xFF8FD3A8),
  );

  static SemanticColors of(BuildContext context) =>
      Theme.of(context).extension<SemanticColors>() ?? light;

  @override
  SemanticColors copyWith({
    Color? insertBackground,
    Color? insertForeground,
    Color? deleteBackground,
    Color? deleteForeground,
    Color? high,
    Color? medium,
    Color? low,
    Color? ok,
  }) =>
      SemanticColors(
        insertBackground: insertBackground ?? this.insertBackground,
        insertForeground: insertForeground ?? this.insertForeground,
        deleteBackground: deleteBackground ?? this.deleteBackground,
        deleteForeground: deleteForeground ?? this.deleteForeground,
        high: high ?? this.high,
        medium: medium ?? this.medium,
        low: low ?? this.low,
        ok: ok ?? this.ok,
      );

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      insertBackground: Color.lerp(insertBackground, other.insertBackground, t)!,
      insertForeground: Color.lerp(insertForeground, other.insertForeground, t)!,
      deleteBackground: Color.lerp(deleteBackground, other.deleteBackground, t)!,
      deleteForeground: Color.lerp(deleteForeground, other.deleteForeground, t)!,
      high: Color.lerp(high, other.high, t)!,
      medium: Color.lerp(medium, other.medium, t)!,
      low: Color.lerp(low, other.low, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
    );
  }
}

/// Tema Material 3 sobrio: semilla azul pizarra, superficies neutras.
abstract final class AppTheme {
  static const Color seed = Color(0xFF3B5874);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      visualDensity: VisualDensity.standard,
    );
    return base.copyWith(
      extensions: [
        brightness == Brightness.light ? SemanticColors.light : SemanticColors.dark,
      ],
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        filled: true,
        fillColor: scheme.surface,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.55),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
