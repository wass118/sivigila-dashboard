import '../../models/humanization_result.dart';
import '../../models/pipeline_models.dart';
import '../../models/protected_element.dart';
import '../../models/text_analysis.dart';
import 'editorial_context.dart';

/// Describe el proveedor activo para mostrarlo en la interfaz.
class ProviderDescriptor {
  const ProviderDescriptor({
    required this.label,
    required this.isRemote,
    required this.isDemo,
    this.endpointHost = '',
    this.model = '',
  });

  final String label;
  final bool isRemote;
  final bool isDemo;
  final String endpointHost;
  final String model;
}

class AnalysisInput {
  const AnalysisInput({
    required this.text,
    required this.context,
    required this.local,
    this.partial = false,
  });

  final String text;
  final EditorialContext context;
  final LocalAnalysisReport local;

  /// Verdadero si [text] es solo el primer segmento de un documento largo.
  final bool partial;
}

class HumanizationInput {
  const HumanizationInput({
    required this.text,
    required this.context,
    required this.protectedElements,
    this.analysis,
    this.segmentIndex = 0,
    this.segmentCount = 1,
    this.contextBefore = '',
  });

  final String text;
  final EditorialContext context;
  final List<ProtectedElement> protectedElements;
  final TextAnalysis? analysis;
  final int segmentIndex;
  final int segmentCount;
  final String contextBefore;
}

class FragmentInput {
  const FragmentInput({
    required this.fragment,
    required this.context,
    required this.protectedElements,
    this.originalReference,
    this.contextBefore = '',
    this.contextAfter = '',
  });

  /// Párrafo actual (versión humanizada) que se desea regenerar.
  final String fragment;

  /// Párrafo original correspondiente, fuente de verdad de los datos.
  final String? originalReference;
  final EditorialContext context;
  final List<ProtectedElement> protectedElements;
  final String contextBefore;
  final String contextAfter;
}

/// Abstracción principal. Las pantallas y el pipeline dependen solo de esta
/// interfaz; cambiar de proveedor no requiere tocar la interfaz de usuario.
abstract interface class HumanizerService {
  ProviderDescriptor get descriptor;

  /// Fase 1: diagnóstico estructurado.
  Future<TextAnalysis> analyze(AnalysisInput input);

  /// Fase 3: reescritura (o solo recomendaciones, según la intensidad).
  Future<HumanizationResult> humanize(HumanizationInput input);

  /// Regeneración contextual de un párrafo.
  Future<HumanizationResult> rewriteFragment(FragmentInput input);
}
