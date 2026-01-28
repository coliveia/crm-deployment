# 🔧 Helm Error no Windows CMD - Solução

## Erro: `nil pointer evaluating interface {}.Namespace`

### Problema

```cmd
C:\workarea\CRM\crm-deployment>helm upgrade --install crm-backend helm-charts/crm-backend --namespace crm-backend --create-namespace --values helm-charts/crm-backend/values.yaml --wait
Release "crm-backend" does not exist. Installing it now.
Error: template: crm-backend/templates/service.yaml:7:24: executing "crm-backend/templates/service.yaml" at <.Release.Namespace>: nil pointer evaluating interface {}.Namespace
```

### Causa

Cache local do Helm está usando versão antiga dos templates.

---

## Solução para Windows CMD

### Opção 1: Usar Script Batch (Recomendado)

**Passo 1: Executar o script**

```cmd
cd C:\workarea\CRM\crm-deployment
scripts\helm-clean-install.bat
```

O script vai:
1. ✅ Limpar cache Helm
2. ✅ Deletar release anterior
3. ✅ Aguardar 5 segundos
4. ✅ Instalar novo crm-backend
5. ✅ Verificar pods

### Opção 2: Comandos Manuais no CMD

**Passo 1: Deletar release anterior**

```cmd
helm uninstall crm-backend -n crm-backend --ignore-not-found
```

**Passo 2: Limpar cache Helm**

```cmd
REM Limpar cache
rmdir /s /q "%APPDATA%\helm\cache"

REM Limpar cache alternativo
rmdir /s /q "%USERPROFILE%\.cache\helm"
```

Se der erro "The system cannot find the file specified", ignore - significa que não existe.

**Passo 3: Aguardar 5 segundos**

```cmd
timeout /t 5
```

**Passo 4: Validar template**

```cmd
helm template crm-backend .\helm-charts\crm-backend ^
  --namespace crm-backend ^
  --values .\helm-charts\crm-backend\values.yaml
```

Deve retornar YAML válido (não erro).

**Passo 5: Instalar**

```cmd
helm upgrade --install crm-backend .\helm-charts\crm-backend ^
  --namespace crm-backend ^
  --create-namespace ^
  --values .\helm-charts\crm-backend\values.yaml ^
  --wait
```

**Passo 6: Verificar**

```cmd
kubectl get pods -n crm-backend
```

---

## Verificação Passo a Passo

### 1. Verificar se arquivo foi atualizado

```cmd
type helm-charts\crm-backend\templates\_helpers.tpl | findstr /A:2 "crm-backend.namespace"
```

Deve mostrar:
```
{{- define "crm-backend.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
```

### 2. Verificar se service.yaml usa função

```cmd
type helm-charts\crm-backend\templates\service.yaml | findstr "namespace"
```

Deve mostrar:
```
namespace: {{ include "crm-backend.namespace" . }}
```

### 3. Testar template

```cmd
helm template crm-backend .\helm-charts\crm-backend --namespace crm-backend --values .\helm-charts\crm-backend\values.yaml > template-output.yaml
```

Se funcionar, arquivo `template-output.yaml` será criado sem erros.

---

## Comandos Úteis no CMD

### Limpar Cache Manualmente

```cmd
REM Listar diretórios de cache
echo %APPDATA%\helm\cache
echo %USERPROFILE%\.cache\helm

REM Deletar cache
rmdir /s /q "%APPDATA%\helm\cache"
rmdir /s /q "%USERPROFILE%\.cache\helm"
```

### Deletar Release

```cmd
REM Deletar sem erro se não existir
helm uninstall crm-backend -n crm-backend --ignore-not-found

REM Verificar se foi deletado
helm list -n crm-backend
```

### Validar Helm Chart

```cmd
REM Validar sintaxe
helm lint .\helm-charts\crm-backend

REM Gerar template
helm template crm-backend .\helm-charts\crm-backend --namespace crm-backend --values .\helm-charts\crm-backend\values.yaml

REM Salvar em arquivo
helm template crm-backend .\helm-charts\crm-backend --namespace crm-backend --values .\helm-charts\crm-backend\values.yaml > output.yaml
```

### Debug

```cmd
REM Ver debug detalhado
helm upgrade --install crm-backend .\helm-charts\crm-backend ^
  --namespace crm-backend ^
  --create-namespace ^
  --values .\helm-charts\crm-backend\values.yaml ^
  --debug

REM Ver dry-run (não instala, só mostra o que faria)
helm upgrade --install crm-backend .\helm-charts\crm-backend ^
  --namespace crm-backend ^
  --create-namespace ^
  --values .\helm-charts\crm-backend\values.yaml ^
  --dry-run
```

---

## Checklist de Resolução

- [ ] Executar: `helm uninstall crm-backend -n crm-backend --ignore-not-found`
- [ ] Executar: `rmdir /s /q "%APPDATA%\helm\cache"`
- [ ] Aguardar: `timeout /t 5`
- [ ] Validar: `helm template crm-backend ...`
- [ ] Instalar: `helm upgrade --install crm-backend ...`
- [ ] Verificar: `kubectl get pods -n crm-backend`

---

## Se Ainda Não Funcionar

### Opção A: Usar docker-compose

```cmd
cd C:\workarea\CRM\crm-deployment
docker-compose up -d
```

### Opção B: Reinstalar Helm

```cmd
REM Desinstalar Helm
choco uninstall helm

REM Reinstalar
choco install helm

REM Verificar versão
helm version
```

### Opção C: Usar kubectl apply direto

```cmd
REM Gerar manifests
helm template crm-backend .\helm-charts\crm-backend ^
  --namespace crm-backend ^
  --values .\helm-charts\crm-backend\values.yaml > manifests.yaml

REM Aplicar
kubectl apply -f manifests.yaml
```

---

## Próximos Passos

1. **Executar script batch:**
   ```cmd
   scripts\helm-clean-install.bat
   ```

2. **Ou executar comandos manuais:**
   - Deletar release
   - Limpar cache
   - Validar
   - Instalar

3. **Verificar resultado:**
   ```cmd
   kubectl get pods -n crm-backend
   kubectl get services -n crm-backend
   ```

Tenta rodar o script batch e me avisa se funcionar! 🚀
