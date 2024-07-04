module "permission_set" {
  source            = "./module"
  for_each          = local.permission_sets
  name              = each.value.name
  inline_policy     = each.value.inline_policy
  target_ids        = each.value.target_ids
  identity_store_id = local.identity_store_id
  instance_arn      = local.instance_arn
}
