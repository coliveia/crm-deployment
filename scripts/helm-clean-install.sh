#!/bin/bash

# Script para limpar cache Helm e reinstalar crm-backend

set -e

echo "🧹 Limpando cache Helm..."

# Limpar cache do Helm
rm -rf ~/.helm/cache
rm -rf ~/.cache/helm

# Limpar repositórios
helm repo update

echo "✅ Cache limpo!"

echo ""
echo "🗑️  Deletando release anterior (se existir)..."

# Deletar release anterior
helm uninstall crm-backend -n crm-backend --ignore-not-found

echo "✅ Release deletada!"

echo ""
echo "⏳ Aguardando 5 segundos..."
sleep 5

echo ""
echo "🚀 Instalando crm-backend..."

# Instalar novo
helm upgrade --install crm-backend ./helm-charts/crm-backend \
  --namespace crm-backend \
  --create-namespace \
  --values ./helm-charts/crm-backend/values.yaml \
  --wait \
  --timeout 5m

echo ""
echo "✅ Instalação concluída!"

echo ""
echo "📊 Verificando pods..."
kubectl get pods -n crm-backend

echo ""
echo "🎉 Sucesso!"
