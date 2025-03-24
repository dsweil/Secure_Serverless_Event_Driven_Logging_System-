# ─────────────────────────────────────────────────────────────
# Enable Security Hub
# ─────────────────────────────────────────────────────────────
resource "aws_securityhub_account" "security_hub" {}

# ─────────────────────────────────────────────────────────────
# Enable GuardDuty
# ─────────────────────────────────────────────────────────────
resource "aws_guardduty_detector" "main" {
  enable = true
}

# ─────────────────────────────────────────────────────────────
# DLQ for Security Hub EventBridge -> Lambda
# ─────────────────────────────────────────────────────────────
resource "aws_sqs_queue" "securityhub_dlq" {
  name = "securityhub-dlq"
}

resource "aws_lambda_function" "securityhub_handler" {
  function_name = "SecurityHubAlertHandler"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "lambda_function.lambda_handler"
  s3_bucket     = "my-lambda-deployment-bucket-5y3lp26l"
  s3_key        = "securityhub_alert_handler.zip"
  timeout       = 10

  dead_letter_config {
    target_arn = aws_sqs_queue.securityhub_dlq.arn
  }
}

resource "aws_cloudwatch_event_target" "lambda_securityhub_alert" {
  rule      = aws_cloudwatch_event_rule.security_hub_high_risk.name
  target_id = "SecurityHubLambdaTarget"
  arn       = aws_lambda_function.securityhub_handler.arn
}

resource "aws_lambda_permission" "allow_eventbridge_securityhub" {
  statement_id  = "AllowExecutionFromEventBridgeSecurityHub"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.securityhub_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.security_hub_high_risk.arn
}
