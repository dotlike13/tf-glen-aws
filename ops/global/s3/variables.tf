# NAME
variable "name" {
  type        = string
  default     = ""
  description = "(Required, Forces new resource) The name of the Permission Set."
}

# DESCRIPTION
variable "description" {
  type        = string
  description = "(Optional) The description of the Permission Set."
  default     = null
}

variable "account" {
  type        = any
  description = "AWS assume role for account"
}

variable "cors_rules" {
  description = "A data structure that configures CORS rules"
  type        = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = []
}
