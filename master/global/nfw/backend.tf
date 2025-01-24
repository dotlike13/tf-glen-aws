terraform {
  cloud {
    organization = "glen"

    workspaces {
      name = "glen-aws-nfw"
    }
  }
}

data "terraform_remote_state" "vpc" {
  backend = "remote"

  config = {
    organization = "glen"
    workspaces = {
      name = "glen-aws-vpc"
    }
  }
}