output "firewall_id" {
  description = "The ID of the Network Firewall"
  value       = aws_networkfirewall_firewall.main.id
}

output "gwlb_arn" {
  description = "The ARN of the Gateway Load Balancer"
  value       = aws_lb.gwlb.arn
}

output "ingress_endpoint_id" {
  description = "The ID of the ingress GWLB endpoint"
  value       = aws_vpc_endpoint.ingress.id
}

output "egress_endpoint_id" {
  description = "The ID of the egress GWLB endpoint"
  value       = aws_vpc_endpoint.egress.id
}

output "east_west_endpoint_id" {
  description = "The ID of the east-west GWLB endpoint"
  value       = aws_vpc_endpoint.east_west.id
}

output "firewall_status" {
  description = "The current status of the Network Firewall"
  value       = aws_networkfirewall_firewall.main.firewall_status
} 