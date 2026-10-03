import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:humanizador_editorial/core/config/ai_provider_settings.dart';
import 'package:humanizador_editorial/core/config/app_environment.dart';
import 'package:humanizador_editorial/core/config/editorial_catalog.dart';
import 'package:humanizador_editorial/core/errors/humanizer_failure.dart';
import 'package:humanizador_editorial/services/ai/adapters/anthropic_client.dart';
import 'package:humanizador_editorial/services/ai/adapters/gemini_client.dart';
import 'package:humanizador_editorial/services/ai/adapters/local_model_client.dart';
import 'package:humanizador_editorial/services/ai/adapters/openai_compatible_client.dart';
import 'package:humanizador_editorial/services/ai/fake_humanizer_service.dart';
import 'package:humanizador_editorial/services/ai/http_error_mapper.dart';
import 'package:humanizador_editorial/services/ai/humanizer_service_factory.dart';
import 'package:humanizador_editorial/services/ai/llm_client.dart';
import 'package:humanizador_editorial/services/ai/llm_humanizer_service.dart';
import 'package:humanizador_editorial/services/analysis/local_text_analyzer.dart';

const prompt = LlmPrompt(system: 's', user: 'u', temperature: 0.3, maxTokens: 100);

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
    jsonEncode(body), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  group('Adaptadores HTTP', () {
    test('OpenAI compatible: cuerpo, cabeceras y respuesta', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return jsonResponse({
          'choices': [
            {'message': {'role': 'assistant', 'content': '{"ok": true}'}}
          ]
        });
      });
      final c = OpenAiCompatibleClient(
        transport: HttpJsonTransport(client),
        endpoint: 'https://api.example.com/v1/chat/completions',
        model: 'modelo-x',
        apiKey: 'sk-test-123456789',
        jsonMode: true,
        isRemote: true,
      );
      expect(await c.complete(prompt), '{"ok": true}');
      final body = jsonDecode(captured.body) as Map;
      expect(body['model'], 'modelo-x');
      expect(body['messages'], hasLength(2));
      expect(body['response_format'], {'type': 'json_object'});
      expect(captured.headers['Authorization'], 'Bearer sk-test-123456789');
    });

    test('Anthropic: cabeceras y bloques de texto', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return jsonResponse({
          'content': [
            {'type': 'text', 'text': '{"a":'},
            {'type': 'text', 'text': '1}'},
          ]
        });
      });
      final c = AnthropicClient(
          transport: HttpJsonTransport(client),
          endpoint: 'https://api.anthropic.com/v1/messages',
          model: 'm',
          apiKey: 'k');
      expect(await c.complete(prompt), '{"a":1}');
      expect(captured.headers['x-api-key'], 'k');
      expect(captured.headers['anthropic-version'], AnthropicClient.apiVersion);
      expect((jsonDecode(captured.body) as Map)['system'], 's');
    });

    test('Gemini: modelo en la URL y clave en cabecera (no en la URL)',
        () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return jsonResponse({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'hola'}
                ]
              }
            }
          ]
        });
      });
      final c = GeminiClient(
          transport: HttpJsonTransport(client),
          endpointTemplate: 'https://g.example/v1beta/models/{model}:generateContent',
          model: 'gm',
          apiKey: 'AIzaSECRET');
      expect(await c.complete(prompt), 'hola');
      expect(captured.url.toString(), contains('/models/gm:generateContent'));
      expect(captured.url.toString(), isNot(contains('AIzaSECRET')));
      expect(captured.headers['x-goog-api-key'], 'AIzaSECRET');
    });

    test('errores HTTP se traducen a fallos tipados', () async {
      Future<void> expectFailure(int status, Matcher matcher) async {
        final c = OpenAiCompatibleClient(
          transport: HttpJsonTransport(MockClient((_) async =>
              jsonResponse({'error': {'message': 'detalle'}}, status))),
          endpoint: 'https://x.example/v1/chat/completions',
          model: 'm',
          isRemote: true,
        );
        await expectLater(c.complete(prompt), throwsA(matcher));
      }

      await expectFailure(401, isA<AuthenticationFailure>());
      await expectFailure(403, isA<AuthenticationFailure>());
      await expectFailure(429, isA<ProviderFailure>());
      await expectFailure(500, isA<ProviderFailure>());
      await expectFailure(400, isA<ProviderFailure>());
    });

    test('fallo de red → ConnectionFailure', () async {
      final c = OpenAiCompatibleClient(
        transport: HttpJsonTransport(MockClient(
            (_) async => throw http.ClientException('sin red'))),
        endpoint: 'https://x.example/v1/chat/completions',
        model: 'm',
        isRemote: true,
      );
      await expectLater(c.complete(prompt), throwsA(isA<ConnectionFailure>()));
    });

    test('cuerpo HTTP no JSON → InvalidResponseFailure', () async {
      final c = OpenAiCompatibleClient(
        transport: HttpJsonTransport(
            MockClient((_) async => http.Response('<html>', 200))),
        endpoint: 'https://x.example/v1/chat/completions',
        model: 'm',
        isRemote: true,
      );
      await expectLater(
          c.complete(prompt), throwsA(isA<InvalidResponseFailure>()));
    });

    test('modo local: funcionalidad futura declarada', () async {
      await expectLater(const LocalModelClient().complete(prompt),
          throwsA(isA<UnsupportedFeatureFailure>()));
    });
  });

  group('HumanizerServiceFactory', () {
    final analyzer =
        LocalTextAnalyzer(domains: EditorialCatalog.domainRegistry());
    HumanizerServiceFactory factory(HumanizerMode mode) =>
        HumanizerServiceFactory(
            httpClient: MockClient((_) async => http.Response('{}', 200)),
            analyzer: analyzer,
            mode: mode);

    test('modo demo por defecto y forzado por entorno', () {
      expect(factory(HumanizerMode.auto).create(const AiProviderSettings()),
          isA<FakeHumanizerService>());
      expect(
          factory(HumanizerMode.demo).create(const AiProviderSettings(
              providerType: AiProviderType.anthropic, model: 'm'),
              apiKey: 'k'),
          isA<FakeHumanizerService>());
    });

    test('modo real con proveedor demo → configuración incompleta', () {
      expect(() => factory(HumanizerMode.real).create(const AiProviderSettings()),
          throwsA(isA<ConfigurationFailure>()));
    });

    test('validaciones de configuración', () {
      final f = factory(HumanizerMode.auto);
      expect(
          () => f.create(const AiProviderSettings(
              providerType: AiProviderType.openAiCompatible)),
          throwsA(isA<ConfigurationFailure>()),
          reason: 'falta modelo');
      expect(
          () => f.create(const AiProviderSettings(
              providerType: AiProviderType.anthropic, model: 'm')),
          throwsA(isA<ConfigurationFailure>()),
          reason: 'falta clave');
      expect(
          () => f.create(const AiProviderSettings(
              providerType: AiProviderType.openAiCompatible,
              endpoint: 'http://remoto.example/v1/chat/completions',
              model: 'm')),
          throwsA(isA<ConfigurationFailure>()),
          reason: 'HTTP remoto no permitido');
      expect(
          () => f.create(const AiProviderSettings(
              providerType: AiProviderType.backendProxy)),
          throwsA(isA<ConfigurationFailure>()),
          reason: 'backend sin endpoint');
    });

    test('Ollama en localhost por HTTP sin clave es válido', () {
      final s = factory(HumanizerMode.auto).create(const AiProviderSettings(
          providerType: AiProviderType.openAiCompatible,
          endpoint: 'http://localhost:11434/v1/chat/completions',
          model: 'llama3.1'));
      expect(s, isA<LlmHumanizerService>());
      expect(s.descriptor.isRemote, isFalse);
    });
  });
}
