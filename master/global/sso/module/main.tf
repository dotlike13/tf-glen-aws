#######################################
# SSO PERMISSION SET
#######################################
resource "aws_ssoadmin_permission_set" "this" {
  name             = format("%s-%s", var.name, "permission_set")
  description      = format("%s-%s", var.name, "permission set")
  instance_arn     = var.instance_arn
  relay_state      = var.relay_state
  session_duration = var.session_duration
  tags             = var.tags
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  count              = var.inline_policy != null ? 1 : 0
  inline_policy      = var.inline_policy
  instance_arn       = var.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
}


#principal_id        = data.aws_identitystore_group.this.group_id
resource "aws_identitystore_group" "this" {
  count             = var.principal_id == "" ? 1 : 0
  display_name      = var.name
  description       = format("%s %s", var.name, "group")
  identity_store_id = var.identity_store_id
}

# SSO GROUP ASSIGNMENT
# each key로 target_ids를 선언한 이유는, 부여하고자 하는 권한이 여러 어카운트에 적용될 수 있도록.
resource "aws_ssoadmin_account_assignment" "this" {
  for_each           = var.target_ids
  instance_arn       = var.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn

  principal_id   = var.principal_id != "" ? var.principal_id : aws_identitystore_group.this[0].group_id
  principal_type = var.principal_type

  target_id   = each.value
  target_type = var.target_type
}