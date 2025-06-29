{{/*
Expand the name of the chart.
*/}}
{{- define "sglang.name" -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sglang.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
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
{{- define "sglang.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sglang.labels" -}}
helm.sh/chart: {{ include "sglang.chart" . }}
{{ include "sglang.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "sglang.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sglang.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "sglang.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "sglang.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Common environment variables
*/}}
{{- define "sglang.commonEnv" -}}
- name: PYTORCH_FORCE_FLOAT32
  value: "1"
- name: TORCHINDUCTOR_CACHE_DIR
  value: "/torch_cache/inductor_root_cache"
{{- end }}

{{/*
Common volume mounts
*/}}
{{- define "sglang.commonVolumeMounts" -}}
{{- if .Values.storage.shm.enabled }}
- name: shm
  mountPath: /dev/shm
{{- end }}
- name: model
  mountPath: /model
  readOnly: true
- name: torch-cache
  mountPath: /torch_cache/inductor_root_cache
- name: localtime
  mountPath: /etc/localtime
  readOnly: true
{{- end }}

{{/*
Common volumes
*/}}
{{- define "sglang.commonVolumes" -}}
{{- if .Values.storage.shm.enabled }}
- name: shm
  emptyDir:
    medium: Memory
    sizeLimit: {{ .Values.storage.shm.size }}
{{- end }}
- name: model
  persistentVolumeClaim:
    claimName: {{ .Values.storage.model.pvcName }}
- name: torch-cache
  persistentVolumeClaim:
    claimName: {{ .Values.storage.torchCache.pvcName }}
- name: localtime
  hostPath:
    path: /etc/localtime
    type: File
{{- end }}

{{/*
Model path resolution
*/}}
{{- define "sglang.modelPath" -}}
{{- if eq .Values.storage.model.type "huggingface" }}
{{- .Values.global.model.path }}
{{- else }}
/model
{{- end }}
{{- end }}