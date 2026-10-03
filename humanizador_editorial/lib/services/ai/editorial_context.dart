import '../../models/domain_profile.dart';
import '../../models/editorial_option.dart';
import '../../models/intensity.dart';

/// Opciones editoriales ya resueltas a objetos (lo que necesita el prompt).
class EditorialContext {
  const EditorialContext({
    required this.domain,
    required this.audience,
    required this.goal,
    required this.author,
    required this.intensity,
    this.extraStyleRules = const [],
  });

  final DomainProfile domain;
  final EditorialOption audience;
  final EditorialOption goal;
  final EditorialOption author;
  final Intensity intensity;
  final List<String> extraStyleRules;
}
