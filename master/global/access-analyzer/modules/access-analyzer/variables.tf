variable "env" {
  type        = string
  description = "env for the resources"
} 

variable "unused_access_age" {
  description = "미사용 액세스 분석 기간 (일)"
  type        = number
  default     = 180
}

variable "slack_webhook_url" {
  description = "Slack Webhook URL"
  type        = string
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}

variable "notification_lambda_code" {
  description = "알림 Lambda 함수의 Python 코드"
  type        = string
}

variable "approval_lambda_code" {
  description = "승인 처리 Lambda 함수의 Python 코드"
  type        = string
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
  default     = "cron(10 7 9 * ? *)"  # 기본값으로 매월 9일 오전 7시 10분으로 설정
} 

variable "slack_channel" {
  description = "Slack Channel"
  type        = string
}

variable "slack_bot_token" {
  description = "Slack Bot Token"
  type        = string
}