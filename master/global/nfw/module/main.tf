# Gateway Load Balancer
resource "aws_lb" "gwlb" {
  name               = format("%s-%s", var.name, "gwlb")
  load_balancer_type = "gateway"
  subnets            = var.firewall_subnet_ids

  tags = var.tags
}

# Gateway Load Balancer Target Group
resource "aws_lb_target_group" "nfw" {
  name        = format("%s-%s", var.name, "nfw-tg")
  port        = 6081
  protocol    = "GENEVE"
  target_type = "ip"
  vpc_id      = var.security_vpc_id

  health_check {
    port     = 80
    protocol = "HTTP"
  }
}

# Network Firewall
resource "aws_networkfirewall_firewall" "main" {
  name                = format("%s-%s", var.name, "nfw")
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id             = var.security_vpc_id
  
  dynamic "subnet_mapping" {
    for_each = var.firewall_subnet_ids
    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = var.tags
}

# Gateway Load Balancer VPC Endpoint Service
resource "aws_vpc_endpoint_service" "gwlb" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.gwlb.arn]
}

# GWLB Endpoints
resource "aws_vpc_endpoint" "ingress" {
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids        = var.ingress_subnet_ids
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = var.security_vpc_id

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "gwlbe-ingress")
  })
}

resource "aws_vpc_endpoint" "egress" {
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids        = var.egress_subnet_ids
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = var.security_vpc_id

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "gwlbe-egress")
  })
}

resource "aws_vpc_endpoint" "east_west" {
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids        = var.east_west_subnet_ids
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = var.security_vpc_id

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "gwlbe-east-west")
  })
}

# Firewall Policy
resource "aws_networkfirewall_firewall_policy" "main" {
  name = format("%s-%s", var.name, "policy")

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.block_domains.arn
    }
  }

  tags = var.tags
}

# Rule Groups
resource "aws_networkfirewall_rule_group" "block_domains" {
  capacity = 100
  name     = format("%s-%s", var.name, "domain-block")
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "DENYLIST"
        target_types        = ["HTTP_HOST", "TLS_SNI"]
        targets             = var.blocked_domains
      }
    }
  }

  tags = var.tags
}