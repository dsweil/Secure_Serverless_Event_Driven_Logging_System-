# ─────────────────────────────────────────────────────────────
# IAM Role & Policy Attachments for Lambda
# ─────────────────────────────────────────────────────────────
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  description = "Allows Lambda to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logging_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "attach_lambda_s3_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_s3_access.arn
}

# ─────────────────────────────────────────────────────────────
# Lambda Function with DLQ
# ─────────────────────────────────────────────────────────────
resource "aws_lambda_function" "process_logs_lambda" {
  function_name = "ProcessLogsLambda" 
  role          = aws_iam_role.lambda_exec_role.arn  
  runtime       = "python3.9"
  handler       = "lambda_function.lambda_handler"
  s3_bucket     = "my-lambda-deployment-bucket-5y3lp26l"
  s3_key        = "process_logs_lambda.zip"
  memory_size   = 512  
  timeout       = 10

  dead_letter_config {
    target_arn = aws_sqs_queue.process_logs_dlq.arn
  }
}

# ─────────────────────────────────────────────────────────────
# Lambda Permissions
# ─────────────────────────────────────────────────────────────
resource "aws_iam_policy" "lambda_dlq_write_policy" {
  name        = "lambda_dlq_write_policy"
  description = "Allow Lambda to write to DLQ"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["sqs:SendMessage"],
      Resource = aws_sqs_queue.process_logs_dlq.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_dlq_write" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_dlq_write_policy.arn
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_logs_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}

# ─────────────────────────────────────────────────────────────
# Dead Letter Queue (DLQ) for Lambda Failures
# ─────────────────────────────────────────────────────────────
resource "aws_sqs_queue" "process_logs_dlq" {
  name = "process-logs-dlq"

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = []
  })
}

# ─────────────────────────────────────────────────────────────
# DLQ Monitoring with CloudWatch + SNS
# ─────────────────────────────────────────────────────────────
resource "aws_sns_topic" "dlq_alerts" {
  name = "dlq-alerts"
}

resource "aws_cloudwatch_metric_alarm" "dlq_message_alarm" {
  alarm_name          = "DLQMessagesPending"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 0

  dimensions = {
    QueueName = aws_sqs_queue.process_logs_dlq.name
  }

  alarm_description = "Alert when messages are sitting in the DLQ"
  alarm_actions     = [aws_sns_topic.dlq_alerts.arn]
}

resource "aws_sns_topic_subscription" "dlq_email" {
  topic_arn = aws_sns_topic.dlq_alerts.arn
  protocol  = "email"
  endpoint  = "your.email@example.com"
}

