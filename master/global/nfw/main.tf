module "network_firewall" {
  source = "./modules/nfw"

  prefix           = "prod"
  security_vpc_id  = "vpc-1234567890"
  
  firewall_subnet_ids   = ["subnet-firewall1", "subnet-firewall2"]
  ingress_subnet_ids    = ["subnet-ingress1", "subnet-ingress2"]
  egress_subnet_ids     = ["subnet-egress1", "subnet-egress2"]
  east_west_subnet_ids  = ["subnet-eastwest1", "subnet-eastwest2"]
  
  blocked_domains = [
    "malicious-site.com",
    "bad-domain.com"
  ]

  tags = {
    Environment = "Production"
    Project     = "Security"
  }
} 