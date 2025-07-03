# variable "role_arn" {
#   type        = string
#   description = "AWS assume role arn"
# }

# variable "session_name" {
#   type        = string
#   description = "Session name for role"
# }

variable "web_acls" {
  type = map(object({
    name           = string
    scope          = string # "REGIONAL" or "CLOUDFRONT"
    description    = string
    default_action = optional(string, "allow") # "allow" or "block"
    managed_rules = list(object({
      name            = string
      priority        = number
      override_action = string # "none" or "count"
      vendor_name     = string
      rule_name       = string
      rule_action_overrides = optional(list(object({
        name   = string
        action = string # "allow", "block", "count", or "challenge"
      })), [])
    }))
    custom_rules = optional(list(object({
      name         = string
      priority     = number
      action       = string # "allow", "block", "count", or "challenge"
      type         = string # "host_match", "path_match", "host_path_match"
      host         = optional(string)
      path_pattern = optional(string)
    })), [])
    ip_rate_limit_rules = list(object({
      name                  = string
      priority              = number
      limit                 = number
      evaluation_window_sec = optional(number, 300)
      action                = string # "allow", "block", "count", or "challenge"
      response_code         = number
      response_body         = string
      scope_down_statement = optional(object({
        ip_set_reference_statement = object({
          arn = string
        })
      }))
    }))
    ip_set_rules = list(object({
      name        = string
      priority    = number
      ip_set_name = string
      action      = string # "allow", "block", or "count"
      use_existing = optional(bool, false)  # true면 data source 사용, false면 새로 생성
      addresses    = optional(list(string), []) # use_existing = false일 때 필수
    }))
    resource_arns   = list(string)
    logging_enabled = optional(bool, false)
    log_group_name  = optional(string) # 기존 CloudWatch Log Group 이름
    # ddos_protection = optional(object({
    #   alb_low_reputation_mode = string
    # })), []
  }))
  description = "Map of WAF Web ACL configurations"
  default     = {}
}

variable "prefix" {
  type        = string
  description = "Prefix for all resources"
  default     = ""
}

variable "team" {
  type        = string
  description = "team name for the resources"
}

variable "env" {
  type        = string
  description = "Environment name"
}

# variable "purpose" {
#   type        = string
#   description = "purpose for the resources"
# }

variable "web_acl_scope" {
  type        = string
  description = "Scope of the WAF web ACL (REGIONAL or CLOUDFRONT)"
  default     = "REGIONAL"
}

variable "managed_rules" {
  type = list(object({
    name                = string
    priority            = number
    override_action     = string # "none" or "count"
    vendor_name         = string
    rule_name           = string
    excluded_rule_names = list(string)
  }))
  description = "List of AWS managed rules to enable"
  default     = []
}

variable "ip_rate_limit_rules" {
  type = list(object({
    name          = string
    priority      = number
    limit         = number
    action        = string # "allow", "block", or "count"
    response_code = number
    response_body = string
  }))
  description = "List of IP rate limiting rules"
  default     = []
}

variable "ip_set_rules" {
  type = list(object({
    name        = string
    priority    = number
    ip_set_name = string
    addresses   = list(string)
    action      = string # "allow", "block", or "count"
  }))
  description = "List of IP set based rules"
  default     = []
}

variable "resource_arns" {
  type        = list(string)
  description = "List of ARNs of resources to associate with the WAF web ACL"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
} 