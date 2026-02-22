output "queue_arn" {
  value = module.payment_events.queue_arn_primary
}

output "lambda_arn" {
  value = module.payment_events.lambda_arn_primary
}

output "alarm_topic_arn" {
  value = module.payment_events.alarm_topic_arn_primary
}
