/// Instrucciones para audiencias, objetivos y perfiles de autor.
abstract final class EditorialPrompts {
  // Audiencias
  static const String audienceGeneral =
      'Audiencia general: lenguaje claro, sin jerga innecesaria.';
  static const String audienceTechnical =
      'Audiencia técnica: conserva la terminología especializada y la '
      'densidad informativa.';
  static const String audienceProfessional =
      'Audiencia profesional: registro formal y preciso, directo.';
  static const String audienceExecutive =
      'Audiencia directiva: priorizar lo esencial y lo accionable; oraciones '
      'breves; datos clave visibles.';
  static const String audienceAcademic =
      'Audiencia académica: rigor argumentativo, cautela epistémica y '
      'conectores lógicos explícitos.';
  static const String audienceInstitutional =
      'Audiencia institucional: formal, impersonal cuando corresponda, '
      'trazable.';
  static const String audienceCommunity =
      'Audiencia comunitaria: lenguaje cercano y comprensible, respetuoso; '
      'explica términos técnicos sin eliminarlos.';

  // Objetivos
  static const String goalNaturalness =
      'Objetivo: mejorar la naturalidad de la redacción.';
  static const String goalClarity =
      'Objetivo: mejorar la claridad (orden de ideas, referentes explícitos, '
      'oraciones manejables).';
  static const String goalRigidity =
      'Objetivo: reducir la rigidez (fórmulas burocráticas, pasivas '
      'innecesarias, nominalizaciones).';
  static const String goalCohesion =
      'Objetivo: mejorar la cohesión (progresión temática, conectores con '
      'función lógica, referencias).';
  static const String goalTechnical =
      'Objetivo: adaptar a lenguaje técnico sin agregar contenido.';
  static const String goalExecutive =
      'Objetivo: adaptar a lenguaje ejecutivo: lo esencial primero, frases '
      'breves, sin perder datos.';
  static const String goalInstitutional =
      'Objetivo: adaptar a lenguaje institucional formal.';
  static const String goalSimplify =
      'Objetivo: simplificar manteniendo la precisión. No elimines datos ni '
      'matices de certeza.';
  static const String goalTechnicalReview =
      'Objetivo: revisar técnicamente sin reescribir. Entrega solo '
      'diagnóstico y recomendaciones.';

  // Perfiles de autor
  static const String authorNone = '';
  static const String authorTechnical =
      'Voz de profesional técnico: precisa, sobria, orientada a datos.';
  static const String authorEpidemiologist =
      'Voz de epidemiólogo: distingue dato, interpretación y recomendación; '
      'usa terminología de vigilancia con exactitud.';
  static const String authorPhysician =
      'Voz de médico: clínica, precisa, sin coloquialismos.';
  static const String authorLawyer =
      'Voz de abogado: rigurosa, literal en normas y obligaciones.';
  static const String authorResearcher =
      'Voz de investigador: argumentativa y cautelosa.';
  static const String authorPublicServant =
      'Voz de funcionario público: institucional, clara y trazable.';
  static const String authorTeacher =
      'Voz de docente: explicativa y ordenada.';
  static const String authorExecutive =
      'Voz de directivo: concisa, orientada a decisiones.';
  static const String authorCommunicator =
      'Voz de comunicador: fluida y cercana, sin perder exactitud.';
}
