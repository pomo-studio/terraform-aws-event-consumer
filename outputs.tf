# =============================================================================
# Outputs
# =============================================================================

# SQS
# -----------------------------------------------------------------------------

output "queue_arn_primary" {
  description = "ARN of the primary SQS queue"
  value       = aws_sqs_queue.primary.arn
}

output "queue_arn_dr" {
  description = "ARN of the DR SQS queue"
  value       = var.enable_dr ? aws_sqs_queue.dr[0].arn : null
}

output "queue_url_primary" {
  description = "URL of the primary SQS queue"
  value       = aws_sqs_queue.primary.url
}

output "queue_url_dr" {
  description = "URL of the DR SQS queue"
  value       = var.enable_dr ? aws_sqs_queue.dr[0].url : null
}

output "dlq_arn_primary" {
  description = "ARN of the primary Dead Letter Queue"
  value       = var.enable_dlq ? aws_sqs_queue.dlq_primary[0].arn : null
}

output "dlq_arn_dr" {
  description = "ARN of the DR Dead Letter Queue"
  value       = var.enable_dr && var.enable_dlq ? aws_sqs_queue.dlq_dr[0].arn : null
}

# EventBridge
# -----------------------------------------------------------------------------

output "rule_arn_primary" {
  description = "ARN of the primary EventBridge rule"
  value       = aws_cloudwatch_event_rule.primary.arn
}

output "rule_arn_dr" {
  description = "ARN of the DR EventBridge rule"
  value       = var.enable_dr ? aws_cloudwatch_event_rule.dr[0].arn : null
}

# Lambda
# -----------------------------------------------------------------------------

output "lambda_arn_primary" {
  description = "ARN of the primary Lambda function"
  value       = var.create_lambda ? aws_lambda_function.primary[0].arn : null
}

output "lambda_arn_dr" {
  description = "ARN of the DR Lambda function"
  value       = var.enable_dr && var.create_lambda ? aws_lambda_function.dr[0].arn : null
}

output "lambda_function_name_primary" {
  description = "Name of the primary Lambda function"
  value       = var.create_lambda ? aws_lambda_function.primary[0].function_name : null
}

output "lambda_function_name_dr" {
  description = "Name of the DR Lambda function"
  value       = var.enable_dr && var.create_lambda ? aws_lambda_function.dr[0].function_name : null
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role (shared by both regions)"
  value       = var.create_lambda ? aws_iam_role.lambda[0].arn : null
}

# Alarms
# -----------------------------------------------------------------------------

output "alarm_topic_arn_primary" {
  description = "ARN of the primary SNS alarm topic"
  value       = var.enable_alarms ? aws_sns_topic.alarms_primary[0].arn : null
}

output "alarm_topic_arn_dr" {
  description = "ARN of the DR SNS alarm topic"
  value       = var.enable_dr && var.enable_alarms ? aws_sns_topic.alarms_dr[0].arn : null
}
