# CRM+ Deployment - Azure AKS com Oracle Autonomous Database

Este repositório contém todos os arquivos necessários para fazer deploy do ecossistema CRM+ no Azure Kubernetes Service (AKS) com conexão ao Oracle Autonomous Database na OCI.

## 📋 Estrutura do Projeto

```
crm-deployment/
├── dockerfiles/                    # Dockerfiles otimizados para cada serviço
│   ├── Dockerfile.customer-service
│   ├── Dockerfile.case-management-service
│   ├── Dockerfile.sla-management-service
│   ├── Dockerfile.interaction-service
│   ├── Dockerfile.workflow-engine-service
│   ├── Dockerfile.copilot-service
│   ├── Dockerfile.bff-service
│   ├── Dockerfile.agent-portal
│   ├── Dockerfile.workflow-admin-portal
│   └── nginx.conf                  # Configuração Nginx para frontends
│
├── helm-charts/                    # Helm Charts para deployment
│   ├── crm-backend/                # Backend services
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   ├── crm-bff/                    # BFF service
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   ├── crm-frontend/               # Frontend applications
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   ├── kafka/                      # Kafka configuration
│   │   └── values.yaml
│   └── redis/                      # Redis configuration
│       └── values.yaml
│
├── k8s-manifests/                  # Kubernetes manifests
│   ├── 01-namespaces.yaml
│   ├── 02-oracle-secrets.yaml
│   └── 03-configmaps.yaml
│
├── scripts/
│   └── deploy.sh                   # Script de deployment automático
│
├── DEPLOYMENT_GUIDE.md             # Guia passo a passo
├── DEPLOYMENT_ARCHITECTURE.md      # Arquitetura detalhada
└── README.md                       # Este arquivo
```

## 🚀 Quick Start

### Opção 1: Deployment Automático (Recomendado)

```bash
# 1. Clonar repositório
git clone <repository-url>
cd crm-deployment

# 2. Preparar wallet
unzip wallet_crmdb.zip -d ./wallet/

# 3. Executar deployment
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### Opção 2: Deployment Manual

Veja [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) para instruções detalhadas.

## 📦 Serviços Inclusos

### Backend Services (Java 21 + Spring Boot 3.2.1)
- **crm-customer-service** (porta 8081) - Visão 360 do cliente
- **crm-case-management-service** (porta 8080) - Gerenciamento de casos
- **crm-sla-management-service** (porta 8081) - Gerenciamento de SLA
- **crm-interaction-service** (porta 8084) - Registro de interações
- **crm-workflow-engine-service** (porta 8083) - Engine de workflows
- **crm-copilot-service** (porta 8084) - Assistente IA

### BFF Service (Node.js 22 + Express)
- **crm-bff-service** (porta 3001) - Backend for Frontend

### Frontend Services (React + Vite)
- **crm-agent-portal** (porta 80) - Portal de agentes
- **crm-workflow-admin-portal** (porta 80) - Admin de workflows

### Infrastructure Services
- **Kafka 3.5+** - Message broker
- **Redis 7.0+** - Cache e session store

## 🔧 Configuração

### Variáveis de Ambiente

#### Oracle Database
```
ORACLE_URL=jdbc:oracle:thin:@(DESCRIPTION=...)
ORACLE_USER=admin
ORACLE_PASSWORD=CRM@Oracle26ai#2026!
TNS_ADMIN=/opt/oracle/wallet/
```

#### Kafka
```
KAFKA_BOOTSTRAP_SERVERS=kafka-broker:9092
```

#### Redis
```
REDIS_HOST=redis-master
REDIS_PORT=6379
```

## 📊 Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure AKS Cluster                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              crm-frontend namespace                 │  │
│  │  ┌──────────────────┐  ┌──────────────────────────┐ │  │
│  │  │ Agent Portal     │  │ Workflow Admin Portal   │ │  │
│  │  │ (React + Nginx)  │  │ (React + Nginx)        │ │  │
│  │  └──────────────────┘  └──────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────┘  │
│                           ↓                                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              crm-backend namespace                  │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │         crm-bff-service (Node.js)           │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │                      ↓                              │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │         Backend Services (Java/Spring)       │ │  │
│  │  │  ┌──────────────┐  ┌──────────────────────┐  │ │  │
│  │  │  │  Customer    │  │  Case Management    │  │ │  │
│  │  │  │  Service     │  │  Service            │  │ │  │
│  │  │  └──────────────┘  └──────────────────────┘  │ │  │
│  │  │  ┌──────────────┐  ┌──────────────────────┐  │ │  │
│  │  │  │  SLA Mgmt    │  │  Interaction        │  │ │  │
│  │  │  │  Service     │  │  Service            │  │ │  │
│  │  │  └──────────────┘  └──────────────────────┘  │ │  │
│  │  │  ┌──────────────┐  ┌──────────────────────┐  │ │  │
│  │  │  │  Workflow    │  │  Copilot            │  │ │  │
│  │  │  │  Engine      │  │  Service            │  │ │  │
│  │  │  └──────────────┘  └──────────────────────┘  │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────┘  │
│                           ↓                                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          crm-infrastructure namespace              │  │
│  │  ┌──────────────────┐  ┌──────────────────────────┐ │  │
│  │  │  Kafka Broker    │  │  Redis Master           │ │  │
│  │  │  (3 replicas)    │  │  (2 replicas)          │ │  │
│  │  └──────────────────┘  └──────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│        Oracle Autonomous Database (OCI)                    │
│  - Duality Views para acesso relacional/JSON               │
│  - mTLS com Oracle Wallet                                  │
│  - 2 ECPUs, 20GB storage                                   │
└─────────────────────────────────────────────────────────────┘
```

## 📝 Pré-requisitos

- Azure CLI
- kubectl
- Helm 3+
- Docker
- Git
- Oracle Wallet (extraído)

## 🔐 Segurança

- Todos os serviços rodam como usuários não-root
- Network Policies habilitadas
- Secrets criptografados
- RBAC configurado
- Security contexts aplicados

## 📈 Escalabilidade

- HPA (Horizontal Pod Autoscaler) configurado
- Min/Max replicas definidos
- Métricas de CPU e memória monitoradas
- Load balancing automático

## 🔍 Monitoramento

- Prometheus para coleta de métricas
- Grafana para dashboards
- Health checks em todos os serviços
- Logs centralizados

## 🐛 Troubleshooting

Veja [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md#verificação-e-troubleshooting) para soluções de problemas comuns.

## 📚 Documentação

- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Guia passo a passo completo
- [DEPLOYMENT_ARCHITECTURE.md](./DEPLOYMENT_ARCHITECTURE.md) - Arquitetura detalhada

## 🤝 Contribuindo

1. Clone o repositório
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📞 Suporte

Para suporte, abra uma issue no repositório ou entre em contato com o time de DevOps.

## 📄 Licença

Proprietary - CRM+ Platform

## 🎯 Roadmap

- [ ] CI/CD com GitHub Actions
- [ ] Monitoring completo (Prometheus + Grafana)
- [ ] Logging centralizado (ELK/Loki)
- [ ] Backup automático
- [ ] Disaster Recovery
- [ ] Multi-region deployment

---

**Última atualização:** 27/01/2026
**Versão:** 1.0.0
