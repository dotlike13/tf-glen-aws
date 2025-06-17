variable "unused_access_age" {
  description = "미사용 액세스 분석 기간 (일)"
  type        = number
  default     = 180
}

variable "slack_webhook_url" {
  description = "Slack Webhook URL"
  type        = string
}

variable "role_arn" {
  type        = any
  description = "AWS assume role arn"
}

variable "session_name" {
  type        = any
  description = "Session name for role"
}

variable "prefix" {
  type        = string
  description = "prefix for the resources"
}

variable "team" {
  type        = string
  description = "env for the resources"
}

variable "env" {
  type        = string
  description = "env for the resources"
}

variable "purpose" {
  type        = string
  description = "purpose for the resources"
}

variable "resource_tags" {
  description = "분석에서 제외할 리소스 태그 목록"
  type = list(object({
    key   = string
    value = string
  }))
  default = []
}

variable "schedule_expression" {
  description = "EventBridge 규칙의 스케줄 표현식 (cron 또는 rate 형식)"
  type        = string
  default     = "cron(00 1 10 * ? *)"
}

variable "slack_channel" {
  description = "Slack Channel"
  type        = string
}

variable "slack_bot_token" {
  description = "Slack Bot Token"
  type        = string
}