################################################################################
### SSO PERMISSION SET
################################################################################

# NAME
variable "name" {
  type        = string
  description = "(Required, Forces new resource) The name of the Permission Set."
}

variable "role_arn" {
  type        = any
  description = "AWS assume role arn"
}


# DESCRIPTION
variable "description" {
  type        = string
  description = "(Optional) The description of the Permission Set."
  default     = null
}

# INSTANCE ARN
variable "instance_arn" {
  description = "(Required, Forces new resource) The Amazon Resource Name (ARN) of the SSO Instance under which the operation will be executed."
  type        = string

}

# RELAY STATE
variable "relay_state" {
  description = "(Optional) The relay state URL used to redirect users within the application during the federation authentication process."
  type        = string
  default     = "/"
}

# SESSION DURATION 
variable "session_duration" {
  description = "(Optional) The length of time that the application user sessions are valid in the ISO-8601 standard. Default: PT1H."
  type        = string
  default     = "PT9H"
}

# TAGS
variable "tags" {
  description = "(Optional) Key-value map of resource tags. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(string)
  default     = {}
}

################################################################################
### SSO MANAGED POLICY ATTACHMENT
################################################################################

# SSO MANAGED POLICY ARNS
variable "managed_policy_arns" {
  type        = list(string)
  description = "(Optional) List of aws managed policy arns that will be attached to the permission set."
  default     = []
}

variable "managed_policy" {
  type        = any
}

variable "principal_id" {
  type    = string
  default = ""
}

################################################################################
### SSO GROUP ASSIGNMENT
################################################################################

# PRINCIPAL TYPE (GROUP)
variable "principal_type" {
  description = "(Required, Forces new resource) The entity type for which the assignment will be created. Valid values: USER, GROUP. Defaults to GROUP."
  type        = string
  default     = "GROUP"
}

# TARGET ID (AWS_ACCOUNT_ID)

variable "target_ids" {}

variable "identity_store_id" {}

# TARGET TYPE (AWS_ACCOUNT)
variable "target_type" {
  description = "(Optional, Forces new resource) The entity type for which the assignment will be created. Valid values: AWS_ACCOUNT"
  type        = string
  default     = "AWS_ACCOUNT"
}

variable "ou_id" {
  type        = any
  description = "ou id"
}
