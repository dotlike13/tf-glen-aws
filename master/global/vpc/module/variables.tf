variable "name" {
  type        = string
  description = "Name prefix for all resources"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

variable "is_security_vpc" {
  type        = bool
  description = "Whether this VPC is a security VPC"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags for all resources"
  default     = {}
} 