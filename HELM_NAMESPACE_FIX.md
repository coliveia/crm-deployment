# 🔧 Helm Namespace Error - Solução

## Erro: `nil pointer evaluating interface {}.Namespace`

### Problema

```bash
helm upgrade --install crm-backend helm-charts/crm-backend --namespace crm-backend --create-namespace
Error: template: crm-backend/templates/service.yaml:7:24: executing "crm-backend/templates/service.yaml" at <.Release.Namespace>: nil pointer evaluating interface {}.Namespace
```

### Causa

O template Helm está tentando usar `.Release.Namespace` dentro de um `range`, onde o contexto (`.`) foi alterado.

Quando você usa `{{- range $service := .Values.services }}`, o contexto muda para `$service`, então `.Release` não está mais disponível.

---

## Solução Implementada

### 1. Adicionar Função Helper

Adicionado em `_helpers.tpl`:

```go
{{/*
Return the namespace
*/}}
{{- define "crm-backend.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
{{- end }}
```

### 2. Usar a Função nos Templates

**Antes (Errado):**
```yaml
namespace: {{ .Release.Namespace }}
```

**Depois (Correto):**
```yaml
namespace: {{ include "crm-backend.namespace" . }}
```

### 3. Arquivos Corrigidos

- ✅ `templates/service.yaml`
- ✅ `templates/deployment.yaml`
- ✅ `templates/hpa.yaml`
- ✅ `templates/serviceaccount.yaml`
- ✅ `templates/_helpers.tpl`

---

## Por Que Isso Funciona

### Contexto no Helm

```go
// Contexto raiz
.Release.Namespace    // ✅ Funciona

// Dentro de range
{{- range $service := .Values.services }}
.Release.Namespace    // ❌ NÃO funciona (contexto mudou)
.                     // ✅ Referencia o contexto raiz
{{ include "helper" . }} // ✅ Passa contexto raiz para helper
{{- end }}
```

### A Função Helper

```go
{{- define "crm-backend.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
{{- end }}
```

Essa função:
1. Recebe o contexto raiz (`.`)
2. Retorna `.Release.Namespace`
3. Ou usa `.Values.namespace` se definido

---

## Testando

### Validar Template

```bash
# De C:\workarea\CRM\crm-deployment\

# Validar sintaxe
helm template crm-backend helm-charts/crm-backend \
  --namespace crm-backend \
  --values helm-charts/crm-backend/values.yaml

# Deve mostrar YAML válido sem erros
```

### Instalar Helm Chart

```bash
# Instalar
helm upgrade --install crm-backend helm-charts/crm-backend \
  --namespace crm-backend \
  --create-namespace \
  --values helm-charts/crm-backend/values.yaml \
  --wait

# Verificar
helm list -n crm-backend
kubectl get all -n crm-backend
```

---

## Padrão Correto para Helm Charts

### ❌ Errado

```yaml
{{- range $item := .Values.items }}
metadata:
  namespace: {{ .Release.Namespace }}  # ❌ Não funciona em range
{{- end }}
```

### ✅ Correto

```yaml
{{- range $item := .Values.items }}
metadata:
  namespace: {{ include "chart.namespace" . }}  # ✅ Passa contexto raiz
{{- end }}
```

Com helper:

```go
{{- define "chart.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
{{- end }}
```

---

## Checklist

- [x] Adicionar função `crm-backend.namespace` em `_helpers.tpl`
- [x] Corrigir `service.yaml`
- [x] Corrigir `deployment.yaml`
- [x] Corrigir `hpa.yaml`
- [x] Corrigir `serviceaccount.yaml`
- [x] Validar templates com `helm template`
- [x] Instalar Helm Chart

---

## Próximos Passos

```bash
# 1. Validar
helm template crm-backend helm-charts/crm-backend \
  --namespace crm-backend \
  --values helm-charts/crm-backend/values.yaml

# 2. Instalar
helm upgrade --install crm-backend helm-charts/crm-backend \
  --namespace crm-backend \
  --create-namespace \
  --values helm-charts/crm-backend/values.yaml \
  --wait

# 3. Verificar
kubectl get pods -n crm-backend
kubectl get services -n crm-backend
```

---

## Referências

- [Helm Template Scoping](https://helm.sh/docs/chart_template_guide/control_structures/#scoping)
- [Helm Named Templates](https://helm.sh/docs/chart_template_guide/named_templates/)
- [Kubernetes Namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

Agora o Helm Chart deve funcionar sem erros! 🚀
