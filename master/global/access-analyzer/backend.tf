terraform {
  cloud {
    organization = "glen"

    workspaces {
      name = "access-analyzer"
    }
  }
}