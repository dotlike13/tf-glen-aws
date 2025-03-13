variable "name" {
  type        = string
  description = "Name prefix for all resources"
}

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

variable "enable_stateful_rule" {
  type        = bool
  description = "Enable stateful rule group"
  default     = false
}

variable "enable_stateless_rule" {
  type        = bool
  description = "Enable stateless rule group"
  default     = false
}

variable "stateful_rule_config" {
  description = "Configuration for stateful rule"
  type = object({
    action              = string     # "PASS", "DROP", "REJECT", "ALERT"
    source_ip           = string
    destination_ip      = string
    source_port        = string
    destination_port   = string
    protocol           = string
    rule_order         = string     # "ACTION_ORDER" or "STRICT_ORDER"
  })
  default = {
    action              = "PASS"
    source_ip           = "ANY"
    destination_ip      = "ANY"
    source_port        = "ANY"
    destination_port   = "ANY"
    protocol           = "IP"
    rule_order         = "ACTION_ORDER"
  }

  validation {
    condition = contains(["PASS", "DROP", "REJECT", "ALERT"], var.stateful_rule_config.action)
    error_message = "Action must be one of: PASS, DROP, REJECT, ALERT"
  }

  validation {
    condition = contains(["DEFAULT_ACTION_ORDER", "STRICT_ORDER"], var.stateful_rule_config.rule_order)
    error_message = "Rule order must be either ACTION_ORDER or STRICT_ORDER"
  }
}

variable "stateless_rule_config" {
  description = "Configuration for stateless rule"
  type = object({
    action              = string # "aws:pass", "aws:drop", "aws:forward_to_sfe"
    source_ip           = string
    destination_ip      = string
  })
  default = {
    action              = "aws:forward_to_sfe"
    source_ip           = "0.0.0.0/0"
    destination_ip      = "0.0.0.0/0"
  }

  validation {
    condition = contains(["aws:pass", "aws:drop", "aws:forward_to_sfe"], var.stateless_rule_config.action)
    error_message = "Action must be one of: aws:pass, aws:drop, aws:forward_to_sfe"
  }
}

variable "enable_gwlbe_ingress" {
  type        = bool
  description = "Enable GWLB Endpoint for ingress traffic"
  default     = true
}

variable "enable_gwlbe_egress" {
  type        = bool
  description = "Enable GWLB Endpoint for egress traffic"
  default     = true
}

variable "enable_gwlbe_east_west" {
  type        = bool
  description = "Enable GWLB Endpoint for east-west traffic"
  default     = true
} 