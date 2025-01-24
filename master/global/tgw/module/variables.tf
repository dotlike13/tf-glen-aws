variable "name" {
  type        = string
  description = "Name prefix for Transit Gateway"
}

variable "security_vpc_id" {
  type        = string
  description = "ID of the security VPC"
}

variable "security_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs in security VPC for TGW attachment"
}

variable "spoke_vpc_configs" {
  type = map(object({
    vpc_id     = string
    subnet_ids = list(string)
  }))
  description = "Map of spoke VPC configurations"
}

variable "tags" {
  type        = map(string)
  description = "Tags for all resources"
  default     = {}
}