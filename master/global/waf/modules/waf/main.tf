# 기존 IP Set 참조 (ip_set_name이 지정된 경우)
data "aws_wafv2_ip_set" "existing" {
  for_each = { for rule in flatten([
    for acl in var.web_acls : [
      for ip_rule in acl.ip_set_rules : {
        name = ip_rule.ip_set_name
        use_existing = ip_rule.use_existing
      } if ip_rule.use_existing == true
    ]
  ]) : rule.name => rule }

  name  = each.key
  scope = "REGIONAL"
}

# 기존 Rule Group 참조
data "aws_wafv2_rule_group" "existing" {
  for_each = { for rule in flatten([
    for acl in var.web_acls : [
      for rule in acl.rule_group_rules : rule.rule_group_name
    ]
  ]) : rule => rule }

  name  = each.key
  scope = "REGIONAL"
}

# 새로운 IP Set 생성 (use_existing = false인 경우)
resource "aws_wafv2_ip_set" "this" {
  for_each = { for rule in flatten([
    for acl in var.web_acls : [
      for ip_rule in acl.ip_set_rules : {
        name = ip_rule.ip_set_name
        addresses = ip_rule.addresses
      } if ip_rule.use_existing == false
    ]
  ]) : rule.name => rule }

  name               = each.key
  description        = "IP set for ${each.key}"
  scope             = "REGIONAL"
  ip_address_version = "IPV4"
  addresses         = each.value.addresses

}

# 기존 CloudWatch Log Group 참조
data "aws_cloudwatch_log_group" "existing" {
  for_each = { for name, acl in var.web_acls : name => acl.log_group_name 
    if acl.logging_enabled == true && acl.log_group_name != null }

  name = each.value
}

# CloudWatch Log Group for WAF Logs (log_group_name이 지정되지 않은 경우에만)
resource "aws_cloudwatch_log_group" "waf_logs" {
  for_each = { for name, acl in var.web_acls : name => acl 
    if acl.logging_enabled == true && (acl.log_group_name == null || acl.log_group_name == "") }

  name              = "/aws/waf/${each.value.name}"
  retention_in_days = 30

}

# Custom Rule Types
locals {
  custom_rule_types = {
    host_match = {
      statement = {
        byte_match_statement = {
          field_to_match = {
            single_header = {
              name = "host"
            }
          }
          positional_constraint = "EXACTLY"
          text_transformation = [
            {
              priority = 0
              type     = "NONE"
            }
          ]
        }
      }
    }
    path_match = {
      statement = {
        regex_match_statement = {
          field_to_match = {
            uri_path = {}
          }
          text_transformation = [
            {
              priority = 0
              type     = "NONE"
            }
          ]
        }
      }
    }
    host_path_match = {
      statement = {
        and_statement = {
          statements = [
            {
              byte_match_statement = {
                field_to_match = {
                  single_header = {
                    name = "host"
                  }
                }
                positional_constraint = "EXACTLY"
                text_transformation = [
                  {
                    priority = 0
                    type     = "NONE"
                  }
                ]
              }
            },
            {
              regex_match_statement = {
                field_to_match = {
                  uri_path = {}
                }
                text_transformation = [
                  {
                    priority = 0
                    type     = "NONE"
                  }
                ]
              }
            }
          ]
        }
      }
    }
  }
}

# ALB 데이터 소스
data "aws_lb" "existing" {
  for_each = { for item in flatten([
    for acl_name, acl in var.web_acls : [
      for alb_name in acl.association_alb_name : {
        acl_name = acl_name
        alb_name = alb_name
      }
    ]
  ]) : "${item.acl_name}-${item.alb_name}" => item }

  name = each.value.alb_name
}

# WAF Web ACL Association
resource "aws_wafv2_web_acl_association" "this" {
  for_each = { for item in flatten([
    for acl_name, acl in var.web_acls : [
      for alb_name in(acl.association_alb_name != null ? acl.association_alb_name : []) : {
        acl_name = acl_name
        alb_name = alb_name
      }
    ]
  ]) : "${item.acl_name}-${item.alb_name}" => item }

  resource_arn = data.aws_lb.existing[each.key].arn
  web_acl_arn  = aws_wafv2_web_acl.this[each.value.acl_name].arn
}

# WAF v2 Web ACL 생성
resource "aws_wafv2_web_acl" "this" {
  for_each = var.web_acls

  name        = each.value.name
  description = each.value.description
  scope       = each.value.scope

  default_action {
    dynamic "allow" {
      for_each = each.value.default_action == "allow" ? [1] : []
      content {}
    }
    dynamic "block" {
      for_each = each.value.default_action == "block" ? [1] : []
      content {}
    }
  }

  # Rule Group Rules
  dynamic "rule" {
    for_each = each.value.rule_group_rules != null ? each.value.rule_group_rules : []
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.action == "override_none" ? [1] : []
          content {}
        }
        dynamic "count" {
          for_each = rule.value.action == "override_count" ? [1] : []
          content {}
        }
      }

      statement {
        rule_group_reference_statement {
          arn = data.aws_wafv2_rule_group.existing[rule.value.rule_group_name].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name               = rule.value.name
        sampled_requests_enabled  = true
      }
    }
  }

  # AWS Managed Rules
  dynamic "rule" {
    for_each = each.value.managed_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }
        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.rule_name
          vendor_name = rule.value.vendor_name

          dynamic "rule_action_override" {
            for_each = rule.value.rule_action_overrides
            content {
              name = rule_action_override.value.name
              action_to_use {
                dynamic "allow" {
                  for_each = rule_action_override.value.action == "allow" ? [1] : []
                  content {}
                }
                dynamic "block" {
                  for_each = rule_action_override.value.action == "block" ? [1] : []
                  content {}
                }
                dynamic "count" {
                  for_each = rule_action_override.value.action == "count" ? [1] : []
                  content {}
                }
                dynamic "challenge" {
                  for_each = rule_action_override.value.action == "challenge" ? [1] : []
                  content {}
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name               = rule.value.name
        sampled_requests_enabled  = true
      }
    }
  }

  # 커스텀 규칙
  dynamic "rule" {
    for_each = each.value.custom_rules != null ? each.value.custom_rules : []
    content {
      name     = rule.value.name
      priority = rule.value.priority

      dynamic "action" {
        for_each = rule.value.action == "allow" ? [1] : []
        content {
          allow {}
        }
      }

      dynamic "action" {
        for_each = rule.value.action == "block" ? [1] : []
        content {
          block {}
        }
      }

      dynamic "action" {
        for_each = rule.value.action == "count" ? [1] : []
        content {
          count {}
        }
      }

      statement {
        dynamic "byte_match_statement" {
          for_each = rule.value.type == "host_match" ? [1] : []
          content {
            search_string = rule.value.search_string
            field_to_match {
              single_header {
                name = "host"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }

        dynamic "regex_match_statement" {
          for_each = rule.value.type == "path_match" ? [1] : []
          content {
            regex_string = rule.value.regex_string
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        dynamic "and_statement" {
          for_each = rule.value.type == "host_path_match" ? [1] : []
          content {
            statement {
              byte_match_statement {
                search_string = rule.value.host
                field_to_match {
                  single_header {
                    name = "host"
                  }
                }
                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
                positional_constraint = "EXACTLY"
              }
            }
            statement {
              regex_match_statement {
                regex_string = rule.value.path_pattern
                field_to_match {
                  uri_path {}
                }
                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name               = rule.value.custom_rule_metric_name
        sampled_requests_enabled  = true
      }
    }
  }

  # IP Rate Limit Rules
  dynamic "rule" {
    for_each = each.value.ip_rate_limit_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      dynamic "action" {
        for_each = rule.value.action == "allow" ? [1] : []
        content {
          allow {}
        }
      }

      dynamic "action" {
        for_each = rule.value.action == "block" ? [1] : []
        content {
          block {
            dynamic "custom_response" {
              for_each = try(rule.value.custom_response != null ? [rule.value.custom_response] : [], [])
              content {
                response_code = custom_response.value.response_code
                dynamic "custom_response_body_key" {
                  for_each = try(custom_response.value.custom_response_body_key != null ? [custom_response.value.custom_response_body_key] : [], [])
                  content {
                    key = custom_response_body_key.value
                  }
                }
              }
            }
          }
        }
      }

      dynamic "action" {
        for_each = rule.value.action == "count" ? [1] : []
        content {
          count {}
        }
      }

      dynamic "action" {
        for_each = rule.value.action == "challenge" ? [1] : []
        content {
          challenge {}
        }
      }

      statement {
        rate_based_statement {
          limit              = rule.value.limit
          aggregate_key_type = "IP"
          evaluation_window_sec = rule.value.evaluation_window_sec

          dynamic "scope_down_statement" {
            for_each = rule.value.scope_down_statement != null ? [rule.value.scope_down_statement] : []
            content {
              dynamic "byte_match_statement" {
                for_each = scope_down_statement.value.byte_match_statement != null ? [scope_down_statement.value.byte_match_statement] : []
                content {
                  search_string = byte_match_statement.value.search_string
                  field_to_match {
                    dynamic "uri_path" {
                      for_each = byte_match_statement.value.field_to_match.uri_path != null ? [1] : []
                      content {}
                    }
                  }
                  positional_constraint = byte_match_statement.value.positional_constraint
                  text_transformation {
                    priority = byte_match_statement.value.text_transformation.priority
                    type     = byte_match_statement.value.text_transformation.type
                  }
                }
              }

              dynamic "ip_set_reference_statement" {
                for_each = scope_down_statement.value.ip_set_reference_statement != null ? [scope_down_statement.value.ip_set_reference_statement] : []
                content {
                  arn = ip_set_reference_statement.value.arn
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name               = rule.value.name
        sampled_requests_enabled  = true
      }
    }
  }

  # IP Set Rules
  dynamic "rule" {
    for_each = each.value.ip_set_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority
      
      dynamic "action" {
        for_each = rule.value.action == "allow" ? [1] : []
        content {
          allow {}
        }
      }

      dynamic "action" {
        for_each = rule.value.action == "block" ? [1] : []
        content {
          block {}
        }
      }

      dynamic "action" {
        for_each = rule.value.action == "count" ? [1] : []
        content {
          count {}
        }
      }

      dynamic "override_action" {
        for_each = rule.value.action == "override_none" ? [1] : []
        content {
          none {}
        }
      }

      dynamic "override_action" {
        for_each = rule.value.action == "override_count" ? [1] : []
        content {
          count {}
        }
      }

      statement {
        ip_set_reference_statement {
          arn = rule.value.use_existing ? data.aws_wafv2_ip_set.existing[rule.value.ip_set_name].arn : aws_wafv2_ip_set.this[rule.value.ip_set_name].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name               = rule.value.name
        sampled_requests_enabled  = true
      }
    }
  }

  # # Custom Response Bodies
  # dynamic "custom_response_body" {
  #   for_each = { for rule in each.value.ip_rate_limit_rules : rule.name => rule if rule.action == "block" }
  #   content {
  #     key          = custom_response_body.value.name
  #     content_type = "TEXT_PLAIN"
  #     content      = custom_response_body.value.response_body
  #   }
  # }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = each.value.name
    sampled_requests_enabled  = true
  }

}

# Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "this" {
  for_each = { for name, acl in var.web_acls : name => acl if acl.logging_enabled }

  log_destination_configs = [
    lookup(data.aws_cloudwatch_log_group.existing, each.key, null) != null ? 
    data.aws_cloudwatch_log_group.existing[each.key].arn : 
    aws_cloudwatch_log_group.waf_logs[each.key].arn
  ]
  resource_arn = aws_wafv2_web_acl.this[each.key].arn

  
  depends_on = [aws_wafv2_web_acl.this]
}