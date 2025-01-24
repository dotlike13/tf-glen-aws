output "security_vpc" {
  description = "Security VPC outputs"
  value = {
    vpc_id                  = module.security_vpc.vpc_id
    vpc_cidr                = module.security_vpc.vpc_cidr
    public_subnet_ids       = module.security_vpc.public_subnet_ids
    private_subnet_ids      = module.security_vpc.private_subnet_ids
    gwlbe_ingress_subnet_ids  = module.security_vpc.gwlbe_ingress_subnet_ids
    gwlbe_egress_subnet_ids   = module.security_vpc.gwlbe_egress_subnet_ids
    gwlbe_east_west_subnet_ids = module.security_vpc.gwlbe_east_west_subnet_ids
  }
}

output "vpc_a" {
  description = "VPC A outputs"
  value = {
    vpc_id            = module.vpc_a.vpc_id
    vpc_cidr          = module.vpc_a.vpc_cidr
    public_subnet_ids = module.vpc_a.public_subnet_ids
    private_subnet_ids = module.vpc_a.private_subnet_ids
  }
}

output "vpc_b" {
  description = "VPC B outputs"
  value = {
    vpc_id            = module.vpc_b.vpc_id
    vpc_cidr          = module.vpc_b.vpc_cidr
    public_subnet_ids = module.vpc_b.public_subnet_ids
    private_subnet_ids = module.vpc_b.private_subnet_ids
  }
}