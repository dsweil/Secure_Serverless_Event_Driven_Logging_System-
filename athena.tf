resource "aws_athena_database" "quere" {
  name   = "logs_quere"
  bucket = aws_s3_bucket.logs_bucket.id
}

resource "aws_s3_bucket" "athena_bucket" {
  bucket = "athena-reports-5y3lp26l"
}
resource "aws_s3_bucket_public_access_block" "athena_bucket_public_access" {
  bucket                  = aws_s3_bucket.athena_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.athena_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_athena_workgroup" "reporting" {
  name = "security_reporting"

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = "s3://athena-reports-5y3lp26l/reports/"
    }
  }
}
#___________________________________________________________
#     Athena Named Queries
#___________________________________________________________
#Top Status Codes
resource "aws_athena_named_query" "top_status_codes" {
  name        = "TopStatusCodes"
  description = "Top 5 HTTP status codes"
  database    = aws_athena_database.quere.name
  workgroup   = aws_athena_workgroup.reporting.name

  query = <<EOT
SELECT status_code, COUNT(*) AS occurrences
FROM logs_table
GROUP BY status_code
ORDER BY occurrences DESC
LIMIT 5;
EOT
}

#Top 5 IPs Causing 403/401
resource "aws_athena_named_query" "top_unauthorized_ips" {
  name        = "TopUnauthorizedIPs"
  description = "Top 5 IPs causing 403 or 401"
  database    = aws_athena_database.quere.name
  workgroup   = aws_athena_workgroup.reporting.name

  query = <<EOT
SELECT ip_address, COUNT(*) AS attempts
FROM logs_table
WHERE status_code IN (401, 403)
GROUP BY ip_address
ORDER BY attempts DESC
LIMIT 5;
EOT
}

#Top 5 IPs Causing 404s
resource "aws_athena_named_query" "top_404_ips" {
  name        = "Top404IPs"
  description = "Top 5 IPs generating 404s"
  database    = aws_athena_database.quere.name
  workgroup   = aws_athena_workgroup.reporting.name

  query = <<EOT
SELECT ip_address, COUNT(*) AS not_found_count
FROM logs_table
WHERE status_code = 404
GROUP BY ip_address
ORDER BY not_found_count DESC
LIMIT 5;
EOT
}

#Top 5 IPs Causing 5xx Errors
resource "aws_athena_named_query" "top_5xx_ips" {
  name        = "Top5xxIPs"
  description = "Top 5 IPs causing server errors"
  database    = aws_athena_database.quere.name
  workgroup   = aws_athena_workgroup.reporting.name

  query = <<EOT
SELECT ip_address, COUNT(*) AS server_error_count
FROM logs_table
WHERE status_code BETWEEN 500 AND 599
GROUP BY ip_address
ORDER BY server_error_count DESC
LIMIT 5;
EOT
}

#Top 5 User Agents
resource "aws_athena_named_query" "top_user_agents" {
  name        = "TopUserAgents"
  description = "Top 5 most used User Agents"
  database    = aws_athena_database.quere.name
  workgroup   = aws_athena_workgroup.reporting.name

  query = <<EOT
SELECT user_agent, COUNT(*) AS frequency
FROM logs_table
GROUP BY user_agent
ORDER BY frequency DESC
LIMIT 5;
EOT
}

#Unauthorized Spikes by Hour
resource "aws_athena_named_query" "unauthorized_spikes_hourly" {
  name        = "UnauthorizedSpikesHourly"
  description = "Hourly trend of 403s"
  database    = aws_athena_database.quere.name
  workgroup   = aws_athena_workgroup.reporting.name

  query = <<EOT
SELECT date_trunc('hour', request_time) AS hour, COUNT(*) AS request_count
FROM logs_table
WHERE status_code = 403
GROUP BY hour
ORDER BY hour DESC
LIMIT 24;
EOT
}







resource "aws_s3_bucket_lifecycle_configuration" "cleanup" {
  bucket = aws_s3_bucket.athena_bucket.id

  rule {
    id     = "expire-old-results"
    status = "Enabled"

    expiration {
      days = 30
    }

    filter {
      prefix = ""
    }
  }
}


# ─────────────────────────────────────────────────────────────
# Athena Query Runner Lambda Function (Python)
# ─────────────────────────────────────────────────────────────
resource "aws_iam_role" "athena_lambda_role" {
  name = "athena_query_runner_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "athena_lambda_policy" {
  name        = "athena_query_execution_policy"
  description = "Allow Lambda to run Athena queries and write to S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Action: [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults"
        ],
        Resource: "*"
      },
      {
        Effect: "Allow",
        Action: [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource: [
          "arn:aws:s3:::athena-reports-5y3lp26l",
          "arn:aws:s3:::athena-reports-5y3lp26l/*"
        ]
      },
      {
        Effect: "Allow",
        Action: [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource: "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_athena_lambda_policy" {
  role       = aws_iam_role.athena_lambda_role.name
  policy_arn = aws_iam_policy.athena_lambda_policy.arn
}

resource "aws_lambda_function" "athena_runner" {
  function_name = "run_athena_reports"
  role          = aws_iam_role.athena_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  filename      = "lambda_athena_runner.zip"
  source_code_hash = filebase64sha256("lambda_athena_runner.zip")
  environment {
    variables = {
      WORKGROUP = "security_reporting"
      DATABASE  = "logs_db"
      OUTPUT    = "s3://athena-reports-5y3lp26l/reports/"
    }
  }
}

# ─────────────────────────────────────────────────────────────
# EventBridge Rule to Trigger Lambda Every 24 Hours
# ─────────────────────────────────────────────────────────────
resource "aws_cloudwatch_event_rule" "athena_schedule" {
  name                = "run_athena_queries_daily"
  schedule_expression = "rate(24 hours)"
}

resource "aws_cloudwatch_event_target" "athena_lambda_target" {
  rule      = aws_cloudwatch_event_rule.athena_schedule.name
  target_id = "AthenaLambdaTrigger"
  arn       = aws_lambda_function.athena_runner.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.athena_runner.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.athena_schedule.arn
}
