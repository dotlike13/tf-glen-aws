module "network_firewall" {
  source = "./module"

  name            = "test-nfw"
  security_vpc_id = data.terraform_remote_state.vpc.outputs.security_vpc.vpc_id
  
  prefix = "test"

  firewall_subnet_ids   = [data.terraform_remote_state.vpc.outputs.security_vpc.private_subnet_ids[0]]
  ingress_subnet_ids    = [data.terraform_remote_state.vpc.outputs.security_vpc.gwlbe_ingress_subnet_ids[0]]
  egress_subnet_ids     = [data.terraform_remote_state.vpc.outputs.security_vpc.gwlbe_egress_subnet_ids[0]]
  east_west_subnet_ids  = [data.terraform_remote_state.vpc.outputs.security_vpc.gwlbe_east_west_subnet_ids[0]]

  # GWLB Endpoint 활성화 설정
  enable_gwlbe_ingress   = true    # 인그레스 트래픽 필요
  enable_gwlbe_egress    = true    # 이그레스 트래픽 필요
  enable_gwlbe_east_west = false   # 테스트에서는 비활성화

  enable_stateful_rule  = true   # stateful 규칙 활성화
  enable_stateless_rule = true   # stateless 규칙 활성화

  stateless_rule_config = {
    action         = "aws:drop"           # "aws:pass", "aws:drop", "aws:forward_to_sfe" 중 선택
    source_ip      = "10.0.0.0/16"        # 원하는 소스 IP CIDR
    destination_ip = "192.168.0.0/16"     # 원하는 대상 IP CIDR
  }

  stateful_rule_config = {
    action              = "DROP"              # "PASS", "DROP", "REJECT", "ALERT" 중 선택
    source_ip           = "10.0.0.0/16"       # 원하는 소스 IP 또는 "ANY"
    destination_ip      = "192.168.0.0/16"    # 원하는 대상 IP 또는 "ANY"
    source_port        = "80"                # 원하는 소스 포트 또는 "ANY"
    destination_port   = "443"               # 원하는 대상 포트 또는 "ANY"
    protocol           = "TCP"               # 원하는 프로토콜
    rule_order         = "STRICT_ORDER"      # "ACTION_ORDER" 또는 "STRICT_ORDER"
  }

  tags = merge(local.default_tags, {
    Name = format("%s%s-%s", var.prefix, var.env, var.purpose)
  })
}