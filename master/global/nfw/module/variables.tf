variable "prefix" {
  type        = string
  description = "Prefix for all resources"
}

variable "security_vpc_id" {
  type        = string
  description = "Security VPC ID where the firewall will be deployed"
}

variable "firewall_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for Network Firewall deployment"
}

variable "ingress_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for ingress GWLB endpoints"
}

variable "egress_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for egress GWLB endpoints"
}

variable "east_west_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for east-west GWLB endpoints"
}

variable "blocked_domains" {
  type        = list(string)
  description = "List of domains to block"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
} 