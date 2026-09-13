# Core
# -----------------------------------------------------------------------------

variable "name" {
  description = "Resource naming prefix (e.g. 'payments-enricher')"
  type        = string
}

variable "bus_name_primary" {
  description = "EventBridge bus name in the primary region, typically from the event-bus module output"
  type        = string
}

variable "bus_name_dr" {
  description = "EventBridge bus name in the DR region. Required when enable_dr = true."
  type        = string
  default     = null

  validation {
    condition     = !var.enable_dr || var.bus_name_dr != null
    error_message = "bus_name_dr is required when enable_dr = true."
  }
}

variable "enable_dr" {
  description = "Deploy consumer stack (rule + queue + Lambda + alarms) in the DR region. Disable for dev/staging."
  type        = bool
  default     = true
}

variable "event_pattern" {
  description = "EventBridge event pattern: which events this consumer receives. See the AWS docs for pattern syntax."
  type        = any
}

# SQS
# -----------------------------------------------------------------------------

variable "sqs_visibility_timeout_seconds" {
  description = "SQS visibility timeout in seconds. Should be at least 6× lambda_timeout."
  type        = number
  default     = 180
}

variable "sqs_message_retention_seconds" {
  description = "SQS message retention period in seconds"
  type        = number
  default     = 345600 # 4 days
}

variable "dlq_visibility_timeout_seconds" {
  description = "DLQ visibility timeout in seconds"
  type        = number
  default     = 30
}

variable "enable_dlq" {
  description = "Enable Dead Letter Queue for failed events"
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "Receive attempts before moving to DLQ (1–1000)"
  type        = number
  default     = 3

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "max_receive_count must be between 1 and 1000."
  }
}

# Lambda
# -----------------------------------------------------------------------------

variable "create_lambda" {
  description = "Create a Lambda function to process events from SQS"
  type        = bool
  default     = false
}

variable "lambda_code" {
  description = "Path to Lambda deployment package zip (required when create_lambda = true)"
  type        = string
  default     = null

  validation {
    condition     = !var.create_lambda || var.lambda_code != null
    error_message = "lambda_code is required when create_lambda is true."
  }
}

variable "lambda_handler" {
  description = "Lambda function handler"
  type        = string
  default     = "index.handler"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds. Must be less than sqs_visibility_timeout_seconds."
  type        = number
  default     = 30

  validation {
    condition     = var.lambda_timeout < var.sqs_visibility_timeout_seconds
    error_message = "lambda_timeout must be less than sqs_visibility_timeout_seconds to prevent duplicate processing."
  }
}

variable "lambda_memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = 128
}

variable "lambda_environment_variables" {
  description = "Environment variables for Lambda function. Applied to both primary and DR functions."
  type        = map(string)
  default     = {}
}

variable "lambda_batch_size" {
  description = "Max SQS records per Lambda invocation (1–10000)"
  type        = number
  default     = 10

  validation {
    condition     = var.lambda_batch_size >= 1 && var.lambda_batch_size <= 10000
    error_message = "lambda_batch_size must be between 1 and 10000."
  }
}

# Observability
# -----------------------------------------------------------------------------

variable "enable_logging" {
  description = "Log matched EventBridge events to CloudWatch"
  type        = bool
  default     = true
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms (DLQ depth, Lambda errors, Lambda throttles)"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "SNS alarm destination (required when enable_alarms = true)"
  type        = string
  default     = null

  validation {
    condition     = !var.enable_alarms || var.alarm_email != null
    error_message = "alarm_email is required when enable_alarms is true."
  }
}

variable "dlq_alarm_threshold" {
  description = "DLQ message count that triggers alarm"
  type        = number
  default     = 1
}

variable "lambda_error_threshold" {
  description = "Lambda errors per minute that trigger alarm"
  type        = number
  default     = 1
}

# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
