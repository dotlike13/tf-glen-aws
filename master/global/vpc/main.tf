# Security VPC
module "security_vpc" {
  source = "./module"
  
  name            = "security"
  vpc_cidr        = "10.0.0.0/16"
  is_security_vpc = true
  
  availability_zones = [
    "ap-northeast-2a"
    # "ap-northeast-2c"
  ]
  
  # transit_gateway_id           = data.terraform_remote_state.tgw.outputs.transit_gateway_id
  # gwlbe_ingress_endpoint_id   = data.terraform_remote_state.nfw.outputs.ingress_endpoint_id
  # gwlbe_egress_endpoint_id    = data.terraform_remote_state.nfw.outputs.egress_endpoint_id
  # gwlbe_east_west_endpoint_id = data.terraform_remote_state.nfw.outputs.east_west_endpoint_id

  tags = merge(local.default_tags, {
    Name = format("%s%s-%s", var.prefix, var.env, var.purpose)
  })
}

# Service VPC A
module "vpc_a" {
  source = "./module"
  
  name     = "vpc-a"
  vpc_cidr = "10.1.0.0/16"
  
  availability_zones = [
    "ap-northeast-2a"
    # "ap-northeast-2c"
  ]

  # transit_gateway_id = data.terraform_remote_state.tgw.outputs.transit_gateway_id

  tags = merge(local.default_tags, {
    Name = format("%s%s-%s", var.prefix, var.env, var.purpose)
  })
}

# Service VPC B
module "vpc_b" {
  source = "./module"
  
  name     = "vpc-b"
  vpc_cidr = "10.2.0.0/16"
  
  availability_zones = [
    "ap-northeast-2a"
    # "ap-northeast-2c"
  ]

  # transit_gateway_id = data.terraform_remote_state.tgw.outputs.transit_gateway_id

  tags = merge(local.default_tags, {
    Name = format("%s%s-%s", var.prefix, var.env, var.purpose)
  })
}