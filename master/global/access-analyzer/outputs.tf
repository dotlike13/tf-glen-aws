output "analyzer_arn" {
  description = "생성된 Access Analyzer의 ARN"
  value       = module.access_analyzer.analyzer_arn
}

output "notification_lambda_function_arn" {
  description = "생성된 알림 Lambda 함수의 ARN"
  value       = module.access_analyzer.notification_lambda_function_arn
}

output "notification_lambda_function_name" {
  description = "생성된 알림 Lambda 함수의 이름"
  value       = module.access_analyzer.notification_lambda_function_name
}

output "approval_lambda_function_arn" {
  description = "생성된 승인 처리 Lambda 함수의 ARN"
  value       = module.access_analyzer.approval_lambda_function_arn
}

output "approval_lambda_function_name" {
  description = "생성된 승인 처리 Lambda 함수의 이름"
  value       = module.access_analyzer.approval_lambda_function_name
}

output "api_gateway_url" {
  description = "API Gateway 엔드포인트 URL"
  value       = module.access_analyzer.api_gateway_url
} 