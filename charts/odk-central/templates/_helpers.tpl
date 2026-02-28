{{/*
Expand the name of the chart.
*/}}
{{- define "odk-central.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "odk-central.fullname" -}}
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
Create chart label.
*/}}
{{- define "odk-central.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "odk-central.labels" -}}
helm.sh/chart: {{ include "odk-central.chart" . }}
{{ include "odk-central.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "odk-central.selectorLabels" -}}
app.kubernetes.io/name: {{ include "odk-central.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Postgres service hostname
*/}}
{{- define "odk-central.postgresHost" -}}
{{- printf "%s-postgres" (include "odk-central.fullname" .) }}
{{- end }}

{{/*
Enketo redis main service hostname
*/}}
{{- define "odk-central.enketoRedisMainHost" -}}
{{- printf "%s-enketo-redis-main" (include "odk-central.fullname" .) }}
{{- end }}

{{/*
Enketo redis cache service hostname
*/}}
{{- define "odk-central.enketoRedisCacheHost" -}}
{{- printf "%s-enketo-redis-cache" (include "odk-central.fullname" .) }}
{{- end }}

{{/*
SMTP2Graph service hostname
*/}}
{{- define "odk-central.smtp2graphHost" -}}
{{- printf "%s-smtp2graph" (include "odk-central.fullname" .) }}
{{- end }}

{{/*
Email host: use smtp2graph service if smtp2graph enabled and email.host not set
*/}}
{{- define "odk-central.emailHost" -}}
{{- if .Values.email.host }}
{{- .Values.email.host }}
{{- else if .Values.smtp2graph.enabled }}
{{- include "odk-central.smtp2graphHost" . }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}

{{/*
Enketo secret name
*/}}
{{- define "odk-central.enketoSecretName" -}}
{{- if .Values.existingSecrets.enketo }}
{{- .Values.existingSecrets.enketo }}
{{- else }}
{{- printf "%s-enketo" (include "odk-central.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Postgres secret name
*/}}
{{- define "odk-central.postgresSecretName" -}}
{{- if .Values.existingSecrets.postgres }}
{{- .Values.existingSecrets.postgres }}
{{- else }}
{{- printf "%s-postgres" (include "odk-central.fullname" .) }}
{{- end }}
{{- end }}

{{/*
SMTP2Graph secret name
*/}}
{{- define "odk-central.smtp2graphSecretName" -}}
{{- if .Values.existingSecrets.smtp2graph }}
{{- .Values.existingSecrets.smtp2graph }}
{{- else }}
{{- printf "%s-smtp2graph" (include "odk-central.fullname" .) }}
{{- end }}
{{- end }}

{{/*
OIDC secret name
*/}}
{{- define "odk-central.oidcSecretName" -}}
{{- if .Values.existingSecrets.oidc }}
{{- .Values.existingSecrets.oidc }}
{{- else }}
{{- printf "%s-oidc" (include "odk-central.fullname" .) }}
{{- end }}
{{- end }}

{{/*
S3 secret name
*/}}
{{- define "odk-central.s3SecretName" -}}
{{- if .Values.existingSecrets.s3 }}
{{- .Values.existingSecrets.s3 }}
{{- else }}
{{- printf "%s-s3" (include "odk-central.fullname" .) }}
{{- end }}
{{- end }}
