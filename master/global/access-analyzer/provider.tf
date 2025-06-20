terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.97.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
  assume_role {
    role_arn     = var.role_arn
    session_name = var.session_name
  }
}