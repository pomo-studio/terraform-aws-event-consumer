provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "dr"
  region = "us-west-2"
}

module "payment_events" {
  source  = "pomo-studio/event-consumer/aws"
  version = "~> 1.0"

  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  # Core
  name             = "payment-enricher"
  bus_name_primary = "payments-bus"
  bus_name_dr      = "payments-bus"
  enable_dr        = true

  event_pattern = {
    source      = ["com.myapp.payments"]
    detail-type = ["PaymentReceived", "PaymentRefunded"]
  }

  # SQS tuning
  sqs_visibility_timeout_seconds = 360
  sqs_message_retention_seconds  = 604800 # 7 days
  max_receive_count              = 5

  # Lambda processor
  create_lambda                = true
  lambda_code                  = "${path.module}/dist/handler.zip"
  lambda_handler               = "index.handler"
  lambda_runtime               = "nodejs20.x"
  lambda_timeout               = 60
  lambda_memory_size           = 256
  lambda_batch_size            = 5
  lambda_environment_variables = { TABLE_NAME = "payments" }

  # Observability
  enable_logging         = true
  enable_alarms          = true
  alarm_email            = "ops@example.com"
  dlq_alarm_threshold    = 5
  lambda_error_threshold = 3

  tags = {
    Environment = "production"
    Team        = "payments"
  }
}
