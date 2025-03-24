# ─────────────────────────────────────────────────────────────
# IAM Role and Policy for API Gateway Logging
# ─────────────────────────────────────────────────────────────
resource "aws_iam_role" "api_gateway_logging" {
  name = "api_gateway_logging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "apigateway.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
    lifecycle {
    prevent_destroy = false  
  
  }
}

resource "aws_iam_policy" "api_gateway_logging_policy" {
  name        = "api_gateway_logging_policy"
  description = "Allows API Gateway to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "logs:GetLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:log-group:/aws/lambda/security-logs:*",
        "arn:aws:logs:*:*:log-group:/aws/api-gateway/security-logs:*"
]

    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_api_gateway_logging_policy" {
  role       = aws_iam_role.api_gateway_logging.name
  policy_arn = aws_iam_policy.api_gateway_logging_policy.arn
}

# ─────────────────────────────────────────────────────────────
# IAM Role and Policy for Lambda to Access S3
# ─────────────────────────────────────────────────────────────
resource "aws_iam_policy" "lambda_s3_access" {
  name        = "lambda_s3_access"
  description = "Allow Lambda to write logs to S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      Resource = [
        aws_s3_bucket.logs_bucket.arn,
        "${aws_s3_bucket.logs_bucket.arn}/logs/*"
      ]
    }]
  })
}

resource "aws_s3_bucket_policy" "logs_bucket_policy" {
  bucket = aws_s3_bucket.logs_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.lambda_exec_role.arn
        },
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.logs_bucket.arn,
          "${aws_s3_bucket.logs_bucket.arn}/*"
        ]
      }
    ]
  })
}

# ─────────────────────────────────────────────────────────────
# IAM Role and Policy for Athena to Access S3 Results Bucket
# ─────────────────────────────────────────────────────────────
resource "aws_iam_role" "athena_access_role" {
  name = "AthenaAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "athena.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "athena_s3_access" {
  name        = "athena_s3_access"
  description = "Allows Athena to access Athena S3 results bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AllowBucketAccess",
        Effect: "Allow",
        Action: [
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ],
        Resource: "arn:aws:s3:::athena-reports-5y3lp26l"
      },
      {
        Sid: "AllowObjectAccess",
        Effect: "Allow",
        Action: [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        Resource: "arn:aws:s3:::athena-reports-5y3lp26l/*"
      }
    ]
  })
}