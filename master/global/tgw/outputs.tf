output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = module.tgw.transit_gateway_id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway"
  value       = module.tgw.transit_gateway_arn
}

output "security_attachment_id" {
  description = "ID of the security VPC attachment"
  value       = module.tgw.security_attachment_id
}

output "spoke_attachment_ids" {
  description = "Map of spoke VPC attachment IDs"
  value       = module.tgw.spoke_attachment_ids
}