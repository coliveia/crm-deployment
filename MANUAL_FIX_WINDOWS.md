# 🔧 Correção Manual - Windows

## Problema

O arquivo `service.yaml` ainda tem a versão antiga com `.Release.Namespace` em vez de `{{ include "crm-backend.namespace" . }}`.

## Solução: Copiar Arquivo Corrigido

### Passo 1: Abrir o Arquivo

Abra este arquivo no seu computador:
```
C:\workarea\CRM\crm-deployment\helm-charts\crm-backend\templates\service.yaml
```

### Passo 2: Copiar Conteúdo Correto

Copie **TODO** o conteúdo abaixo e **substitua** o conteúdo do arquivo:

```yaml
{{- range $service := .Values.services }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $service.name }}
  namespace: {{ include "crm-backend.namespace" . }}
  labels:
    app: {{ $service.name }}
    chart: {{ include "crm-backend.chart" . }}
    release: {{ .Release.Name }}
spec:
  type: ClusterIP
  ports:
  - port: {{ $service.port }}
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: {{ $service.name }}
  sessionAffinity: None
{{- end }}
```

### Passo 3: Salvar Arquivo

Salve o arquivo (Ctrl+S).

---

## Passo 4: Corrigir Outros Arquivos

### Arquivo: `deployment.yaml`

Abra:
```
C:\workarea\CRM\crm-deployment\helm-charts\crm-backend\templates\deployment.yaml
```

Na **linha 7**, mude de:
```yaml
  namespace: {{ .Release.Namespace }}
```

Para:
```yaml
  namespace: {{ include "crm-backend.namespace" . }}
```

Salve o arquivo.

### Arquivo: `hpa.yaml`

Abra:
```
C:\workarea\CRM\crm-deployment\helm-charts\crm-backend\templates\hpa.yaml
```

Na **linha 8**, mude de:
```yaml
  namespace: {{ .Release.Namespace }}
```

Para:
```yaml
  namespace: {{ include "crm-backend.namespace" . }}
```

Salve o arquivo.

### Arquivo: `serviceaccount.yaml`

Abra:
```
C:\workarea\CRM\crm-deployment\helm-charts\crm-backend\templates\serviceaccount.yaml
```

Na **linha 6**, mude de:
```yaml
  namespace: {{ .Release.Namespace }}
```

Para:
```yaml
  namespace: {{ include "crm-backend.namespace" . }}
```

Salve o arquivo.

### Arquivo: `_helpers.tpl`

Abra:
```
C:\workarea\CRM\crm-deployment\helm-charts\crm-backend\templates\_helpers.tpl
```

Procure por `crm-backend.namespace`. Se não encontrar, adicione isto **depois** da função `crm-backend.chart`:

```go
{{/*
Return the namespace
*/}}
{{- define "crm-backend.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
{{- end }}
```

Salve o arquivo.

---

## Passo 5: Testar

Abra CMD e execute:

```cmd
cd C:\workarea\CRM\crm-deployment

helm template crm-backend .\helm-charts\crm-backend --namespace crm-backend --values .\helm-charts\crm-backend\values.yaml
```

Deve retornar YAML válido (não erro).

---

## Passo 6: Instalar

```cmd
helm upgrade --install crm-backend .\helm-charts\crm-backend ^
  --namespace crm-backend ^
  --create-namespace ^
  --values .\helm-charts\crm-backend\values.yaml ^
  --wait
```

---

## Verificação Rápida

Para verificar se o arquivo está correto, procure por esta linha:

```yaml
namespace: {{ include "crm-backend.namespace" . }}
```

Se encontrar, está correto! ✅

Se encontrar isto:

```yaml
namespace: {{ .Release.Namespace }}
```

Está errado! ❌ Precisa corrigir.

---

## Resumo dos Arquivos a Corrigir

| Arquivo | Linha | Mudar De | Para |
|---------|-------|----------|------|
| service.yaml | 7 | `{{ .Release.Namespace }}` | `{{ include "crm-backend.namespace" . }}` |
| deployment.yaml | 7 | `{{ .Release.Namespace }}` | `{{ include "crm-backend.namespace" . }}` |
| hpa.yaml | 8 | `{{ .Release.Namespace }}` | `{{ include "crm-backend.namespace" . }}` |
| serviceaccount.yaml | 6 | `{{ .Release.Namespace }}` | `{{ include "crm-backend.namespace" . }}` |
| _helpers.tpl | - | (adicionar função) | (ver acima) |

---

## Se Tiver Dúvida

Abra o arquivo com Notepad++ ou VS Code e:
1. Procure por `.Release.Namespace`
2. Substitua por `{{ include "crm-backend.namespace" . }}`
3. Salve

Pronto! 🚀
