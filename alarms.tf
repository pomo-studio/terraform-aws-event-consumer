# =============================================================================
# CloudWatch Alarms + SNS — DLQ depth, Lambda errors, Lambda throttles
# =============================================================================

# -----------------------------------------------------------------------------
# SNS Topics
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "alarms_primary" {
  count    = var.enable_alarms ? 1 : 0
  provider = aws.primary
  name     = "${var.name}-alarms"
  tags     = var.tags
}

resource "aws_sns_topic" "alarms_dr" {
  count    = var.enable_dr && var.enable_alarms ? 1 : 0
  provider = aws.dr
  name     = "${var.name}-alarms"
  tags     = var.tags
}

resource "aws_sns_topic_subscription" "email_primary" {
  count     = var.enable_alarms ? 1 : 0
  provider  = aws.primary
  topic_arn = aws_sns_topic.alarms_primary[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_sns_topic_subscription" "email_dr" {
  count     = var.enable_dr && var.enable_alarms ? 1 : 0
  provider  = aws.dr
  topic_arn = aws_sns_topic.alarms_dr[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# -----------------------------------------------------------------------------
# DLQ Depth Alarms
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "dlq_depth_primary" {
  count               = var.enable_alarms && var.enable_dlq ? 1 : 0
  provider            = aws.primary
  alarm_name          = "${var.name}-dlq-depth"
  alarm_description   = "${var.name}: DLQ has ${var.dlq_alarm_threshold}+ messages"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.dlq_alarm_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms_primary[0].arn]

  dimensions = {
    QueueName = aws_sqs_queue.dlq_primary[0].name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "dlq_depth_dr" {
  count               = var.enable_dr && var.enable_alarms && var.enable_dlq ? 1 : 0
  provider            = aws.dr
  alarm_name          = "${var.name}-dlq-depth"
  alarm_description   = "${var.name}: DLQ has ${var.dlq_alarm_threshold}+ messages (DR)"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.dlq_alarm_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms_dr[0].arn]

  dimensions = {
    QueueName = aws_sqs_queue.dlq_dr[0].name
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Lambda Error Alarms
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "lambda_errors_primary" {
  count               = var.enable_alarms && var.create_lambda ? 1 : 0
  provider            = aws.primary
  alarm_name          = "${var.name}-lambda-errors"
  alarm_description   = "${var.name}: Lambda error rate >= ${var.lambda_error_threshold}/min"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = var.lambda_error_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms_primary[0].arn]

  dimensions = {
    FunctionName = aws_lambda_function.primary[0].function_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors_dr" {
  count               = var.enable_dr && var.enable_alarms && var.create_lambda ? 1 : 0
  provider            = aws.dr
  alarm_name          = "${var.name}-lambda-errors"
  alarm_description   = "${var.name}: Lambda error rate >= ${var.lambda_error_threshold}/min (DR)"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = var.lambda_error_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms_dr[0].arn]

  dimensions = {
    FunctionName = aws_lambda_function.dr[0].function_name
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Lambda Throttle Alarms
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "lambda_throttles_primary" {
  count               = var.enable_alarms && var.create_lambda ? 1 : 0
  provider            = aws.primary
  alarm_name          = "${var.name}-lambda-throttles"
  alarm_description   = "${var.name}: Lambda throttled"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms_primary[0].arn]

  dimensions = {
    FunctionName = aws_lambda_function.primary[0].function_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles_dr" {
  count               = var.enable_dr && var.enable_alarms && var.create_lambda ? 1 : 0
  provider            = aws.dr
  alarm_name          = "${var.name}-lambda-throttles"
  alarm_description   = "${var.name}: Lambda throttled (DR)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms_dr[0].arn]

  dimensions = {
    FunctionName = aws_lambda_function.dr[0].function_name
  }

  tags = var.tags
}
