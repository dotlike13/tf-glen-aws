## description
- local에 map형태로 permission_set을 입력
  - 기존 sso 코드는 테라폼에서 다른 어카운트에 정책을 한번에 생성하고 attach 할수없어서 inline정책을 활용.
  - stackset으로 고객 관리형 정책을 위한 iam policy 생성
  - stackset을 service managed로 배포하면 ou 단위로 배포할수있고, 별도의 role 설정이 필요없음.
  - sso group 생성 되고 고객 관리형 정책에 attach.
  - name, description은 var.name을 기준으로 작성됨
  - account는 tfvars에서 사용할 수 있도록 함
- group이 이미 존재하면 data로 principal_id를 사용할 수 있도록 조건 추가.

### tfvars example
- role_arn     = "arn:aws:iam::12345678:role/TerraformAssumedRole"
- session_name = "sso_with_stackset"

- devops_ids = {
  "devops1team" = "321321321321"
}
- secops_ids = {
  "secops" = "234234234234"
}

- devops_ou_id = "ou-oer8-12345678"
- secops_ou_id = "ou-oer8-abcdefgh"

### tip
- docs 생성
  - terraform-docs markdown table --output-file README.md .

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_permission_set"></a> [permission\_set](#module\_permission\_set) | ./module | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy_document.devops](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.secops](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_ssoadmin_instances.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_devops_ids"></a> [devops\_ids](#input\_devops\_ids) | devops accounts | `any` | n/a | yes |
| <a name="input_devops_ou_id"></a> [devops\_ou\_id](#input\_devops\_ou\_id) | devops ou id | `any` | n/a | yes |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | AWS assume role arn | `any` | n/a | yes |
| <a name="input_secops_ids"></a> [secops\_ids](#input\_secops\_ids) | secops accounts | `any` | n/a | yes |
| <a name="input_secops_ou_id"></a> [secops\_ou\_id](#input\_secops\_ou\_id) | secops ou id | `any` | n/a | yes |
| <a name="input_session_name"></a> [session\_name](#input\_session\_name) | Session name for role | `any` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->