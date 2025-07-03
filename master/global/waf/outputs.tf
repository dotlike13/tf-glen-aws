output "web_acl_arns" {
  description = "Map of created WAF web ACLs"
  value       = module.waf.web_acl_arns
}

output "web_acl_ids" {
  description = "Map of created WAF web ACLs"
  value       = module.waf.web_acl_ids
}

output "ip_sets" {
  description = "Map of created IP sets"
  value       = module.waf.ip_sets
}
