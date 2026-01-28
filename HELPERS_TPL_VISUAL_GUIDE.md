# 📍 Guia Visual - Onde Adicionar a Função no _helpers.tpl

## Seu Arquivo Atual

Abra este arquivo:
```
C:\workarea\CRM\crm-deployment\helm-charts\crm-backend\templates\_helpers.tpl
```

Você vai ver algo assim:

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

## Onde Adicionar

### ❌ ERRADO - Adicionar no Final

```go
{{- define "crm-backend.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "crm-backend.serviceAccountName" -}}
...
```

### ✅ CORRETO - Adicionar ENTRE `chart` e `serviceAccountName`

```go
{{- define "crm-backend.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

👇 ADICIONAR AQUI 👇

{{/*
Return the namespace
*/}}
{{- define "crm-backend.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
{{- end }}

👆 ADICIONAR AQUI 👆

{{/*
Create the name of the service account to use
*/}}
{{- define "crm-backend.serviceAccountName" -}}
...
```

---

## Arquivo Completo Corrigido

Copie e cole **TODO** este conteúdo no arquivo `_helpers.tpl`:

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
{{- default .Release.Namespace .Values.namespace }}
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

## Passo a Passo no Notepad++

### 1. Abrir arquivo

```
C:\workarea\CRM\crm-deployment\helm-charts\crm-backend\templates\_helpers.tpl
```

### 2. Procurar por

```
Create chart name and version
```

### 3. Encontrar esta linha

```go
{{- end }}
```

Que vem **depois** de:

```go
{{- define "crm-backend.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
```

### 4. Colocar cursor **DEPOIS** dessa linha

```go
{{- end }}
👈 CURSOR AQUI
```

### 5. Pressionar ENTER para criar nova linha

### 6. Colar isto:

```go

{{/*
Return the namespace
*/}}
{{- define "crm-backend.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
{{- end }}
```

### 7. Salvar (Ctrl+S)

---

## Verificação

Procure no arquivo por:

```
crm-backend.namespace
```

Se encontrar, está correto! ✅

---

## Resumo Visual

```
┌─ _helpers.tpl ─────────────────────────────┐
│                                             │
│  {{- define "crm-backend.name" -}}         │
│  ...                                        │
│  {{- end }}                                 │
│                                             │
│  {{- define "crm-backend.fullname" -}}     │
│  ...                                        │
│  {{- end }}                                 │
│                                             │
│  {{- define "crm-backend.chart" -}}        │
│  ...                                        │
│  {{- end }}                                 │
│                                             │
│  ← ADICIONAR AQUI ↓                        │
│                                             │
│  {{- define "crm-backend.namespace" -}}    │
│  {{- default .Release.Namespace ...        │
│  {{- end }}                                 │
│                                             │
│  {{- define "crm-backend.serviceAccountName" -}}
│  ...                                        │
│  {{- end }}                                 │
│                                             │
└─────────────────────────────────────────────┘
```

Pronto! Agora ficou claro? 🎉
