# Guia Passo a Passo - Deployment CRM+ no Azure AKS

## Índice
1. [Pré-requisitos](#pré-requisitos)
2. [Preparação do Ambiente](#preparação-do-ambiente)
3. [Build das Imagens Docker](#build-das-imagens-docker)
4. [Deployment Automático](#deployment-automático)
5. [Deployment Manual](#deployment-manual)
6. [Verificação e Troubleshooting](#verificação-e-troubleshooting)
7. [Acessar as Aplicações](#acessar-as-aplicações)

---

## Pré-requisitos

### Ferramentas Necessárias
Instale as seguintes ferramentas em sua máquina:

```bash
# 1. Azure CLI
# Windows: https://aka.ms/installazurecliwindows
# macOS: brew install azure-cli
# Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 2. kubectl
# https://kubernetes.io/docs/tasks/tools/

# 3. Helm
# https://helm.sh/docs/intro/install/

# 4. Docker
# https://docs.docker.com/get-docker/

# Verificar instalações
az --version
kubectl version --client
helm version
docker --version
```

### Credenciais Necessárias
- **Azure Subscription ID**
- **Azure Resource Group:** `rg-core-lazarus`
- **AKS Cluster Name:** `lazaruskube`
- **ACR Name:** `lazarusacr`
- **Oracle Wallet:** Extraído em `./wallet/`

---

## Preparação do Ambiente

### Passo 1: Clonar Repositórios

```bash
# Criar diretório de trabalho
mkdir -p ~/crm-deployment && cd ~/crm-deployment

# Clonar repositórios (configure SSH key ou use GitHub CLI)
# Opção 1: SSH (recomendado)
git clone git@github.com:coliveia/crm-case-management-service.git
git clone git@github.com:coliveia/crm-bff-service.git
git clone git@github.com:coliveia/crm-customer-service.git
git clone git@github.com:coliveia/crm-sla-management-service.git
git clone git@github.com:coliveia/crm-interaction-service.git
git clone git@github.com:coliveia/crm-workflow-engine-service.git
git clone git@github.com:coliveia/crm-copilot-service.git
git clone git@github.com:coliveia/crm-agent-portal.git
git clone git@github.com:coliveia/crm-workflow-admin-portal.git

# Opção 2: GitHub CLI
# gh repo clone coliveia/crm-case-management-service
# gh repo clone coliveia/crm-bff-service
# ... etc
```

### Passo 2: Extrair Oracle Wallet

```bash
# Descompactar o arquivo wallet
unzip -d ./wallet/ wallet_crmdb.zip

# Verificar arquivos
ls -la ./wallet/
# Deve conter: cwallet.sso, ewallet.p12, ewallet.pem, keystore.jks, truststore.jks, ojdbc.properties, sqlnet.ora, tnsnames.ora
```

### Passo 3: Copiar Estrutura de Deployment

```bash
# Os arquivos já devem estar em /home/ubuntu/crm-deployment/
# Verificar estrutura
tree crm-deployment/
```

---

## Build das Imagens Docker

### Opção 1: Build Automático (Recomendado)

```bash
cd /home/ubuntu/crm-deployment

# Executar script de deployment completo
./scripts/deploy.sh
```

### Opção 2: Build Manual

#### Passo 1: Login no Azure e ACR

```bash
# Login no Azure
az login

# Login no ACR
az acr login --name lazarusacr

# Obter URL do ACR
ACR_URL=$(az acr show --resource-group rg-core-lazarus --name lazarusacr --query loginServer --output tsv)
echo $ACR_URL
# Resultado: lazarusacr.azurecr.io
```

#### Passo 2: Build Backend Services

```bash
cd /home/ubuntu/crm-deployment

# Definir variáveis
ACR_URL="lazarusacr.azurecr.io"

# Build crm-customer-service
docker build -f dockerfiles/Dockerfile.customer-service \
  -t $ACR_URL/crm-customer-service:latest \
  -t $ACR_URL/crm-customer-service:1.0.0 \
  ../crm-customer-service

docker push $ACR_URL/crm-customer-service:latest
docker push $ACR_URL/crm-customer-service:1.0.0

# Build crm-case-management-service
docker build -f dockerfiles/Dockerfile.case-management-service \
  -t $ACR_URL/crm-case-management-service:latest \
  -t $ACR_URL/crm-case-management-service:1.0.0 \
  ../crm-case-management-service

docker push $ACR_URL/crm-case-management-service:latest
docker push $ACR_URL/crm-case-management-service:1.0.0

# Build crm-sla-management-service
docker build -f dockerfiles/Dockerfile.sla-management-service \
  -t $ACR_URL/crm-sla-management-service:latest \
  -t $ACR_URL/crm-sla-management-service:1.0.0 \
  ../crm-sla-management-service

docker push $ACR_URL/crm-sla-management-service:latest
docker push $ACR_URL/crm-sla-management-service:1.0.0

# Build crm-interaction-service
docker build -f dockerfiles/Dockerfile.interaction-service \
  -t $ACR_URL/crm-interaction-service:latest \
  -t $ACR_URL/crm-interaction-service:1.0.0 \
  ../crm-interaction-service

docker push $ACR_URL/crm-interaction-service:latest
docker push $ACR_URL/crm-interaction-service:1.0.0

# Build crm-workflow-engine-service
docker build -f dockerfiles/Dockerfile.workflow-engine-service \
  -t $ACR_URL/crm-workflow-engine-service:latest \
  -t $ACR_URL/crm-workflow-engine-service:1.0.0 \
  ../crm-workflow-engine-service

docker push $ACR_URL/crm-workflow-engine-service:latest
docker push $ACR_URL/crm-workflow-engine-service:1.0.0

# Build crm-copilot-service
docker build -f dockerfiles/Dockerfile.copilot-service \
  -t $ACR_URL/crm-copilot-service:latest \
  -t $ACR_URL/crm-copilot-service:1.0.0 \
  ../crm-copilot-service

docker push $ACR_URL/crm-copilot-service:latest
docker push $ACR_URL/crm-copilot-service:1.0.0
```

#### Passo 3: Build BFF Service

```bash
# Build crm-bff-service
docker build -f dockerfiles/Dockerfile.bff-service \
  -t $ACR_URL/crm-bff-service:latest \
  -t $ACR_URL/crm-bff-service:1.0.0 \
  ../crm-bff-service

docker push $ACR_URL/crm-bff-service:latest
docker push $ACR_URL/crm-bff-service:1.0.0
```

#### Passo 4: Build Frontend Services

```bash
# Build crm-agent-portal
docker build -f dockerfiles/Dockerfile.agent-portal \
  -t $ACR_URL/crm-agent-portal:latest \
  -t $ACR_URL/crm-agent-portal:1.0.0 \
  ../crm-agent-portal

docker push $ACR_URL/crm-agent-portal:latest
docker push $ACR_URL/crm-agent-portal:1.0.0

# Build crm-workflow-admin-portal
docker build -f dockerfiles/Dockerfile.workflow-admin-portal \
  -t $ACR_URL/crm-workflow-admin-portal:latest \
  -t $ACR_URL/crm-workflow-admin-portal:1.0.0 \
  ../crm-workflow-admin-portal

docker push $ACR_URL/crm-workflow-admin-portal:latest
docker push $ACR_URL/crm-workflow-admin-portal:1.0.0
```

---

## Deployment Automático

### Executar Script de Deployment

```bash
cd /home/ubuntu/crm-deployment

# Tornar executável
chmod +x scripts/deploy.sh

# Executar deployment
./scripts/deploy.sh
```

O script irá:
1. ✅ Verificar pré-requisitos
2. ✅ Configurar credenciais Azure
3. ✅ Configurar credenciais ACR
4. ✅ Build todas as imagens Docker
5. ✅ Criar namespaces Kubernetes
6. ✅ Criar secrets (Oracle credentials e Wallet)
7. ✅ Criar ConfigMaps
8. ✅ Deploy Kafka
9. ✅ Deploy Redis
10. ✅ Deploy Backend Services
11. ✅ Deploy BFF
12. ✅ Deploy Frontend
13. ✅ Verificar deployment

---

## Deployment Manual

### Passo 1: Conectar ao AKS

```bash
# Login no Azure
az login

# Obter credenciais do AKS
az aks get-credentials \
  --resource-group rg-core-lazarus \
  --name lazaruskube \
  --overwrite-existing

# Verificar conexão
kubectl cluster-info
kubectl get nodes
```

### Passo 2: Criar Namespaces

```bash
kubectl apply -f k8s-manifests/01-namespaces.yaml

# Verificar
kubectl get namespaces | grep crm
```

### Passo 3: Criar Secrets

```bash
# Secret de credenciais Oracle
kubectl create secret generic oracle-credentials \
  --from-literal=jdbc-url='jdbc:oracle:thin:@(DESCRIPTION=(RETRY_COUNT=20)(RETRY_DELAY=3)(ADDRESS=(PROTOCOL=tcps)(PORT=1522)(HOST=adb.us-ashburn-1.oraclecloud.com))(CONNECT_DATA=(SERVICE_NAME=gc557477e093c7a_crmdb_high.adb.oraclecloud.com))(SECURITY=(SSL_SERVER_DN_MATCH=yes)))' \
  --from-literal=username='admin' \
  --from-literal=password='CRM@Oracle26ai#2026!' \
  -n crm-backend

# Secret do Oracle Wallet
kubectl create secret generic oracle-wallet \
  --from-file=./wallet/ \
  -n crm-backend

# Secret do ACR (para pull de imagens)
ACR_USERNAME=$(az acr credential show --resource-group rg-core-lazarus --name lazarusacr --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --resource-group rg-core-lazarus --name lazarusacr --query passwords[0].value --output tsv)

kubectl create secret docker-registry acr-secret \
  --docker-server=lazarusacr.azurecr.io \
  --docker-username=$ACR_USERNAME \
  --docker-password=$ACR_PASSWORD \
  --docker-email=admin@example.com \
  -n crm-backend

# Verificar secrets
kubectl get secrets -n crm-backend
```

### Passo 4: Criar ConfigMaps

```bash
kubectl apply -f k8s-manifests/03-configmaps.yaml

# Verificar
kubectl get configmaps -n crm-backend
```

### Passo 5: Deploy Kafka

```bash
# Adicionar Helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Deploy Kafka
helm upgrade --install kafka bitnami/kafka \
  --namespace crm-infrastructure \
  --create-namespace \
  --set auth.enabled=false \
  --set replicaCount=3 \
  --wait

# Verificar
kubectl get pods -n crm-infrastructure
```

### Passo 6: Deploy Redis

```bash
# Deploy Redis
helm upgrade --install redis bitnami/redis \
  --namespace crm-infrastructure \
  --create-namespace \
  --set auth.enabled=false \
  --set replica.replicaCount=2 \
  --wait

# Verificar
kubectl get pods -n crm-infrastructure
```

### Passo 7: Deploy Backend Services

```bash
# Deploy com Helm
helm upgrade --install crm-backend helm-charts/crm-backend \
  --namespace crm-backend \
  --create-namespace \
  --values helm-charts/crm-backend/values.yaml \
  --wait

# Verificar
kubectl get pods -n crm-backend
kubectl get svc -n crm-backend
```

### Passo 8: Deploy BFF

```bash
helm upgrade --install crm-bff helm-charts/crm-bff \
  --namespace crm-backend \
  --values helm-charts/crm-bff/values.yaml \
  --wait

# Verificar
kubectl get pods -n crm-backend | grep bff
```

### Passo 9: Deploy Frontend

```bash
helm upgrade --install crm-frontend helm-charts/crm-frontend \
  --namespace crm-frontend \
  --create-namespace \
  --values helm-charts/crm-frontend/values.yaml \
  --wait

# Verificar
kubectl get pods -n crm-frontend
kubectl get svc -n crm-frontend
```

---

## Verificação e Troubleshooting

### Verificar Status dos Pods

```bash
# Todos os pods
kubectl get pods -A

# Pods específicos
kubectl get pods -n crm-backend
kubectl get pods -n crm-frontend
kubectl get pods -n crm-infrastructure

# Detalhes de um pod
kubectl describe pod <pod-name> -n <namespace>
```

### Ver Logs

```bash
# Logs de um pod
kubectl logs -n crm-backend <pod-name>

# Logs em tempo real
kubectl logs -f -n crm-backend <pod-name>

# Logs de um container específico
kubectl logs -n crm-backend <pod-name> -c <container-name>

# Logs de todos os pods de um deployment
kubectl logs -n crm-backend -l app=crm-customer-service
```

### Troubleshooting Comum

#### Pod não está iniciando

```bash
# Verificar eventos
kubectl describe pod <pod-name> -n crm-backend

# Verificar logs
kubectl logs <pod-name> -n crm-backend

# Verificar recursos
kubectl top nodes
kubectl top pods -n crm-backend
```

#### Problema de conexão com Oracle

```bash
# Verificar se o secret do wallet foi criado
kubectl get secret oracle-wallet -n crm-backend

# Verificar se o secret de credenciais foi criado
kubectl get secret oracle-credentials -n crm-backend

# Testar conexão (dentro do pod)
kubectl exec -it <pod-name> -n crm-backend -- bash
# Dentro do pod:
sqlplus admin@crmdb_high
```

#### Problema de conectividade entre serviços

```bash
# Testar DNS
kubectl run -it --rm debug --image=busybox --restart=Never -n crm-backend -- nslookup crm-customer-service

# Testar conectividade
kubectl run -it --rm debug --image=busybox --restart=Never -n crm-backend -- nc -zv crm-customer-service 8081

# Verificar services
kubectl get svc -n crm-backend
```

### Escalabilidade

```bash
# Verificar HPA
kubectl get hpa -n crm-backend

# Verificar métricas
kubectl top pods -n crm-backend

# Escalar manualmente
kubectl scale deployment crm-customer-service --replicas=3 -n crm-backend
```

---

## Acessar as Aplicações

### Port-Forward (Acesso Local)

```bash
# Agent Portal
kubectl port-forward -n crm-frontend svc/crm-agent-portal 5175:80
# Acesse: http://localhost:5175

# Workflow Admin Portal
kubectl port-forward -n crm-frontend svc/crm-workflow-admin-portal 5173:80
# Acesse: http://localhost:5173

# BFF Service
kubectl port-forward -n crm-backend svc/crm-bff-service 3001:3001
# Acesse: http://localhost:3001
```

### Via Ingress (Acesso Externo)

```bash
# Instalar NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer

# Instalar cert-manager (para SSL)
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true

# Criar ClusterIssuer para Let's Encrypt
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Atualizar Ingress com domínio real
# Editar helm-charts/crm-frontend/values.yaml
# Alterar hosts e tls

helm upgrade crm-frontend helm-charts/crm-frontend \
  --namespace crm-frontend \
  --values helm-charts/crm-frontend/values.yaml

# Obter IP externo
kubectl get svc -n ingress-nginx
```

### Endpoints Disponíveis

| Aplicação | URL | Descrição |
|-----------|-----|-----------|
| Agent Portal | http://crm-agent.example.com | Portal de agentes (modernizado) |
| Workflow Admin | http://crm-workflow.example.com | Admin de workflows (design futurístico) |
| BFF API | http://api.crm.example.com | Backend for Frontend |
| Prometheus | http://prometheus.crm.example.com | Métricas |
| Grafana | http://grafana.crm.example.com | Dashboards |

---

## Próximos Passos

1. **Configurar DNS**: Apontar domínios para o IP do LoadBalancer
2. **Configurar SSL**: Usar cert-manager com Let's Encrypt
3. **Monitoramento**: Deploy Prometheus e Grafana
4. **Logging**: Deploy ELK Stack ou Loki
5. **Backup**: Configurar backup do Oracle Database
6. **CI/CD**: Configurar GitHub Actions para deploy automático

---

## Comandos Úteis

```bash
# Listar todos os recursos
kubectl get all -n crm-backend

# Deletar um deployment
kubectl delete deployment crm-customer-service -n crm-backend

# Deletar um namespace (cuidado!)
kubectl delete namespace crm-backend

# Atualizar um Helm Chart
helm upgrade crm-backend helm-charts/crm-backend -n crm-backend

# Rollback de um Helm Chart
helm rollback crm-backend -n crm-backend

# Ver histórico de deployments
helm history crm-backend -n crm-backend

# Executar comando dentro de um pod
kubectl exec -it <pod-name> -n crm-backend -- /bin/bash

# Copiar arquivo de/para pod
kubectl cp crm-backend/<pod-name>:/path/to/file ./local/path
kubectl cp ./local/path crm-backend/<pod-name>:/path/to/file
```

---

## Suporte

Para mais informações:
- [Documentação Kubernetes](https://kubernetes.io/docs/)
- [Documentação Helm](https://helm.sh/docs/)
- [Documentação Azure AKS](https://docs.microsoft.com/en-us/azure/aks/)
- [Documentação Oracle Database](https://docs.oracle.com/en/database/)
