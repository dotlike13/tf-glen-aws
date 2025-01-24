locals {
  default_tags = {
    env        = var.env
    team       = var.team
    purpose    = var.purpose
    managed_by = "terraform"
  }
}