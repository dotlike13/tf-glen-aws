module "waf" {
  source = "./modules/waf"

  web_acls = var.web_acls
  # team     = var.team
  # env      = var.env
  # tags     = var.tags
}