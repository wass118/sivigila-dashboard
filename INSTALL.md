# Guía de Instalación - SIVIGILA Dashboard

## 📦 Instalación Local

### Paso 1: Clonar el repositorio

```bash
git clone https://github.com/wass118/sivigila-dashboard.git
cd sivigila-dashboard
```

### Paso 2: Instalar Node.js

Si aún no tienes Node.js instalado, descárgalo desde:
- [nodejs.org](https://nodejs.org) - Se recomienda la versión LTS (16+)

Verifica la instalación:
```bash
node --version
npm --version
```

### Paso 3: Instalar dependencias

```bash
npm install
```

Esto instalará todos los paquetes necesarios listados en `package.json`.

### Paso 4: Variables de entorno (Opcional)

Copia el archivo de ejemplo:
```bash
cp .env.example .env.local
```

Edita `.env.local` si necesitas configuración específica.

### Paso 5: Ejecutar en desarrollo

```bash
npm run dev
```

La aplicación se abrirá automáticamente en tu navegador en `http://localhost:5173`

## 🏗️ Build para Producción

### Compilar la aplicación

```bash
npm run build
```

Esto generará una carpeta `dist/` lista para desplegar.

### Servir localmente el build

```bash
npm run preview
```

## 🚀 Despliegue en Netlify

### Opción 1: Via Netlify CLI

```bash
npm install -g netlify-cli
npm run build
netlify deploy --prod --dir=dist
```

### Opción 2: Via GitHub

1. Push a tu repositorio GitHub
2. Conecta el repo en [netlify.com](https://netlify.com)
3. Configura:
   - Build command: `npm run build`
   - Publish directory: `dist`
4. Deploy automático en cada push

## 🚀 Despliegue en Vercel

### Via Vercel CLI

```bash
npm install -g vercel
vercel
```

### Via GitHub

1. Importa el proyecto en [vercel.com](https://vercel.com)
2. Vercel detectará automáticamente la configuración de Vite
3. Deploy automático

## 🐳 Despliegue con Docker

### Crear Dockerfile

Crea un archivo `Dockerfile` en la raíz:

```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine
WORKDIR /app
RUN npm install -g serve
COPY --from=builder /app/dist ./dist
EXPOSE 3000
CMD ["serve", "-s", "dist", "-l", "3000"]
```

### Crear Dockerfile para desarrollo

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5173
CMD ["npm", "run", "dev"]
```

### Build y run

```bash
# Producción
docker build -t sivigila-dashboard .
docker run -p 3000:3000 sivigila-dashboard

# Desarrollo
docker build -f Dockerfile.dev -t sivigila-dashboard-dev .
docker run -p 5173:5173 -v $(pwd):/app sivigila-dashboard-dev
```

## 🐋 Docker Compose

Crea `docker-compose.yml`:

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
```

Ejecuta:
```bash
docker-compose up
```

## 📱 Instalación como PWA

### En Google Chrome / Microsoft Edge

1. Abre la aplicación en tu navegador
2. Click en el icono de instalación en la barra de dirección (esquina superior derecha)
3. Selecciona "Instalar"
4. La app se instalará en tu dispositivo como una aplicación nativa

### En iOS Safari

1. Abre la aplicación en Safari
2. Click en el botón "Compartir" (cuadro con flecha)
3. Selecciona "Añadir a pantalla de inicio"
4. Dale un nombre a la app
5. Click en "Añadir"

### En Android Chrome

1. Abre la aplicación en Chrome
2. Click en el menú (tres puntos)
3. Selecciona "Instalar aplicación"
4. Confirma la instalación

## 🔍 Verificar Instalación

### Desarrollo
```bash
# Verifica que se haya clonado correctamente
ls -la

# Verifica que Node.js esté instalado
node --version

# Verifica que las dependencias se instalaron
ls node_modules | head

# Ejecuta los tests de lint
npm run lint
```

## ⚙️ Configuración Adicional

### Cambiar Puerto de Desarrollo

Edita `vite.config.ts`:

```ts
server: {
  port: 3000,  // Cambia 5173 por 3000
  open: true,
}
```

### Agregar Proxy para API

En `vite.config.ts`:

```ts
server: {
  proxy: {
    '/api': {
      target: 'http://tu-api.com',
      changeOrigin: true,
      rewrite: (path) => path.replace(/^\/api/, '')
    }
  }
}
```

## 🆘 Problemas Comunes

### Error: "npm command not found"
- Reinstala Node.js desde [nodejs.org](https://nodejs.org)

### Error: "Port 5173 already in use"
```bash
# Cambia el puerto en vite.config.ts o usa:
npm run dev -- --port 5174
```

### Error: "Module not found"
```bash
# Limpia cache y reinstala
rm -rf node_modules package-lock.json
npm install
```

### Error: "Service Worker no funciona"
- Asegúrate que estés en HTTPS en producción
- En desarrollo, abre DevTools > Application > Service Workers

## ✅ Verificación Final

Al ejecutar `npm run dev`, deberías ver:

```
  VITE v5.0.0  ready in 234 ms

  ➜  Local:   http://localhost:5173/
  ➜  press h to show help
```

Abre `http://localhost:5173` en tu navegador y debería cargar la aplicación.

---

¿Necesitas ayuda? Abre un issue en el repositorio.
