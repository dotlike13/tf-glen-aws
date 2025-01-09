terraform {
  cloud {
    organization = "glen"

    workspaces {
      name = "glen-w4-sso"
    }
  }
}

# SSO 인스턴스 정보 가져오기
data "aws_ssoadmin_instances" "main" {}