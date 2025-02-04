{{/* 
   Copyright (c) 2023. Cloud Software Group, Inc. All Rights Reserved. Confidential & Proprietary.

   File       : _shared.tpl
   Version    : 1.0.0
   Description: Template helpers that can be shared with other charts. 
   
    NOTES: 
      - Helpers below are making some assumptions regarding files Chart.yaml and values.yaml. Change carefully!
      - Any change in this file needs to be synchronized with all charts
*/}}

{{/*
    ===========================================================================
    SECTION: labels
    ===========================================================================
*/}}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "tp-dp-monitor-agent.shared.labels.chartLabelValue" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Selector labels used by the resources in this chart
*/}}
{{- define "tp-dp-monitor-agent.shared.labels.selector" -}}
app.kubernetes.io/name: {{ include "tp-dp-monitor-agent.consts.appName" . }}
app.kubernetes.io/component: {{ include "tp-dp-monitor-agent.consts.component" . }}
app.kubernetes.io/part-of: {{ include "tp-dp-monitor-agent.consts.team" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
platform.tibco.com/workload-type: infra
platform.tibco.com/dataplane-id: {{ .Values.global.cp.dataplaneId }}
platform.tibco.com/capability-instance-id: {{ .Values.global.cp.instanceId }}
{{- end -}}

{{/*
Standard labels added to all resources created by this chart.
Includes labels used as selectors (i.e. template "labels.selector")
*/}}
{{- define "tp-dp-monitor-agent.shared.labels.standard" -}}
{{ include  "tp-dp-monitor-agent.shared.labels.selector" . }}
app.cloud.tibco.com/created-by: {{ include "tp-dp-monitor-agent.consts.team" . }}
helm.sh/chart: {{ include "tp-dp-monitor-agent.shared.labels.chartLabelValue" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.cloud.tibco.com/tenant-name: {{ include "tp-dp-monitor-agent.consts.tenantName" . }}
{{- end -}}