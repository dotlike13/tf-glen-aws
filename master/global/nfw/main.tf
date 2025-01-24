module "network_firewall" {
  source = "./module"

  name            = "test-nfw"
  security_vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  
  prefix = "test"

  firewall_subnet_ids   = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  ingress_subnet_ids    = data.terraform_remote_state.vpc.outputs.gwlbe_ingress_subnet_ids
  egress_subnet_ids     = data.terraform_remote_state.vpc.outputs.gwlbe_egress_subnet_ids
  east_west_subnet_ids  = data.terraform_remote_state.vpc.outputs.gwlbe_east_west_subnet_ids

  tags = merge(local.default_tags, {
    Name = format("%s%s-%s", var.prefix, var.env, var.purpose)
  })
}