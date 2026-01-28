# ✅ Checklist de Deployment - CRM+ no Azure AKS

## 📋 Pré-Deployment

### Preparação do Ambiente Local
- [ ] Azure CLI instalado e configurado
- [ ] kubectl instalado e configurado
- [ ] Helm 3+ instalado
- [ ] Docker instalado e rodando
- [ ] Git configurado com token

### Credenciais e Acesso
- [ ] Acesso à Azure Subscription
- [ ] Acesso ao Resource Group `rg-core-lazarus`
- [ ] Acesso ao AKS Cluster `lazaruskube`
- [ ] Acesso ao ACR `lazarusacr`
- [ ] Credenciais do Oracle Database
- [ ] Oracle Wallet extraído em `./wallet/`

### Repositórios
- [ ] Todos os 9 repositórios clonados
- [ ] Token Git válido
- [ ] Branches corretas (`main`)

---

## 🏗️ Preparação da Infraestrutura

### Azure AKS
- [ ] Cluster AKS criado
- [ ] 2 node pools configurados (nodepool e agentpool)
- [ ] Versão Kubernetes 1.32.9+
- [ ] Network policies habilitadas

### ACR (Azure Container Registry)
- [ ] Registro criado
- [ ] Credenciais obtidas
- [ ] Quotas suficientes

### Oracle Database
- [ ] Base Autonomous criada
- [ ] Duality Views configuradas
- [ ] Wallet gerado e extraído
- [ ] Firewall configurado para AKS

---

## 🐳 Build das Imagens Docker

### Backend Services
- [ ] crm-customer-service (Java 21)
- [ ] crm-case-management-service (Java 21)
- [ ] crm-sla-management-service (Java 21)
- [ ] crm-interaction-service (Java 21)
- [ ] crm-workflow-engine-service (Java 21)
- [ ] crm-copilot-service (Java 21)

### BFF Service
- [ ] crm-bff-service (Node.js 22)

### Frontend Services
- [ ] crm-agent-portal (React + Vite)
- [ ] crm-workflow-admin-portal (React + Vite)

### Verificação
- [ ] Todas as imagens no ACR
- [ ] Tags corretas (latest, 1.0.0)
- [ ] Tamanho das imagens aceitável

---

## 🚀 Deployment no AKS

### Namespaces
- [ ] crm (namespace geral)
- [ ] crm-backend (serviços backend)
- [ ] crm-frontend (aplicações frontend)
- [ ] crm-infrastructure (Kafka, Redis)
- [ ] crm-monitoring (Prometheus, Grafana)

### Secrets
- [ ] oracle-credentials criado
- [ ] oracle-wallet criado
- [ ] acr-secret criado
- [ ] Todos os secrets em crm-backend

### ConfigMaps
- [ ] crm-backend-config criado
- [ ] crm-bff-config criado
- [ ] crm-frontend-config criado

### Infrastructure
- [ ] Kafka deployado (3 replicas)
- [ ] Redis deployado (2 replicas)
- [ ] Ambos em crm-infrastructure namespace

### Backend Services
- [ ] crm-customer-service deployado
- [ ] crm-case-management-service deployado
- [ ] crm-sla-management-service deployado
- [ ] crm-interaction-service deployado
- [ ] crm-workflow-engine-service deployado
- [ ] crm-copilot-service deployado
- [ ] Todos com 2 replicas
- [ ] Health checks passando

### BFF Service
- [ ] crm-bff-service deployado
- [ ] 2 replicas rodando
- [ ] Conectando em todos os backends
- [ ] Health check passando

### Frontend
- [ ] crm-agent-portal deployado
- [ ] crm-workflow-admin-portal deployado
- [ ] Ambos com 1+ replicas
- [ ] Health checks passando

---

## ✅ Verificações Pós-Deployment

### Pods
- [ ] Todos os pods em status `Running`
- [ ] Nenhum pod em `CrashLoopBackOff`
- [ ] Nenhum pod em `Pending`
- [ ] Nenhum pod com restarts excessivos

### Services
- [ ] Todos os services criados
- [ ] ClusterIP atribuído
- [ ] Endpoints corretos

### Conectividade
- [ ] Backend services comunicando com Oracle
- [ ] BFF comunicando com backends
- [ ] Frontend comunicando com BFF
- [ ] Kafka acessível
- [ ] Redis acessível

### Logs
- [ ] Nenhum erro crítico nos logs
- [ ] Aplicações iniciadas corretamente
- [ ] Conexão com Oracle estabelecida

### Recursos
- [ ] CPU requests/limits configurados
- [ ] Memory requests/limits configurados
- [ ] HPA funcionando corretamente
- [ ] Nenhum pod excedendo limites

---

## 🔐 Segurança

### RBAC
- [ ] Service accounts criados
- [ ] Roles configurados
- [ ] RoleBindings aplicados

### Network Policies
- [ ] Network policies habilitadas
- [ ] Tráfego entre namespaces controlado
- [ ] Ingress/Egress configurados

### Secrets
- [ ] Todos os secrets criptografados
- [ ] Nenhuma senha em logs
- [ ] Nenhuma senha em ConfigMaps

### Security Context
- [ ] Todos os containers rodando como non-root
- [ ] Capabilities dropadas
- [ ] Read-only filesystem onde possível

---

## 📊 Monitoramento

### Métricas
- [ ] Prometheus coletando métricas
- [ ] Endpoints `/metrics` respondendo
- [ ] Métricas de negócio sendo coletadas

### Logs
- [ ] Logs sendo gerados corretamente
- [ ] Nível de log apropriado
- [ ] Logs centralizados (opcional)

### Alertas
- [ ] Alertas configurados para falhas
- [ ] Alertas para uso de recursos
- [ ] Notificações funcionando

---

## 🌐 Acesso Externo

### Ingress
- [ ] Ingress controller instalado
- [ ] Ingress rules criadas
- [ ] DNS configurado

### SSL/TLS
- [ ] Certificados gerados
- [ ] HTTPS funcionando
- [ ] Certificados válidos

### Endpoints
- [ ] Agent Portal acessível
- [ ] Workflow Admin acessível
- [ ] BFF API acessível

---

## 🔄 Escalabilidade

### HPA
- [ ] HPA criado para cada serviço
- [ ] Min/Max replicas corretos
- [ ] Métricas de CPU/Memory configuradas

### Load Testing
- [ ] Testes de carga realizados
- [ ] Autoscaling funcionando
- [ ] Performance aceitável

---

## 📝 Documentação

### Documentação Criada
- [ ] README.md completo
- [ ] DEPLOYMENT_GUIDE.md detalhado
- [ ] DEPLOYMENT_ARCHITECTURE.md
- [ ] Runbooks para troubleshooting

### Documentação Atualizada
- [ ] Diagrama de arquitetura
- [ ] Matriz de dependências
- [ ] Plano de backup/recovery
- [ ] Plano de disaster recovery

---

## 🎯 Testes Finais

### Testes Funcionais
- [ ] Agent Portal carregando
- [ ] Workflow Admin carregando
- [ ] BFF respondendo
- [ ] Casos carregando
- [ ] Workflows criáveis

### Testes de Integração
- [ ] Frontend → BFF → Backend
- [ ] Backend → Oracle Database
- [ ] Kafka funcionando
- [ ] Redis funcionando

### Testes de Resiliência
- [ ] Pod restart automático
- [ ] Service recovery
- [ ] Database failover
- [ ] Network partition handling

---

## 📋 Handover

### Documentação Entregue
- [ ] Guias de operação
- [ ] Guias de troubleshooting
- [ ] Runbooks de incident
- [ ] Planos de manutenção

### Treinamento
- [ ] Time de DevOps treinado
- [ ] Time de Suporte treinado
- [ ] Documentação revisada

### Suporte
- [ ] Contato de suporte definido
- [ ] SLA definido
- [ ] Escalation path definido

---

## 🎉 Go-Live

- [ ] Todos os itens acima completados
- [ ] Aprovação final obtida
- [ ] Backup realizado
- [ ] Rollback plan testado
- [ ] **DEPLOYMENT AUTORIZADO** ✅

---

## 📞 Contatos de Emergência

| Papel | Nome | Telefone | Email |
|------|------|----------|-------|
| DevOps Lead | | | |
| DBA | | | |
| Arquiteto | | | |
| Suporte 24/7 | | | |

---

**Data de Deployment:** ___/___/______
**Aprovado por:** _____________________
**Executado por:** _____________________
**Verificado por:** _____________________

---

*Última atualização: 27/01/2026*
