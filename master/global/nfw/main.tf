module "network_firewall" {
  source = "./module"

  name            = "test-nfw"
  security_vpc_id = data.terraform_remote_state.vpc.outputs.security_vpc.vpc_id
  
  prefix = "test"

  firewall_subnet_ids   = data.terraform_remote_state.vpc.outputs.security_vpc.private_subnet_ids
  ingress_subnet_ids    = data.terraform_remote_state.vpc.outputs.security_vpc.gwlbe_ingress_subnet_ids
  egress_subnet_ids     = data.terraform_remote_state.vpc.outputs.security_vpc.gwlbe_egress_subnet_ids
  east_west_subnet_ids  = data.terraform_remote_state.vpc.outputs.security_vpc.gwlbe_east_west_subnet_ids

  tags = merge(local.default_tags, {
    Name = format("%s%s-%s", var.prefix, var.env, var.purpose)
  })
}