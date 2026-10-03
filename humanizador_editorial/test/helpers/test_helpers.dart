import 'package:humanizador_editorial/core/config/editorial_catalog.dart';
import 'package:humanizador_editorial/models/domain_profile.dart';
import 'package:humanizador_editorial/services/ai/editorial_context.dart';
import 'package:humanizador_editorial/services/ai/llm_client.dart';
import 'package:humanizador_editorial/models/intensity.dart';

/// Cliente LLM programable: devuelve respuestas en orden y registra prompts.
class ScriptedLlmClient implements LlmClient {
  ScriptedLlmClient(this.responses, {this.remote = true});

  final List<Object> responses;
  final bool remote;
  final List<LlmPrompt> prompts = [];
  int _i = 0;

  @override
  String get providerLabel => 'Proveedor simulado';

  @override
  bool get isRemote => remote;

  @override
  Future<String> complete(LlmPrompt prompt) async {
    prompts.add(prompt);
    final r = responses[_i < responses.length ? _i : responses.length - 1];
    _i++;
    if (r is Exception) throw r;
    if (r is Error) throw r;
    return r as String;
  }
}

DomainProfile publicHealthDomain() =>
    EditorialCatalog.domainRegistry().byId('vigilancia_sp_co');

EditorialContext contextFor({
  String domainId = 'vigilancia_sp_co',
  Intensity intensity = Intensity.moderate,
}) =>
    EditorialContext(
      domain: EditorialCatalog.domainRegistry().byId(domainId),
      audience: EditorialCatalog.audienceCatalog().byId('tecnica'),
      goal: EditorialCatalog.goalCatalog().byId('claridad'),
      author: EditorialCatalog.authorCatalog().byId('epidemiologo'),
      intensity: intensity,
    );
