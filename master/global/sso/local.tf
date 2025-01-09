locals {

  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  instance_arn      = tolist(data.aws_ssoadmin_instances.main.arns)[0]

  permission_sets = {
    devops = {
      name          = "devops"
      inline_policy = data.aws_iam_policy_document.devops.json
      target_ids    = var.devops_ids
    },
    secops = {
      name          = "secops"
      inline_policy = data.aws_iam_policy_document.secops.json
      target_ids    = var.secops_ids
    }
  }
}