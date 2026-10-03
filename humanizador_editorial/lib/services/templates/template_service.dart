import '../../core/config/editorial_catalog.dart';
import '../../models/document_template.dart';

/// PLANTILLAS DOCUMENTALES — FUTURA FUNCIONALIDAD (v1.2).
///
/// Expone el catálogo previsto. Aún no modifica prompts ni estructura del
/// resultado; la interfaz lo presenta como "próximamente".
class TemplateService {
  const TemplateService();

  List<DocumentTemplate> available() => EditorialCatalog.futureTemplates;

  bool get isEnabled => false;
}
