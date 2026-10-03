import 'package:flutter_test/flutter_test.dart';
import 'package:humanizador_editorial/core/config/ai_provider_settings.dart';
import 'package:humanizador_editorial/core/config/editorial_catalog.dart';
import 'package:humanizador_editorial/models/domain_profile.dart';
import 'package:humanizador_editorial/models/editorial_document.dart';
import 'package:humanizador_editorial/models/editorial_preset.dart';
import 'package:humanizador_editorial/models/editorial_request.dart';
import 'package:humanizador_editorial/models/fidelity_warning.dart';
import 'package:humanizador_editorial/models/intensity.dart';
import 'package:humanizador_editorial/models/protected_element.dart';
import 'package:humanizador_editorial/models/recommendation.dart';
import 'package:humanizador_editorial/models/text_analysis.dart';

void main() {
  group('EditorialOptions', () {
    test('el objetivo de revisión técnica fuerza "Solo recomendaciones"', () {
      const o = EditorialOptions(
          goalId: EditorialOptions.reviewOnlyGoalId,
          intensity: Intensity.deep);
      expect(o.effectiveIntensity, Intensity.recommendationsOnly);
      expect(o.effectiveIntensity.producesRewrite, isFalse);
    });

    test('serialización ida y vuelta', () {
      const o = EditorialOptions(
        domainId: 'clinico',
        audienceId: 'directiva',
        goalId: 'claridad',
        intensity: Intensity.conservative,
        authorProfileId: 'medico',
        extraStyleRules: ['Frases breves'],
      );
      final back = EditorialOptions.fromJson(o.toJson());
      expect(back.domainId, 'clinico');
      expect(back.intensity, Intensity.conservative);
      expect(back.extraStyleRules, ['Frases breves']);
    });

    test('JSON incompleto usa valores por defecto', () {
      final o = EditorialOptions.fromJson(const {});
      expect(o.domainId, 'auto');
      expect(o.intensity, Intensity.moderate);
    });
  });

  group('Catálogo y registro de dominios', () {
    test('incluye los dominios iniciales y el perfil de vigilancia', () {
      final r = EditorialCatalog.domainRegistry();
      for (final id in [
        'general', 'academico', 'clinico', 'vigilancia_sp_co',
        'administrativo', 'juridico', 'empresarial', 'divulgativo'
      ]) {
        expect(r.contains(id), isTrue, reason: id);
      }
      expect(r.byId('vigilancia_sp_co').privacyNotice, isNotNull);
      expect(r.byId('vigilancia_sp_co').protectedTerms, contains('SIVIGILA'));
    });

    test('se pueden registrar dominios nuevos sin cambiar la app', () {
      final r = EditorialCatalog.domainRegistry();
      r.register(const DomainProfile(
          id: 'ambiental',
          label: 'Ambiental',
          description: '',
          promptContext: 'Texto ambiental.'));
      expect(r.byId('ambiental').label, 'Ambiental');
      expect(r.byId('inexistente').id, 'general');
    });

    test('hay cinco presets demostrativos', () {
      final names = EditorialCatalog.builtInPresets.map((p) => p.name);
      expect(names, containsAll([
        'Informe epidemiológico', 'SITREP', 'Documento académico',
        'Informe ejecutivo', 'Comunicación institucional'
      ]));
    });

    test('cuatro niveles de intensidad', () {
      expect(Intensity.values.map((i) => i.label), [
        'Conservadora', 'Moderada', 'Profunda', 'Solo recomendaciones'
      ]);
    });
  });

  group('Modelos de resultado', () {
    test('Recommendation normaliza categorías en español', () {
      expect(RecommendationCategory.fromLabel('precision_tecnica'),
          RecommendationCategory.technicalAccuracy);
      expect(RecommendationCategory.fromLabel('Consistencia terminológica'),
          RecommendationCategory.terminology);
      expect(RecommendationCategory.fromLabel('cohesión'),
          RecommendationCategory.cohesion);
      expect(RecommendationCategory.fromLabel('desconocida'),
          RecommendationCategory.clarity);
    });

    test('FidelityWarning acepta severidades en español', () {
      final w = FidelityWarning.fromJson(const {
        'tipo': 'Cifra',
        'original': '51,99',
        'encontrado': '52',
        'mensaje': 'redondeo',
        'severidad': 'alta',
      });
      expect(w.severity, WarningSeverity.high);
      expect(w.origin, WarningOrigin.model);
      expect(w.foundValue, '52');
    });

    test('TextAnalysis admite problemas como cadenas u objetos', () {
      final a = TextAnalysis.fromJson(const {
        'dominioDetectado': 'Vigilancia',
        'problemas': ['frase larga', {'categoria': 'Cohesión', 'descripcion': 'x'}],
        'observaciones': 'una',
      });
      expect(a.problems, hasLength(2));
      expect(a.problems.first.description, 'frase larga');
      expect(a.observations, ['una']);
    });

    test('ProtectedType.fromName reconoce nombres en español', () {
      expect(ProtectedType.fromName('fecha'), ProtectedType.date);
      expect(ProtectedType.fromName('Porcentaje'), ProtectedType.percentage);
      expect(ProtectedType.fromName('percentage'), ProtectedType.percentage);
    });

    test('documento y preset se serializan', () {
      final doc = EditorialDocument(
          id: '1',
          createdAt: DateTime(2026, 9, 1),
          title: 't',
          domainId: 'general',
          goalId: 'claridad',
          intensityName: 'moderate',
          originalText: 'a',
          generatedText: 'b');
      final back = EditorialDocument.fromJson(doc.toJson());
      expect(back.generatedText, 'b');
      expect(back.createdAt, DateTime(2026, 9, 1));

      final p = EditorialCatalog.builtInPresets.first;
      final pb = EditorialPreset.fromJson(p.toJson());
      expect(pb.options.domainId, p.options.domainId);
    });
  });

  group('AiProviderSettings', () {
    test('detecta proveedores remotos y locales', () {
      expect(const AiProviderSettings().isRemote, isFalse);
      expect(
          const AiProviderSettings(
                  providerType: AiProviderType.openAiCompatible,
                  endpoint: 'http://localhost:11434/v1/chat/completions')
              .isRemote,
          isFalse);
      expect(
          const AiProviderSettings(providerType: AiProviderType.anthropic)
              .isRemote,
          isTrue);
    });

    test('fromJson acota valores fuera de rango', () {
      final s = AiProviderSettings.fromJson(const {
        'providerType': 'gemini',
        'temperature': 3.5,
        'maxOutputTokens': 10,
      });
      expect(s.providerType, AiProviderType.gemini);
      expect(s.temperature, 1.0);
      expect(s.maxOutputTokens, 256);
    });

    test('la configuración serializada no contiene claves', () {
      final json = const AiProviderSettings(
              providerType: AiProviderType.anthropic, model: 'm')
          .toJson();
      expect(json.keys.any((k) => k.toLowerCase().contains('key')), isFalse);
    });
  });
}
