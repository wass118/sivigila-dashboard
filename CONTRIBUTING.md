# Guía de Contribución

Gracias por tu interés en contribuir a SIVIGILA Dashboard. Este documento te guiará a través del proceso.

## 📋 Código de Conducta

Esta comunidad mantiene los siguientes principios:
- Sé respetuoso
- Sé colaborativo
- Sé constructivo
- Acepta críticas constructivas

## 🐛 Reportar Bugs

### Antes de Reportar

1. Verifica que el bug no haya sido reportado
2. Comprueba la última versión
3. Intenta reproducirlo

### Cómo Reportar

1. Abre un [Issue](https://github.com/wass118/sivigila-dashboard/issues)
2. Usa un título descriptivo
3. Incluye:
   - Descripción clara del problema
   - Pasos para reproducirlo
   - Comportamiento esperado
   - Comportamiento actual
   - Screenshots si es relevante
   - Tu entorno (OS, navegador, versión Node)

## ✨ Proponer Nuevas Funcionalidades

1. Abre un [Issue](https://github.com/wass118/sivigila-dashboard/issues)
2. Describe la funcionalidad
3. Explica por qué sería útil
4. Proporciona ejemplos de uso

## 🔧 Contribuir Código

### Setup

```bash
# Fork el repositorio
git clone https://github.com/tu-usuario/sivigila-dashboard.git
cd sivigila-dashboard

# Crea una rama
git checkout -b feature/nombre-descriptivo

# Instala dependencias
npm install

# Inicia desarrollo
npm run dev
```

### Commits

```bash
# Commits con mensaje descriptivo
git commit -m "feat: agregar nueva funcionalidad"
```

**Prefijos recomendados**:
- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `docs`: Cambios en documentación
- `style`: Cambios de estilo (sin cambiar lógica)
- `refactor`: Refactorización de código
- `test`: Agregar/modificar tests
- `perf`: Mejoras de rendimiento

### Estándares de Código

- Usa TypeScript
- Sigue el estilo de código existente
- Ejecuta `npm run lint` antes de commit
- Escribe componentes funcionales con hooks
- Documenta funciones complejas

### Ejemplo

```typescript
// ✅ Bien
interface EventData {
  id: string
  nombre: string
  casos: number
}

const MiComponente: React.FC<{ evento: EventData }> = ({ evento }) => {
  return <div>{evento.nombre}</div>
}

// ❌ Evitar
const MiComponente = (props) => {
  return <div>{props.evento.nombre}</div>
}
```

## 📝 Requerimientos para Pull Request

1. **Descripción clara**: Qué cambios hace y por qué
2. **Referencia a Issues**: Link a issues relacionados
3. **Tests**: Si es aplicable
4. **Documentación**: Actualiza README si es necesario
5. **Screenshots**: Si cambios visuales

### Template de PR

```markdown
## Descripción
Breve descripción de los cambios

## Tipo de cambio
- [ ] Bug fix
- [ ] Nueva funcionalidad
- [ ] Breaking change
- [ ] Documentación

## Relacionado a
Fixes #123
Closes #456

## Cambios
- Cambio 1
- Cambio 2

## Testing
Describe cómo testeaste los cambios

## Screenshots
[Si es relevante]

## Checklist
- [ ] Mi código sigue los estándares del proyecto
- [ ] He ejecutado `npm run lint`
- [ ] He actualizado la documentación
- [ ] He testeado manualmente los cambios
```

## 📚 Estructura del Proyecto

```
src/
├── components/    # Componentes React reutilizables
├── pages/         # Páginas principales
├── store/         # Estado global (Zustand)
├── types/         # Tipos TypeScript
├── utils/         # Funciones utilitarias
├── App.tsx        # Componente raíz
└── main.tsx       # Punto de entrada
```

## 🎯 Áreas de Contribución

### Alta Prioridad
- [ ] Tests automatizados
- [ ] Validación mejorada de datos
- [ ] Exportación de reportes en PDF
- [ ] API real para SIVIGILA

### Media Prioridad
- [ ] Traducciones (i18n)
- [ ] Análisis predictivos
- [ ] Notificaciones de alertas
- [ ] Dashboard personalizable

### Baja Prioridad
- [ ] Temas oscuros
- [ ] Animaciones mejoradas
- [ ] Documentación

## 🧪 Testing

```bash
# Ejecutar linter
npm run lint

# Build de prueba
npm run build

# Preview
npm run preview
```

## 📚 Recursos

- [React Documentation](https://react.dev)
- [TypeScript Handbook](https://www.typescriptlang.org/docs)
- [Zustand Docs](https://github.com/pmndrs/zustand)
- [Chart.js Docs](https://www.chartjs.org/docs/latest/)
- [Leaflet Docs](https://leafletjs.com/)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)

## ❓ Preguntas

Si tienes dudas:
1. Abre una [Discussion](https://github.com/wass118/sivigila-dashboard/discussions)
2. Consulta la documentación existente
3. Revisa issues similares

## 🎓 Proceso de Review

1. Maintainer revisa el PR
2. Feedback o aprobación
3. Cambios según feedback
4. Merge cuando esté listo

## 🚀 Después de Merge

Tu contribución:
- Será incluida en la próxima versión
- Será creditada en el changelog
- Será mencionada en las releases

---

¡Gracias por tu contribución! 🎉
