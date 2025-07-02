output "web_acls" {
  description = "Map of created WAF Web ACLs"
  value = {
    for key, acl in aws_wafv2_web_acl.this : key => {
      id  = acl.id
      arn = acl.arn
    }
  }
}

output "ip_sets" {
  description = "Map of created IP Sets"
  value = {
    for key, ip_set in aws_wafv2_ip_set.this : key => {
      id  = ip_set.id
      arn = ip_set.arn
    }
  }
}
