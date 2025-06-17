output "analyzer_arn" {
  description = "생성된 Access Analyzer의 ARN"
  value       = aws_accessanalyzer_analyzer.this.arn
}

output "notification_lambda_function_arn" {
  description = "생성된 알림 Lambda 함수의 ARN"
  value       = aws_lambda_function.notification_handler.arn
}

output "notification_lambda_function_name" {
  description = "생성된 알림 Lambda 함수의 이름"
  value       = aws_lambda_function.notification_handler.function_name
}

output "approval_lambda_function_arn" {
  description = "생성된 승인 처리 Lambda 함수의 ARN"
  value       = aws_lambda_function.approval_handler.arn
}

output "approval_lambda_function_name" {
  description = "생성된 승인 처리 Lambda 함수의 이름"
  value       = aws_lambda_function.approval_handler.function_name
}

output "api_gateway_url" {
  description = "API Gateway 엔드포인트 URL"
  value       = "${aws_api_gateway_stage.api_stage.invoke_url}/slack"
} 