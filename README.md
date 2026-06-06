# SIVIGILA Dashboard PWA

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Una Aplicación Web Progresiva (PWA) moderna e interactiva para análisis epidemiológico de datos SIVIGILA en Colombia. Permite importar, procesar y visualizar datos de vigilancia epidemiológica con gráficas interactivas, georreferenciación de casos y análisis de tendencias.

## 🌟 Características

✅ **Importación de Datos**
- Carga de archivos Excel SIVIGILA (.xlsx, .xls)
- Validación y homologación automática de datos
- Procesamiento en tiempo real

✅ **Dashboards Interactivos**
- Tarjetas de estadísticas clave (KPIs)
- Curva epidémica semanal
- Distribución de eventos por pie chart
- Ranking de eventos por casos
- Tablero detallado de eventos

✅ **Visualizaciones Avanzadas**
- Gráficas interactivas con Chart.js
- Mapa georreferenciado con Leaflet
- Markers dinámicos por municipio
- Leyenda visual de intensidad de casos

✅ **Análisis Epidemiológico**
- Número de casos por evento
- Porcentaje del total de casos
- Tasa de incidencia calculada
- Análisis de tendencias (aumento, disminución, estable)

✅ **PWA Functionality**
- Instalable en dispositivos
- Funcionamiento offline
- Service Workers integrados
- Interfaz responsive y adaptive

## 🛠️ Stack Tecnológico

- **Frontend Framework**: React 18.2
- **Language**: TypeScript 5.0
- **Build Tool**: Vite 5.0
- **State Management**: Zustand 4.4
- **Charting**: Chart.js 4.4 + React-ChartJS-2
- **Maps**: Leaflet 1.9 + React-Leaflet
- **Excel Parsing**: XLSX 0.18
- **Styling**: Tailwind CSS 3.3
- **Icons**: Lucide React
- **Date Utils**: date-fns 2.30

## 📋 Requisitos

- Node.js >= 16.0
- npm >= 8.0 o yarn >= 1.22

## 🚀 Instalación y Uso

### 1. Clonar el repositorio
```bash
git clone https://github.com/wass118/sivigila-dashboard.git
cd sivigila-dashboard
```

### 2. Instalar dependencias
```bash
npm install
# o
yarn install
```

### 3. Configurar variables de entorno
```bash
cp .env.example .env.local
```

### 4. Ejecutar en desarrollo
```bash
npm run dev
# o
yarn dev
```

La aplicación se abrirá automáticamente en `http://localhost:5173`

### 5. Compilar para producción
```bash
npm run build
# o
yarn build
```

### 6. Previsualizar build
```bash
npm run preview
# o
yarn preview
```

## 📁 Estructura del Proyecto

```
src/
├── components/
│   ├── Layout.tsx              # Layout principal
│   ├── Header.tsx              # Barra de encabezado
│   ├── Sidebar.tsx             # Barra lateral de navegación
│   ├── FileUpload.tsx          # Componente de carga de archivos
│   ├── StatsCards.tsx          # Tarjetas de estadísticas
│   ├── EventsTable.tsx         # Tablero de eventos
│   ├── charts/
│   │   ├── EpidemicCurve.tsx   # Curva epidémica (línea)
│   │   ├── EventsChart.tsx     # Gráfico de eventos (barras)
│   │   └── EventsDistributionPie.tsx # Distribución de eventos (pie)
│   └── maps/
│       └── CasesMap.tsx        # Mapa georreferenciado
├── pages/
│   └── Dashboard.tsx           # Página principal del dashboard
├── store/
│   └── sivigilaStore.ts        # Estado global con Zustand
├── types/
│   └── index.ts                # Tipos TypeScript
├── utils/
│   ├── excelParser.ts          # Procesamiento de Excel
│   └── dateUtils.ts            # Utilidades de fecha
├── App.tsx                     # Componente raíz
├── main.tsx                    # Punto de entrada
└── index.css                   # Estilos globales

public/
├── manifest.json               # Manifiesto PWA
└── sw.js                       # Service Worker
```

## 📊 Formato de Archivo Excel SIVIGILA

El archivo Excel debe contener las siguientes columnas (se aceptan variaciones en los nombres):

| Columna | Tipo | Descripción |
|---------|------|-------------|
| MUNICIPIO | String | Nombre del municipio |
| EVENTO | String | Nombre del evento/enfermedad |
| CASOS | Number | Número de casos |
| FECHA | Date | Fecha de reporte (YYYY-MM-DD) |
| SEMANA | Number | Semana epidemiológica (1-53) |
| AÑO | Number | Año (YYYY) |

### Ejemplo de datos:

```
MUNICIPIO | EVENTO | CASOS | FECHA | SEMANA | AÑO
Bogotá | Dengue | 5 | 2024-01-15 | 3 | 2024
Medellín | Malaria | 2 | 2024-01-15 | 3 | 2024
Cali | COVID-19 | 8 | 2024-01-15 | 3 | 2024
```

## 🗺️ Municipios Soportados

La aplicación incluye coordenadas geográficas para los principales municipios colombianos:
- Bogotá
- Medellín
- Cali
- Barranquilla
- Cartagena
- Santa Marta
- Cúcuta
- Bucaramanga
- Manizales
- Ibagué

**Nota**: Para municipios no incluidos, se asignan coordenadas por defecto al centro de Colombia.

## 🎨 Personalización

### Temas de Color
Modifica los colores en `tailwind.config.js`:

```js
colors: {
  primary: '#1a73e8',
  secondary: '#34a853',
  danger: '#d33b27',
  warning: '#fbbc04',
  info: '#4285f4',
}
```

### Agregar Municipios
Edita `src/utils/excelParser.ts` en la constante `MUNICIPIOS_DATA`:

```ts
const MUNICIPIOS_DATA: Record<string, { lat: number; lng: number }> = {
  'tu-municipio': { lat: 4.5709, lng: -74.2973 },
  // ...
}
```

## 📱 PWA - Características Offline

La aplicación incluye:
- **Service Worker**: Cacheo automático de assets
- **Manifest**: Instalación como app nativa
- **Offline Support**: Acceso a datos cargados sin conexión

### Instalar como App

1. **Chrome/Edge**: Click en el icono "Instalar" en la barra de dirección
2. **iOS Safari**: Share > Añadir a pantalla de inicio
3. **Android Chrome**: Menu > Instalar aplicación

## 📈 Funcionalidades Principales

### 1. Importación de Datos
- Arrastra/suelta archivos Excel
- Validación automática de formato
- Procesamiento progresivo
- Mensajes de error detallados

### 2. Análisis de Eventos
- Ranking automático por número de casos
- Cálculo de porcentajes
- Tasa de incidencia por evento
- Análisis de tendencias semana a semana

### 3. Curva Epidémica
- Visualización semanal de casos
- Línea de tendencia
- Información interactiva al pasar mouse
- Exportable en múltiples formatos

### 4. Georreferenciación
- Mapa interactivo por municipio
- Marcadores dinámicos
- Tamaño proporcional a número de casos
- Color según intensidad (rojo > amarillo > verde > azul)
- Popup con información detallada

### 5. Tablero de Eventos
- Lista completa de eventos
- Ordenable por columnas
- Indicadores visuales de tendencia
- Detalles de tasa de incidencia

## 🔄 Actualización Automática de Datos

Para implementar actualización automática:

```tsx
// En Dashboard.tsx
useEffect(() => {
  const interval = setInterval(async () => {
    // Recargar datos cada 5 minutos
    if (fileInput.current?.files?.[0]) {
      const newData = await parseExcelFile(fileInput.current.files[0])
      setData(newData)
    }
  }, 5 * 60 * 1000)
  
  return () => clearInterval(interval)
}, [])
```

## 🐛 Troubleshooting

### Problema: "El archivo Excel no se procesa"
**Solución**: Verifica que el archivo tenga las columnas correctas (MUNICIPIO, EVENTO, CASOS, FECHA, SEMANA, AÑO)

### Problema: "El mapa no se visualiza"
**Solución**: Verifica que Leaflet esté correctamente importado y que haya internet para cargar OpenStreetMap

### Problema: "Service Worker no funciona"
**Solución**: Asegúrate de que la app esté en HTTPS (requerido para PWA)

## 📝 Licencia

Este proyecto está bajo licencia MIT. Ver archivo `LICENSE` para más detalles.

## 👨‍💻 Autor

**wass118** - Desarrollo y mantenimiento

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📞 Soporte

Si tienes problemas o sugerencias, abre un issue en el repositorio.

## 🔮 Roadmap

- [ ] Exportación de reportes en PDF
- [ ] Integración con API SIVIGILA oficial
- [ ] Dashboard personalizable por usuario
- [ ] Análisis predictivos con tendencias
- [ ] Comparativa entre municipios
- [ ] Sincronización automática en la nube
- [ ] Soporte para múltiples idiomas
- [ ] Notificaciones de alertas epidemiológicas

---

**Hecho con ❤️ para la vigilancia epidemiológica en Colombia**
