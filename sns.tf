resource "aws_sns_topic" "security_alerts" {
  name = "security-alerts"
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]
    
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "securityhub.amazonaws.com"]
    }

    resources = [aws_sns_topic.security_alerts.arn]
  }
}

resource "aws_sns_topic_policy" "sns_policy" {
  arn    = aws_sns_topic.security_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = "security-team@example.com"  # Replace with real email
}


resource "aws_sqs_queue" "sns_dlq" {
  name = "sns-alerts-dlq"
}

resource "aws_sns_topic_subscription" "sns_dlq_subscription" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.sns_dlq.arn
}
