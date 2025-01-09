variable "devops_ids" {
  type        = any
  description = "devops accounts"
}

variable "secops_ids" {
  type        = any
  description = "secops accounts"
}

variable "role_arn" {
  type        = any
  description = "AWS assume role arn"
}

variable "session_name" {
  type        = any
  description = "Session name for role"
}
