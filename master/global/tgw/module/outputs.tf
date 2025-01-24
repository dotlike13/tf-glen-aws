output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.arn
}

output "security_attachment_id" {
  description = "ID of the security VPC attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.security.id
}

output "spoke_attachment_ids" {
  description = "Map of spoke VPC attachment IDs"
  value       = { for k, v in aws_ec2_transit_gateway_vpc_attachment.spoke : k => v.id }
}