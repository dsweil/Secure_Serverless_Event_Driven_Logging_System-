resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/security-logs"
  retention_in_days = 30  
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/security-logs"
  retention_in_days = 30
}

resource "aws_iam_policy" "cloudwatch_logging" {
  name        = "cloudwatch_logging"
  description = "Allow services to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_logging_lambda" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.cloudwatch_logging.arn
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_logging_api" {
  role       = aws_iam_role.api_gateway_logging.name
  policy_arn = aws_iam_policy.cloudwatch_logging.arn
}
