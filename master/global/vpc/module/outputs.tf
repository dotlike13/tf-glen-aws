output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "gwlbe_ingress_subnet_ids" {
  description = "List of GWLB endpoint ingress subnet IDs"
  value       = var.is_security_vpc ? aws_subnet.gwlbe_ingress[*].id : []
}

output "gwlbe_egress_subnet_ids" {
  description = "List of GWLB endpoint egress subnet IDs"
  value       = var.is_security_vpc ? aws_subnet.gwlbe_egress[*].id : []
}

output "gwlbe_east_west_subnet_ids" {
  description = "List of GWLB endpoint east-west subnet IDs"
  value       = var.is_security_vpc ? aws_subnet.gwlbe_east_west[*].id : []
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

output "public_subnet_cidr_blocks" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidr_blocks" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "gwlbe_ingress_subnet_cidr_blocks" {
  description = "List of GWLB endpoint ingress subnet CIDR blocks"
  value       = var.is_security_vpc ? aws_subnet.gwlbe_ingress[*].cidr_block : []
}

output "gwlbe_egress_subnet_cidr_blocks" {
  description = "List of GWLB endpoint egress subnet CIDR blocks"
  value       = var.is_security_vpc ? aws_subnet.gwlbe_egress[*].cidr_block : []
}

output "gwlbe_east_west_subnet_cidr_blocks" {
  description = "List of GWLB endpoint east-west subnet CIDR blocks"
  value       = var.is_security_vpc ? aws_subnet.gwlbe_east_west[*].cidr_block : []
}

output "gwlbe_ingress_route_table_id" {
  description = "ID of the GWLB endpoint ingress route table"
  value       = var.is_security_vpc ? aws_route_table.gwlbe_ingress[0].id : null
}

output "gwlbe_egress_route_table_id" {
  description = "ID of the GWLB endpoint egress route table"
  value       = var.is_security_vpc ? aws_route_table.gwlbe_egress[0].id : null
}

output "gwlbe_east_west_route_table_id" {
  description = "ID of the GWLB endpoint east-west route table"
  value       = var.is_security_vpc ? aws_route_table.gwlbe_east_west[0].id : null
}