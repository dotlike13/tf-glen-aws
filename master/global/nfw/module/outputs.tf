output "firewall_id" {
  description = "The ID of the Network Firewall"
  value       = aws_networkfirewall_firewall.main.id
}

output "firewall_arn" {
  description = "The ARN of the Network Firewall"
  value       = aws_networkfirewall_firewall.main.arn
}

output "gwlb_arn" {
  description = "The ARN of the Gateway Load Balancer"
  value       = aws_lb.gwlb.arn
}

output "gwlb_endpoint_service_name" {
  description = "The service name of the Gateway Load Balancer endpoint service"
  value       = aws_vpc_endpoint_service.gwlb.service_name
}

output "ingress_endpoint_id" {
  description = "The ID of the ingress GWLB endpoint"
  value       = var.enable_gwlbe_ingress ? aws_vpc_endpoint.ingress[0].id : null
}

output "egress_endpoint_id" {
  description = "The ID of the egress GWLB endpoint"
  value       = var.enable_gwlbe_egress ? aws_vpc_endpoint.egress[0].id : null
}

output "east_west_endpoint_id" {
  description = "The ID of the east-west GWLB endpoint"
  value       = var.enable_gwlbe_east_west ? aws_vpc_endpoint.east_west[0].id : null
}

output "firewall_status" {
  description = "The current status of the Network Firewall"
  value       = aws_networkfirewall_firewall.main.firewall_status
}