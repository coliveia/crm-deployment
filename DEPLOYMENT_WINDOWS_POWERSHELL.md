# Deployment CRM+ no Azure AKS - Windows PowerShell

## 📋 Pré-requisitos

Instale no seu Windows:

1. **Azure CLI**
   ```powershell
   # Via Chocolatey
   choco install azure-cli
   
   # Ou baixe em: https://aka.ms/installazurecliwindows
   ```

2. **kubectl**
   ```powershell
   # Via Chocolatey
   choco install kubernetes-cli
   
   # Ou via Azure CLI
   az aks install-cli
   ```

3. **Helm**
   ```powershell
   # Via Chocolatey
   choco install kubernetes-helm
   
   # Ou manualmente: https://github.com/helm/helm/releases
   ```

4. **kubelogin** (para autenticação Azure AD)
   ```powershell
   # Via Chocolatey
   choco install kubelogin
   
   # Ou manualmente: https://github.com/Azure/kubelogin/releases
   ```

## 🚀 Deployment Automático

### Passo 1: Preparar o ambiente

```powershell
# Ir para o diretório de deployment
cd C:\workarea\CRM\crm-deployment

# Extrair wallet
Expand-Archive -Path ..\Wallet_crmdb.zip -DestinationPath wallet\ -Force

# Verificar estrutura
ls wallet/
```

### Passo 2: Executar o script de deployment

```powershell
# Executar com parâmetros padrão
.\scripts\deploy-to-aks.ps1

# Ou com parâmetros customizados
.\scripts\deploy-to-aks.ps1 -ResourceGroup "seu-rg" -ClusterName "seu-cluster" -RegistryName "seu-acr"
```

### Passo 3: Aguardar deployment

O script vai:
1. ✅ Conectar ao AKS
2. ✅ Criar namespaces
3. ✅ Criar secrets (Oracle, ACR)
4. ✅ Deploy Kafka
5. ✅ Deploy Redis
6. ✅ Deploy CRM Backend
7. ✅ Deploy BFF
8. ✅ Deploy Frontend
9. ✅ Verificar pods

Tempo estimado: **10-15 minutos**

## 📊 Verificar Deployment

### Ver pods
```powershell
kubectl get pods -n crm-backend
kubectl get pods -n crm-infrastructure
kubectl get pods -n crm-frontend
```

### Ver logs
```powershell
kubectl logs -n crm-backend <pod-name>
kubectl logs -n crm-backend -l app=crm-customer-service
```

### Port forward para acessar frontend
```powershell
kubectl port-forward -n crm-frontend svc/crm-agent-portal 5175:80
```

Acesse: http://localhost:5175

## 🔧 Troubleshooting

### Pod não inicia
```powershell
# Ver eventos
kubectl describe pod <pod-name> -n crm-backend

# Ver logs
kubectl logs <pod-name> -n crm-backend

# Ver status detalhado
kubectl get pod <pod-name> -n crm-backend -o yaml
```

### ImagePullBackOff
```powershell
# Verificar credenciais ACR
kubectl get secret acr-secret -n crm-backend -o yaml

# Recriar secret
$acrPassword = az acr credential show --name lazarusacr --query "passwords[0].value" -o tsv
kubectl create secret docker-registry acr-secret `
    --docker-server=lazarusacr.azurecr.io `
    --docker-username=lazarusacr `
    --docker-password=$acrPassword `
    -n crm-backend --dry-run=client -o yaml | kubectl apply -f -
```

### Conexão com Oracle não funciona
```powershell
# Verificar secret
kubectl get secret oracle-credentials -n crm-backend -o yaml

# Verificar wallet
kubectl get secret oracle-wallet -n crm-backend -o yaml

# Testar conectividade
kubectl exec -it <pod-name> -n crm-backend -- /bin/bash
# Dentro do pod:
sqlplus admin@gc557477e093c7a_crmdb_high
```

## 📈 Escalabilidade

### Aumentar replicas
```powershell
kubectl scale deployment crm-customer-service --replicas=3 -n crm-backend
```

### Ver HPA (Horizontal Pod Autoscaler)
```powershell
kubectl get hpa -n crm-backend
```

## 🧹 Limpeza

### Deletar deployment
```powershell
helm uninstall crm-backend -n crm-backend
helm uninstall crm-bff -n crm-backend
helm uninstall crm-frontend -n crm-frontend
helm uninstall kafka -n crm-infrastructure
helm uninstall redis -n crm-infrastructure
```

### Deletar namespaces
```powershell
kubectl delete namespace crm-backend
kubectl delete namespace crm-frontend
kubectl delete namespace crm-infrastructure
```

## 📚 Referências

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
