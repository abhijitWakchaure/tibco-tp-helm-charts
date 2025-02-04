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
{{- define "tp-cp-proxy.consts.appName" }}cp-proxy{{ end -}}

{{/* Tenant name. */}}
{{- define "tp-cp-proxy.consts.tenantName" }}infrastructure{{ end -}}

{{/* Component we're a part of. */}}
{{- define "tp-cp-proxy.consts.component" }}tibco-platform-data-plane{{ end -}}

{{/* Team we're a part of. */}}
{{- define "tp-cp-proxy.consts.team" }}cic-compute{{ end -}}

{{/* Data plane workload type */}}
{{- define "tp-cp-proxy.consts.workloadType" }}infra{{ end -}}

{{/* Secret name created as part of client credentials generation */}}
{{- define "tp-cp-proxy.consts.outputSecretName"}}cp-proxy-client-credentials{{ end -}}

{{- define "tp-cp-proxy.consts.jfrogImageRepo" }}platform/infra{{end}}
{{- define "tp-cp-proxy.consts.ecrImageRepo" }}stratosphere{{end}}
{{- define "tp-cp-proxy.consts.acrImageRepo" }}stratosphere{{end}}
{{- define "tp-cp-proxy.consts.harborImageRepo" }}stratosphere{{end}}
{{- define "tp-cp-proxy.consts.defaultImageRepo" }}stratosphere{{end}}
 
{{- define "tp-cp-proxy.image.registry" }}
  {{- .Values.global.cp.containerRegistry.url }}
{{- end -}}
 
{{/* set repository based on the registry url. We will have different repo for each one. */}}
{{- define "tp-cp-proxy.image.repository" -}}
  {{- if contains "jfrog.io" (include "tp-cp-proxy.image.registry" .) }}
    {{- include "tp-cp-proxy.consts.jfrogImageRepo" .}}
  {{- else if contains "amazonaws.com" (include "tp-cp-proxy.image.registry" .) }}
    {{- include "tp-cp-proxy.consts.ecrImageRepo" .}}
  {{- else if contains "reldocker.tibco.com" (include "tp-cp-proxy.image.registry" .) }}
    {{- include "tp-cp-proxy.consts.harborImageRepo" .}}
  {{- else }}
    {{- include "tp-cp-proxy.consts.defaultImageRepo" .}}
  {{- end }}
{{- end -}}