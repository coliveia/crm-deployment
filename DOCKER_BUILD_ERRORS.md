# 🐛 Solução de Erros Comuns - Docker Build

## Erro 1: `addgroup: gid '1000' in use`

### Problema

```
ERROR [stage-1 4/8] RUN addgroup -g 1000 appuser && adduser -D -u 1000 -G appuser appuser:
0.493 addgroup: gid '1000' in use
```

### Causa

A imagem base `node:22-alpine` já possui um grupo com ID 1000 (geralmente o usuário `node`). Quando você tenta criar outro grupo com o mesmo ID, ocorre conflito.

### Solução

**Opção 1: Usar o usuário `node` que já existe (Recomendado)**

```dockerfile
FROM node:22-alpine

WORKDIR /app

# Use the existing 'node' user instead of creating a new one
USER node

COPY --chown=node:node package.json package-lock.json ./
RUN npm ci --only=production

COPY --chown=node:node . .

EXPOSE 3001

CMD ["node", "src/server.js"]
```

**Opção 2: Usar um ID diferente**

```dockerfile
FROM node:22-alpine

WORKDIR /app

# Create user with different ID (1001 instead of 1000)
RUN addgroup -g 1001 appuser && \
    adduser -D -u 1001 -G appuser appuser

COPY --chown=appuser:appuser package.json package-lock.json ./
RUN npm ci --only=production

COPY --chown=appuser:appuser . .

USER appuser

EXPOSE 3001

CMD ["node", "src/server.js"]
```

**Opção 3: Verificar antes de criar (Mais Robusto)**

```dockerfile
FROM node:22-alpine

WORKDIR /app

# Create user only if it doesn't exist
RUN id -u node > /dev/null 2>&1 || \
    (addgroup -g 1001 appuser && adduser -D -u 1001 -G appuser appuser)

# Use node user if it exists, otherwise use appuser
RUN if id -u node > /dev/null 2>&1; then \
      chown -R node:node /app; \
    else \
      chown -R appuser:appuser /app; \
    fi

COPY package.json package-lock.json ./
RUN npm ci --only=production

COPY . .

USER node

EXPOSE 3001

CMD ["node", "src/server.js"]
```

### Implementação no CRM+

Para o `crm-bff-service`, use:

```dockerfile
# Build stage
FROM node:22-alpine AS builder

WORKDIR /build

COPY package.json package-lock.json ./
RUN npm ci --only=production

# Runtime stage
FROM node:22-alpine

WORKDIR /app

RUN apk add --no-cache curl

# Copy from builder
COPY --from=builder --chown=node:node /build/node_modules ./node_modules

# Copy application code
COPY --chown=node:node . .

# Use existing node user
USER node

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3001/health || exit 1

CMD ["node", "src/server.js"]
```

---

## Erro 2: `COPY crm-customer-service/src: not found`

### Problema

```
ERROR: failed to solve: failed to compute cache key: failed to calculate checksum of ref 0d40d46b-f5b6-4adb-bc65-a2bc9b080470::hgtqmjmrf9ctryaz89dog3ejn: "/crm-customer-service/src": not found
```

### Causa

O Dockerfile está tentando copiar de um caminho que não existe relativo ao contexto de build.

### Solução

**Opção 1: Executar do diretório correto**

```bash
# De C:\workarea\CRM\
docker build -f crm-deployment/dockerfiles/Dockerfile.customer-service `
  -t lazarusacr.azurecr.io/crm-customer-service:latest `
  ./crm-customer-service
```

**Opção 2: Ajustar o Dockerfile**

Mudar de:
```dockerfile
COPY crm-customer-service/pom.xml .
COPY crm-customer-service/src ./src
```

Para:
```dockerfile
COPY pom.xml .
COPY src ./src
```

E executar de `crm-deployment/`:
```bash
docker build -f dockerfiles/Dockerfile.customer-service `
  -t lazarusacr.azurecr.io/crm-customer-service:latest `
  ../crm-customer-service
```

**Opção 3: Usar docker-compose (Mais Fácil)**

```bash
cd C:\workarea\CRM\crm-deployment
docker-compose build
```

---

## Erro 3: `port already in use`

### Problema

```
Error response from daemon: Ports are not available: exposing port TCP 0.0.0.0:8080 -> 0.0.0.0:0: listen tcp 0.0.0.0:8080: bind: An attempt was made to use a socket in a way forbidden by its access rules.
```

### Solução

**Opção 1: Liberar a porta**

```bash
# PowerShell como Admin
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

**Opção 2: Usar porta diferente**

```bash
docker run -p 8090:8080 crm-customer-service
```

**Opção 3: Parar containers anteriores**

```bash
docker-compose down
docker ps -a
docker rm <container-id>
```

---

## Erro 4: `permission denied`

### Problema

```
Error: EACCES: permission denied, open '/app/config.json'
```

### Solução

**Verificar permissões no Dockerfile:**

```dockerfile
# Garantir que o usuário tem permissão
RUN chown -R node:node /app
USER node
```

**No Windows, verificar permissões da pasta:**

```bash
icacls C:\workarea\CRM\wallet
icacls C:\workarea\CRM\wallet /grant:r "%USERNAME%:F" /t
```

---

## Erro 5: `npm ERR! code ERESOLVE`

### Problema

```
npm ERR! code ERESOLVE
npm ERR! ERESOLVE unable to resolve dependency tree
```

### Solução

```bash
# Usar --legacy-peer-deps
npm ci --legacy-peer-deps

# Ou no Dockerfile:
RUN npm ci --legacy-peer-deps --only=production
```

---

## Checklist de Build

- [ ] Executar do diretório correto
- [ ] Verificar se arquivo existe no contexto
- [ ] Não criar usuários/grupos que já existem
- [ ] Usar permissões corretas (chown)
- [ ] Liberar portas antes de build
- [ ] Verificar espaço em disco
- [ ] Limpar cache se necessário: `docker system prune -a`

---

## Comandos Úteis

```bash
# Ver imagens
docker images

# Ver containers
docker ps -a

# Ver logs
docker logs <container-id>

# Limpar tudo
docker system prune -a

# Build com cache desabilitado
docker build --no-cache -t image:tag .

# Inspecionar imagem
docker inspect <image-id>

# Entrar no container
docker run -it <image-id> /bin/sh
```

---

## Estrutura Correta para Build

### Estrutura de Diretórios

```
C:\workarea\CRM\
├── crm-deployment/
│   ├── dockerfiles/
│   │   ├── Dockerfile.customer-service
│   │   ├── Dockerfile.bff-service
│   │   └── ...
│   ├── docker-compose.yml
│   └── ...
├── crm-customer-service/
│   ├── src/
│   ├── pom.xml
│   └── ...
├── crm-bff-service/
│   ├── src/
│   ├── package.json
│   └── ...
└── ... outros repos
```

### Comandos Corretos

```bash
# De C:\workarea\CRM\
cd C:\workarea\CRM

# Build Java services
docker build -f crm-deployment/dockerfiles/Dockerfile.customer-service `
  -t lazarusacr.azurecr.io/crm-customer-service:latest `
  ./crm-customer-service

# Build Node services
cd crm-bff-service
docker build -t lazarusacr.azurecr.io/crm-bff-service:latest .

# Ou use docker-compose
cd crm-deployment
docker-compose build
```

---

## Próximos Passos

1. Corrigir o Dockerfile do BFF
2. Fazer build novamente
3. Testar containers localmente
4. Push para Azure Container Registry
5. Deploy no AKS

Sucesso! 🚀
