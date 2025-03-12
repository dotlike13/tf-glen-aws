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

# GWLB Endpoint 서브넷용 라우팅 테이블
resource "aws_route_table" "gwlbe_ingress" {
  count  = var.is_security_vpc ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "gwlbe-ingress-rt")
  })
}

resource "aws_route_table" "gwlbe_egress" {
  count  = var.is_security_vpc ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "gwlbe-egress-rt")
  })
}

resource "aws_route_table" "gwlbe_east_west" {
  count  = var.is_security_vpc ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "gwlbe-east-west-rt")
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

# GWLB Endpoint 서브넷 라우팅 테이블 연결
resource "aws_route_table_association" "gwlbe_ingress" {
  count          = var.is_security_vpc ? length(var.availability_zones) : 0
  subnet_id      = aws_subnet.gwlbe_ingress[count.index].id
  route_table_id = aws_route_table.gwlbe_ingress[0].id
}

resource "aws_route_table_association" "gwlbe_egress" {
  count          = var.is_security_vpc ? length(var.availability_zones) : 0
  subnet_id      = aws_subnet.gwlbe_egress[count.index].id
  route_table_id = aws_route_table.gwlbe_egress[0].id
}

resource "aws_route_table_association" "gwlbe_east_west" {
  count          = var.is_security_vpc ? length(var.availability_zones) : 0
  subnet_id      = aws_subnet.gwlbe_east_west[count.index].id
  route_table_id = aws_route_table.gwlbe_east_west[0].id
}

# Internet Gateway 추가 필요
resource "aws_internet_gateway" "main" {
  count  = var.is_security_vpc ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "igw")
  })
}

# NAT Gateway 추가 필요
resource "aws_eip" "nat" {
  count = var.is_security_vpc ? length(var.availability_zones) : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = format("%s-%s-%s", var.name, "nat-eip", var.availability_zones[count.index])
  })
}

resource "aws_nat_gateway" "main" {
  count         = var.is_security_vpc ? length(var.availability_zones) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = format("%s-%s-%s", var.name, "nat", var.availability_zones[count.index])
  })
}

# Public Route Table에 Internet Gateway 라우팅 추가
resource "aws_route" "public_igw" {
  count                  = var.is_security_vpc ? 1 : 0
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id
}

# Private Route Table에 NAT Gateway 라우팅 추가
resource "aws_route" "private_nat" {
  count                  = var.is_security_vpc ? length(var.availability_zones) : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

# Private 서브넷에서 다른 VPC로 가는 트래픽을 TGW로 라우팅
resource "aws_route" "private_to_tgw" {
  count                  = var.transit_gateway_id != null ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "10.0.0.0/8"  # VPC CIDR 범위
  transit_gateway_id     = var.transit_gateway_id
}

# Security VPC의 경우 GWLB Endpoint 서브넷에서 TGW로의 라우팅
resource "aws_route" "gwlbe_to_tgw" {
  count                  = var.is_security_vpc && var.transit_gateway_id != null ? 3 : 0
  route_table_id         = count.index == 0 ? aws_route_table.gwlbe_ingress[0].id : (
                          count.index == 1 ? aws_route_table.gwlbe_egress[0].id :
                          aws_route_table.gwlbe_east_west[0].id
                          )
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = var.transit_gateway_id
}

# Security VPC의 인터넷 바운드 트래픽을 GWLB Endpoint로 라우팅
# nfw, tgw의 data 리스소 사용전에 배포되지 않도록 count 문 추가.
resource "aws_route" "to_gwlbe_egress" {
  count                  = var.is_security_vpc && var.gwlbe_egress_endpoint_id != null ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = var.gwlbe_egress_endpoint_id
}

# Security VPC의 East-West 트래픽을 GWLB Endpoint로 라우팅
# nfw, tgw의 data 리스소 사용전에 배포되지 않도록 count 문 추가.
resource "aws_route" "to_gwlbe_east_west" {
  count                  = var.is_security_vpc && var.gwlbe_east_west_endpoint_id != null ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "10.0.0.0/8"
  vpc_endpoint_id        = var.gwlbe_east_west_endpoint_id
}

# Security VPC의 인그레스 트래픽을 GWLB Endpoint로 라우팅
# nfw, tgw의 data 리스소 사용전에 배포되지 않도록 count 문 추가.
resource "aws_route" "to_gwlbe_ingress" {
  count                  = var.is_security_vpc && var.gwlbe_ingress_endpoint_id != null ? 1 : 0
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = var.vpc_cidr  # VPC 내부로 향하는 트래픽
  vpc_endpoint_id        = var.gwlbe_ingress_endpoint_id
}