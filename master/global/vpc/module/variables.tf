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

variable "is_nat_gw" {
  type        = bool
  description = "Whether this nat gateway is needed"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags for all resources"
  default     = {}
}

variable "transit_gateway_id" {
  type        = string
  description = "ID of the Transit Gateway to attach to"
  default     = null
}

variable "gwlbe_egress_endpoint_id" {
  type        = string
  description = "ID of the GWLB Endpoint for egress traffic"
  default     = null
}

variable "gwlbe_east_west_endpoint_id" {
  type        = string
  description = "ID of the GWLB Endpoint for east-west traffic"
  default     = null
}

variable "gwlbe_ingress_endpoint_id" {
  type        = string
  description = "ID of the GWLB Endpoint for ingress traffic"
  default     = null
} 