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

variable "role_arn" {
  type        = any
  description = "AWS assume role arn"
}

variable "session_name" {
  type        = any
  description = "Session name for role"
}