{{/* 
   Copyright (c) 2023 Cloud Software Group, Inc.
   All Rights Reserved.

   File       : _helper.tpl
   Version    : 1.0.0
   Description: Template helper used across chart. 
   
    NOTES: 
      - Helpers below are making some assumptions regarding files Chart.yaml and values.yaml. Change carefully!
      - Any change in this file needs to be synchronized with all charts
*/}}


{{/*
================================================================
                  SECTION COMMON VARS
================================================================   
*/}}
{{/*
Expand the name of the chart.
*/}}
{{- define "dp-o11y-infrastructure.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "dp-o11y-infrastructure.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "dp-o11y-infrastructure.component" -}}
{{- "dp-infrastructure" }}
{{- end }}

{{- define "dp-o11y-infrastructure.part-of" -}}
{{- "o11y" }}
{{- end }}

{{- define "dp-o11y-infrastructure.team" -}}
{{- "cic-compute" }}
{{- end }}


{{/*
================================================================
                  SECTION LABELS
================================================================   
*/}}

{{/*
Common labels
*/}}
{{- define "dp-o11y-infrastructure.labels" -}}
helm.sh/chart: {{ include "dp-o11y-infrastructure.chart" . }}
{{ include "dp-o11y-infrastructure.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.cloud.tibco.com/created-by: {{ include "dp-o11y-infrastructure.team" .}}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "dp-o11y-infrastructure.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dp-o11y-infrastructure.name" . }}
app.kubernetes.io/component: {{ include "dp-o11y-infrastructure.component" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: {{ include "dp-o11y-infrastructure.part-of" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "dp-o11y-infrastructure.validate" -}}
{{- $ns_name := .Release.Namespace }}
{{- $ns := (lookup "v1" "Namespace" "" $ns_name) }}
{{- if $ns }}
{{- if $ns.metadata.labels }}
{{- if (hasKey $ns.metadata.labels "platform.tibco.com/dataplane-id" ) }}
{{- if eq (get $ns.metadata.labels "platform.tibco.com/dataplane-id") .Values.global.cp.resources.serviceaccount.namespace }}
{{/* check for sa */}}
{{- $sa := (lookup "v1" "ServiceAccount" $ns_name .Values.global.cp.resources.serviceaccount.serviceAccountName) }}
{{- if $sa }}
{{- else }} 
{{- fail (printf "sa %s/%s missing" .Release.Namespace .Values.global.cp.resources.serviceaccount.serviceAccountName  )}}
{{- end }}
{{- else }}
{{- fail (printf "%s %s" "invalid label" (get $ns.metadata.labels "platform.tibco.com/dataplane-id")) }}
{{- end }}
{{- else }}
{{- fail "labels platform.tibco.com/dataplane-id does not exists" }}
{{- end }}   
{{- else }}
{{- fail "labels not found"}}
{{- end }}
{{- else }}
{{/* no op is ns does not exists. We expect the ns to be already present. We have this to avoid helm templating issue*/}}
{{- end }}
{{- end }}