# 🔧 Vite vs Webpack - Guia Completo

## Diferenças Principais

| Aspecto | Webpack | Vite |
|--------|---------|------|
| **Tipo** | Bundler tradicional | Bundler moderno |
| **Velocidade Build** | Mais lenta | Muito rápida |
| **Dev Server** | Mais lento | Muito rápido (HMR) |
| **Configuração** | Complexa | Simples |
| **Suporte** | Amplo (legado) | Crescente |
| **Arquivo Config** | `webpack.config.js` | `vite.config.js` |
| **Build Script** | `npm run build` | `npm run build` |
| **Output** | `dist/` | `dist/` |

## Seu Projeto: Agent Portal

### Estrutura Atual

```
crm-agent-portal/
├── webpack.config.js      ← Você usa Webpack!
├── .babelrc               ← Configuração Babel
├── src/
│   ├── App.jsx
│   ├── index.js
│   └── components/
├── public/
│   └── index.html
├── package.json
└── dist/                  ← Output do build
```

### Dockerfile Correto para Webpack

```dockerfile
# Stage 1: Build
FROM node:22-alpine AS builder

WORKDIR /build

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy source code (importante: webpack.config.js e .babelrc)
COPY src ./src
COPY public ./public
COPY webpack.config.js ./
COPY .babelrc ./

# Build application with webpack
RUN npm run build

# Stage 2: Runtime
FROM nginx:alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built app from builder
COPY --from=builder /build/dist /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Run nginx
CMD ["nginx", "-g", "daemon off;"]
```

## Dockerfile Incorreto (Vite)

```dockerfile
# ❌ ERRADO - Vite
COPY vite.config.js ./        # Você não tem isso!
RUN npm run build             # Procura vite.config.js
```

## Dockerfile Correto (Webpack)

```dockerfile
# ✅ CORRETO - Webpack
COPY webpack.config.js ./     # Você tem isso!
COPY .babelrc ./              # Configuração Babel
RUN npm run build             # Usa webpack.config.js
```

## Como Verificar Qual Você Usa

### Opção 1: Verificar arquivo de configuração

```bash
# Se existe webpack.config.js → Webpack
# Se existe vite.config.js → Vite

ls webpack.config.js 2>/dev/null && echo "Webpack" || echo "Não encontrado"
ls vite.config.js 2>/dev/null && echo "Vite" || echo "Não encontrado"
```

### Opção 2: Verificar package.json

```json
{
  "devDependencies": {
    "webpack": "^5.x",           // ← Webpack
    "webpack-cli": "^5.x",
    "webpack-dev-server": "^4.x"
  }
}
```

vs

```json
{
  "devDependencies": {
    "vite": "^5.x"               // ← Vite
  }
}
```

### Opção 3: Verificar scripts no package.json

```json
{
  "scripts": {
    "build": "webpack",          // ← Webpack
    "dev": "webpack serve"
  }
}
```

vs

```json
{
  "scripts": {
    "build": "vite build",       // ← Vite
    "dev": "vite"
  }
}
```

## Seu Projeto: Webpack

### package.json

```json
{
  "scripts": {
    "build": "webpack",
    "dev": "webpack serve"
  },
  "devDependencies": {
    "webpack": "^5.x",
    "webpack-cli": "^5.x",
    "webpack-dev-server": "^4.x",
    "@babel/core": "^7.x",
    "@babel/preset-react": "^7.x"
  }
}
```

### webpack.config.js

```javascript
const path = require('path');

module.exports = {
  mode: 'production',
  entry: './src/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'bundle.js'
  },
  module: {
    rules: [
      {
        test: /\.jsx?$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader']
      }
    ]
  }
};
```

### .babelrc

```json
{
  "presets": [
    "@babel/preset-react",
    "@babel/preset-env"
  ]
}
```

## Build Process

### Webpack

```bash
npm install                    # Instala dependências
npm run build                  # Executa webpack
                              # Lê webpack.config.js
                              # Processa com Babel
                              # Gera dist/bundle.js
```

### Vite

```bash
npm install                    # Instala dependências
npm run build                  # Executa vite
                              # Lê vite.config.js
                              # Gera dist/index.html
```

## Dockerfile Correto para Seu Projeto

```dockerfile
# Stage 1: Build
FROM node:22-alpine AS builder

WORKDIR /build

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY src ./src
COPY public ./public
COPY webpack.config.js ./
COPY .babelrc ./

# Build application with webpack
RUN npm run build

# Stage 2: Runtime
FROM nginx:alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built app from builder
COPY --from=builder /build/dist /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Run nginx
CMD ["nginx", "-g", "daemon off;"]
```

## Build Local para Testar

```bash
# De C:\workarea\CRM\crm-agent-portal\

# Build
npm run build

# Verificar output
ls dist/

# Testar com nginx local
docker run -p 8080:80 -v %cd%\dist:/usr/share/nginx/html nginx:alpine
```

## Build com Docker

```bash
# De C:\workarea\CRM\

# Build
docker build -f crm-deployment/dockerfiles/Dockerfile.agent-portal-webpack `
  -t lazarusacr.azurecr.io/crm-agent-portal:latest `
  ./crm-agent-portal

# Run
docker run -p 5175:80 lazarusacr.azurecr.io/crm-agent-portal:latest
```

## Checklist

- [ ] Verificar que tem `webpack.config.js`
- [ ] Verificar que tem `.babelrc`
- [ ] Verificar que `npm run build` funciona localmente
- [ ] Usar Dockerfile com `webpack.config.js` (não vite)
- [ ] Copiar `public/` se existir
- [ ] Testar build local antes de Docker

## Resumo

**Seu projeto usa:** Webpack
**Dockerfile correto:** Dockerfile.agent-portal-webpack
**Arquivo config:** webpack.config.js
**Output:** dist/

Agora é só usar o Dockerfile correto e tudo funciona! 🚀
