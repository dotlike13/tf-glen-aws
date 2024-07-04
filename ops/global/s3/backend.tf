terraform {
  cloud {
    organization = "glen"

    workspaces {
      name = "ops-global-s3"
    }
  }
}