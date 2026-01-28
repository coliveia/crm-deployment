# 🔧 Kubernetes Troubleshooting - ImagePullBackOff

## Erro: `Init:ImagePullBackOff`

### Problema

```bash
kubectl get pods -n crm-infrastructure
NAME                 READY   STATUS                  RESTARTS   AGE
kafka-controller-0   0/1     Init:ImagePullBackOff   0          7m
kafka-controller-1   0/1     Init:ImagePullBackOff   0          7m
kafka-controller-2   0/1     Init:ImagePullBackOff   0          7m
```

### Causa

O Kubernetes não consegue fazer **pull** da imagem do Kafka. Possíveis razões:

1. ❌ Sem acesso à internet (Docker Hub)
2. ❌ Imagem não encontrada
3. ❌ Problema de autenticação
4. ❌ Registry indisponível
5. ❌ Limite de rate no Docker Hub

---

## Diagnóstico

### Passo 1: Ver Detalhes do Pod

```bash
# Ver descrição completa
kubectl describe pod kafka-controller-0 -n crm-infrastructure

# Procurar por "Events" na saída
# Deve mostrar algo como:
# Warning  Failed     5m    kubelet  Failed to pull image "bitnami/kafka:latest": rpc error: code = Unknown desc = ...
```

### Passo 2: Ver Logs do Pod

```bash
# Ver logs
kubectl logs kafka-controller-0 -n crm-infrastructure

# Ver logs do init container
kubectl logs kafka-controller-0 -n crm-infrastructure -c init-container
```

### Passo 3: Testar Conectividade

```bash
# Entrar no node e testar pull
kubectl debug node/node-name -it --image=ubuntu

# Dentro do container debug:
docker pull bitnami/kafka:latest
```

---

## Soluções

### Solução 1: Usar Imagem Local (Mais Rápido)

Se você já tem a imagem Kafka localmente:

```bash
# Fazer tag da imagem
docker tag kafka:latest lazarusacr.azurecr.io/kafka:latest

# Push para ACR
docker push lazarusacr.azurecr.io/kafka:latest

# Atualizar Helm
helm upgrade --install kafka bitnami/kafka \
  --namespace crm-infrastructure \
  --create-namespace \
  --set auth.enabled=false \
  --set replicaCount=3 \
  --set image.repository=lazarusacr.azurecr.io/kafka \
  --set image.tag=latest \
  --wait
```

### Solução 2: Usar Imagem Alternativa (Confluent)

```bash
# Usar imagem Confluent (mais leve)
helm repo add confluentinc https://confluentinc.github.io/cp-helm-charts/
helm repo update

helm upgrade --install kafka confluentinc/cp-kafka \
  --namespace crm-infrastructure \
  --create-namespace \
  --set auth.enabled=false \
  --set replicaCount=3 \
  --wait
```

### Solução 3: Usar Imagem do Docker Hub com Retry

```bash
# Aumentar timeout e adicionar retry
helm upgrade --install kafka bitnami/kafka \
  --namespace crm-infrastructure \
  --create-namespace \
  --set auth.enabled=false \
  --set replicaCount=3 \
  --set image.pullPolicy=IfNotPresent \
  --set podAnnotations."container\.apparmor\.security\.beta\.kubernetes\.io/kafka"=runtime/default \
  --timeout 10m \
  --wait
```

### Solução 4: Usar docker-compose Localmente (Desenvolvimento)

Se o Kubernetes está com problemas, use docker-compose:

```bash
# De C:\workarea\CRM\crm-deployment\

docker-compose up -d kafka zookeeper redis

# Verificar
docker-compose ps
```

### Solução 5: Configurar Image Pull Secrets

Se usar ACR privado:

```bash
# Criar secret
kubectl create secret docker-registry acr-secret \
  --docker-server=lazarusacr.azurecr.io \
  --docker-username=<username> \
  --docker-password=<password> \
  -n crm-infrastructure

# Usar no Helm
helm upgrade --install kafka bitnami/kafka \
  --namespace crm-infrastructure \
  --create-namespace \
  --set auth.enabled=false \
  --set replicaCount=3 \
  --set imagePullSecrets[0].name=acr-secret \
  --wait
```

---

## Verificação de Conectividade

### Testar Acesso ao Docker Hub

```bash
# De sua máquina
docker pull bitnami/kafka:latest

# Se funcionar, o problema é no cluster
# Se não funcionar, problema é sua internet
```

### Testar Dentro do Cluster

```bash
# Criar pod de teste
kubectl run test-pod --image=ubuntu -it --rm -n crm-infrastructure -- bash

# Dentro do pod:
apt-get update && apt-get install -y curl
curl -I https://registry-1.docker.io

# Se não conectar, cluster não tem internet
```

---

## Solução Rápida para Desenvolvimento

### Usar docker-compose em vez de Kubernetes

```bash
cd C:\workarea\CRM\crm-deployment

# Parar Kafka no Kubernetes
helm uninstall kafka -n crm-infrastructure

# Iniciar com docker-compose
docker-compose up -d kafka zookeeper redis

# Verificar
docker-compose ps
docker-compose logs kafka
```

### Atualizar docker-compose.yml

```yaml
services:
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

  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    container_name: crm-zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    networks:
      - crm-network

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

---

## Comandos Úteis

### Limpar e Recomeçar

```bash
# Deletar release Helm
helm uninstall kafka -n crm-infrastructure

# Deletar namespace
kubectl delete namespace crm-infrastructure

# Recriar
kubectl create namespace crm-infrastructure

# Reinstalar
helm upgrade --install kafka bitnami/kafka \
  --namespace crm-infrastructure \
  --set auth.enabled=false \
  --set replicaCount=3 \
  --wait
```

### Ver Eventos do Pod

```bash
# Ver eventos recentes
kubectl get events -n crm-infrastructure --sort-by='.lastTimestamp'

# Ver eventos de um pod específico
kubectl describe pod kafka-controller-0 -n crm-infrastructure
```

### Forçar Pull de Imagem

```bash
# Deletar pod para forçar novo pull
kubectl delete pod kafka-controller-0 -n crm-infrastructure

# Kubernetes vai criar novo pod e tentar pull novamente
kubectl get pods -n crm-infrastructure -w
```

### Usar Imagem Local

```bash
# Se tiver imagem local, fazer load no cluster
docker save kafka:latest | kubectl exec -i -n crm-infrastructure kafka-controller-0 -- docker load

# Ou usar nodectl se disponível
kind load docker-image kafka:latest
```

---

## Checklist: Resolver ImagePullBackOff

- [ ] Verificar conectividade à internet
- [ ] Testar `docker pull bitnami/kafka:latest` localmente
- [ ] Ver logs do pod: `kubectl describe pod`
- [ ] Aumentar timeout do Helm
- [ ] Usar imagem alternativa (Confluent)
- [ ] Usar docker-compose para desenvolvimento
- [ ] Configurar Image Pull Secrets se usar ACR privado

---

## Recomendação para Desenvolvimento

Para MVP/desenvolvimento, **use docker-compose** em vez de Kubernetes:

```bash
# Simples e funciona offline
docker-compose up -d

# Testar
docker-compose ps
docker-compose logs -f kafka
```

Depois quando estiver pronto para produção, migre para Kubernetes com:
- Imagens pré-construídas
- Registry privado (ACR)
- Configuração de pull secrets

---

## Próximos Passos

1. **Opção A: Usar docker-compose** (Recomendado para MVP)
   ```bash
   docker-compose up -d kafka zookeeper redis
   ```

2. **Opção B: Corrigir Kubernetes**
   - Verificar conectividade
   - Usar imagem alternativa
   - Configurar pull secrets

3. **Opção C: Usar Kafka gerenciado**
   - Azure Event Hubs (compatível com Kafka)
   - AWS MSK
   - Confluent Cloud

Qual opção você prefere? 🚀
