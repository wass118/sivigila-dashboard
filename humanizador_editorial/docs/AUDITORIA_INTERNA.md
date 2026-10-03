# Auditoría interna del MVP (v1.0)

Revisión realizada al cerrar la implementación. Se indica el estado y, cuando hay
riesgo residual, la mitigación o la versión prevista.

## Arquitectura
- **Desacople UI / lógica / IA:** las pantallas dependen de controladores; los
  controladores, de `EditorialPipeline`; el pipeline, de la interfaz
  `HumanizerService`. Solo `HumanizerServiceFactory` conoce adaptadores. ✔
- **Extensibilidad:** dominios, audiencias, objetivos, perfiles y presets salen de un
  catálogo; nuevos proveedores = nuevo `LlmClient`. ✔
- **Riesgo:** sin framework de inyección; la composición está en `AppServices`
  (explícita y suficiente para el tamaño actual).

## Seguridad
- Claves en almacenamiento seguro, separadas de la configuración, nunca mostradas ni
  registradas (prueba: `storage_test.dart`). ✔
- Gemini recibe la clave en cabecera, no en la URL (prueba de adaptador). ✔
- Endpoints remotos solo HTTPS; HTTP permitido únicamente para localhost. ✔
- Logs con redacción de patrones de secretos; nunca se registra texto del usuario. ✔
- **Riesgo residual:** en Web, el almacenamiento del navegador es menos robusto →
  usar backend intermedio (documentado).

## Privacidad
- Ningún envío sin acción explícita; confirmación por sesión con proveedor remoto;
  indicador permanente del tipo de proveedor. ✔
- Aviso de datos personales en perfiles de vigilancia y clínico. ✔
- Historial local desactivable; sin sincronización. ✔
- **Pendiente (v1.1):** anonimización integrada antes del envío (el módulo existe y
  está probado de forma aislada).

## Fidelidad del texto
- Prompts con reglas de fidelidad explícitas, lista de elementos protegidos y
  autoauditoría del modelo. ✔
- Auditoría local determinista independiente del modelo; alertas con valor original
  y encontrado; nunca corrige automáticamente. ✔
- La demo enmascara los elementos protegidos antes de aplicar reglas (prueba: los 38
  elementos del ejemplo se conservan). ✔
- **Limitación:** detección por regex (ver README §9). La interfaz
  `ProtectedContentExtractor` permite sumar extracción semántica.

## Manejo de errores
- Errores tipados y diferenciados (conexión, autenticación, proveedor, respuesta
  inválida, vacío, longitud, configuración, no soportado, inesperado). ✔
- JSON inválido: limpieza segura + un reintento controlado; cualquier excepción no
  tipada se convierte en `UnexpectedFailure` (pruebas en
  `humanizer_services_test.dart`). ✔
- Fallos de almacenamiento del historial no invalidan el resultado. ✔

## UX
- Escritorio: dos columnas; acción principal en barra fija siempre visible. ✔
- Móvil: Entrada/Resultado con cambio automático y pestañas Humanizado, Cambios,
  Auditoría, Recomendaciones, Diagnóstico y Original; fases compactas. ✔
- Modo claro y oscuro con colores semánticos para diff y severidades. ✔
- Verificado con capturas reales del build Web (escritorio 1440 px, móvil 390 px).

## Rendimiento
- Diff de Myers en dos niveles (párrafo → palabra) con recorte de prefijo/sufijo y
  tope de distancia. ✔
- Regex compiladas una vez y cacheadas. ✔
- **Hallazgo corregido durante la auditoría:** con un documento de 59 000
  caracteres, la auditoría tardaba ~750 ms y la detección ~220 ms (VM de pruebas),
  lo que bloqueaba la interfaz. Ahora el análisis local, la detección y la
  auditoría se ejecutan en un isolate (`compute`) para textos de más de 8 000
  caracteres; la prueba de integración de segmentación cubre esa ruta. ✔
- **Riesgo residual:** en Web, `compute` se ejecuta en el hilo principal (limitación
  de Flutter Web); con documentos cercanos al límite puede notarse una pausa breve.

## Mantenibilidad y pruebas
- `flutter analyze`: sin avisos. `flutter test`: 109 pruebas (modelos, detección,
  JSON, diff, auditoría, segmentación, analizador, servicios, adaptadores HTTP,
  fábrica, almacenamiento, anonimizador, integración con proveedor HTTP simulado y
  widgets en escritorio/móvil). ✔
- **Pendiente:** pruebas en dispositivos Android/iOS/Windows reales.
