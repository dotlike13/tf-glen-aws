resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "vpc")
  })
}

# Subnets
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = format("%s-%s-%s", var.name, "public", var.availability_zones[count.index])
  })
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = format("%s-%s-%s", var.name, "private", var.availability_zones[count.index])
  })
}

# Security VPC specific subnets
resource "aws_subnet" "gwlbe_ingress" {
  count             = var.is_security_vpc ? length(var.availability_zones) : 0
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 2 * length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = format("%s-%s-%s", var.name, "gwlbe-ingress", var.availability_zones[count.index])
  })
}

resource "aws_subnet" "gwlbe_egress" {
  count             = var.is_security_vpc ? length(var.availability_zones) : 0
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 3 * length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = format("%s-%s-%s", var.name, "gwlbe-egress", var.availability_zones[count.index])
  })
}

resource "aws_subnet" "gwlbe_east_west" {
  count             = var.is_security_vpc ? length(var.availability_zones) : 0
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 4 * length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = format("%s-%s-%s", var.name, "gwlbe-east-west", var.availability_zones[count.index])
  })
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "public-rt")
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "private-rt")
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}