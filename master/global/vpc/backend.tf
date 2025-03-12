terraform {
  cloud {
    organization = "glen"

    workspaces {
      name = "glen-aws-vpc"
    }
  }
}

# data "terraform_remote_state" "nfw" {
#   backend = "remote"

#   config = {
#     organization = "glen"
#     workspaces = {
#       name = "glen-aws-nfw"
#     }
#   }
# }

# data "terraform_remote_state" "tgw" {
#   backend = "remote"

#   config = {
#     organization = "glen"
#     workspaces = {
#       name = "glen-aws-tgw"
#     }
#   }
# }
