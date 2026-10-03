# Humanizador Editorial Técnico

Aplicación Flutter (Android, iOS, Web y Windows) que recibe un texto, lo **analiza**,
**protege** sus datos técnicos, genera una **versión editorial más natural, clara y
coherente** y **audita** que cifras, fechas, códigos, nombres y afirmaciones no hayan
cambiado.

Es un **editor técnico asistido por IA**, no una herramienta de evasión: no promete
que un texto sea "indetectable", no calcula ninguna "probabilidad de IA" y no
introduce errores deliberados. Todo resultado es revisable, comparable y auditable
por una persona.

> Prioridad absoluta: **fidelidad del contenido**. Ante un conflicto entre
> naturalidad y precisión técnica, prevalece la precisión técnica.

---

## 1. Requisitos

| Herramienta | Versión verificada |
|---|---|
| Flutter (canal stable) | 3.47.6 |
| Dart | 3.13.5 |
| Navegador (Web) | Chrome/Edge recientes |
| Android | minSdk 24 (por `flutter_secure_storage`) |
| Windows | Visual Studio 2022 con "Desktop development with C++" |
| iOS | Xcode reciente + CocoaPods |

```bash
flutter --version
flutter doctor
```

## 2. Instalación y ejecución

```bash
cd humanizador_editorial
flutter pub get

# Web (modo demostración, sin proveedor de IA)
flutter run -d chrome

# Windows / Android / iOS
flutter run -d windows
flutter run -d <id_dispositivo_android>
flutter run -d <id_simulador_ios>
```

### Variables de entorno (`--dart-define`)

| Variable | Valores | Efecto |
|---|---|---|
| `HUMANIZER_MODE` | `auto` (defecto), `demo`, `real` | `auto`: usa el proveedor elegido en Ajustes (por defecto, la demo). `demo`: fuerza el servicio simulado sin red. `real`: exige un proveedor real. |
| `ENABLE_LOGS` | `true` / `false` | Logs técnicos. Por defecto activos fuera de release. Nunca registran claves ni el texto del usuario. |

```bash
flutter run -d chrome --dart-define=HUMANIZER_MODE=demo
flutter build web --release --dart-define=HUMANIZER_MODE=real --dart-define=ENABLE_LOGS=false
```

### Pruebas y análisis estático

```bash
flutter analyze      # sin avisos
flutter test         # 109 pruebas
```

## 3. Configurar el proveedor de IA

En la app: **Ajustes → Proveedor de IA**. Se configuran proveedor, URL del endpoint,
modelo, temperatura, límite de tokens, salida JSON nativa y segmentación. La clave se
guarda en almacenamiento seguro del sistema y **nunca vuelve a mostrarse**.

| Proveedor | Endpoint por defecto | Clave | Notas |
|---|---|---|---|
| Demostración local | — | No | Reglas deterministas; resultados marcados como *Demostración*. |
| Compatible OpenAI | `https://api.openai.com/v1/chat/completions` | Opcional | Sirve para OpenAI, **Ollama**, LM Studio, vLLM. |
| Anthropic | `https://api.anthropic.com/v1/messages` | Sí | Messages API (`anthropic-version: 2023-06-01`). |
| Google Gemini | `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent` | Sí | La clave va en cabecera `x-goog-api-key`, no en la URL. |
| Backend intermedio | (su URL) | Token opcional | **Recomendado en producción.** Ver `docs/backend_contract.md`. |
| Modo local | — | — | Funcionalidad futura (abstracción preparada). |

El campo **Modelo** debe contener el identificador exacto que indique su proveedor;
la app no trae un modelo preconfigurado para no acoplarse a un fabricante.

**Ejemplo sin enviar datos a internet (Ollama):**

```bash
ollama pull llama3.1
ollama serve
```

En Ajustes: *Compatible OpenAI*, endpoint `http://localhost:11434/v1/chat/completions`,
modelo `llama3.1`, sin clave. HTTP solo se acepta para `localhost`; los endpoints
remotos deben usar HTTPS.

**Web:** la mayoría de proveedores bloquean llamadas directas desde el navegador
(CORS). En Web use el backend intermedio o un servidor local.

**Producción:** no distribuya claves en la app móvil. Use el backend intermedio, que
custodia la clave del proveedor y aplica autenticación, cuotas y registros.

### Parámetros y su justificación

- **Temperatura 0,3 (reescritura):** baja para estabilidad y menor riesgo de alterar
  datos; deja algo de variedad léxica para mejorar la naturalidad.
- **Temperatura ≤ 0,2 (diagnóstico, recomendaciones y reintentos):** son tareas no
  creativas.
- **4096 tokens de salida:** el JSON incluye el texto completo reescrito más el
  análisis; cubre un segmento de 12 000 caracteres.
- **12 000 caracteres por petición / 60 000 por documento:** ≈ 3 000–3 500 tokens de
  entrada por segmento; por encima se segmenta automáticamente.

## 4. Flujo y arquitectura

```
Usuario ─▶ InputPanel ─▶ EditorController ─▶ EditorialPipeline
                                              │
   1. Análisis ──── LocalTextAnalyzer (heurísticas) + HumanizerService.analyze
   2. Protección ── ProtectedContentDetector (regex)
   3. Reescritura ─ TextSegmenter ─▶ HumanizerService.humanize ─▶ ResponseParser
   4. Auditoría ─── FidelityAuditor (entidades, marcadores, longitud) + TextDiffer
                                              │
                         ResultsPanel ◀───────┘  (Humanizado · Cambios · Auditoría ·
                                                 Recomendaciones · Diagnóstico · Original)
```

`HumanizerService` es la abstracción central. Implementaciones:

- `LlmHumanizerService`: cualquier `LlmClient` (adaptadores OpenAI-compatible,
  Anthropic, Gemini, backend, local). Valida JSON y hace **un** segundo intento
  controlado si la respuesta es inválida.
- `FakeHumanizerService`: demostración sin IA, determinista, claramente etiquetada.

`HumanizerServiceFactory` es el único lugar que conoce los adaptadores concretos; las
pantallas no dependen de ningún fabricante.

### Estructura de carpetas

```
lib/
  main.dart                      arranque, captura de errores
  app/                           app.dart (shell), app_scope, app_services (DI), theme
  core/
    config/                      entorno, límites, ajustes del proveedor, catálogo editorial
    errors/                      HumanizerFailure (conexión, autenticación, proveedor,
                                 respuesta inválida, texto vacío, longitud, configuración,
                                 no soportado, inesperado)
    prompts/                     system_prompt, domain_prompts, editorial_prompts,
                                 style_rules, fidelity_rules, audit_rules, output_format,
                                 prompt_builder
    utils/                       logger con redacción de secretos, JSON sanitizer, texto
  models/                        documento, análisis, resultado, elemento protegido,
                                 alerta de fidelidad, recomendación, preset, diff,
                                 índice editorial, auditoría, fases del pipeline
  services/
    ai/                          HumanizerService, LlmClient, adaptadores, parser, fábrica
    analysis/                    analizador local e índice editorial
    audit/                       ProtectedContent, diff (Myers), auditor de fidelidad
    pipeline/                    pipeline de 4 fases y segmentador
    storage/                     preferencias, secretos, historial, presets
    anonymization/               (preparado) anonimizador por reglas
    import/                      (preparado) DocumentImportService: TXT hoy; DOCX/PDF/OCR futuro
    templates/                   (preparado) plantillas documentales
  features/
    home/ analysis/ humanization/ comparison/ history/ settings/ shared/
  widgets/                       componentes reutilizables
  demo/                          texto de demostración (datos ficticios)
test/                            modelos, servicios, integración y widgets
docs/                            contrato del backend y auditoría interna
```

## 5. Protección de contenido y auditoría

**Detección (regex, v1):** números, decimales y miles; porcentajes; fechas
(`15/03/2026`, `2026-03-15`, `9 de septiembre de 2026`); semanas y periodos
epidemiológicos; intervalos e IC; tasas con denominador; cifras con unidad; razones;
fórmulas; códigos (evento SIVIGILA, CIE-10, alfanuméricos, códigos largos); citas
`(Autor, año)` y `[n]`; referencias (URL, DOI, normas); siglas; instituciones; nombres
propios; nombres científicos; eventos y términos técnicos del dominio.

La interfaz `ProtectedContentExtractor` permite añadir después extracción semántica
con el modelo.

**Auditoría:** compara la huella de entidades antes y después:

| Diferencia | Severidad |
|---|---|
| Cifra, porcentaje, fecha, periodo, código, cita o referencia ausente, modificada o nueva | Alta |
| Misma cifra con distinta unidad (`5 mg` → `5 g`) | Alta |
| Mismo valor con otro formato (`1.248` → `1248`) | Media |
| Sigla, institución, evento, término técnico o nombre científico eliminado o nuevo | Media |
| Cambio en marcadores de certeza, negación o tendencia | Media |
| Versión > 30 % más larga o > 40 % más corta (posible adición u omisión) | Media |
| Alertas reportadas por el modelo | Las que indique (marcadas por origen) |

Estados: *Sin cambios técnicos detectados*, *Cambios editoriales detectados*,
*Revisión humana recomendada*, *Posible modificación técnica*. Son apoyo para la
revisión humana, **no garantía de equivalencia semántica**. La app **nunca corrige
automáticamente** el texto: muestra el valor original y el encontrado.

**Índice editorial:** promedio de seis métricas observables (longitud de oración,
oraciones largas, repetición léxica, densidad de conectores, nominalizaciones,
fórmulas genéricas). Las fórmulas están en `editorial_metrics.dart` y en la propia
interfaz. No mide autoría ni detecta IA.

## 6. Prompts modulares

Cada petición contiene cuatro secciones: **CONTEXTO DE DOMINIO**, **RESTRICCIONES**
(reglas de fidelidad + reglas del dominio + autoauditoría + elementos protegidos +
intensidad), **ESTILO** (naturalidad profesional + prohibición de "humanización
artificial" + reglas del preset) y **FORMATO DE SALIDA** (esquema JSON). Al modelo solo
se envían el texto, los parámetros editoriales y la lista de elementos protegidos.

## 7. Extender la aplicación

- **Nuevo dominio, audiencia, objetivo o perfil de autor:** añadir una entrada en
  `lib/core/config/editorial_catalog.dart` (y su contexto en `core/prompts/`). Las
  pantallas se generan desde el catálogo.
- **Nuevo proveedor:** implementar `LlmClient` en `services/ai/adapters/`, añadir el
  valor a `AiProviderType` y un caso en `HumanizerServiceFactory.createClient`.
- **Nuevo preset de fábrica:** `EditorialCatalog.builtInPresets`. Los presets del
  usuario se guardan desde el editor.

## 8. Privacidad y seguridad

- Ningún envío sin acción explícita (Analizar/Humanizar) y, con proveedor remoto,
  confirmación una vez por sesión. La interfaz indica siempre si el proveedor es
  local, remoto o demostración.
- Perfil de vigilancia y clínico: aviso para no introducir datos personales
  identificables salvo entorno autorizado.
- Claves en `flutter_secure_storage` (Keychain/Keystore/DPAPI; en Web, cifrado en el
  almacenamiento del navegador, con menor protección). Nunca se muestran.
- Historial solo local (desactivable). No hay almacenamiento remoto.
- Logs sin claves ni texto; patrón de redacción para `sk-…`, `AIza…`, `Bearer …`.

## 9. Limitaciones actuales (v1.0)

- La detección de entidades es por reglas: puede omitir nombres propios al inicio de
  oración o entidades atípicas y generar falsos positivos. La auditoría lo compensa
  parcialmente; la revisión humana sigue siendo necesaria.
- La auditoría no verifica equivalencia semántica de afirmaciones sin marcadores
  (p. ej., una relación causal reformulada).
- En documentos segmentados, el diagnóstico del modelo se basa en el primer segmento.
- El adaptador compatible OpenAI envía `max_tokens`; algunos modelos recientes de
  OpenAI exigen `max_completion_tokens` (usar backend intermedio o ajustar adaptador).
- En Web, el trabajo pesado (detección y auditoría de documentos largos) corre en el
  hilo principal porque `compute` no usa isolates en esa plataforma; en móvil y
  escritorio sí se ejecuta en segundo plano.
- No se compilaron binarios Android/iOS/Windows en el entorno de desarrollo (sin
  SDKs nativos); sí se compiló y probó la versión Web.
- Modo local, importación de archivos, anonimización integrada y plantillas están
  preparados como interfaces, no activos.

## 10. Hoja de ruta

**v1.1** — Importación TXT/DOCX/PDF (`DocumentImportService`); segmentación con
diagnóstico agregado por segmento; anonimización integrada y reversible
(`AnonymizerService`) antes del envío; reglas de comparación mejoradas (extracción
semántica de entidades con el modelo, equivalencias numéricas configurables,
afirmaciones causales).

**v1.2** — Perfiles de autor personalizables; plantillas documentales (SITREP,
informe epidemiológico, concepto técnico, oficio, ASIS, resumen ejecutivo, IEC,
recomendación técnica); historial avanzado (búsqueda, etiquetas, comparación entre
versiones); exportación DOCX/PDF con anexo de auditoría.

**v2.0** — Backend seguro de producción (custodia de claves, autenticación, cuotas,
auditoría); cuentas de usuario y sincronización opcional cifrada; múltiples proveedores
con enrutamiento y respaldo; OCR de imágenes y PDF escaneados; perfiles especializados
por dominio y modelos locales en el dispositivo.
