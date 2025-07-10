# variable "role_arn" {
#   type        = string
#   description = "AWS assume role arn"
# }

# variable "session_name" {
#   type        = string
#   description = "Session name for role"
# }
variable "web_acls" {
  description = "Map of WAF ACL configurations"
  type = map(object({
    name           = string
    description    = optional(string)
    scope          = string
    default_action = string
    managed_rules = optional(list(object({
      name            = string
      priority        = number
      override_action = string
      vendor_name     = string
      rule_name       = string
      rule_action_overrides = list(object({
        name   = string
        action = string
      }))
    })), [])
    custom_rules = optional(list(object({
      name                    = string
      priority                = number
      action                  = string
      type                    = string
      host                    = optional(string)
      path_pattern            = optional(string)
      search_string           = optional(string)
      regex_string            = optional(string)
      custom_rule_metric_name = optional(string)
    })), [])
    ip_rate_limit_rules = optional(list(object({
      name                  = string
      priority              = number
      limit                 = number
      evaluation_window_sec = number
      action                = string
      custom_response = optional(object({
        response_code            = number
        custom_response_body_key = optional(string)
      }))
      scope_down_statement = optional(object({
        byte_match_statement = optional(object({
          search_string = string
          field_to_match = object({
            uri_path = optional(object({}))
          })
          text_transformation = object({
            priority = number
            type     = string
          })
          positional_constraint = string
        }))
        ip_set_reference_statement = optional(object({
          arn = string
        }))
      }))
    })), [])
    ip_set_rules = optional(list(object({
      name         = string
      priority     = number
      ip_set_name  = string
      use_existing = bool
      action       = string
    })), [])
    rule_group_rules = optional(list(object({
      name            = string
      priority        = number
      rule_group_name = string
      action          = string
    })), [])
    resource_arns   = optional(list(string), [])
    logging_enabled = optional(bool, false)
    log_group_name  = optional(string)
    association_alb_name = optional(list(string), [])
  }))
}
# variable "prefix" {
#   type        = string
#   description = "Prefix for all resources"
#   default     = ""
# }

# variable "team" {
#   type        = string
#   description = "team name for the resources"
# }

# variable "env" {
#   type        = string
#   description = "Environment name"
# }

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

variable "TFC_AWS_PROVIDER_AUTH" {
  description = "AWS provider authentication for Terraform Cloud"
  type        = bool
  default     = false
}

variable "TFC_AWS_RUN_ROLE_ARN" {
  description = "ARN of the AWS IAM Role for Terraform Cloud runs"
  type        = string
  default     = ""
}

variable "TFC_AWS_WORKLOAD_IDENTITY_AUDIENCE" {
  description = "The audience value to use for AWS Workload Identity authentication"
  type        = string
  default     = "aws.workload.identity"
}

variable "AWS_REGION" {
  description = "The AWS region to create resources in"
  type        = string
  default     = "ap-northeast-2" # Seoul region as default
}

