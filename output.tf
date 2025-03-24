output "s3_bucket_name" {
  description = "The name of the S3 bucket for logs"
  value       = aws_s3_bucket.logs_bucket.id
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.process_logs_lambda.function_name
}

output "api_gateway_url" {
  description = "The invoke URL for the API Gateway"
  value       = aws_api_gateway_deployment.example.invoke_url
}

output "sns_topic_arn" {
  description = "The ARN of the SNS Topic for security alerts"
  value       = aws_sns_topic.security_alerts.arn
}

output "iam_role_arn" {
  description = "The ARN of the IAM role for Lambda execution"
  value       = aws_iam_role.lambda_exec_role.arn
}

output "cloudwatch_log_group" {
  description = "The CloudWatch log group for the Lambda function"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "api_gateway_resource_id" {
  description = "The Resource ID of the API Gateway resource"
  value       = aws_api_gateway_resource.example.id
}
