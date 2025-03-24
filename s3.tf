resource "aws_s3_bucket" "logs_bucket" {
  bucket = "resumerx-logs-5y3lp26l"
}
resource "aws_s3_bucket_public_access_block" "logs_bucket_public_access" {
  bucket                  = aws_s3_bucket.logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "logging_bucket" {
  bucket = "resumerx-logging-5y3lp26l"
}
resource "aws_s3_bucket_public_access_block" "logging_bucket_public_access" {
  bucket                  = aws_s3_bucket.logging_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "my-lambda-deployment-bucket" {
  bucket = "my-lambda-deployment-bucket-5y3lp26l"
}
resource "aws_s3_bucket_public_access_block" "my-lambda-deployment-bucket_public_access" {
  bucket                  = aws_s3_bucket.my-lambda-deployment-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.my-lambda-deployment-bucket.id  
  key    = "process_logs_lambda.zip"
  source = "process_logs_lambda.zip"  
  etag   = filemd5("process_logs_lambda.zip")  
}

resource "aws_s3_object" "sec_lambda_zip" {
  bucket = aws_s3_bucket.my-lambda-deployment-bucket.id  
  key    = "securityhub_alert_handler.zip"
  source = "securityhub_alert_handler.zip"  
  etag   = filemd5("securityhub_alert_handler.zip")  
}


resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {
  bucket = aws_s3_bucket.logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logging_encryption" {
  bucket = aws_s3_bucket.logging_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "my-lambda-deployment-bucket" {
  bucket = aws_s3_bucket.my-lambda-deployment-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.logs_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "s3_logging" {
  bucket        = aws_s3_bucket.logs_bucket.id
  target_bucket = "resumerx-logging-5y3lp26l"
  target_prefix = "log/"
}


/* 
aws_s3_bucket - Creates the S3 bucket.
aws_s3_bucket_public_access_block - Controls public access settings, currently allows public access (false values). Should be restricted (true values) for security if needed.
aws_s3_bucket_server_side_encryption_configuration - Enables encryption (AES-256).
aws_s3_bucket_versioning - Enables versioning to keep old file versions.
aws_s3_bucket_logging - Logs access requests to another S3 bucket.
*/