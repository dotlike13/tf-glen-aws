# Gateway Load Balancer
resource "aws_lb" "gwlb" {
  name               = format("%s-%s", var.name, "gwlb")
  load_balancer_type = "gateway"
  subnets            = var.firewall_subnet_ids


  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "gwlb")
  })
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

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "nfw")
  })
}

# Gateway Load Balancer VPC Endpoint Service
resource "aws_vpc_endpoint_service" "gwlb" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.gwlb.arn]
}

# GWLB Endpoints
resource "aws_vpc_endpoint" "ingress" {
  count           = var.enable_gwlbe_ingress ? 1 : 0
  service_name    = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids      = var.ingress_subnet_ids
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id          = var.security_vpc_id

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "gwlbe-ingress")
  })
}

resource "aws_vpc_endpoint" "egress" {
  count           = var.enable_gwlbe_egress ? 1 : 0
  service_name    = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids      = var.egress_subnet_ids
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id          = var.security_vpc_id

  tags = merge(var.tags, {
    Name = format("%s-%s", var.name, "gwlbe-egress")
  })
}

resource "aws_vpc_endpoint" "east_west" {
  count           = var.enable_gwlbe_east_west ? 1 : 0
  service_name    = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids      = var.east_west_subnet_ids
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id          = var.security_vpc_id

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
    
    dynamic "stateful_rule_group_reference" {
      for_each = var.enable_stateful_rule ? [1] : []
      content {
        resource_arn = aws_networkfirewall_rule_group.stateful[0].arn
      }
    }

    dynamic "stateless_rule_group_reference" {
      for_each = var.enable_stateless_rule ? [1] : []
      content {
        priority     = 100
        resource_arn = aws_networkfirewall_rule_group.stateless[0].arn
      }
    }
  }

  tags = var.tags
}

# Stateful Rule Group
resource "aws_networkfirewall_rule_group" "stateful" {
  count    = var.enable_stateful_rule ? 1 : 0
  capacity = 100
  name     = format("%s-%s", var.name, "stateful-rule")
  type     = "STATEFUL"
  
  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = ["10.0.0.0/8"]
        }
      }
    }
    
    rules_source {
      stateful_rule {
        action = var.stateful_rule_config.action
        header {
          destination      = var.stateful_rule_config.destination_ip
          destination_port = var.stateful_rule_config.destination_port
          direction       = "ANY"
          protocol        = var.stateful_rule_config.protocol
          source          = var.stateful_rule_config.source_ip
          source_port     = var.stateful_rule_config.source_port
        }
        rule_option {
          keyword = "sid:1"
        }
      }
    }

    stateful_rule_options {
      rule_order = var.stateful_rule_config.rule_order
    }
  }

  tags = var.tags
}

# Stateless Rule Group
resource "aws_networkfirewall_rule_group" "stateless" {
  count    = var.enable_stateless_rule ? 1 : 0
  capacity = 100
  name     = format("%s-%s", var.name, "stateless-rule")
  type     = "STATELESS"
  
  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 100
          rule_definition {
            actions = [var.stateless_rule_config.action]
            match_attributes {
              source {
                address_definition = var.stateless_rule_config.source_ip
              }
              destination {
                address_definition = var.stateless_rule_config.destination_ip
              }
            }
          }
        }
      }
    }
  }

  tags = var.tags
}
