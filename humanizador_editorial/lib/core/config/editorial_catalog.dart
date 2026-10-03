import '../../models/document_template.dart';
import '../../models/domain_profile.dart';
import '../../models/editorial_option.dart';
import '../../models/editorial_preset.dart';
import '../../models/editorial_request.dart';
import '../../models/intensity.dart';
import '../prompts/domain_prompts.dart';
import '../prompts/editorial_prompts.dart';

/// Catálogo inicial. Para extender la aplicación (nuevo dominio, audiencia,
/// objetivo o perfil de autor) basta con añadir entradas aquí o llamar a
/// `register` en el registro correspondiente; las pantallas se generan a
/// partir de estos datos.
abstract final class EditorialCatalog {
  static const List<String> publicHealthTerms = [
    'SIVIGILA', 'INS', 'MINSALUD', 'ASIS', 'SITREP', 'UPGD', 'UI', 'EAPB',
    'IEC', 'BAI', 'BAC', 'IPS', 'ESE', 'IRAG', 'IRA', 'EDA', 'ETV', 'ETA',
    'evento de interés en salud pública', 'ficha de notificación',
    'notificación inmediata', 'notificación semanal', 'incidencia',
    'prevalencia', 'mortalidad', 'letalidad', 'tasa', 'razón', 'proporción',
    'semana epidemiológica', 'periodo epidemiológico', 'conglomerado',
    'brote', 'investigación epidemiológica de campo', 'búsqueda activa',
    'caso sospechoso', 'caso probable', 'caso confirmado', 'caso descartado',
    'canal endémico', 'unidad de análisis', 'oportunidad de notificación',
  ];

  static const List<String> publicHealthEvents = [
    'dengue', 'dengue grave', 'malaria', 'tuberculosis', 'sarampión',
    'rubéola', 'tosferina', 'varicela', 'leptospirosis', 'chikunguña',
    'zika', 'sífilis gestacional', 'sífilis congénita', 'mortalidad materna',
    'mortalidad perinatal', 'bajo peso al nacer', 'desnutrición aguda',
    'enfermedad diarreica aguda', 'infección respiratoria aguda',
    'intoxicación', 'hepatitis A', 'VIH', 'rabia',
  ];

  static final List<DomainProfile> domains = [
    const DomainProfile(
      id: 'general',
      label: 'General',
      description: 'Textos sin un dominio especializado.',
      promptContext: DomainPrompts.general,
    ),
    const DomainProfile(
      id: 'academico',
      label: 'Académico / científico',
      description: 'Artículos, tesis, protocolos de investigación.',
      promptContext: DomainPrompts.academic,
      keywords: ['metodologia', 'resultados', 'hipotesis', 'estudio',
          'muestra', 'et al', 'objetivo', 'discusion', 'variable',
          'significancia', 'investigacion', 'revision sistematica'],
    ),
    const DomainProfile(
      id: 'clinico',
      label: 'Clínico / salud',
      description: 'Historias, conceptos y guías clínicas.',
      promptContext: DomainPrompts.clinical,
      keywords: ['paciente', 'diagnostico', 'tratamiento', 'dosis', 'mg',
          'clinico', 'sintomas', 'hospitalizacion', 'examen', 'laboratorio',
          'farmaco', 'evolucion'],
      privacyNotice: DomainPrompts.publicHealthPrivacyNotice,
    ),
    const DomainProfile(
      id: 'vigilancia_sp_co',
      label: 'Vigilancia en Salud Pública – Colombia',
      description: 'SIVIGILA, INS, SITREP, informes epidemiológicos.',
      promptContext: DomainPrompts.publicHealthColombia,
      keywords: ['sivigila', 'semana epidemiologica', 'periodo epidemiologico',
          'notificacion', 'notificaron', 'incidencia', 'letalidad', 'upgd',
          'eapb', 'brote', 'conglomerado', 'sitrep', 'evento de interes',
          'iec', 'vigilancia', 'casos', 'tasa', 'ins', 'minsalud', 'asis'],
      protectedTerms: publicHealthTerms,
      eventNames: publicHealthEvents,
      domainRules: DomainPrompts.publicHealthRules,
      privacyNotice: DomainPrompts.publicHealthPrivacyNotice,
    ),
    const DomainProfile(
      id: 'administrativo',
      label: 'Administrativo / institucional',
      description: 'Oficios, actas, circulares, informes de gestión.',
      promptContext: DomainPrompts.administrative,
      keywords: ['oficio', 'radicado', 'circular', 'dependencia', 'secretaria',
          'por medio de la presente', 'acta', 'gestion', 'resolucion',
          'atentamente', 'solicitud'],
    ),
    const DomainProfile(
      id: 'juridico',
      label: 'Jurídico',
      description: 'Conceptos, contratos, actos administrativos.',
      promptContext: DomainPrompts.legal,
      keywords: ['articulo', 'ley', 'decreto', 'sentencia', 'numeral',
          'contrato', 'clausula', 'demandante', 'juzgado', 'corte',
          'jurisprudencia', 'norma'],
    ),
    const DomainProfile(
      id: 'empresarial',
      label: 'Empresarial',
      description: 'Informes de negocio, propuestas, presentaciones.',
      promptContext: DomainPrompts.business,
      keywords: ['clientes', 'ventas', 'ingresos', 'estrategia', 'mercado',
          'kpi', 'rentabilidad', 'presupuesto', 'trimestre', 'meta',
          'negocio', 'proveedor'],
    ),
    const DomainProfile(
      id: 'divulgativo',
      label: 'Divulgativo',
      description: 'Comunicación para público no especializado.',
      promptContext: DomainPrompts.outreach,
      keywords: ['comunidad', 'sabias que', 'recuerda', 'te invitamos',
          'cuidate', 'familia', 'consejos'],
    ),
  ];

  static final List<EditorialOption> audiences = const [
    EditorialOption(id: 'general', label: 'General',
        promptHint: EditorialPrompts.audienceGeneral),
    EditorialOption(id: 'tecnica', label: 'Técnica',
        promptHint: EditorialPrompts.audienceTechnical),
    EditorialOption(id: 'profesional', label: 'Profesional',
        promptHint: EditorialPrompts.audienceProfessional),
    EditorialOption(id: 'directiva', label: 'Directiva',
        promptHint: EditorialPrompts.audienceExecutive),
    EditorialOption(id: 'academica', label: 'Académica',
        promptHint: EditorialPrompts.audienceAcademic),
    EditorialOption(id: 'institucional', label: 'Institucional',
        promptHint: EditorialPrompts.audienceInstitutional),
    EditorialOption(id: 'comunitaria', label: 'Comunitaria',
        promptHint: EditorialPrompts.audienceCommunity),
  ];

  static final List<EditorialOption> goals = const [
    EditorialOption(id: 'naturalidad', label: 'Mejorar naturalidad',
        promptHint: EditorialPrompts.goalNaturalness),
    EditorialOption(id: 'claridad', label: 'Mejorar claridad',
        promptHint: EditorialPrompts.goalClarity),
    EditorialOption(id: 'rigidez', label: 'Reducir rigidez',
        promptHint: EditorialPrompts.goalRigidity),
    EditorialOption(id: 'cohesion', label: 'Mejorar cohesión',
        promptHint: EditorialPrompts.goalCohesion),
    EditorialOption(id: 'tecnico', label: 'Adaptar a lenguaje técnico',
        promptHint: EditorialPrompts.goalTechnical),
    EditorialOption(id: 'ejecutivo', label: 'Adaptar a lenguaje ejecutivo',
        promptHint: EditorialPrompts.goalExecutive),
    EditorialOption(id: 'institucional',
        label: 'Adaptar a lenguaje institucional',
        promptHint: EditorialPrompts.goalInstitutional),
    EditorialOption(id: 'simplificar',
        label: 'Simplificar manteniendo precisión',
        promptHint: EditorialPrompts.goalSimplify),
    EditorialOption(id: EditorialOptions.reviewOnlyGoalId,
        label: 'Revisar técnicamente sin reescribir',
        promptHint: EditorialPrompts.goalTechnicalReview,
        description: 'Solo diagnóstico y recomendaciones.'),
  ];

  static final List<EditorialOption> authorProfiles = const [
    EditorialOption(id: 'ninguno', label: 'Sin perfil específico',
        promptHint: EditorialPrompts.authorNone),
    EditorialOption(id: 'tecnico', label: 'Profesional técnico',
        promptHint: EditorialPrompts.authorTechnical),
    EditorialOption(id: 'epidemiologo', label: 'Epidemiólogo/a',
        promptHint: EditorialPrompts.authorEpidemiologist),
    EditorialOption(id: 'medico', label: 'Médico/a',
        promptHint: EditorialPrompts.authorPhysician),
    EditorialOption(id: 'abogado', label: 'Abogado/a',
        promptHint: EditorialPrompts.authorLawyer),
    EditorialOption(id: 'investigador', label: 'Investigador/a',
        promptHint: EditorialPrompts.authorResearcher),
    EditorialOption(id: 'funcionario', label: 'Funcionario/a público/a',
        promptHint: EditorialPrompts.authorPublicServant),
    EditorialOption(id: 'docente', label: 'Docente',
        promptHint: EditorialPrompts.authorTeacher),
    EditorialOption(id: 'directivo', label: 'Directivo/a',
        promptHint: EditorialPrompts.authorExecutive),
    EditorialOption(id: 'comunicador', label: 'Comunicador/a',
        promptHint: EditorialPrompts.authorCommunicator),
  ];

  /// Presets demostrativos de fábrica.
  static const List<EditorialPreset> builtInPresets = [
    EditorialPreset(
      id: 'preset_informe_epi',
      name: 'Informe epidemiológico',
      builtIn: true,
      options: EditorialOptions(
        domainId: 'vigilancia_sp_co',
        audienceId: 'tecnica',
        goalId: 'claridad',
        intensity: Intensity.moderate,
        authorProfileId: 'epidemiologo',
        extraStyleRules: [
          'Separar dato observado, interpretación y recomendación.',
          'Mantener tasas con su denominador y periodo de referencia.',
        ],
      ),
    ),
    EditorialPreset(
      id: 'preset_sitrep',
      name: 'SITREP',
      builtIn: true,
      options: EditorialOptions(
        domainId: 'vigilancia_sp_co',
        audienceId: 'directiva',
        goalId: 'ejecutivo',
        intensity: Intensity.conservative,
        authorProfileId: 'epidemiologo',
        extraStyleRules: [
          'Oraciones breves y directas.',
          'Orden: situación actual, acciones realizadas, pendientes.',
        ],
      ),
    ),
    EditorialPreset(
      id: 'preset_academico',
      name: 'Documento académico',
      builtIn: true,
      options: EditorialOptions(
        domainId: 'academico',
        audienceId: 'academica',
        goalId: 'cohesion',
        intensity: Intensity.moderate,
        authorProfileId: 'investigador',
        extraStyleRules: ['Conservar la cautela epistémica de cada afirmación.'],
      ),
    ),
    EditorialPreset(
      id: 'preset_ejecutivo',
      name: 'Informe ejecutivo',
      builtIn: true,
      options: EditorialOptions(
        domainId: 'empresarial',
        audienceId: 'directiva',
        goalId: 'ejecutivo',
        intensity: Intensity.moderate,
        authorProfileId: 'directivo',
        extraStyleRules: ['Lo esencial y accionable primero.'],
      ),
    ),
    EditorialPreset(
      id: 'preset_institucional',
      name: 'Comunicación institucional',
      builtIn: true,
      options: EditorialOptions(
        domainId: 'administrativo',
        audienceId: 'institucional',
        goalId: 'institucional',
        intensity: Intensity.moderate,
        authorProfileId: 'funcionario',
        extraStyleRules: ['Evitar fórmulas burocráticas vacías.'],
      ),
    ),
  ];

  /// Plantillas documentales previstas para v1.2 (no aplicadas aún).
  static const List<DocumentTemplate> futureTemplates = [
    DocumentTemplate(id: 'sitrep', name: 'SITREP', tone: 'Directivo',
        sections: ['Situación', 'Acciones', 'Pendientes', 'Fuentes']),
    DocumentTemplate(id: 'informe_epi', name: 'Informe epidemiológico',
        tone: 'Técnico',
        sections: ['Introducción', 'Métodos', 'Resultados', 'Conclusiones',
            'Recomendaciones']),
    DocumentTemplate(id: 'concepto', name: 'Concepto técnico',
        tone: 'Técnico', sections: ['Antecedentes', 'Análisis', 'Concepto']),
    DocumentTemplate(id: 'oficio', name: 'Oficio', tone: 'Institucional',
        sections: ['Encabezado', 'Asunto', 'Cuerpo', 'Cierre']),
    DocumentTemplate(id: 'asis', name: 'ASIS', tone: 'Técnico',
        sections: ['Contexto', 'Morbilidad', 'Mortalidad', 'Priorización']),
    DocumentTemplate(id: 'resumen_ejecutivo', name: 'Resumen ejecutivo',
        tone: 'Directivo', sections: ['Mensajes clave', 'Datos', 'Decisiones']),
    DocumentTemplate(id: 'iec', name: 'Informe de investigación de campo',
        tone: 'Técnico',
        sections: ['Antecedentes', 'Metodología', 'Hallazgos', 'Medidas']),
    DocumentTemplate(id: 'recomendacion', name: 'Recomendación técnica',
        tone: 'Técnico', sections: ['Problema', 'Evidencia', 'Recomendación']),
  ];

  static DomainRegistry domainRegistry() => DomainRegistry(domains);
  static OptionCatalog audienceCatalog() => OptionCatalog(audiences);
  static OptionCatalog goalCatalog() => OptionCatalog(goals);
  static OptionCatalog authorCatalog() => OptionCatalog(authorProfiles);
}
