{{/*
Expand the name of the chart.
*/}}
{{- define "overleaf.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "overleaf.fullname" -}}
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
{{- define "overleaf.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "overleaf.labels" -}}
helm.sh/chart: {{ include "overleaf.chart" . }}
{{ include "overleaf.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "overleaf.selectorLabels" -}}
app.kubernetes.io/name: {{ include "overleaf.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels for oauth2-proxy
*/}}
{{- define "overleaf.oauth2ProxySelectorLabels" -}}
app.kubernetes.io/name: {{ include "overleaf.name" . }}-oauth2-proxy
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component label for oauth2-proxy (overrides app name for selector matching)
*/}}
{{- define "overleaf.oauth2ProxyComponentLabel" -}}
app.kubernetes.io/name: {{ include "overleaf.name" . }}-oauth2-proxy
{{- end }}

{{/*
MongoDB URL
*/}}
{{- define "overleaf.mongodbUrl" -}}
{{- if .Values.mongodb.enabled }}
{{- printf "mongodb://%s-mongodb:27017/sharelatex" (include "overleaf.fullname" .) }}
{{- else }}
{{- .Values.mongodb.external.url }}
{{- end }}
{{- end }}

{{/*
Redis host
*/}}
{{- define "overleaf.redisHost" -}}
{{- if .Values.redis.enabled }}
{{- printf "%s-redis" (include "overleaf.fullname" .) }}
{{- else }}
{{- .Values.redis.external.host }}
{{- end }}
{{- end }}

{{/*
Redis port
*/}}
{{- define "overleaf.redisPort" -}}
{{- if .Values.redis.enabled }}
{{- "6379" }}
{{- else }}
{{- .Values.redis.external.port | toString }}
{{- end }}
{{- end }}

{{/*
OAuth2 proxy secret name
*/}}
{{- define "overleaf.oauth2ProxySecretName" -}}
{{- if .Values.oauth2Proxy.existingSecret }}
{{- .Values.oauth2Proxy.existingSecret }}
{{- else }}
{{- printf "%s-oauth2-proxy" (include "overleaf.fullname" .) }}
{{- end }}
{{- end }}

{{/*
SMTP secret name
*/}}
{{- define "overleaf.smtpSecretName" -}}
{{- if .Values.smtp.existingSecret }}
{{- .Values.smtp.existingSecret }}
{{- else }}
{{- printf "%s-smtp" (include "overleaf.fullname" .) }}
{{- end }}
{{- end }}
