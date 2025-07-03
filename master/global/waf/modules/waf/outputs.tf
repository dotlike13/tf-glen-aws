output "web_acl_arns" {
  description = "ARNs of the WAF Web ACLs"
  value       = { for name, acl in aws_wafv2_web_acl.this : name => acl.arn }
}

output "web_acl_ids" {
  description = "IDs of the WAF Web ACLs"
  value       = { for name, acl in aws_wafv2_web_acl.this : name => acl.id }
}

output "web_acl_capacity" {
  description = "Web ACL capacity units"
  value       = { for name, acl in aws_wafv2_web_acl.this : name => acl.capacity }
}

output "ip_sets" {
  description = "Map of IP Set ARNs being used"
  value       = { for name, ip_set in data.aws_wafv2_ip_set.existing : name => ip_set.arn }
}

output "log_groups" {
  description = "Map of CloudWatch Log Group ARNs being used"
  value = merge(
    { for name, log_group in aws_cloudwatch_log_group.waf_logs : name => log_group.arn },
    { for name, log_group in data.aws_cloudwatch_log_group.existing : name => log_group.arn }
  )
}
