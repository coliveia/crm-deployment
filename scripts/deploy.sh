#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGISTRY="lazarusacr.azurecr.io"
CLUSTER_NAME="lazaruskube"
RESOURCE_GROUP="rg-core-lazarus"
REGION="westus2"
ENVIRONMENT="dev"
WALLET_PATH="./wallet"

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

check_prerequisites() {
    print_header "Verificando Pré-requisitos"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl não está instalado"
        exit 1
    fi
    print_success "kubectl encontrado"
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        print_error "helm não está instalado"
        exit 1
    fi
    print_success "helm encontrado"
    
    # Check az CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI não está instalado"
        exit 1
    fi
    print_success "Azure CLI encontrado"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker não está instalado"
        exit 1
    fi
    print_success "Docker encontrado"
}

setup_azure_credentials() {
    print_header "Configurando Credenciais Azure"
    
    # Login to Azure
    print_warning "Faça login no Azure..."
    az login
    
    # Get AKS credentials
    print_warning "Obtendo credenciais do AKS..."
    az aks get-credentials \
        --resource-group $RESOURCE_GROUP \
        --name $CLUSTER_NAME \
        --overwrite-existing
    
    print_success "Credenciais Azure configuradas"
}

setup_acr_credentials() {
    print_header "Configurando Credenciais ACR"
    
    # Get ACR login server
    ACR_LOGIN_SERVER=$(az acr show \
        --resource-group $RESOURCE_GROUP \
        --name lazarusacr \
        --query loginServer \
        --output tsv)
    
    print_success "ACR Login Server: $ACR_LOGIN_SERVER"
    
    # Create docker registry secret
    kubectl create namespace crm-backend --dry-run=client -o yaml | kubectl apply -f -
    
    # Get ACR credentials
    ACR_USERNAME=$(az acr credential show \
        --resource-group $RESOURCE_GROUP \
        --name lazarusacr \
        --query username \
        --output tsv)
    
    ACR_PASSWORD=$(az acr credential show \
        --resource-group $RESOURCE_GROUP \
        --name lazarusacr \
        --query passwords[0].value \
        --output tsv)
    
    # Create secret
    kubectl create secret docker-registry acr-secret \
        --docker-server=$ACR_LOGIN_SERVER \
        --docker-username=$ACR_USERNAME \
        --docker-password=$ACR_PASSWORD \
        --docker-email=admin@example.com \
        -n crm-backend \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Credenciais ACR configuradas"
}

build_docker_images() {
    print_header "Construindo Imagens Docker"
    
    ACR_LOGIN_SERVER=$(az acr show \
        --resource-group $RESOURCE_GROUP \
        --name lazarusacr \
        --query loginServer \
        --output tsv)
    
    # Build backend services
    services=(
        "crm-customer-service"
        "crm-case-management-service"
        "crm-sla-management-service"
        "crm-interaction-service"
        "crm-workflow-engine-service"
        "crm-copilot-service"
    )
    
    for service in "${services[@]}"; do
        print_warning "Construindo $service..."
        docker build \
            -f dockerfiles/Dockerfile.${service//-/.} \
            -t $ACR_LOGIN_SERVER/$service:latest \
            ..
        
        print_warning "Fazendo push de $service..."
        docker push $ACR_LOGIN_SERVER/$service:latest
        print_success "$service construído e enviado"
    done
    
    # Build BFF service
    print_warning "Construindo crm-bff-service..."
    docker build \
        -f dockerfiles/Dockerfile.bff-service \
        -t $ACR_LOGIN_SERVER/crm-bff-service:latest \
        ..
    docker push $ACR_LOGIN_SERVER/crm-bff-service:latest
    print_success "crm-bff-service construído e enviado"
    
    # Build frontend services
    print_warning "Construindo crm-agent-portal..."
    docker build \
        -f dockerfiles/Dockerfile.agent-portal \
        -t $ACR_LOGIN_SERVER/crm-agent-portal:latest \
        ..
    docker push $ACR_LOGIN_SERVER/crm-agent-portal:latest
    print_success "crm-agent-portal construído e enviado"
    
    print_warning "Construindo crm-workflow-admin-portal..."
    docker build \
        -f dockerfiles/Dockerfile.workflow-admin-portal \
        -t $ACR_LOGIN_SERVER/crm-workflow-admin-portal:latest \
        ..
    docker push $ACR_LOGIN_SERVER/crm-workflow-admin-portal:latest
    print_success "crm-workflow-admin-portal construído e enviado"
}

create_namespaces() {
    print_header "Criando Namespaces"
    
    kubectl apply -f k8s-manifests/01-namespaces.yaml
    print_success "Namespaces criados"
}

create_secrets() {
    print_header "Criando Secrets"
    
    # Create Oracle credentials secret
    kubectl create secret generic oracle-credentials \
        --from-literal=jdbc-url='jdbc:oracle:thin:@(DESCRIPTION=(RETRY_COUNT=20)(RETRY_DELAY=3)(ADDRESS=(PROTOCOL=tcps)(PORT=1522)(HOST=adb.us-ashburn-1.oraclecloud.com))(CONNECT_DATA=(SERVICE_NAME=gc557477e093c7a_crmdb_high.adb.oraclecloud.com))(SECURITY=(SSL_SERVER_DN_MATCH=yes)))' \
        --from-literal=username='admin' \
        --from-literal=password='CRM@Oracle26ai#2026!' \
        -n crm-backend \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Secret de credenciais Oracle criado"
    
    # Create Oracle Wallet secret
    if [ -d "$WALLET_PATH" ]; then
        kubectl create secret generic oracle-wallet \
            --from-file=$WALLET_PATH/ \
            -n crm-backend \
            --dry-run=client -o yaml | kubectl apply -f -
        print_success "Secret do Oracle Wallet criado"
    else
        print_warning "Diretório do wallet não encontrado em $WALLET_PATH"
        print_warning "Certifique-se de extrair o wallet antes de fazer deploy"
    fi
}

create_configmaps() {
    print_header "Criando ConfigMaps"
    
    kubectl apply -f k8s-manifests/03-configmaps.yaml
    print_success "ConfigMaps criados"
}

deploy_kafka() {
    print_header "Deployando Kafka"
    
    # Add Bitnami Helm repo
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    
    # Deploy Kafka
    helm upgrade --install kafka bitnami/kafka \
        --namespace crm-infrastructure \
        --create-namespace \
        --values helm-charts/kafka/values.yaml \
        --wait
    
    print_success "Kafka deployado"
}

deploy_redis() {
    print_header "Deployando Redis"
    
    # Deploy Redis
    helm upgrade --install redis bitnami/redis \
        --namespace crm-infrastructure \
        --create-namespace \
        --values helm-charts/redis/values.yaml \
        --wait
    
    print_success "Redis deployado"
}

deploy_backend() {
    print_header "Deployando Backend Services"
    
    helm upgrade --install crm-backend helm-charts/crm-backend \
        --namespace crm-backend \
        --create-namespace \
        --values helm-charts/crm-backend/values.yaml \
        --wait
    
    print_success "Backend services deployados"
}

deploy_bff() {
    print_header "Deployando BFF Service"
    
    helm upgrade --install crm-bff helm-charts/crm-bff \
        --namespace crm-backend \
        --values helm-charts/crm-bff/values.yaml \
        --wait
    
    print_success "BFF service deployado"
}

deploy_frontend() {
    print_header "Deployando Frontend"
    
    helm upgrade --install crm-frontend helm-charts/crm-frontend \
        --namespace crm-frontend \
        --create-namespace \
        --values helm-charts/crm-frontend/values.yaml \
        --wait
    
    print_success "Frontend deployado"
}

verify_deployment() {
    print_header "Verificando Deployment"
    
    print_warning "Pods no namespace crm-backend:"
    kubectl get pods -n crm-backend
    
    print_warning "Pods no namespace crm-frontend:"
    kubectl get pods -n crm-frontend
    
    print_warning "Pods no namespace crm-infrastructure:"
    kubectl get pods -n crm-infrastructure
    
    print_warning "Services:"
    kubectl get svc -A | grep crm
    
    print_success "Deployment verificado"
}

# Main execution
main() {
    print_header "CRM+ Deployment Script"
    
    check_prerequisites
    setup_azure_credentials
    setup_acr_credentials
    build_docker_images
    create_namespaces
    create_secrets
    create_configmaps
    deploy_kafka
    deploy_redis
    deploy_backend
    deploy_bff
    deploy_frontend
    verify_deployment
    
    print_header "Deployment Concluído com Sucesso!"
    print_success "Todos os serviços foram deployados"
    print_warning "Próximos passos:"
    echo "1. Verifique os pods: kubectl get pods -A"
    echo "2. Verifique os logs: kubectl logs -n crm-backend <pod-name>"
    echo "3. Configure o Ingress com seu domínio"
    echo "4. Configure SSL com cert-manager"
}

# Run main function
main "$@"
