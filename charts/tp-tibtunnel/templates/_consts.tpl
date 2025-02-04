{{/* 
   Copyright (c) 2023 Cloud Software Group, Inc.
   All Rights Reserved.

   File       : _consts.tpl
   Version    : 1.0.0
   Description: Template helpers defining constants for this chart.
   
    NOTES: 
      - this file contains values that are specific only to this chart. Edit accordingly.
*/}}

{{/* A fixed short name for the application. Can be different than the chart name */}}
{{- define "tp-tibtunnel.consts.appName" }}tp-tibtunnel{{ end -}}

{{/* Tenant name. */}}
{{- define "tp-tibtunnel.consts.tenantName" }}infrastructure{{ end -}}

{{/* Component we're a part of. */}}
{{- define "tp-tibtunnel.consts.component" }}tibco-platform-data-plane{{ end -}}

{{/* Team we're a part of. */}}
{{- define "tp-tibtunnel.consts.team" }}cic-compute{{ end -}}

{{/* Data plane workload type */}}
{{- define "tp-tibtunnel.consts.workloadType" }}infra{{ end -}}

{{- define "tp-tibtunnel.consts.fluentbit.buildNumber" }}1.9.4{{end -}}

{{- define "tp-tibtunnel.consts.jfrogImageRepo" }}platform/infra{{end}}
{{- define "tp-tibtunnel.consts.ecrImageRepo" }}stratosphere{{end}}
{{- define "tp-tibtunnel.consts.acrImageRepo" }}stratosphere{{end}}
{{- define "tp-tibtunnel.consts.harborImageRepo" }}stratosphere{{end}}
{{- define "tp-tibtunnel.consts.defaultImageRepo" }}stratosphere{{end}}

{{- define "tp-tibtunnel.image.registry" }}
  {{- .Values.global.tibco.containerRegistry.url }}
{{- end -}}

{{/* set repository based on the registry url. We will have different repo for each one. */}}
{{- define "tp-tibtunnel.image.repository" -}}
  {{- if contains "jfrog.io" (include "tp-tibtunnel.image.registry" .) }} 
    {{- include "tp-tibtunnel.consts.jfrogImageRepo" .}}
  {{- else if contains "amazonaws.com" (include "tp-tibtunnel.image.registry" .) }}
    {{- include "tp-tibtunnel.consts.ecrImageRepo" .}}
  {{- else if contains "reldocker.tibco.com" (include "tp-tibtunnel.image.registry" .) }}
    {{- include "tp-tibtunnel.consts.harborImageRepo" .}}
  {{- else }}
    {{- include "tp-tibtunnel.consts.defaultImageRepo" .}}
  {{- end }}
{{- end -}}