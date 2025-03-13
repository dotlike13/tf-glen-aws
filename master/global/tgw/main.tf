# Transit Gateway
module "tgw" {
  source = "./module"
  
  name   = "transit-gw"
  
  security_vpc_id     = data.terraform_remote_state.vpc.outputs.security_vpc.vpc_id
  security_subnet_ids = data.terraform_remote_state.vpc.outputs.security_vpc.private_subnet_ids
  
  spoke_vpc_configs = {
    vpc-a = {
      vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_a.vpc_id
      subnet_ids = data.terraform_remote_state.vpc.outputs.vpc_a.private_subnet_ids
    }
    # vpc-b = {
    #   vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_b.vpc_id
    #   subnet_ids = data.terraform_remote_state.vpc.outputs.vpc_b.private_subnet_ids
    # }
  }
  
  tags = merge(local.default_tags, {
    Name = format("%s%s-%s", var.prefix, var.env, var.purpose)
  })
}