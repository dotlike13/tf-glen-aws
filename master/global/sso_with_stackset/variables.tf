variable "devops_ids" {
  type        = any
  description = "devops accounts"
}

variable "secops_ids" {
  type        = any
  description = "secops accounts"
}

variable "secops_ou_id" {
  type        = any
  description = "secops ou id"
}

variable "devops_ou_id" {
  type        = any
  description = "devops ou id"
}

variable "role_arn" {
  type        = any
  description = "AWS assume role arn"
}

variable "session_name" {
  type        = any
  description = "Session name for role"
}

# variable "permission_sets" {
#   type = map(object({
#     name = string,
#     description = string,
#     principal_id = string,
#     iam_policy_json = optional(string),
#     target_ids = list(string)
#   }))

#   description = "permission set"
# }
