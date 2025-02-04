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
{{- define "dp-core-infrastructure.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "dp-core-infrastructure.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "dp-core-infrastructure.component" -}}
{{- "dp-infrastructure" }}
{{- end }}

{{- define "dp-core-infrastructure.part-of" -}}
{{- "tibco-platform" }}
{{- end }}

{{- define "dp-core-infrastructure.team" -}}
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
{{- define "dp-core-infrastructure.labels" -}}
helm.sh/chart: {{ include "dp-core-infrastructure.chart" . }}
{{ include "dp-core-infrastructure.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.cloud.tibco.com/created-by: {{ include "dp-core-infrastructure.team" .}}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "dp-core-infrastructure.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dp-core-infrastructure.name" . }}
app.kubernetes.io/component: {{ include "dp-core-infrastructure.component" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: {{ include "dp-core-infrastructure.part-of" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "dp-core-infrastructure.validate" -}}
{{- $ns_name := .Release.Namespace }}
{{- $ns := (lookup "v1" "Namespace" "" $ns_name) }}
{{- if $ns }}
{{- if $ns.metadata.labels }}
{{- if (hasKey $ns.metadata.labels "platform.tibco.com/dataplane-id" ) }}
{{- if eq (get $ns.metadata.labels "platform.tibco.com/dataplane-id") .Values.global.tibco.dataPlaneId }}
{{/* check for sa */}}
{{- $sa := (lookup "v1" "ServiceAccount" $ns_name .Values.global.tibco.serviceAccount) }}
{{- if $sa }}
{{- else }} 
{{- fail (printf "sa %s/%s missing" .Release.Namespace .Values.global.tibco.serviceAccount  )}}
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