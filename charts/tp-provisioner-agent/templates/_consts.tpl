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
{{- define "tp-provisioner-agent.consts.appName" }}provisioner-agent{{ end -}}

{{/* Tenant name. */}}
{{- define "tp-provisioner-agent.consts.tenantName" }}infrastructure{{ end -}}

{{/* Component we're a part of. */}}
{{- define "tp-provisioner-agent.consts.component" }}tibco-platform-data-plane{{ end -}}

{{/* Data plane workload type */}}
{{- define "tp-provisioner-agent.consts.workloadType" }}infra{{ end -}}

{{/* Team we're a part of. */}}
{{- define "tp-provisioner-agent.consts.team" }}cic-compute{{ end -}}

{{- define "tp-provisioner-agent.consts.jfrogImageRepo" }}platform/infra{{end}}
{{- define "tp-provisioner-agent.consts.ecrImageRepo" }}stratosphere{{end}}
{{- define "tp-provisioner-agent.consts.acrImageRepo" }}stratosphere{{end}}
{{- define "tp-provisioner-agent.consts.harborImageRepo" }}stratosphere{{end}}
{{- define "tp-provisioner-agent.consts.defaultImageRepo" }}stratosphere{{end}}

{{- define "tp-provisioner-agent.image.registry" }}
  {{- .Values.global.tibco.containerRegistry.url }}
{{- end -}}

{{/* set repository based on the registry url. We will have different repo for each one. */}}
{{- define "tp-provisioner-agent.image.repository" -}}
  {{- if contains "jfrog.io" (include "tp-provisioner-agent.image.registry" .) }} 
    {{- include "tp-provisioner-agent.consts.jfrogImageRepo" .}}
  {{- else if contains "amazonaws.com" (include "tp-provisioner-agent.image.registry" .) }}
    {{- include "tp-provisioner-agent.consts.ecrImageRepo" .}}
  {{- else if contains "reldocker.tibco.com" (include "tp-provisioner-agent.image.registry" .) }}
    {{- include "tp-provisioner-agent.consts.harborImageRepo" .}}
  {{- else }}
    {{- include "tp-provisioner-agent.consts.defaultImageRepo" .}}
  {{- end }}
{{- end -}}