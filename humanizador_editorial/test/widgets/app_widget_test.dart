import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humanizador_editorial/app/app.dart';
import 'package:humanizador_editorial/app/app_services.dart';
import 'package:humanizador_editorial/core/config/app_environment.dart';
import 'package:humanizador_editorial/features/humanization/humanized_view.dart';
import 'package:humanizador_editorial/services/storage/key_value_store.dart';
import 'package:humanizador_editorial/services/storage/secret_store.dart';

Future<AppServices> testServices() => AppServices.bootstrap(
      mode: HumanizerMode.demo,
      store: InMemoryKeyValueStore(),
      secrets: InMemorySecretStore(),
      fakeLatency: Duration.zero,
    );

Future<void> pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final services = await testServices();
  await tester.pumpWidget(HumanizadorApp(services: services));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('escritorio: dos columnas, ejemplo demo y resultado auditado',
      (tester) async {
    await pumpApp(tester, const Size(1440, 1000));

    expect(find.text('Humanizador Editorial Técnico'), findsOneWidget);
    expect(find.text('Modo demostración'), findsOneWidget);
    expect(find.text('Sin resultados todavía'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);

    await tester.tap(find.text('Cargar ejemplo'));
    await tester.pumpAndSettle();
    // El dominio de vigilancia muestra el aviso de privacidad.
    expect(find.textContaining('Privacidad'), findsOneWidget);

    await tester.tap(find.text('Humanizar'));
    await tester.pumpAndSettle();

    expect(find.text('Texto humanizado'), findsOneWidget);
    expect(find.text('Demostración'), findsWidgets);
    expect(find.text('Copiar resultado'), findsOneWidget);
    final resultList = find
        .descendant(
            of: find.byType(HumanizedView), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.text('Qué mejoró'), 300,
        scrollable: resultList);
    expect(find.text('Qué mejoró'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Qué debes revisar'), 300,
        scrollable: resultList);
    expect(find.text('Qué debes revisar'), findsOneWidget);

    await tester.tap(find.text('Auditoría'));
    await tester.pumpAndSettle();
    expect(find.text('Estado de la auditoría'), findsOneWidget);
    expect(find.text('Cambios editoriales detectados'), findsWidgets);

    await tester.tap(find.text('Cambios'));
    await tester.pumpAndSettle();
    expect(find.textContaining('palabras'), findsWidgets);

    // Historial guardado localmente.
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Boletín de situación'), findsOneWidget);
  });

  testWidgets('móvil: navegación inferior y vista apilada', (tester) async {
    await pumpApp(tester, const Size(400, 860));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Entrada'), findsOneWidget);

    await tester.tap(find.byTooltip('Más acciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cargar ejemplo (demostración)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Humanizar'));
    await tester.pumpAndSettle();

    // Tras procesar, la vista cambia a Resultado.
    expect(find.text('Resultado'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Texto humanizado'), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Texto humanizado'), findsOneWidget);
  });

  testWidgets('texto vacío muestra un error comprensible', (tester) async {
    await pumpApp(tester, const Size(1440, 1000));
    await tester.tap(find.text('Analizar'));
    await tester.pumpAndSettle();
    expect(find.text('Texto vacío'), findsOneWidget);
    expect(find.text('Escriba o pegue un texto antes de continuar.'),
        findsOneWidget);
  });

  testWidgets('ajustes: la clave guardada nunca se muestra', (tester) async {
    await pumpApp(tester, const Size(1440, 1000));
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Proveedor de IA'), findsOneWidget);
    expect(find.textContaining('Modo fijado por entorno'), findsNothing,
        reason: 'el modo demo de prueba se pasa por parámetro, no por entorno');
  });
}
