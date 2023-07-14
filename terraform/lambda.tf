locals {
  lambda_name = local.project_name
}

# File
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../handler.js"
  output_path = "${path.module}/.handler.zip"
}

# Lambda Role & Policy Configuration
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
  tags               = local.project_tags
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]

    resources = [
      "arn:aws:s3:::${local.aws_bucket}",
      "arn:aws:s3:::${local.aws_bucket}/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  path        = "/"
  description = "IAM policy for Lambda"
  policy      = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Cloudwatch & Log Configuration
resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = 3
  tags              = local.project_tags
}

data "aws_iam_policy_document" "lambda_logs_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for creating logs from AWS Lambda."
  policy      = data.aws_iam_policy_document.lambda_logs_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

# S3 Configuration
resource "aws_s3_bucket" "bucket-name" {
  bucket = local.aws_bucket
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.election_scraper.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket-name.arn
}

# Lambda Function
resource "aws_lambda_function" "election_scraper" {
  filename         = data.archive_file.lambda.output_path
  role             = aws_iam_role.iam_for_lambda.arn
  function_name    = local.lambda_name
  handler          = "handler.handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 10
  runtime          = "nodejs14.x"
  tags             = local.project_tags
  layers           = ["lambda-axios-layer"]
  environment {
    variables = {
      BUCKET_NAME       = local.aws_bucket,
      BUCKET_REGION     = local.aws_region,
      BUCKET_ACCESS_KEY = local.aws_access_key,
      BUCKET_SECRET_KEY = local.aws_secret_key
    }
  }
}
