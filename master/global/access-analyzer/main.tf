module "access_analyzer" {
  source                   = "./modules/access-analyzer"
  env                      = var.env
  slack_webhook_url        = var.slack_webhook_url
  slack_channel            = var.slack_channel
  slack_bot_token          = var.slack_bot_token
  schedule_expression      = var.schedule_expression
  unused_access_age        = var.unused_access_age
  resource_tags            = var.resource_tags
  notification_lambda_code = file("${path.module}/notification.py")
  approval_lambda_code     = file("${path.module}/approval.py")

  tags = merge(local.default_tags, {
    Name = format("%s%s-%s", var.prefix, var.env, var.purpose)
  })

}
