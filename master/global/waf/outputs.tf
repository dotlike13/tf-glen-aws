output "web_acls" {
  description = "Map of created WAF web ACLs"
  value       = module.waf.web_acls
}

output "ip_sets" {
  description = "Map of created IP sets"
  value       = module.waf.ip_sets
}
