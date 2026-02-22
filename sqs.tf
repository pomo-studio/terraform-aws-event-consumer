# =============================================================================
# SQS Queues — main event queue + optional DLQ
# =============================================================================

# -----------------------------------------------------------------------------
# Main Queues
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "primary" {
  provider                   = aws.primary
  name                       = "${var.name}-queue"
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  message_retention_seconds  = var.sqs_message_retention_seconds

  redrive_policy = var.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq_primary[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = var.tags
}

resource "aws_sqs_queue" "dr" {
  count                      = var.enable_dr ? 1 : 0
  provider                   = aws.dr
  name                       = "${var.name}-queue"
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  message_retention_seconds  = var.sqs_message_retention_seconds

  redrive_policy = var.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq_dr[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Dead Letter Queues
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "dlq_primary" {
  count                      = var.enable_dlq ? 1 : 0
  provider                   = aws.primary
  name                       = "${var.name}-dlq"
  visibility_timeout_seconds = var.dlq_visibility_timeout_seconds
  message_retention_seconds  = 1209600 # 14 days — max retention for investigation
  tags                       = var.tags
}

resource "aws_sqs_queue" "dlq_dr" {
  count                      = var.enable_dr && var.enable_dlq ? 1 : 0
  provider                   = aws.dr
  name                       = "${var.name}-dlq"
  visibility_timeout_seconds = var.dlq_visibility_timeout_seconds
  message_retention_seconds  = 1209600
  tags                       = var.tags
}

# -----------------------------------------------------------------------------
# Queue Policies — allow EventBridge to send messages
# -----------------------------------------------------------------------------

resource "aws_sqs_queue_policy" "primary" {
  provider  = aws.primary
  queue_url = aws_sqs_queue.primary.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridge"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.primary.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_cloudwatch_event_rule.primary.arn
        }
      }
    }]
  })
}

resource "aws_sqs_queue_policy" "dr" {
  count     = var.enable_dr ? 1 : 0
  provider  = aws.dr
  queue_url = aws_sqs_queue.dr[0].url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridge"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.dr[0].arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_cloudwatch_event_rule.dr[0].arn
        }
      }
    }]
  })
}
