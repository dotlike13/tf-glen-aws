terraform {
  cloud {
    organization = "glen"

    workspaces {
      name = "glen-aws-nfw"
    }
  }
}
