module "permission_set" {
  source            = "./module"
  for_each          = local.permission_sets
  name              = each.value.name
  managed_policy    = each.value.managed_policy
  target_ids        = each.value.target_ids
  ou_id             = each.value.ou_id
  identity_store_id = local.identity_store_id
  instance_arn      = local.instance_arn
  role_arn          = var.role_arn
}
