# 🔧 Correção da Função crm-backend.namespace

## O Erro

```
error calling include: template: crm-backend/templates/_helpers.tpl:35:20: executing "crm-backend.namespace" at <.Release.Namespace>: nil pointer evaluating interface {}.Namespace
```

## O Problema

A função que você adicionou está tentando acessar `.Release.Namespace` mas o contexto está errado.

## A Solução

### ❌ ERRADO (o que você tem agora)

```go
{{- define "crm-backend.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
{{- end }}
```

### ✅ CORRETO (use isto)

```go
{{- define "crm-backend.namespace" -}}
{{- .Release.Namespace }}
{{- end }}
```

OU (mais seguro):

```go
{{- define "crm-backend.namespace" -}}
{{- default "crm-backend" .Release.Namespace }}
{{- end }}
```

---

## Opção 1: Simples (Recomendado)

Abra `_helpers.tpl` e mude a função para:

```go
{{/*
Return the namespace
*/}}
{{- define "crm-backend.namespace" -}}
{{- .Release.Namespace }}
{{- end }}
```

---

## Opção 2: Com Fallback

Se quiser um valor padrão caso o namespace não exista:

```go
{{/*
Return the namespace
*/}}
{{- define "crm-backend.namespace" -}}
{{- default "crm-backend" .Release.Namespace }}
{{- end }}
```

---

## Arquivo Completo Corrigido

Copie **TODO** este conteúdo para `_helpers.tpl`:

```go
{{/*
Expand the name of the chart.
*/}}
{{- define "crm-backend.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "crm-backend.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "crm-backend.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return the namespace
*/}}
{{- define "crm-backend.namespace" -}}
{{- .Release.Namespace }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "crm-backend.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "crm-backend.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
```

---

## Passo a Passo

### 1. Abrir arquivo

```
C:\workarea\CRM\crm-deployment\helm-charts\crm-backend\templates\_helpers.tpl
```

### 2. Procurar por

```
Return the namespace
```

### 3. Encontrar esta função

```go
{{- define "crm-backend.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
{{- end }}
```

### 4. Substituir por

```go
{{- define "crm-backend.namespace" -}}
{{- .Release.Namespace }}
{{- end }}
```

### 5. Salvar (Ctrl+S)

---

## Testar

```cmd
helm template crm-backend .\helm-charts\crm-backend --namespace crm-backend --values .\helm-charts\crm-backend\values.yaml
```

Deve funcionar agora! ✅

---

## Por Que Funcionava Errado?

O `default` tenta acessar `.Release.Namespace` primeiro, mas dentro de um `range`, o contexto `.` muda e `.Release` não existe mais.

A solução é usar apenas `.Release.Namespace` diretamente, que funciona porque o contexto raiz é passado corretamente pela função `include`.

---

## Resumo

| Versão | Status | Motivo |
|--------|--------|--------|
| `{{- default .Release.Namespace .Values.namespace }}` | ❌ Erro | `.Release` não existe no contexto |
| `{{- .Release.Namespace }}` | ✅ Funciona | Acessa contexto raiz corretamente |
| `{{- default "crm-backend" .Release.Namespace }}` | ✅ Funciona | Mesmo acima + fallback |

Tenta corrigir e me avisa! 🚀
