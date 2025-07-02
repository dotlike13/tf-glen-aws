terraform {
  cloud {
    organization = "glen"

    workspaces {
      name = "waf"
    }
  }
} 