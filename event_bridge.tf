# ─────────────────────────────────────────────────────────────
# EventBridge Rule: Monitor S3 Logs for Security Events
# ─────────────────────────────────────────────────────────────
resource "aws_cloudwatch_event_rule" "security_log_alert" {
  name        = "security-log-alert"
  description = "Trigger alerts for security-related events in S3 logs"

  event_pattern = jsonencode({
    source = ["aws.s3"],
    "detail-type" = ["Object Created"],
    detail = {
      bucket = {
        name = ["resumerx-logs-bucket"]
      },
      object = {
        key = [{ prefix = "logs/security/" }]
      }
    }
  })
}

resource "aws_cloudwatch_event_rule" "security_hub_high_risk" {
  name        = "security-hub-high-risk-alerts"
  description = "Trigger alerts for high-risk Security Hub findings"

  event_pattern = jsonencode({
    source = ["aws.securityhub"],
    "detail-type" = ["Security Hub Findings"],
    detail = {
      findings = {
        Severity = {
          Label = ["CRITICAL", "HIGH"]
        }
      }
    }
  })
}

# ─────────────────────────────────────────────────────────────
# EventBridge Target: Send to SNS Topic
# ─────────────────────────────────────────────────────────────
resource "aws_cloudwatch_event_target" "sns_security_alert" {
  rule      = aws_cloudwatch_event_rule.security_log_alert.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_alerts.arn
}

# ─────────────────────────────────────────────────────────────
# IAM Role for EventBridge Execution
# ─────────────────────────────────────────────────────────────
resource "aws_iam_role" "eventbridge_execution_role" {
  name = "eventbridge_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "events.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# ─────────────────────────────────────────────────────────────
# IAM Policies for EventBridge Permissions
# ─────────────────────────────────────────────────────────────
resource "aws_iam_policy" "eventbridge_s3_trigger" {
  name        = "eventbridge_s3_trigger"
  description = "Allow only S3 logs bucket to trigger EventBridge"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "events:PutEvents",
      Resource = aws_cloudwatch_event_rule.security_log_alert.arn,
      Condition = {
        StringEquals = {
          "aws:SourceArn": "arn:aws:s3:::resumerx-logs-bucket"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "eventbridge_processing" {
  name        = "eventbridge_processing"
  description = "Allow EventBridge to process security events and send to SNS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["events:PutEvents"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["sns:Publish"],
        Resource = aws_sns_topic.security_alerts.arn
      }
    ]
  })
}

resource "aws_iam_policy" "eventbridge_security_sources" {
  name        = "eventbridge_security_sources"
  description = "Allow only Security Hub & CloudWatch Logs to trigger EventBridge"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "events:PutEvents",
      Resource = aws_cloudwatch_event_rule.security_hub_high_risk.arn,
      Condition = {
        StringEquals = {
          "aws:SourceArn": [
            "arn:aws:securityhub:us-east-1:123456789012:hub/default",
            "arn:aws:logs:us-east-1:123456789012:log-group:/aws/lambda/security-logs:*"
          ]
        }
      }
    }]
  })
}

# ─────────────────────────────────────────────────────────────
# IAM Policy Attachments to Execution Role
# ─────────────────────────────────────────────────────────────
resource "aws_iam_role_policy_attachment" "attach_eventbridge_processing" {
  role       = aws_iam_role.eventbridge_execution_role.name
  policy_arn = aws_iam_policy.eventbridge_processing.arn
}

resource "aws_iam_role_policy_attachment" "attach_eventbridge_s3_trigger" {
  role       = aws_iam_role.eventbridge_execution_role.name
  policy_arn = aws_iam_policy.eventbridge_s3_trigger.arn
}

resource "aws_iam_role_policy_attachment" "attach_eventbridge_security_sources" {
  role       = aws_iam_role.eventbridge_execution_role.name
  policy_arn = aws_iam_policy.eventbridge_security_sources.arn
}