{{/* common labels */}}
{{- define "common.labels" -}}
app: nginx
type: demo
identify_key: {{ .Values.identity_key }}
{{- end }}