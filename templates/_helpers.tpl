{{/*
返回 Web 地址
*/}}
{{- define "app.webUrl" -}}
{{- $host := .Values.ingress.host | default "" -}}
{{- printf "%s://%s" (ternary "https" "http" .Values.ingress.tls.enabled) $host -}}
{{- end -}}

{{/*
返回镜像名称
*/}}
{{- define "app.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) -}}
{{- end -}}

{{/*
返回 Docker 镜像源密文名称
*/}}
{{- define "app.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" (list .Values.image) "global" .Values.global) -}}
{{- end -}}

{{/*
创建一个默认的全限定 PostgreSQL 名称
*/}}
{{- define "app.postgresql.fullname" -}}
{{- $name := default "postgresql" .Values.postgresql.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
创建一个默认的全限定 Redis 名称
*/}}
{{- define "app.redis.fullname" -}}
{{- $name := default "redis" .Values.redis.nameOverride -}}
{{- printf "%s-%s-master" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
创建一个默认的全限定 RabbitMQ 名称
*/}}
{{- define "app.rabbitmq.fullname" -}}
{{- $name := default "rabbitmq" .Values.rabbitmq.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
创建一个默认的全限定 Meilisearch 名称
*/}}
{{- define "app.meilisearch.fullname" -}}
{{- $name := default "meilisearch" .Values.meilisearch.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
获取 PostgreSQL 凭证密文名称
*/}}
{{- define "app.postgresql.secretName" -}}
{{- if and (.Values.postgresql.enabled) (not .Values.postgresql.existingSecret) -}}
    {{- printf "%s" (include "app.postgresql.fullname" .) -}}
{{- else if and (.Values.postgresql.enabled) (.Values.postgresql.existingSecret) -}}
    {{- printf "%s" .Values.postgresql.existingSecret -}}
{{- else }}
    {{- if .Values.externalPostgresql.existingSecret -}}
        {{- printf "%s" .Values.externalPostgresql.existingSecret -}}
    {{- else -}}
        {{ printf "%s-%s" (include "common.names.fullname" .) "postgresql" }}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
获取 Redis 凭证密文名称
*/}}
{{- define "app.redis.secretName" -}}
{{- if and (.Values.redis.enabled) (not .Values.redis.auth.existingSecret) -}}
    {{- $name := default "redis" .Values.redis.nameOverride -}}
    {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- else if and (.Values.redis.enabled) ( .Values.redis.auth.existingSecret) -}}
    {{- printf "%s" .Values.redis.auth.existingSecret -}}
{{- else }}
    {{- if .Values.externalRedis.existingSecret -}}
        {{- printf "%s" .Values.externalRedis.existingSecret -}}
    {{- else -}}
        {{ printf "%s-%s" (include "common.names.fullname" .) "redis" }}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
获取 RabbitMQ 凭证密文名称
*/}}
{{- define "app.rabbitmq.secretName" -}}
{{- if and (.Values.rabbitmq.enabled) (not .Values.rabbitmq.auth.existingPasswordSecret) -}}
    {{- $name := default "rabbitmq" .Values.rabbitmq.nameOverride -}}
    {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- else if and (.Values.rabbitmq.enabled) ( .Values.rabbitmq.auth.existingPasswordSecret) -}}
    {{- printf "%s" .Values.rabbitmq.auth.existingPasswordSecret -}}
{{- else }}
    {{- if .Values.externalRabbitmq.existingSecret -}}
        {{- printf "%s" .Values.externalRabbitmq.existingSecret -}}
    {{- else -}}
        {{ printf "%s-%s" (include "common.names.fullname" .) "rabbitmq" }}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
添加环境变量来配置 PostgreSQL 值
*/}}
{{- define "app.configure.postgresql" -}}
- name: DATABASE_TYPE
  value: postgres
- name: DATABASE_HOST
  value: {{ ternary (include "app.postgresql.fullname" .) .Values.externalPostgresql.host .Values.postgresql.enabled | quote }}
- name: DATABASE_PORT
  value: {{ ternary "5432" .Values.externalPostgresql.port .Values.postgresql.enabled | quote }}
- name: DATABASE_NAME
  value: {{ ternary .Values.postgresql.postgresqlDatabase .Values.externalPostgresql.name .Values.postgresql.enabled | quote }}
- name: DATABASE_USERNAME
  value: {{ ternary .Values.postgresql.postgresqlUsername .Values.externalPostgresql.username .Values.postgresql.enabled | quote }}
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "app.postgresql.secretName" . }}
      key: postgresql-password
{{- end }}

{{/*
添加环境变量来配置 Redis 值
*/}}
{{- define "app.configure.redis" -}}
- name: REDIS_HOST
  value: {{ ternary (include "app.redis.fullname" .) .Values.externalRedis.host .Values.redis.enabled | quote }}
- name: REDIS_PORT
  value: {{ ternary "6379" .Values.externalRedis.port .Values.redis.enabled | quote }}
{{- if and (not .Values.redis.enabled) .Values.externalRedis.username }}
- name: REDIS_USERNAME
  value: {{ .Values.externalRedis.username | quote }}
{{- end }}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "app.redis.secretName" . }}
      key: redis-password
{{- end -}}

{{/*
添加环境变量来配置 RabbitMQ 值
*/}}
{{- define "app.configure.rabbitmq" -}}
- name: RABBITMQ_HOST
  value: {{ ternary (include "app.rabbitmq.fullname" .) .Values.externalRabbitmq.host .Values.rabbitmq.enabled | quote }}
- name: RABBITMQ_PORT
  value: {{ ternary "5432" .Values.externalRabbitmq.port .Values.rabbitmq.enabled | quote }}
- name: RABBITMQ_VHOST
  value: {{ ternary .Values.rabbitmq.vhost .Values.externalRabbitmq.vhost .Values.rabbitmq.enabled | quote }}
- name: RABBITMQ_USERNAME
  value: {{ ternary .Values.rabbitmq.username .Values.externalRabbitmq.username .Values.rabbitmq.enabled | quote }}
- name: RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "app.rabbitmq.secretName" . }}
      key: rabbitmq-password
{{- end }}

{{/*
添加环境变量来配置 Meilisearch 值
*/}}
{{- define "app.configure.meilisearch" -}}
- name: MEILISEARCH_HOST
  value: "http://{{ include "app.meilisearch.fullname" . }}:7700"
- name: MEILISEARCH_KEY
  value: {{ .Values.meilisearch.environment.MEILI_MASTER_KEY | quote }}
{{- end -}}
