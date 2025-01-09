#######################################
# Stack Set Create and Deploy
#######################################
resource "aws_cloudformation_stack_set" "this" {
  name                    = format("%s-%s", var.name, "servicemanaged-policy")
  permission_model        = "SERVICE_MANAGED"
  
  auto_deployment {
    enabled                      = true
    retain_stacks_on_account_removal = false
  }
  
  template_body = jsonencode({
    Parameters = {},
    Resources  = {
      "${format("%s%s", var.name, "policy")}" = {
        Type       = "AWS::IAM::ManagedPolicy",
        Properties = {
          ManagedPolicyName  = format("%s-%s", var.name, "policySetAdmin"),
          PolicyDocument     = var.managed_policy
        }
      }
    }
  })

  capabilities = ["CAPABILITY_NAMED_IAM"]
}

resource "aws_cloudformation_stack_set_instance" "this" {
  deployment_targets {
    organizational_unit_ids = [ var.ou_id ]
  }
  stack_set_name = aws_cloudformation_stack_set.this.name
}

#######################################
# SSO PERMISSION SET
#######################################
resource "aws_ssoadmin_permission_set" "this" {
  name             = format("%s-%s", var.name, "ou-policy")
  description      = format("%s-%s", var.name, "ou-policy")
  instance_arn     = var.instance_arn
  relay_state      = var.relay_state
  session_duration = var.session_duration
  tags             = var.tags
}

#######################################
# SSO POLICY ATTACHMENT
#######################################
# stackset으로 미리 해당 어카운트에 정책을 배포해둔다.

resource "aws_ssoadmin_customer_managed_policy_attachment" "this" {
  for_each           = var.target_ids
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
  
  #위에서 stackset으로 생성한 policy이름과 같도록.
  customer_managed_policy_reference {
    name = format("%s-%s", var.name, "policySetAdmin")
  }
  # aws_cloudformation_stack_set_instance가 완료 되었을때 attach 할 수 있도록.
  depends_on = [aws_cloudformation_stack_set_instance.this]
}

resource "aws_identitystore_group" "this" {
  count             = var.principal_id == "" ? 1 : 0
  display_name      = format("%s%s", var.name, "sso group")
  description       = format("%s%s", var.name, "sso group")
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