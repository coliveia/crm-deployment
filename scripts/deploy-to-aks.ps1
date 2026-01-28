# Deploy CRM+ to Azure AKS
# Usage: .\scripts\deploy-to-aks.ps1

param(
    [string]$ResourceGroup = "rg-core-lazarus",
    [string]$ClusterName = "lazaruskube",
    [string]$RegistryName = "lazarusacr",
    [string]$Environment = "dev"
)

Write-Host "🚀 CRM+ Deployment to Azure AKS" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# Step 1: Get AKS credentials
Write-Host "📝 Step 1: Getting AKS credentials..." -ForegroundColor Cyan
az aks get-credentials --resource-group $ResourceGroup --name $ClusterName --overwrite-existing
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get AKS credentials" -ForegroundColor Red
    exit 1
}
Write-Host "✅ AKS credentials configured" -ForegroundColor Green
Write-Host ""

# Step 2: Verify cluster connection
Write-Host "📝 Step 2: Verifying cluster connection..." -ForegroundColor Cyan
kubectl cluster-info
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to connect to cluster" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Connected to cluster" -ForegroundColor Green
Write-Host ""

# Step 3: Create namespaces
Write-Host "📝 Step 3: Creating namespaces..." -ForegroundColor Cyan
$namespaces = @("crm", "crm-backend", "crm-frontend", "crm-infrastructure", "crm-monitoring")
foreach ($ns in $namespaces) {
    kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f -
    Write-Host "✅ Namespace '$ns' ready" -ForegroundColor Green
}
Write-Host ""

# Step 4: Create secrets
Write-Host "📝 Step 4: Creating secrets..." -ForegroundColor Cyan
if (Test-Path "wallet") {
    kubectl create secret generic oracle-wallet --from-file=wallet/ -n crm-backend --dry-run=client -o yaml | kubectl apply -f -
    Write-Host "✅ Oracle wallet secret created" -ForegroundColor Green
} else {
    Write-Host "⚠️  wallet/ directory not found. Skipping oracle-wallet secret" -ForegroundColor Yellow
}

# Create oracle credentials secret
kubectl create secret generic oracle-credentials `
    --from-literal=username=admin `
    --from-literal=password='CRM@Oracle26ai#2026!' `
    --from-literal=jdbc-url='jdbc:oracle:thin:@gc557477e093c7a_crmdb_high.adb.oraclecloud.com:1522/crmdb_high' `
    -n crm-backend --dry-run=client -o yaml | kubectl apply -f -
Write-Host "✅ Oracle credentials secret created" -ForegroundColor Green

# Create ACR secret for image pull
Write-Host "📝 Creating ACR credentials secret..." -ForegroundColor Cyan
$acrPassword = az acr credential show --name $RegistryName --query "passwords[0].value" -o tsv
kubectl create secret docker-registry acr-secret `
    --docker-server="${RegistryName}.azurecr.io" `
    --docker-username=$RegistryName `
    --docker-password=$acrPassword `
    -n crm-backend --dry-run=client -o yaml | kubectl apply -f -
Write-Host "✅ ACR credentials secret created" -ForegroundColor Green
Write-Host ""

# Step 5: Apply Kubernetes manifests
Write-Host "📝 Step 5: Applying Kubernetes manifests..." -ForegroundColor Cyan
kubectl apply -f k8s-manifests/01-namespaces.yaml
kubectl apply -f k8s-manifests/02-oracle-secrets.yaml
kubectl apply -f k8s-manifests/03-configmaps.yaml
Write-Host "✅ Manifests applied" -ForegroundColor Green
Write-Host ""

# Step 6: Deploy Kafka
Write-Host "📝 Step 6: Deploying Kafka..." -ForegroundColor Cyan
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade --install kafka bitnami/kafka `
    --namespace crm-infrastructure `
    --create-namespace `
    --set auth.enabled=false `
    --set replicaCount=1 `
    --set persistence.enabled=false `
    --timeout 10m `
    --wait
Write-Host "✅ Kafka deployed" -ForegroundColor Green
Write-Host ""

# Step 7: Deploy Redis
Write-Host "📝 Step 7: Deploying Redis..." -ForegroundColor Cyan
helm upgrade --install redis bitnami/redis `
    --namespace crm-infrastructure `
    --create-namespace `
    --set auth.enabled=false `
    --set master.persistence.enabled=false `
    --set replica.persistence.enabled=false `
    --timeout 10m `
    --wait
Write-Host "✅ Redis deployed" -ForegroundColor Green
Write-Host ""

# Step 8: Deploy CRM Backend
Write-Host "📝 Step 8: Deploying CRM Backend services..." -ForegroundColor Cyan
helm upgrade --install crm-backend helm-charts/crm-backend `
    --namespace crm-backend `
    --create-namespace `
    --values helm-charts/crm-backend/values.yaml `
    --set global.registry="${RegistryName}.azurecr.io" `
    --set global.imagePullPolicy=IfNotPresent `
    --timeout 15m `
    --wait
Write-Host "✅ CRM Backend deployed" -ForegroundColor Green
Write-Host ""

# Step 9: Deploy BFF
Write-Host "📝 Step 9: Deploying BFF service..." -ForegroundColor Cyan
helm upgrade --install crm-bff helm-charts/crm-bff `
    --namespace crm-backend `
    --values helm-charts/crm-bff/values.yaml `
    --set global.registry="${RegistryName}.azurecr.io" `
    --timeout 10m `
    --wait
Write-Host "✅ BFF deployed" -ForegroundColor Green
Write-Host ""

# Step 10: Deploy Frontend
Write-Host "📝 Step 10: Deploying Frontend services..." -ForegroundColor Cyan
helm upgrade --install crm-frontend helm-charts/crm-frontend `
    --namespace crm-frontend `
    --create-namespace `
    --values helm-charts/crm-frontend/values.yaml `
    --set global.registry="${RegistryName}.azurecr.io" `
    --timeout 10m `
    --wait
Write-Host "✅ Frontend deployed" -ForegroundColor Green
Write-Host ""

# Step 11: Verify deployment
Write-Host "📝 Step 11: Verifying deployment..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Pods in crm-backend namespace:" -ForegroundColor Yellow
kubectl get pods -n crm-backend
Write-Host ""
Write-Host "Pods in crm-infrastructure namespace:" -ForegroundColor Yellow
kubectl get pods -n crm-infrastructure
Write-Host ""
Write-Host "Pods in crm-frontend namespace:" -ForegroundColor Yellow
kubectl get pods -n crm-frontend
Write-Host ""

# Step 12: Get services
Write-Host "📝 Services deployed:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend services:" -ForegroundColor Yellow
kubectl get svc -n crm-backend
Write-Host ""
Write-Host "Frontend services:" -ForegroundColor Yellow
kubectl get svc -n crm-frontend
Write-Host ""

Write-Host "✨ Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Check pod status: kubectl get pods -n crm-backend"
Write-Host "2. Check logs: kubectl logs -n crm-backend <pod-name>"
Write-Host "3. Port forward: kubectl port-forward -n crm-frontend svc/crm-agent-portal 5175:80"
Write-Host "4. Access: http://localhost:5175"
