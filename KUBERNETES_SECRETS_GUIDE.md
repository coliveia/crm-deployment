# 🔐 Kubernetes Secrets - Guia Completo

## Erro: `The system cannot find the file specified`

### Problema

```bash
kubectl create secret generic oracle-wallet --from-file=./wallet/ -n crm-backend
error: error reading ./wallet/: The system cannot find the file specified.
```

### Causa

A pasta `wallet/` não existe em `C:\workarea\CRM\crm-deployment\`

### Solução

Você precisa extrair o arquivo `Wallet_crmdb.zip` primeiro.

---

## Passo a Passo: Criar Secrets no Kubernetes

### Passo 1: Preparar o Diretório

```bash
# De C:\workarea\CRM\crm-deployment\

# Criar pasta wallet se não existir
mkdir wallet

# Verificar se existe
ls wallet/
```

### Passo 2: Extrair o Wallet

**Opção 1: PowerShell (Recomendado)**

```powershell
# De C:\workarea\CRM\crm-deployment\

# Extrair o zip
Expand-Archive -Path ..\Wallet_crmdb.zip -DestinationPath wallet\ -Force

# Verificar conteúdo
ls wallet/
```

**Opção 2: Windows Explorer**

1. Localize `C:\workarea\CRM\Wallet_crmdb.zip`
2. Clique direito → "Extrair tudo..."
3. Destino: `C:\workarea\CRM\crm-deployment\wallet\`
4. Clique "Extrair"

**Opção 3: Command Prompt**

```cmd
cd C:\workarea\CRM\crm-deployment
tar -xf ..\Wallet_crmdb.zip -C wallet\
```

### Passo 3: Verificar Conteúdo

```bash
# Listar arquivos do wallet
ls wallet/

# Deve ter:
# - cwallet.sso
# - ewallet.p12
# - ojdbc.properties
# - sqlnet.ora
# - tnsnames.ora
# - truststore.jks (opcional)
```

### Passo 4: Criar Namespace (se não existir)

```bash
# Criar namespace crm-backend
kubectl create namespace crm-backend

# Verificar
kubectl get namespaces
```

### Passo 5: Criar Secret do Wallet

```bash
# De C:\workarea\CRM\crm-deployment\

# Criar secret
kubectl create secret generic oracle-wallet \
  --from-file=./wallet/ \
  -n crm-backend

# Verificar
kubectl get secrets -n crm-backend
kubectl describe secret oracle-wallet -n crm-backend
```

### Passo 6: Criar Secret das Credenciais Oracle

```bash
# Criar secret com credenciais
kubectl create secret generic oracle-credentials \
  --from-literal=username=admin \
  --from-literal=password='CRM@Oracle26ai#2026!' \
  -n crm-backend

# Verificar
kubectl get secrets -n crm-backend
```

### Passo 7: Criar Secret do Azure Container Registry

```bash
# Se for usar Azure Container Registry (ACR)
kubectl create secret docker-registry lazarusacr \
  --docker-server=lazarusacr.azurecr.io \
  --docker-username=<username> \
  --docker-password=<password> \
  -n crm-backend

# Verificar
kubectl get secrets -n crm-backend
```

---

## Estrutura Completa de Secrets

### Arquivo: `02-oracle-secrets.yaml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: crm-backend
---
apiVersion: v1
kind: Secret
metadata:
  name: oracle-wallet
  namespace: crm-backend
type: Opaque
data:
  # Base64 encoded files
  cwallet.sso: <base64-encoded-content>
  ewallet.p12: <base64-encoded-content>
  ojdbc.properties: <base64-encoded-content>
  sqlnet.ora: <base64-encoded-content>
  tnsnames.ora: <base64-encoded-content>
---
apiVersion: v1
kind: Secret
metadata:
  name: oracle-credentials
  namespace: crm-backend
type: Opaque
stringData:
  username: admin
  password: "CRM@Oracle26ai#2026!"
---
apiVersion: v1
kind: Secret
metadata:
  name: acr-credentials
  namespace: crm-backend
type: docker-registry
data:
  .dockerconfigjson: <base64-encoded-docker-config>
```

---

## Usar Secrets nos Deployments

### Exemplo: Deployment com Wallet

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: customer-service
  namespace: crm-backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: customer-service
  template:
    metadata:
      labels:
        app: customer-service
    spec:
      # Usar secret do ACR para pull de imagem
      imagePullSecrets:
        - name: acr-credentials
      
      containers:
      - name: customer-service
        image: lazarusacr.azurecr.io/crm-customer-service:latest
        ports:
        - containerPort: 8080
        
        # Montar wallet como volume
        volumeMounts:
        - name: oracle-wallet
          mountPath: /opt/oracle/wallet
          readOnly: true
        
        # Variáveis de ambiente com secrets
        env:
        - name: ORACLE_USER
          valueFrom:
            secretKeyRef:
              name: oracle-credentials
              key: username
        - name: ORACLE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: oracle-credentials
              key: password
        - name: TNS_ADMIN
          value: /opt/oracle/wallet
      
      # Volume do wallet
      volumes:
      - name: oracle-wallet
        secret:
          secretName: oracle-wallet
```

---

## Comandos Úteis

### Listar Secrets

```bash
# Todos os secrets
kubectl get secrets

# Secrets em namespace específico
kubectl get secrets -n crm-backend

# Detalhes de um secret
kubectl describe secret oracle-wallet -n crm-backend
```

### Ver Conteúdo de Secret

```bash
# Ver valor (encoded)
kubectl get secret oracle-credentials -n crm-backend -o yaml

# Decodificar valor
kubectl get secret oracle-credentials -n crm-backend \
  -o jsonpath='{.data.password}' | base64 -d
```

### Deletar Secret

```bash
# Deletar um secret
kubectl delete secret oracle-wallet -n crm-backend

# Deletar todos os secrets de um namespace
kubectl delete secrets --all -n crm-backend
```

### Atualizar Secret

```bash
# Deletar e recriar
kubectl delete secret oracle-wallet -n crm-backend
kubectl create secret generic oracle-wallet \
  --from-file=./wallet/ \
  -n crm-backend
```

---

## Troubleshooting

### Erro: `The system cannot find the file specified`

**Solução:**
```bash
# Verificar se pasta existe
ls wallet/

# Se não existir, extrair
Expand-Archive -Path ..\Wallet_crmdb.zip -DestinationPath wallet\
```

### Erro: `namespace "crm-backend" not found`

**Solução:**
```bash
# Criar namespace
kubectl create namespace crm-backend

# Ou usar manifesto
kubectl apply -f 01-namespaces.yaml
```

### Erro: `secret already exists`

**Solução:**
```bash
# Deletar secret existente
kubectl delete secret oracle-wallet -n crm-backend

# Recriar
kubectl create secret generic oracle-wallet \
  --from-file=./wallet/ \
  -n crm-backend
```

### Erro: `permission denied`

**Solução:**
```bash
# Verificar permissões da pasta
icacls wallet/

# Dar permissão se necessário
icacls wallet /grant:r "%USERNAME%:F" /t
```

---

## Checklist: Criar Secrets

- [ ] Extrair `Wallet_crmdb.zip` em `wallet/`
- [ ] Verificar conteúdo da pasta `wallet/`
- [ ] Criar namespace `crm-backend`
- [ ] Criar secret `oracle-wallet`
- [ ] Criar secret `oracle-credentials`
- [ ] Criar secret `acr-credentials` (se usar ACR)
- [ ] Verificar secrets com `kubectl get secrets -n crm-backend`
- [ ] Testar acesso aos secrets

---

## Estrutura Final

```
C:\workarea\CRM\crm-deployment\
├── wallet/                    ← Extraído aqui!
│   ├── cwallet.sso
│   ├── ewallet.p12
│   ├── ojdbc.properties
│   ├── sqlnet.ora
│   ├── tnsnames.ora
│   └── truststore.jks
├── k8s-manifests/
│   ├── 01-namespaces.yaml
│   ├── 02-oracle-secrets.yaml
│   └── 03-configmaps.yaml
├── helm-charts/
└── ...
```

---

## Próximos Passos

1. ✅ Extrair wallet
2. ✅ Criar secrets
3. ⏳ Aplicar manifests Kubernetes
4. ⏳ Deploy dos serviços
5. ⏳ Verificar pods

Sucesso! 🚀
