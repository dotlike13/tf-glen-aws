# locals {
#   name = "${var.prefix}${var.env}-waf"

#   tags = merge(
#     {
#       Name        = local.name
#       Environment = var.env
#       Terraform   = "true"
#     },
#     var.tags
#   )
# } 