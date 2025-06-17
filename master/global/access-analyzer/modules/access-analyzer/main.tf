resource "aws_accessanalyzer_analyzer" "this" {
  analyzer_name = "unused-access-analyzer-${var.env}"
  type          = "ACCOUNT_UNUSED_ACCESS"
  tags          = var.tags
  
  configuration {
    unused_access {
      unused_access_age = var.unused_access_age
      analysis_rule {
        exclusion {
          resource_tags = var.resource_tags
        }
      }
    }
  }
}

# 알림 Lambda 함수 코드 관리
resource "local_file" "notification_lambda" {
  filename = "${path.module}/lambda/notification.py"
  content  = var.notification_lambda_code
}

data "archive_file" "notification_lambda" {
  type        = "zip"
  source_file = local_file.notification_lambda.filename
  output_path = "${path.module}/lambda/notification_handler.zip"
}

# 승인 Lambda 함수 코드 관리
resource "local_file" "approval_lambda" {
  filename = "${path.module}/lambda/approval.py"
  content  = var.approval_lambda_code
}

data "archive_file" "approval_lambda" {
  type        = "zip"
  source_file = local_file.approval_lambda.filename
  output_path = "${path.module}/lambda/approval_handler.zip"
}

# Lambda Layer 생성
resource "aws_lambda_layer_version" "requests_layer" {
  filename         = "${path.module}/package.zip"
  layer_name       = "requests-layer-${var.env}"
  description      = "Lambda Layer for requests module"
  compatible_runtimes = ["python3.9"]

}

# 첫 번째 Lambda 함수: Access Analyzer 결과를 Slack으로 전송
resource "aws_lambda_function" "notification_handler" {
  filename         = data.archive_file.notification_lambda.output_path
  source_code_hash = data.archive_file.notification_lambda.output_base64sha256
  function_name    = "access-analyzer-notification-${var.env}"
  role            = aws_iam_role.notification_lambda_role.arn
  handler         = "notification.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256
  layers          = [aws_lambda_layer_version.requests_layer.arn]

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      ENVIRONMENT      = var.env
      ANALYZER_ARN     = aws_accessanalyzer_analyzer.this.arn
      SLACK_BOT_TOKEN  = var.slack_bot_token
      SLACK_CHANNEL    = var.slack_channel
    }
  }

  tags = var.tags
}

# 두 번째 Lambda 함수: Slack 응답 처리
resource "aws_lambda_function" "approval_handler" {
  filename         = data.archive_file.approval_lambda.output_path
  source_code_hash = data.archive_file.approval_lambda.output_base64sha256
  function_name    = "access-analyzer-approval-${var.env}"
  role            = aws_iam_role.approval_lambda_role.arn
  handler         = "approval.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  memory_size     = 256
  layers          = [aws_lambda_layer_version.requests_layer.arn]

  environment {
    variables = {
      SLACK_WEBHOOK_URL    = var.slack_webhook_url
      ENVIRONMENT          = var.env
      DEFAULT_ANALYZER_ARN = aws_accessanalyzer_analyzer.this.arn
      SLACK_BOT_TOKEN      = var.slack_bot_token
    }
  }

  tags = var.tags
}

# 알림 Lambda 함수의 IAM 역할
resource "aws_iam_role" "notification_lambda_role" {
  name = "access-analyzer-notification-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# 알림 Lambda 함수의 IAM 정책
resource "aws_iam_role_policy" "notification_lambda_policy" {
  name = "access-analyzer-notification-policy-${var.env}"
  role = aws_iam_role.notification_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
                "access-analyzer:ListFindings",
                "access-analyzer:GetFinding",
                "access-analyzer:GetFindingRecommendation",
                "access-analyzer:StartPolicyGeneration",
                "access-analyzer:GetGeneratedPolicy",
                "access-analyzer:ListAccessPreviews",
                "access-analyzer:GenerateFindingRecommendation",
                "iam:ListAttachedRolePolicies",
                "iam:ListRolePolicies",
                "iam:ListAccessKeys",
                "iam:GetAccessKeyLastUsed",
                "iam:GetUser",
                "iam:GetRole",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# 승인 처리 Lambda 함수의 IAM 역할
resource "aws_iam_role" "approval_lambda_role" {
  name = "access-analyzer-approval-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# 승인 처리 Lambda 함수의 IAM 정책
resource "aws_iam_role_policy" "approval_lambda_policy" {
  name = "access-analyzer-approval-policy-${var.env}"
  role = aws_iam_role.approval_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
                "access-analyzer:ListFindings",
                "access-analyzer:GetFinding",
                "access-analyzer:GetGeneratedPolicy",
                "access-analyzer:UpdateFindings",
                "access-analyzer:GetFinding",
                "access-analyzer:GetFindingRecommendation",
                "iam:CreatePolicy",
                "iam:DeletePolicy",
                "iam:GetPolicy",
                "iam:DetachUserPolicy",
                "iam:ListPolicyVersions",
                "iam:CreatePolicyVersion",
                "iam:DeletePolicyVersion",
                "iam:GetPolicyVersion",
                "iam:AttachRolePolicy",
                "iam:AttachUserPolicy",
                "iam:DetachRolePolicy",
                "iam:DetachUserPolicy",
                "iam:ListAttachedRolePolicies",
                "iam:ListRolePolicies",
                "iam:DeleteRolePolicy",
                "iam:DeleteUserPolicy",
                "iam:DetachUserPolicy",
                "iam:UpdateRole",
                "iam:UpdateUser",
                "iam:GetRole",
                "iam:GetUser",
                "iam:ListAttachedUserPolicies",
                "iam:ListUserPolicies",
                "iam:PutRolePolicy",
                "iam:DeleteRole",
                "iam:TagUser",
                "iam:TagRole",
                "iam:UntagUser",
                "iam:UntagRole",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# API Gateway REST API 생성
resource "aws_api_gateway_rest_api" "slack_api" {
  name        = "access-analyzer-slack-api-${var.env}"
  description = "API for Slack interactions"
}

# API Gateway 리소스 생성
resource "aws_api_gateway_resource" "slack_resource" {
  rest_api_id = aws_api_gateway_rest_api.slack_api.id
  parent_id   = aws_api_gateway_rest_api.slack_api.root_resource_id
  path_part   = "slack"
}

# API Gateway POST 메서드 생성
resource "aws_api_gateway_method" "slack_method" {
  rest_api_id   = aws_api_gateway_rest_api.slack_api.id
  resource_id   = aws_api_gateway_resource.slack_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Lambda 통합 설정
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.slack_api.id
  resource_id             = aws_api_gateway_resource.slack_resource.id
  http_method             = aws_api_gateway_method.slack_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.approval_handler.invoke_arn
}

# API Gateway 배포
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.slack_api.id
  depends_on  = [aws_api_gateway_integration.lambda_integration]
}

# API Gateway 스테이지 생성
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.slack_api.id
  stage_name    = var.env
}

# Lambda 함수에 API Gateway 권한 부여
resource "aws_lambda_permission" "api_gateway_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.approval_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.slack_api.execution_arn}/*/*"
}

# EventBridge 규칙 생성
resource "aws_cloudwatch_event_rule" "access_analyzer_trigger" {
  name                = "access-analyzer-trigger-${var.env}"
  description         = "Access Analyzer 결과를 주기적으로 확인"
  schedule_expression = var.schedule_expression

  tags = var.tags
}

# EventBridge 타겟 설정
resource "aws_cloudwatch_event_target" "analyzer_lambda" {
  rule      = aws_cloudwatch_event_rule.access_analyzer_trigger.name
  target_id = "AccessAnalyzerLambda"
  arn       = aws_lambda_function.notification_handler.arn
}

# EventBridge에 Lambda 실행 권한 부여
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notification_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.access_analyzer_trigger.arn
} 