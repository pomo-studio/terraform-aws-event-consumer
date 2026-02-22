# =============================================================================
# EventBridge Rules, Targets, and Logging
# =============================================================================

# -----------------------------------------------------------------------------
# Rules — filter events on the bus
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "primary" {
  provider       = aws.primary
  name           = var.name
  description    = "${var.name} consumer — routes matched events to SQS"
  event_bus_name = var.bus_name_primary
  event_pattern  = jsonencode(var.event_pattern)
  tags           = var.tags
}

resource "aws_cloudwatch_event_rule" "dr" {
  count          = var.enable_dr ? 1 : 0
  provider       = aws.dr
  name           = var.name
  description    = "${var.name} consumer — routes matched events to SQS"
  event_bus_name = var.bus_name_dr
  event_pattern  = jsonencode(var.event_pattern)
  tags           = var.tags
}

# -----------------------------------------------------------------------------
# Targets — route matched events to SQS
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_target" "sqs_primary" {
  provider       = aws.primary
  rule           = aws_cloudwatch_event_rule.primary.name
  event_bus_name = var.bus_name_primary
  target_id      = "sqs"
  arn            = aws_sqs_queue.primary.arn
}

resource "aws_cloudwatch_event_target" "sqs_dr" {
  count          = var.enable_dr ? 1 : 0
  provider       = aws.dr
  rule           = aws_cloudwatch_event_rule.dr[0].name
  event_bus_name = var.bus_name_dr
  target_id      = "sqs"
  arn            = aws_sqs_queue.dr[0].arn
}

# -----------------------------------------------------------------------------
# EventBridge Logging — matched events to CloudWatch Logs
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "eventbridge_primary" {
  count             = var.enable_logging ? 1 : 0
  provider          = aws.primary
  name              = "/aws/events/${var.name}"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "eventbridge_dr" {
  count             = var.enable_dr && var.enable_logging ? 1 : 0
  provider          = aws.dr
  name              = "/aws/events/${var.name}"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_cloudwatch_event_target" "logs_primary" {
  count          = var.enable_logging ? 1 : 0
  provider       = aws.primary
  rule           = aws_cloudwatch_event_rule.primary.name
  event_bus_name = var.bus_name_primary
  target_id      = "cloudwatch-logs"
  arn            = aws_cloudwatch_log_group.eventbridge_primary[0].arn
}

resource "aws_cloudwatch_event_target" "logs_dr" {
  count          = var.enable_dr && var.enable_logging ? 1 : 0
  provider       = aws.dr
  rule           = aws_cloudwatch_event_rule.dr[0].name
  event_bus_name = var.bus_name_dr
  target_id      = "cloudwatch-logs"
  arn            = aws_cloudwatch_log_group.eventbridge_dr[0].arn
}

# Resource policy allowing EventBridge to write to CloudWatch Logs
resource "aws_cloudwatch_log_resource_policy" "eventbridge_primary" {
  count       = var.enable_logging ? 1 : 0
  provider    = aws.primary
  policy_name = "${var.name}-eventbridge-logs"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = ["logs:PutLogEvents", "logs:CreateLogStream"]
      Resource  = "${aws_cloudwatch_log_group.eventbridge_primary[0].arn}:*"
    }]
  })
}

resource "aws_cloudwatch_log_resource_policy" "eventbridge_dr" {
  count       = var.enable_dr && var.enable_logging ? 1 : 0
  provider    = aws.dr
  policy_name = "${var.name}-eventbridge-logs"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = ["logs:PutLogEvents", "logs:CreateLogStream"]
      Resource  = "${aws_cloudwatch_log_group.eventbridge_dr[0].arn}:*"
    }]
  })
}
