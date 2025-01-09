## description
- local에 map형태로 permission_set을 입력
  - group 생성 되고 inline 정책에 attach.
  - name, description은 var.name을 기준으로 작성됨
  - account는 tfvars에서 사용할 수 있도록 함
- group이 이미 존재하면 data로 principal_id를 사용할 수 있도록 조건 추가.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.51.1 |

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
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | AWS assume role arn | `any` | n/a | yes |
| <a name="input_secops_ids"></a> [secops\_ids](#input\_secops\_ids) | secops accounts | `any` | n/a | yes |
| <a name="input_session_name"></a> [session\_name](#input\_session\_name) | Session name for role | `any` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->