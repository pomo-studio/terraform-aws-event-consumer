# terraform-aws-event-consumer

[![Terraform Validation](https://github.com/pomo-studio/terraform-aws-event-consumer/actions/workflows/terraform.yml/badge.svg)](https://github.com/pomo-studio/terraform-aws-event-consumer/actions/workflows/terraform.yml)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-844FBA?logo=terraform)](https://registry.terraform.io/modules/pomo-studio/event-consumer/aws)

- [Changelog](CHANGELOG.md)

Per-service EventBridge consumer — subscribes to events on a shared bus and routes them through SQS for reliable processing.

- **Single-concern consumer** — one module per event subscription, clean microservices boundaries
- **Multi-region by default** — primary + DR with `enable_dr` toggle (ADR-007)
- **Optional Lambda processor** — built-in SQS-to-Lambda wiring with `ReportBatchItemFailures`
- **DLQ with alarms** — dead-letter queue, SNS notifications, CloudWatch metrics out of the box
- **EventBridge logging** — matched events logged to CloudWatch for debugging

## Usage

```hcl
module "order_events" {
  source  = "pomo-studio/event-consumer/aws"
  version = "~> 1.0"

  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  name             = "order-processor"
  bus_name_primary = "my-event-bus"
  bus_name_dr      = "my-event-bus"

  event_pattern = {
    source      = ["com.myapp.orders"]
    detail-type = ["OrderCreated"]
  }

  # Optional: wire a Lambda processor
  create_lambda = true
  lambda_code   = "${path.module}/dist/handler.zip"

  # Optional: alarms
  enable_alarms = true
  alarm_email   = "ops@example.com"

  tags = { Environment = "production" }
}
```

## What it creates

| Resource | Primary | DR |
|----------|---------|-----|
| EventBridge rule | 1 | 0–1 |
| SQS queue | 1 | 0–1 |
| SQS dead-letter queue | 0–1 | 0–1 |
| Lambda function | 0–1 | 0–1 |
| Lambda log group | 0–1 | 0–1 |
| EventBridge log group | 0–1 | 0–1 |
| SNS alarm topic | 0–1 | 0–1 |
| CloudWatch alarms | 0–3 | 0–3 |

## Design decisions

- **SQS buffer** — decouples EventBridge from processing; retries and backpressure handled by SQS, not Lambda concurrency
- **Shared IAM role** — single Lambda execution role used by both regions (IAM is global)
- **ReportBatchItemFailures** — partial batch failure support enabled by default on event source mappings
- **Log resource policies** — EventBridge-to-CloudWatch logging uses resource-based policies, not IAM role ARNs on targets
- **Cross-variable validation** — requires Terraform >= 1.9.0 for `lambda_timeout < sqs_visibility_timeout` checks

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Resource naming prefix | `string` | — | yes |
| `bus_name_primary` | EventBridge bus name in primary region | `string` | — | yes |
| `bus_name_dr` | EventBridge bus name in DR region | `string` | `null` | when `enable_dr` |
| `enable_dr` | Deploy consumer stack in DR region | `bool` | `true` | no |
| `event_pattern` | EventBridge event pattern filter | `any` | — | yes |
| `sqs_visibility_timeout_seconds` | SQS visibility timeout | `number` | `180` | no |
| `sqs_message_retention_seconds` | SQS message retention | `number` | `345600` | no |
| `dlq_visibility_timeout_seconds` | DLQ visibility timeout | `number` | `30` | no |
| `enable_dlq` | Enable Dead Letter Queue | `bool` | `true` | no |
| `max_receive_count` | Receive attempts before DLQ (1–1000) | `number` | `3` | no |
| `create_lambda` | Create Lambda processor | `bool` | `false` | no |
| `lambda_code` | Path to Lambda zip | `string` | `null` | when `create_lambda` |
| `lambda_handler` | Lambda handler | `string` | `index.handler` | no |
| `lambda_runtime` | Lambda runtime | `string` | `nodejs20.x` | no |
| `lambda_timeout` | Lambda timeout in seconds | `number` | `30` | no |
| `lambda_memory_size` | Lambda memory in MB | `number` | `128` | no |
| `lambda_environment_variables` | Lambda env vars | `map(string)` | `{}` | no |
| `lambda_batch_size` | Max SQS records per invocation (1–10000) | `number` | `10` | no |
| `enable_logging` | Log matched events to CloudWatch | `bool` | `true` | no |
| `enable_alarms` | Enable CloudWatch alarms | `bool` | `true` | no |
| `alarm_email` | SNS alarm email | `string` | `null` | when `enable_alarms` |
| `dlq_alarm_threshold` | DLQ depth alarm threshold | `number` | `1` | no |
| `lambda_error_threshold` | Lambda errors/min alarm threshold | `number` | `1` | no |
| `tags` | Tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `queue_arn_primary` | ARN of the primary SQS queue |
| `queue_arn_dr` | ARN of the DR SQS queue |
| `queue_url_primary` | URL of the primary SQS queue |
| `queue_url_dr` | URL of the DR SQS queue |
| `dlq_arn_primary` | ARN of the primary DLQ |
| `dlq_arn_dr` | ARN of the DR DLQ |
| `rule_arn_primary` | ARN of the primary EventBridge rule |
| `rule_arn_dr` | ARN of the DR EventBridge rule |
| `lambda_arn_primary` | ARN of the primary Lambda function |
| `lambda_arn_dr` | ARN of the DR Lambda function |
| `lambda_function_name_primary` | Name of the primary Lambda function |
| `lambda_function_name_dr` | Name of the DR Lambda function |
| `lambda_role_arn` | ARN of the Lambda execution role |
| `alarm_topic_arn_primary` | ARN of the primary SNS alarm topic |
| `alarm_topic_arn_dr` | ARN of the DR SNS alarm topic |

## Examples

- [Basic](examples/basic/) — SQS-only consumer, no Lambda, single region
- [Complete](examples/complete/) — Lambda processor, DLQ, alarms, multi-region

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.9.0 |
| AWS provider | ~> 5.0 |

## License

MIT
