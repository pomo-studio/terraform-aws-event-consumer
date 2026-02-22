# =============================================================================
# Lambda Processor — optional, wired to SQS via event source mapping
# =============================================================================

# -----------------------------------------------------------------------------
# IAM Role (global — shared by primary + DR functions)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda" {
  count    = var.create_lambda ? 1 : 0
  provider = aws.primary
  name     = "${var.name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count      = var.create_lambda ? 1 : 0
  provider   = aws.primary
  role       = aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SQS read permission — primary queue
resource "aws_iam_role_policy" "lambda_sqs_primary" {
  count    = var.create_lambda ? 1 : 0
  provider = aws.primary
  name     = "${var.name}-sqs-primary"
  role     = aws_iam_role.lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      Resource = [aws_sqs_queue.primary.arn]
    }]
  })
}

# SQS read permission — DR queue
resource "aws_iam_role_policy" "lambda_sqs_dr" {
  count    = var.enable_dr && var.create_lambda ? 1 : 0
  provider = aws.primary
  name     = "${var.name}-sqs-dr"
  role     = aws_iam_role.lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      Resource = [aws_sqs_queue.dr[0].arn]
    }]
  })
}

# -----------------------------------------------------------------------------
# Lambda Functions
# -----------------------------------------------------------------------------

resource "aws_lambda_function" "primary" {
  count    = var.create_lambda ? 1 : 0
  provider = aws.primary

  function_name    = "${var.name}-processor"
  description      = "${var.name} event consumer — primary region"
  role             = aws_iam_role.lambda[0].arn
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  filename         = var.lambda_code
  source_code_hash = var.lambda_code != null ? filebase64sha256(var.lambda_code) : null
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = var.lambda_environment_variables
  }

  tags = var.tags
}

resource "aws_lambda_function" "dr" {
  count    = var.enable_dr && var.create_lambda ? 1 : 0
  provider = aws.dr

  function_name    = "${var.name}-processor"
  description      = "${var.name} event consumer — DR region"
  role             = aws_iam_role.lambda[0].arn
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  filename         = var.lambda_code
  source_code_hash = var.lambda_code != null ? filebase64sha256(var.lambda_code) : null
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = var.lambda_environment_variables
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Log Groups — managed for retention control
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "lambda_primary" {
  count             = var.create_lambda ? 1 : 0
  provider          = aws.primary
  name              = "/aws/lambda/${var.name}-processor"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "lambda_dr" {
  count             = var.enable_dr && var.create_lambda ? 1 : 0
  provider          = aws.dr
  name              = "/aws/lambda/${var.name}-processor"
  retention_in_days = 14
  tags              = var.tags
}

# -----------------------------------------------------------------------------
# Event Source Mappings — SQS → Lambda
# -----------------------------------------------------------------------------

resource "aws_lambda_event_source_mapping" "primary" {
  count            = var.create_lambda ? 1 : 0
  provider         = aws.primary
  event_source_arn = aws_sqs_queue.primary.arn
  function_name    = aws_lambda_function.primary[0].arn
  batch_size       = var.lambda_batch_size

  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_lambda_event_source_mapping" "dr" {
  count            = var.enable_dr && var.create_lambda ? 1 : 0
  provider         = aws.dr
  event_source_arn = aws_sqs_queue.dr[0].arn
  function_name    = aws_lambda_function.dr[0].arn
  batch_size       = var.lambda_batch_size

  function_response_types = ["ReportBatchItemFailures"]
}
