resource "aws_ec2_transit_gateway" "main" {
  description = "Main Transit Gateway"
  
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  
  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "tgw")
  })
}

resource "aws_ec2_transit_gateway_route_table" "security" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "security-rt")
  })
}

resource "aws_ec2_transit_gateway_route_table" "spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "spoke-rt")
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "security" {
  subnet_ids         = var.security_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.security_vpc_id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "security-attachment")
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke" {
  for_each = var.spoke_vpc_configs

  subnet_ids         = each.value.subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = each.value.vpc_id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.tags, {
    Name = format("%s-%s-%s", var.name, each.key, "attachment")
  })
}

resource "aws_ec2_transit_gateway_route_table_association" "security" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.security.id
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke" {
  for_each = aws_ec2_transit_gateway_vpc_attachment.spoke

  transit_gateway_attachment_id  = each.value.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

resource "aws_ec2_transit_gateway_route" "to_security" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}