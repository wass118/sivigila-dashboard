import 'package:flutter_test/flutter_test.dart';
import 'package:humanizador_editorial/core/config/ai_provider_settings.dart';
import 'package:humanizador_editorial/models/editorial_document.dart';
import 'package:humanizador_editorial/models/editorial_preset.dart';
import 'package:humanizador_editorial/models/editorial_request.dart';
import 'package:humanizador_editorial/services/anonymization/anonymizer_service.dart';
import 'package:humanizador_editorial/services/storage/history_repository.dart';
import 'package:humanizador_editorial/services/storage/key_value_store.dart';
import 'package:humanizador_editorial/services/storage/preset_repository.dart';
import 'package:humanizador_editorial/services/storage/secret_store.dart';
import 'package:humanizador_editorial/services/storage/settings_repository.dart';

EditorialDocument doc(String id, int minute) => EditorialDocument(
      id: id,
      createdAt: DateTime(2026, 10, 1, 8, minute),
      title: 'Doc $id',
      domainId: 'general',
      goalId: 'claridad',
      intensityName: 'moderate',
      originalText: 'Original $id',
      generatedText: 'Generado $id',
    );

void main() {
  group('HistoryRepository', () {
    test('agrega, ordena, limita y elimina individualmente', () async {
      final repo = HistoryRepository(InMemoryKeyValueStore(), maxEntries: 3);
      for (var i = 0; i < 5; i++) {
        await repo.add(doc('$i', i));
      }
      var items = await repo.list();
      expect(items.map((d) => d.id), ['4', '3', '2']);
      await repo.delete('3');
      items = await repo.list();
      expect(items.map((d) => d.id), ['4', '2']);
      await repo.clear();
      expect(await repo.list(), isEmpty);
    });

    test('datos corruptos no rompen la lectura', () async {
      final store = InMemoryKeyValueStore()
        ..data['history.documents.v1'] = '{no json';
      expect(await HistoryRepository(store).list(), isEmpty);
    });
  });

  group('SettingsRepository', () {
    test('guarda configuración y clave por separado', () async {
      final store = InMemoryKeyValueStore();
      final secrets = InMemorySecretStore();
      final repo = SettingsRepository(store: store, secrets: secrets);
      await repo.save(const AiProviderSettings(
          providerType: AiProviderType.anthropic, model: 'm'));
      await repo.saveApiKey(AiProviderType.anthropic, '  secreto  ');

      final loaded = await repo.load();
      expect(loaded.providerType, AiProviderType.anthropic);
      expect(await repo.hasApiKey(AiProviderType.anthropic), isTrue);
      expect(await repo.hasApiKey(AiProviderType.gemini), isFalse);
      expect(await repo.readApiKey(AiProviderType.anthropic), 'secreto');
      // La clave nunca se escribe en el almacenamiento no cifrado.
      expect(store.data.values.any((v) => v.contains('secreto')), isFalse);

      await repo.deleteApiKey(AiProviderType.anthropic);
      expect(await repo.hasApiKey(AiProviderType.anthropic), isFalse);
    });

    test('configuración corrupta → valores por defecto', () async {
      final store = InMemoryKeyValueStore()
        ..data['settings.ai_provider.v1'] = '###';
      final s = await SettingsRepository(
              store: store, secrets: InMemorySecretStore())
          .load();
      expect(s.providerType, AiProviderType.demo);
    });
  });

  group('PresetRepository', () {
    test('incluye presets de fábrica y guarda/elimina los propios', () async {
      final repo = PresetRepository(InMemoryKeyValueStore());
      expect(await repo.list(), hasLength(5));
      await repo.save(const EditorialPreset(
          id: 'u1', name: 'Mío', options: EditorialOptions(goalId: 'claridad')));
      final list = await repo.list();
      expect(list, hasLength(6));
      expect(list.last.name, 'Mío');
      await repo.delete('u1');
      expect(await repo.list(), hasLength(5));
    });
  });

  group('RuleBasedAnonymizer (arquitectura preparada)', () {
    test('detecta y revierte datos personales', () {
      const text = 'Paciente con CC 1.234.567.890, tel. 300 123 4567, '
          'correo ana@ejemplo.co, HC: 12345678, ubicado en 10.9632, -74.7964.';
      const anonymizer = RuleBasedAnonymizer();
      final types = anonymizer.detect(text).map((m) => m.type).toSet();
      expect(types, containsAll([
        SensitiveType.documentId,
        SensitiveType.phone,
        SensitiveType.email,
        SensitiveType.clinicalRecord,
        SensitiveType.coordinates,
      ]));
      final anon = anonymizer.anonymize(text);
      expect(anon.text, isNot(contains('ana@ejemplo.co')));
      expect(anon.text, contains('[EMAIL_1]'));
      expect(anon.restore(anon.text), text);
    });
  });
}
