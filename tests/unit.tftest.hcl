# =============================================================================
# Unit tests — terraform-aws-event-consumer
# =============================================================================

mock_provider "aws" {
  alias = "primary"

  mock_resource "aws_sqs_queue" {
    defaults = {
      arn  = "arn:aws:sqs:us-east-1:123456789012:mock-queue"
      url  = "https://sqs.us-east-1.amazonaws.com/123456789012/mock-queue"
      name = "mock-queue"
    }
  }

  mock_resource "aws_cloudwatch_event_rule" {
    defaults = {
      arn = "arn:aws:events:us-east-1:123456789012:rule/mock-rule"
    }
  }

  mock_resource "aws_lambda_function" {
    defaults = {
      arn           = "arn:aws:lambda:us-east-1:123456789012:function:mock-fn"
      function_name = "mock-fn"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
      id  = "mock-role-id"
    }
  }

  mock_resource "aws_sns_topic" {
    defaults = {
      arn = "arn:aws:sns:us-east-1:123456789012:mock-topic"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/events/mock"
    }
  }
}

mock_provider "aws" {
  alias = "dr"

  mock_resource "aws_sqs_queue" {
    defaults = {
      arn  = "arn:aws:sqs:us-west-2:123456789012:mock-queue"
      url  = "https://sqs.us-west-2.amazonaws.com/123456789012/mock-queue"
      name = "mock-queue-dr"
    }
  }

  mock_resource "aws_cloudwatch_event_rule" {
    defaults = {
      arn = "arn:aws:events:us-west-2:123456789012:rule/mock-rule"
    }
  }

  mock_resource "aws_lambda_function" {
    defaults = {
      arn           = "arn:aws:lambda:us-west-2:123456789012:function:mock-fn"
      function_name = "mock-fn-dr"
    }
  }

  mock_resource "aws_sns_topic" {
    defaults = {
      arn = "arn:aws:sns:us-west-2:123456789012:mock-topic"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-west-2:123456789012:log-group:/aws/events/mock"
    }
  }
}

# -----------------------------------------------------------------------------
# 1. Basic defaults — SQS-only, no Lambda, no DR
# -----------------------------------------------------------------------------

run "basic_defaults" {
  command = plan

  variables {
    name             = "test-consumer"
    bus_name_primary = "test-bus"
    event_pattern    = { source = ["com.test"] }
    enable_dr        = false
    enable_alarms    = false
    create_lambda    = false
  }

  # Primary queue always created
  assert {
    condition     = aws_sqs_queue.primary.name == "test-consumer-queue"
    error_message = "Primary queue should be named test-consumer-queue"
  }

  # DR queue not created
  assert {
    condition     = length(aws_sqs_queue.dr) == 0
    error_message = "DR queue should not be created when enable_dr = false"
  }

  # EventBridge rule created
  assert {
    condition     = aws_cloudwatch_event_rule.primary.name == "test-consumer"
    error_message = "Primary rule should be named test-consumer"
  }
}

# -----------------------------------------------------------------------------
# 2. DR enabled — all resources duplicated
# -----------------------------------------------------------------------------

run "dr_enabled" {
  command = plan

  variables {
    name             = "test-consumer"
    bus_name_primary = "test-bus"
    bus_name_dr      = "test-bus-dr"
    enable_dr        = true
    enable_alarms    = false
    create_lambda    = false
    event_pattern    = { source = ["com.test"] }
  }

  assert {
    condition     = length(aws_sqs_queue.dr) == 1
    error_message = "DR queue should be created when enable_dr = true"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.dr) == 1
    error_message = "DR rule should be created when enable_dr = true"
  }
}

# -----------------------------------------------------------------------------
# 3. DLQ enabled (default)
# -----------------------------------------------------------------------------

run "dlq_enabled" {
  command = plan

  variables {
    name             = "test-consumer"
    bus_name_primary = "test-bus"
    event_pattern    = { source = ["com.test"] }
    enable_dr        = false
    enable_alarms    = false
    create_lambda    = false
  }

  assert {
    condition     = length(aws_sqs_queue.dlq_primary) == 1
    error_message = "DLQ should be created by default"
  }

  assert {
    condition     = aws_sqs_queue.dlq_primary[0].name == "test-consumer-dlq"
    error_message = "DLQ should be named test-consumer-dlq"
  }
}

# -----------------------------------------------------------------------------
# 4. DLQ disabled
# -----------------------------------------------------------------------------

run "dlq_disabled" {
  command = plan

  variables {
    name             = "test-consumer"
    bus_name_primary = "test-bus"
    event_pattern    = { source = ["com.test"] }
    enable_dr        = false
    enable_dlq       = false
    enable_alarms    = false
    create_lambda    = false
  }

  assert {
    condition     = length(aws_sqs_queue.dlq_primary) == 0
    error_message = "DLQ should not be created when enable_dlq = false"
  }
}

# -----------------------------------------------------------------------------
# 5. Lambda processor enabled
# -----------------------------------------------------------------------------

run "lambda_enabled" {
  command = plan

  variables {
    name             = "test-consumer"
    bus_name_primary = "test-bus"
    event_pattern    = { source = ["com.test"] }
    enable_dr        = false
    enable_alarms    = false
    create_lambda    = true
    lambda_code      = "tests/handler.zip"
  }

  assert {
    condition     = length(aws_lambda_function.primary) == 1
    error_message = "Lambda should be created when create_lambda = true"
  }

  assert {
    condition     = aws_lambda_function.primary[0].function_name == "test-consumer-processor"
    error_message = "Lambda should be named test-consumer-processor"
  }

  assert {
    condition     = length(aws_lambda_event_source_mapping.primary) == 1
    error_message = "Event source mapping should be created"
  }
}

# -----------------------------------------------------------------------------
# 6. Lambda + DR
# -----------------------------------------------------------------------------

run "lambda_with_dr" {
  command = plan

  variables {
    name             = "test-consumer"
    bus_name_primary = "test-bus"
    bus_name_dr      = "test-bus-dr"
    enable_dr        = true
    enable_alarms    = false
    create_lambda    = true
    lambda_code      = "tests/handler.zip"
    event_pattern    = { source = ["com.test"] }
  }

  assert {
    condition     = length(aws_lambda_function.dr) == 1
    error_message = "DR Lambda should be created"
  }

  assert {
    condition     = length(aws_lambda_event_source_mapping.dr) == 1
    error_message = "DR event source mapping should be created"
  }
}

# -----------------------------------------------------------------------------
# 7. Alarms enabled
# -----------------------------------------------------------------------------

run "alarms_enabled" {
  command = plan

  variables {
    name             = "test-consumer"
    bus_name_primary = "test-bus"
    event_pattern    = { source = ["com.test"] }
    enable_dr        = false
    enable_alarms    = true
    alarm_email      = "ops@test.com"
    create_lambda    = false
  }

  assert {
    condition     = length(aws_sns_topic.alarms_primary) == 1
    error_message = "SNS alarm topic should be created"
  }

  assert {
    condition     = length(aws_sns_topic_subscription.email_primary) == 1
    error_message = "Email subscription should be created"
  }
}

# -----------------------------------------------------------------------------
# 8. DLQ alarm requires both enable_alarms and enable_dlq
# -----------------------------------------------------------------------------

run "dlq_alarm" {
  command = plan

  variables {
    name             = "test-consumer"
    bus_name_primary = "test-bus"
    event_pattern    = { source = ["com.test"] }
    enable_dr        = false
    enable_alarms    = true
    alarm_email      = "ops@test.com"
    enable_dlq       = true
    create_lambda    = false
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.dlq_depth_primary) == 1
    error_message = "DLQ alarm should be created when both alarms and DLQ enabled"
  }
}

# -----------------------------------------------------------------------------
# 9. bus_name_dr required when enable_dr = true
# -----------------------------------------------------------------------------

run "dr_requires_bus_name" {
  command = plan

  variables {
    name             = "test-consumer"
    bus_name_primary = "test-bus"
    enable_dr        = true
    enable_alarms    = false
    create_lambda    = false
    event_pattern    = { source = ["com.test"] }
  }

  expect_failures = [
    var.bus_name_dr,
  ]
}

# -----------------------------------------------------------------------------
# 10. lambda_code required when create_lambda = true
# -----------------------------------------------------------------------------

run "lambda_requires_code" {
  command = plan

  variables {
    name             = "test-consumer"
    bus_name_primary = "test-bus"
    enable_dr        = false
    enable_alarms    = false
    create_lambda    = true
    event_pattern    = { source = ["com.test"] }
  }

  expect_failures = [
    var.lambda_code,
  ]
}

# -----------------------------------------------------------------------------
# 11. alarm_email required when enable_alarms = true
# -----------------------------------------------------------------------------

run "alarms_require_email" {
  command = plan

  variables {
    name             = "test-consumer"
    bus_name_primary = "test-bus"
    enable_dr        = false
    enable_alarms    = true
    create_lambda    = false
    event_pattern    = { source = ["com.test"] }
  }

  expect_failures = [
    var.alarm_email,
  ]
}

# -----------------------------------------------------------------------------
# 12. Logging creates CloudWatch log groups
# -----------------------------------------------------------------------------

run "logging_enabled" {
  command = plan

  variables {
    name             = "test-consumer"
    bus_name_primary = "test-bus"
    event_pattern    = { source = ["com.test"] }
    enable_dr        = false
    enable_alarms    = false
    enable_logging   = true
    create_lambda    = false
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.eventbridge_primary) == 1
    error_message = "EventBridge log group should be created when logging enabled"
  }

  assert {
    condition     = length(aws_cloudwatch_log_resource_policy.eventbridge_primary) == 1
    error_message = "Log resource policy should be created when logging enabled"
  }
}

# -----------------------------------------------------------------------------
# 13. Resource naming consistency
# -----------------------------------------------------------------------------

run "resource_naming" {
  command = plan

  variables {
    name             = "payment-enricher"
    bus_name_primary = "payments-bus"
    event_pattern    = { source = ["com.payments"] }
    enable_dr        = false
    enable_alarms    = false
    create_lambda    = true
    lambda_code      = "tests/handler.zip"
  }

  assert {
    condition     = aws_sqs_queue.primary.name == "payment-enricher-queue"
    error_message = "Queue naming should use name prefix"
  }

  assert {
    condition     = aws_lambda_function.primary[0].function_name == "payment-enricher-processor"
    error_message = "Lambda naming should use name prefix"
  }

  assert {
    condition     = aws_cloudwatch_event_rule.primary.name == "payment-enricher"
    error_message = "Rule should use name directly"
  }
}
