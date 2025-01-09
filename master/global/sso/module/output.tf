#######################################
# OUTPUTS
#######################################

output "name" {
  description = "The Name of the SSO Permission Set"
  value       = aws_ssoadmin_permission_set.this.name
}

output "arn" {
  description = "The ARN of the SSO Permission Set"
  value       = aws_ssoadmin_permission_set.this.arn
}

output "group_id" {
  value = length(aws_identitystore_group.this) > 0 ? aws_identitystore_group.this[0].group_id : null
}

output "assignment_id" {
  description = "The identifier of the SSO Group Assignment i.e. principal_id, principal_type, target_id, target_type, permission_set_arn, instance_arn separated by commas (,)."
  value       = values(aws_ssoadmin_account_assignment.this)[*].id
}

