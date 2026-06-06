# Guía de Uso - SIVIGILA Dashboard

## 🎯 Inicio Rápido

### 1. Abrir la Aplicación

- **Desarrollo**: http://localhost:5173
- **Producción**: Tu URL de despliegue

### 2. Cargar Datos

1. Haz click en la sección "Importar Datos SIVIGILA"
2. Arrastra tu archivo Excel o haz click para seleccionar
3. El archivo se procesará automáticamente
4. Verás un mensaje de confirmación si todo es correcto

## 📊 Secciones del Dashboard

### A. Tarjetas de Estadísticas (KPIs)

Muestran 4 métricas principales:

- **Casos Totales**: Suma de todos los casos importados
- **Eventos Reportados**: Cantidad de eventos/enfermedades diferentes
- **Municipios Afectados**: Cantidad de municipios con casos
- **Semanas Registradas**: Rango temporal de los datos

### B. Curva Epidémica

Gráfico de línea que muestra:
- Eje X: Número de semana epidemiológica
- Eje Y: Cantidad de casos por semana
- Puntos interactivos: Hover para ver detalles
- Área bajo la línea: Visualización de intensidad

**Cómo interpretar**:
- Línea hacia arriba = Aumento de casos
- Línea hacia abajo = Disminución de casos
- Línea plana = Situación estable

### C. Distribución de Eventos (Pie Chart)

Muestra la proporción de casos por evento:
- Cada color representa un evento
- El tamaño de la sección indica el porcentaje
- Legend en la parte inferior
- Click en la leyenda para ocultar/mostrar eventos

### D. Top 10 Eventos (Gráfico de Barras)

Ranking horizontal de los 10 eventos con más casos:
- Barra más larga = Más casos
- Colores diversos para diferenciación
- Hover para ver el valor exacto

### E. Mapa Interactivo

Visualización geográfica de casos por municipio:

**Significado de los círculos**:
- **Tamaño**: Proporcional al número de casos
- **Color**:
  - 🔴 Rojo: Casos altos (>75%)
  - 🟡 Amarillo: Casos moderados (50-75%)
  - 🟢 Verde: Casos bajos (25-50%)
  - 🔵 Azul: Casos muy bajos (<25%)

**Interacciones**:
- **Click en círculo**: Muestra popup con:
  - Nombre del municipio
  - Número de casos
  - Eventos reportados
- **Zoom**: Rueda del mouse o controles de mapa
- **Desplazamiento**: Click y arrastra

### F. Tablero de Eventos (Tabla)

Listado detallado de todos los eventos con columnas:

| Columna | Descripción |
|---------|-------------|
| Evento | Nombre de la enfermedad/evento |
| Casos | Número total de casos |
| % del Total | Porcentaje respecto a casos totales |
| Tasa Incidencia | Casos por 100,000 habitantes (estimado) |
| Tendencia | ↑ Aumento, ↓ Disminución, → Estable |

**Indicadores de Tendencia**:
- 🔴 **Aumento**: Más casos que la semana anterior (>5% incremento)
- 🟢 **Disminución**: Menos casos que la semana anterior (>5% disminución)
- 🟡 **Estable**: Variación menor al 5%

## 📁 Formato del Archivo Excel

Tu archivo debe contener estas columnas (puede variar el nombre ligeramente):

### Estructura Recomendada

```
MUNICIPIO | EVENTO | CASOS | FECHA | SEMANA | AÑO
```

### Ejemplo de Datos

```
Bogotá       | Dengue      | 5  | 2024-01-15 | 3  | 2024
Medellín     | Malaria     | 2  | 2024-01-15 | 3  | 2024
Cali         | COVID-19    | 8  | 2024-01-15 | 3  | 2024
Cartagena    | Dengue      | 3  | 2024-01-22 | 4  | 2024
Bogotá       | COVID-19    | 12 | 2024-01-22 | 4  | 2024
```

### Variaciones Aceptadas

La aplicación es flexible con los nombres de columnas:

| Columna Original | Variaciones Aceptadas |
|------------------|----------------------|
| MUNICIPIO | Municipio, municipio, MPIO |
| EVENTO | Evento, enfermedad, ENFERMEDAD, Enfermedad |
| CASOS | Casos, caso, TOTAL_CASOS, total |
| FECHA | Fecha, fecha_inicio, FECHA_INICIO, date |
| SEMANA | Semana, semana_epi, SEMANA_EPI, week |
| AÑO | Año, año, YEAR, year |

## 🔄 Actualizar Datos

### Opción 1: Cargar Nuevo Archivo

1. Haz click en el área de carga nuevamente
2. Selecciona un archivo diferente o actualizado
3. Los datos antiguos se reemplazarán
4. Las gráficas se actualizarán automáticamente

### Opción 2: Actualización Automática (si está configurada)

La aplicación puede configurarse para actualizar datos automáticamente cada cierto tiempo.

## 💾 Guardar datos offline

Como PWA, la aplicación:
- Cachea datos automáticamente
- Permite acceso sin conexión a internet
- Sincroniza cuando se recupera la conexión

## 🎨 Personalización

### Cambiar Tema de Color

1. Edita `src/tailwind.config.js`
2. Modifica los valores en `colors`:

```js
colors: {
  primary: '#TU_COLOR',
  secondary: '#TU_COLOR',
  // ...
}
```

3. Reinicia el servidor de desarrollo

### Agregar Municipios

1. Edita `src/utils/excelParser.ts`
2. Añade entrada en `MUNICIPIOS_DATA`:

```ts
const MUNICIPIOS_DATA = {
  'tu-municipio': { lat: 4.5709, lng: -74.2973 },
  // ...
}
```

3. Los datos se procesarán automáticamente

## 📈 Análisis Avanzado

### Interpretar la Curva Epidémica

**Patrón Explosivo** (aumento rápido):
- Indica brote nuevo
- Requiere intervención inmediata
- Monitoreo intensivo

**Patrón Progresivo** (aumento gradual):
- Propagación progresiva
- Requiere vigilancia constante
- Implementar medidas preventivas

**Patrón Decreciente** (disminución):
- Situación bajo control
- Continuar vigilancia
- Evaluar efectividad de intervenciones

### Analizar por Municipio

1. Haz click en un círculo del mapa
2. Verás popup con información específica
3. Cruza datos con la tabla de eventos
4. Identifica patrones geográficos

### Comparar Eventos

1. Mira el pie chart de distribución
2. Compara porcentajes en la tabla
3. Observa tendencias en la columna "Tendencia"
4. Identifica eventos críticos

## 🔍 Troubleshooting

### Problema: No aparecen datos
**Solución**:
1. Verifica que el Excel tenga las columnas correctas
2. Comprueba que hay datos en las filas
3. Revisa la consola (F12) para errores
4. Intenta con otro archivo

### Problema: Mapa sin markers
**Solución**:
1. Verifica conexión a internet (requiere OpenStreetMap)
2. Recarga la página (F5)
3. Comprueba que los municipios estén en la lista soportada

### Problema: Gráficas no se ven
**Solución**:
1. Espera a que carguen (pueden tardar segundos)
2. Recarga la página
3. Limpia cache del navegador
4. Abre DevTools (F12) para verificar errores

### Problema: Datos no se guardan offline
**Solución**:
1. Verifica que esté instalada como PWA
2. Comprueba que Service Worker esté registrado
3. En DevTools > Application > Service Workers
4. Revisa que el navegador permita PWA

## 📱 Uso en Dispositivos Móviles

### Smartphone/Tablet

1. **Abrir en navegador móvil**
   - Chrome, Safari o Firefox
   - Acceder a tu URL de despliegue

2. **Instalar como App**
   - **iOS**: Share → Añadir a pantalla de inicio
   - **Android**: Menu → Instalar aplicación

3. **Navegar**
   - Usa gestos de zoom (pellizco)
   - Desliza para desplazar mapas
   - Toca dos veces para zoom rápido

## ⌨️ Atajos de Teclado

| Atajo | Acción |
|-------|--------|
| F12 | Abrir DevTools |
| Ctrl+R | Recargar página |
| Ctrl+Shift+Del | Limpiar cache |

## 📞 Obtener Ayuda

- **Documentación**: Ver archivo README.md
- **Problemas técnicos**: Abre issue en GitHub
- **Contacto**: Crea una discusión en el repositorio

---

**¡Disfruta analizando tus datos SIVIGILA!**
