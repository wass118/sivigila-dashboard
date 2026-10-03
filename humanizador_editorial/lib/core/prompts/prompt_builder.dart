import '../../models/pipeline_models.dart';
import '../../models/protected_element.dart';
import '../../models/text_analysis.dart';
import '../../services/ai/editorial_context.dart';
import '../../services/ai/llm_client.dart';
import '../config/ai_provider_settings.dart';
import '../config/app_limits.dart';
import 'audit_rules.dart';
import 'fidelity_rules.dart';
import 'output_format.dart';
import 'style_rules.dart';
import 'system_prompt.dart';

/// Ensambla prompts con cuatro secciones fijas: CONTEXTO DE DOMINIO,
/// RESTRICCIONES, ESTILO y FORMATO DE SALIDA, seguidas del texto delimitado.
///
/// Solo se envía lo necesario: texto, parámetros editoriales y elementos
/// protegidos. Nunca rutas, configuración interna, claves ni logs.
class PromptBuilder {
  const PromptBuilder({
    required this.baseTemperature,
    required this.maxOutputTokens,
  });

  final double baseTemperature;
  final int maxOutputTokens;

  static const String textStart = '<<<TEXTO_ORIGINAL>>>';
  static const String textEnd = '<<<FIN_TEXTO_ORIGINAL>>>';

  double get _analysisTemperature =>
      baseTemperature < AiProviderSettings.analysisTemperatureCap
          ? baseTemperature
          : AiProviderSettings.analysisTemperatureCap;

  LlmPrompt analysis(EditorialContext ctx, String text,
      {LocalAnalysisReport? local, bool partial = false}) {
    final b = StringBuffer()
      ..writeln('TAREA: diagnostica el texto sin reescribirlo.')
      ..writeln()
      ..write(_domainSection(ctx))
      ..writeln('## RESTRICCIONES')
      ..writeln('- No reescribas el texto ni inventes información.')
      ..writeln('- Cita fragmentos literales breves del original como '
          'evidencia de cada problema.')
      ..writeln('- Señala posibles problemas técnicos sin corregirlos.')
      ..writeln()
      ..writeln('## ESTILO')
      ..writeln('- Descripciones concretas y breves en español.')
      ..writeln()
      ..writeln('## ASPECTOS A EVALUAR')
      ..writeln(AuditRules.analysisChecklist.map((e) => '- $e').join('\n'))
      ..writeln();
    if (local != null && local.issues.isNotEmpty) {
      b
        ..writeln('## HALLAZGOS AUTOMÁTICOS PREVIOS (verifícalos, no los '
            'repitas si no aplican)')
        ..writeln(local.issues
            .take(12)
            .map((i) => '- [${i.category}] ${i.description}')
            .join('\n'))
        ..writeln();
    }
    if (partial) {
      b
        ..writeln('Nota: el texto es el primer segmento de un documento más '
            'largo.')
        ..writeln();
    }
    b
      ..writeln('## FORMATO DE SALIDA')
      ..writeln(OutputFormats.analysisSchema)
      ..writeln(OutputFormats.jsonOnly)
      ..writeln()
      ..write(_textBlock(text));
    return LlmPrompt(
      system: SystemPrompts.analystRole,
      user: b.toString(),
      temperature: _analysisTemperature,
      maxTokens: maxOutputTokens,
    );
  }

  LlmPrompt humanization(
    EditorialContext ctx,
    String text, {
    required List<ProtectedElement> protectedElements,
    TextAnalysis? analysis,
    int segmentIndex = 0,
    int segmentCount = 1,
    String contextBefore = '',
  }) {
    final rewrite = ctx.intensity.producesRewrite;
    final b = StringBuffer()
      ..writeln(rewrite
          ? 'TAREA: edita el texto para mejorar su calidad editorial '
              'conservando exactamente su significado y sus datos.'
          : 'TAREA: analiza el texto y entrega recomendaciones editoriales '
              'SIN generar una nueva versión.')
      ..writeln()
      ..write(_domainSection(ctx))
      ..write(_constraintsSection(ctx, protectedElements))
      ..write(_styleSection(ctx));
    if (analysis != null && analysis.problems.isNotEmpty) {
      b
        ..writeln('## DIAGNÓSTICO PREVIO (prioriza estos problemas)')
        ..writeln(analysis.problems
            .take(15)
            .map((p) => '- [${p.category}] ${p.description}')
            .join('\n'))
        ..writeln();
    }
    if (segmentCount > 1) {
      b
        ..writeln('## SEGMENTACIÓN')
        ..writeln('Este es el segmento ${segmentIndex + 1} de $segmentCount '
            'de un documento. Edita solo el segmento; no agregues '
            'introducciones ni cierres.');
      if (contextBefore.isNotEmpty) {
        b
          ..writeln('Contexto previo (SOLO LECTURA, no lo incluyas en la '
              'respuesta):')
          ..writeln('"""$contextBefore"""');
      }
      b.writeln();
    }
    b
      ..writeln('## FORMATO DE SALIDA')
      ..writeln(OutputFormats.humanizationSchema)
      ..writeln(rewrite
          ? '"rewrittenText" debe contener el texto completo editado.'
          : '"rewrittenText" debe ser null.')
      ..writeln('"improvements" explica en frases breves los principales '
          'cambios realizados (sección "Qué mejoró").')
      ..writeln(OutputFormats.jsonOnly)
      ..writeln()
      ..write(_textBlock(text));
    return LlmPrompt(
      system: SystemPrompts.editorRole,
      user: b.toString(),
      temperature: rewrite ? baseTemperature : _analysisTemperature,
      maxTokens: maxOutputTokens,
    );
  }

  LlmPrompt fragment(
    EditorialContext ctx, {
    required String fragment,
    String? originalReference,
    String contextBefore = '',
    String contextAfter = '',
    required List<ProtectedElement> protectedElements,
  }) {
    final b = StringBuffer()
      ..writeln('TAREA: propone una nueva redacción SOLO para el párrafo '
          'indicado, con la misma información.')
      ..writeln()
      ..write(_domainSection(ctx))
      ..write(_constraintsSection(ctx, protectedElements))
      ..write(_styleSection(ctx));
    if (originalReference != null && originalReference.isNotEmpty) {
      b
        ..writeln('## PÁRRAFO ORIGINAL (fuente de verdad de los datos)')
        ..writeln('"""$originalReference"""')
        ..writeln();
    }
    if (contextBefore.isNotEmpty || contextAfter.isNotEmpty) {
      b
        ..writeln('## CONTEXTO (SOLO LECTURA)')
        ..writeln('Anterior: """$contextBefore"""')
        ..writeln('Posterior: """$contextAfter"""')
        ..writeln();
    }
    b
      ..writeln('## FORMATO DE SALIDA')
      ..writeln(OutputFormats.fragmentSchema)
      ..writeln(OutputFormats.jsonOnly)
      ..writeln()
      ..write(_textBlock(fragment));
    return LlmPrompt(
      system: SystemPrompts.editorRole,
      user: b.toString(),
      temperature: baseTemperature,
      maxTokens: maxOutputTokens,
    );
  }

  /// Segundo intento controlado cuando el JSON no es válido. No reenvía el
  /// texto completo de la respuesta anterior para no duplicar costos más de
  /// lo necesario: se envía la tarea original con una advertencia explícita.
  LlmPrompt repair(LlmPrompt original, String problem) => LlmPrompt(
        system: original.system,
        user: '${original.user}\n\n## CORRECCIÓN\nTu respuesta anterior no '
            'fue válida ($problem). Responde de nuevo SOLO con un objeto '
            'JSON válido que cumpla exactamente el formato indicado.',
        temperature: original.temperature < 0.2 ? original.temperature : 0.2,
        maxTokens: original.maxTokens,
        expectJson: original.expectJson,
      );

  // ---------------------------------------------------------------------

  String _domainSection(EditorialContext ctx) {
    final b = StringBuffer()
      ..writeln('## CONTEXTO DE DOMINIO')
      ..writeln('Dominio: ${ctx.domain.label}. ${ctx.domain.promptContext}')
      ..writeln('Audiencia: ${ctx.audience.promptHint}')
      ..writeln(ctx.goal.promptHint);
    if (ctx.author.promptHint.isNotEmpty) {
      b.writeln('Perfil de autor: ${ctx.author.promptHint} Adapta la voz sin '
          'perder el dominio técnico.');
    }
    b.writeln();
    return b.toString();
  }

  String _constraintsSection(
      EditorialContext ctx, List<ProtectedElement> protectedElements) {
    final b = StringBuffer()..writeln('## RESTRICCIONES');
    for (final r in [...FidelityRules.core, ...ctx.domain.domainRules]) {
      b.writeln('- $r');
    }
    for (final r in AuditRules.selfAudit) {
      b.writeln('- $r');
    }
    if (ctx.domain.protectedTerms.isNotEmpty) {
      b.writeln('- Terminología del dominio que debe conservarse cuando '
          'aparezca: ${ctx.domain.protectedTerms.take(40).join(', ')}.');
    }
    final critical = <String>{};
    final lexical = <String>{};
    for (final p in protectedElements) {
      if (p.type.critical) {
        critical.add('${p.value} (${p.type.label})');
      } else if (p.type != ProtectedType.technicalTerm) {
        lexical.add(p.value);
      }
    }
    if (critical.isNotEmpty) {
      b.writeln('- ELEMENTOS PROTEGIDOS (copiar literalmente):');
      for (final c in critical.take(AppLimits.maxProtectedInPrompt)) {
        b.writeln('  • $c');
      }
    }
    if (lexical.isNotEmpty) {
      b.writeln('- Nombres, siglas y términos a conservar: '
          '${lexical.take(AppLimits.maxProtectedInPrompt).join('; ')}.');
    }
    b
      ..writeln('- Intensidad (${ctx.intensity.label}): '
          '${ctx.intensity.instruction}')
      ..writeln();
    return b.toString();
  }

  String _styleSection(EditorialContext ctx) {
    final b = StringBuffer()..writeln('## ESTILO');
    for (final r in [
      ...StyleRules.naturalProfessional,
      ...StyleRules.antiArtificialHumanization,
      ...ctx.extraStyleRules,
    ]) {
      b.writeln('- $r');
    }
    b.writeln();
    return b.toString();
  }

  String _textBlock(String text) => '$textStart\n$text\n$textEnd\n';
}
