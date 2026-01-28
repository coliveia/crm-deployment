# 🐳 Docker no Windows - Guia Completo para CRM+

## 📌 Entendendo o Comando Docker

Você tem razão em questionar! Vamos entender o que acontece:

```dockerfile
RUN mkdir -p /opt/oracle/wallet && chown -R appuser:appuser /opt/oracle/wallet
```

### O que este comando faz?

1. **`mkdir -p /opt/oracle/wallet`** - Cria o diretório (com -p cria diretórios pais se não existirem)
2. **`chown -R appuser:appuser`** - Muda o proprietário para o usuário `appuser` (recursivamente com -R)

### Por que isso é importante?

No Linux/Docker, os containers rodam como usuários específicos por segurança. Se o container rodar como `root`, qualquer vulnerabilidade pode comprometer todo o sistema. Por isso criamos um usuário `appuser` e damos permissões a ele.

---

## 🪟 Windows vs Linux - Diferenças Importantes

### No Windows (sua máquina):

| Aspecto | Windows | Linux/Docker |
|--------|---------|-------------|
| **Sistema de Arquivos** | NTFS | ext4/btrfs |
| **Permissões** | ACL (Access Control List) | rwx (read/write/execute) |
| **Usuários** | Contas Windows | Usuários do SO |
| **Docker Desktop** | Roda em VM Hyper-V/WSL2 | Roda nativamente |
| **Volumes** | Mapeados via WSL2 | Montados diretamente |

### O que acontece quando você roda Docker no Windows?

```
Seu Windows (NTFS)
        ↓
Docker Desktop (WSL2/Hyper-V)
        ↓
Container Linux (ext4)
        ↓
Aplicação Java rodando como 'appuser'
```

---

## 🔧 Como Funciona o Volume com Wallet

### Estrutura de Pastas no Windows:

```
C:\workarea\CRM\
├── crm-deployment\
│   ├── wallet\                    ← Aqui você coloca os arquivos do wallet
│   │   ├── cwallet.sso
│   │   ├── ewallet.p12
│   │   ├── ojdbc.properties
│   │   └── tnsnames.ora
│   ├── helm-charts\
│   ├── dockerfiles\
│   └── ...
```

### Mapeamento do Volume (docker-compose.yml):

```yaml
services:
  customer-service:
    build:
      context: ./dockerfiles
      dockerfile: Dockerfile.customer-service
    volumes:
      # Windows: C:\workarea\CRM\wallet → Container: /opt/oracle/wallet
      - ./wallet:/opt/oracle/wallet:ro
    environment:
      - TNS_ADMIN=/opt/oracle/wallet
```

### O que acontece:

1. **No Windows:** Você coloca arquivos em `C:\workarea\CRM\wallet\`
2. **Docker Desktop:** Converte para caminho Linux via WSL2
3. **No Container:** Aparece como `/opt/oracle/wallet`
4. **Permissões:** O `chown` no Dockerfile garante que `appuser` pode ler

---

## 🛠️ Passo a Passo: Setup Correto no Windows

### Passo 1: Extrair Wallet

```bash
# No PowerShell (como administrador)
cd C:\workarea\CRM\crm-deployment

# Extrair wallet
Expand-Archive -Path Wallet_crmdb.zip -DestinationPath wallet\
```

Você verá:
```
wallet/
├── cwallet.sso
├── ewallet.p12
├── ojdbc.properties
├── sqlnet.ora
├── tnsnames.ora
└── ...
```

### Passo 2: Verificar Permissões Windows

```bash
# Verificar permissões do diretório
icacls C:\workarea\CRM\wallet

# Se necessário, dar permissão total (cuidado!)
icacls C:\workarea\CRM\wallet /grant:r "%USERNAME%:F" /t
```

### Passo 3: Configurar Docker Desktop

**Configurações → Resources → File Sharing:**

Adicione:
- `C:\workarea` (ou o caminho onde está seu projeto)

Isso permite que Docker acesse seus arquivos Windows.

### Passo 4: Criar docker-compose.yml

```yaml
version: '3.8'

services:
  # Backend Services
  customer-service:
    build:
      context: ./dockerfiles
      dockerfile: Dockerfile.customer-service
    container_name: crm-customer-service
    ports:
      - "8081:8080"
    volumes:
      - ./wallet:/opt/oracle/wallet:ro
    environment:
      - ORACLE_URL=jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCPS)(HOST=gc557477e093c7a_crmdb_high.adb.oraclecloud.com)(PORT=1522))(CONNECT_DATA=(SERVICE_NAME=gc557477e093c7a_high.adb.oraclecloud.com)))
      - ORACLE_USER=admin
      - ORACLE_PASSWORD=CRM@Oracle26ai#2026!
      - TNS_ADMIN=/opt/oracle/wallet
      - KAFKA_BOOTSTRAP_SERVERS=kafka:9092
    depends_on:
      - kafka
      - redis
    networks:
      - crm-network

  # BFF Service
  bff-service:
    build:
      context: ./dockerfiles
      dockerfile: Dockerfile.bff-service
    container_name: crm-bff-service
    ports:
      - "3001:3001"
    environment:
      - CUSTOMER_SERVICE_URL=http://customer-service:8080
      - CASE_SERVICE_URL=http://case-service:8080
      - KAFKA_BOOTSTRAP_SERVERS=kafka:9092
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      - customer-service
      - kafka
      - redis
    networks:
      - crm-network

  # Kafka
  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: crm-kafka
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    depends_on:
      - zookeeper
    networks:
      - crm-network

  # Zookeeper
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    container_name: crm-zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_SYNC_LIMIT: 2
      ZOOKEEPER_INIT_LIMIT: 5
    networks:
      - crm-network

  # Redis
  redis:
    image: redis:7.0-alpine
    container_name: crm-redis
    ports:
      - "6379:6379"
    networks:
      - crm-network

networks:
  crm-network:
    driver: bridge
```

### Passo 5: Build e Run

```bash
# Build das imagens
docker-compose build

# Iniciar os containers
docker-compose up -d

# Verificar logs
docker-compose logs -f customer-service
```

---

## 🔐 Entendendo o `chown` no Dockerfile

### Por que `chown appuser:appuser`?

```dockerfile
# Criar usuário não-root
RUN useradd -m -u 1000 appuser

# Criar diretório
RUN mkdir -p /opt/oracle/wallet

# Dar permissão ao usuário
RUN chown -R appuser:appuser /opt/oracle/wallet

# Mudar para o usuário
USER appuser
```

### O que isso significa?

| Comando | Significado |
|---------|------------|
| `useradd -m -u 1000 appuser` | Cria usuário com ID 1000 |
| `mkdir -p /opt/oracle/wallet` | Cria diretório (pai se necessário) |
| `chown -R appuser:appuser` | Muda proprietário (recursivo) |
| `USER appuser` | Container roda como appuser, não root |

### No Windows, isso é importante porque:

1. **Segurança:** Container não roda como root
2. **Compatibilidade:** Funciona igual em Linux/Mac/Windows
3. **Permissões:** Garante que appuser pode ler o wallet

---

## 📝 Modificando Dockerfiles para Windows

### Opção 1: Usar como está (Recomendado)

O Dockerfile já está correto! Funciona igual em Windows/Mac/Linux.

```dockerfile
# Funciona em qualquer SO
RUN mkdir -p /opt/oracle/wallet && chown -R appuser:appuser /opt/oracle/wallet
```

### Opção 2: Simplificar para Desenvolvimento

Se quiser simplificar para desenvolvimento local:

```dockerfile
# Para desenvolvimento (menos seguro)
RUN mkdir -p /opt/oracle/wallet
# Pula o chown se rodar como root
```

Mas **não recomendo** para produção.

---

## 🚀 Workflow Completo no Windows

### 1. Preparar Ambiente

```bash
# PowerShell como Admin
cd C:\workarea\CRM\crm-deployment

# Extrair wallet
Expand-Archive -Path Wallet_crmdb.zip -DestinationPath wallet\

# Verificar estrutura
ls wallet\
```

### 2. Criar docker-compose.yml

Copie o arquivo acima para `crm-deployment/docker-compose.yml`

### 3. Build

```bash
docker-compose build --no-cache
```

### 4. Run

```bash
docker-compose up -d
```

### 5. Verificar

```bash
# Ver containers rodando
docker-compose ps

# Ver logs
docker-compose logs -f customer-service

# Testar conectividade
docker-compose exec customer-service curl http://localhost:8080/health
```

### 6. Parar

```bash
docker-compose down
```

---

## 🐛 Troubleshooting no Windows

### Problema: "Permission denied" ao acessar wallet

**Solução:**
```bash
# Verificar permissões Windows
icacls C:\workarea\CRM\wallet

# Dar permissão
icacls C:\workarea\CRM\wallet /grant:r "%USERNAME%:F" /t
```

### Problema: Docker não consegue acessar arquivo

**Solução:**
1. Abra Docker Desktop → Settings
2. Vá para Resources → File Sharing
3. Adicione `C:\workarea`
4. Clique Apply & Restart

### Problema: Container não inicia

**Solução:**
```bash
# Ver erro detalhado
docker-compose logs customer-service

# Verificar se porta está em uso
netstat -ano | findstr :8081

# Matar processo se necessário
taskkill /PID <PID> /F
```

### Problema: Wallet não encontrado no container

**Solução:**
```bash
# Verificar se volume está montado
docker-compose exec customer-service ls -la /opt/oracle/wallet

# Se vazio, verificar path no docker-compose.yml
# Deve ser: ./wallet:/opt/oracle/wallet:ro
```

---

## 📊 Diferenças: Docker Desktop vs WSL2

### Docker Desktop com WSL2 (Recomendado)

```
Windows (NTFS)
    ↓
WSL2 Linux (ext4)
    ↓
Docker Container
```

**Vantagens:**
- Melhor performance
- Suporte completo a Linux
- Volumes funcionam melhor

**Instalação:**
```bash
# Instalar WSL2
wsl --install

# Instalar Docker Desktop com WSL2 backend
# Download em: https://www.docker.com/products/docker-desktop
```

### Docker Desktop com Hyper-V (Legado)

```
Windows (NTFS)
    ↓
Hyper-V VM Linux
    ↓
Docker Container
```

**Desvantagens:**
- Performance menor
- Compatibilidade limitada

---

## ✅ Checklist para Windows

- [ ] Docker Desktop instalado
- [ ] WSL2 habilitado
- [ ] Wallet extraído em `C:\workarea\CRM\wallet\`
- [ ] Docker Desktop com acesso a `C:\workarea`
- [ ] docker-compose.yml criado
- [ ] Imagens buildadas com sucesso
- [ ] Containers rodando
- [ ] Wallet acessível dentro do container
- [ ] Conexão com Oracle funcionando

---

## 🔗 Recursos Úteis

- [Docker Desktop para Windows](https://docs.docker.com/desktop/install/windows-install/)
- [WSL2 Setup](https://docs.microsoft.com/en-us/windows/wsl/install)
- [Docker Volumes](https://docs.docker.com/storage/volumes/)
- [Docker Compose](https://docs.docker.com/compose/)

---

## 💡 Resumo Rápido

**O comando `chown` no Dockerfile:**
1. Cria um usuário não-root (`appuser`)
2. Dá permissão do diretório a esse usuário
3. Container roda como esse usuário por segurança
4. **No Windows:** Funciona igual, Docker Desktop traduz as permissões

**Para usar no Windows:**
1. Extraia o wallet em `wallet/`
2. Configure Docker Desktop para acessar a pasta
3. Use `docker-compose` com volumes mapeados
4. Tudo funciona igual em Windows/Mac/Linux!

---

**Dúvidas? Abra uma issue no repositório!**
