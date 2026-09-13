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

## Maintaining This Module

The generated interface below is authoritative for requirements, providers, resources, inputs, and outputs. Regenerate with `terraform-docs` **v0.20.0**: `terraform-docs .`. CI fails on drift; keep explanatory prose outside the generated markers.

See the [contribution guide](https://github.com/pomo-studio/.github/blob/main/CONTRIBUTING.md) and [security policy](https://github.com/pomo-studio/.github/blob/main/SECURITY.md). PR validation does not prove a live plan or deployment. Infrastructure plans and applies belong in Terraform Cloud; never provide cloud credentials to untrusted PR code.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws.dr"></a> [aws.dr](#provider\_aws.dr) | 6.64.0 |
| <a name="provider_aws.primary"></a> [aws.primary](#provider\_aws.primary) | 6.64.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.logs_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.logs_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.sqs_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.sqs_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.eventbridge_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.eventbridge_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.lambda_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.lambda_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_resource_policy.eventbridge_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_resource_policy) | resource |
| [aws_cloudwatch_log_resource_policy.eventbridge_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_resource_policy) | resource |
| [aws_cloudwatch_metric_alarm.dlq_depth_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.dlq_depth_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_errors_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_errors_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_throttles_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_throttles_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.lambda_sqs_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.lambda_sqs_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.lambda_basic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_event_source_mapping.dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_event_source_mapping.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_function.dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_sns_topic.alarms_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.alarms_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.email_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.email_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue.dlq_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.dlq_primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_sqs_queue_policy.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_email"></a> [alarm\_email](#input\_alarm\_email) | SNS alarm destination (required when enable\_alarms = true) | `string` | `null` | no |
| <a name="input_bus_name_dr"></a> [bus\_name\_dr](#input\_bus\_name\_dr) | EventBridge bus name in the DR region. Required when enable\_dr = true. | `string` | `null` | no |
| <a name="input_bus_name_primary"></a> [bus\_name\_primary](#input\_bus\_name\_primary) | EventBridge bus name in the primary region — typically from event-bus module output | `string` | n/a | yes |
| <a name="input_create_lambda"></a> [create\_lambda](#input\_create\_lambda) | Create a Lambda function to process events from SQS | `bool` | `false` | no |
| <a name="input_dlq_alarm_threshold"></a> [dlq\_alarm\_threshold](#input\_dlq\_alarm\_threshold) | DLQ message count that triggers alarm | `number` | `1` | no |
| <a name="input_dlq_visibility_timeout_seconds"></a> [dlq\_visibility\_timeout\_seconds](#input\_dlq\_visibility\_timeout\_seconds) | DLQ visibility timeout in seconds | `number` | `30` | no |
| <a name="input_enable_alarms"></a> [enable\_alarms](#input\_enable\_alarms) | Enable CloudWatch alarms (DLQ depth, Lambda errors, Lambda throttles) | `bool` | `true` | no |
| <a name="input_enable_dlq"></a> [enable\_dlq](#input\_enable\_dlq) | Enable Dead Letter Queue for failed events | `bool` | `true` | no |
| <a name="input_enable_dr"></a> [enable\_dr](#input\_enable\_dr) | Deploy consumer stack (rule + queue + Lambda + alarms) in the DR region. Disable for dev/staging. | `bool` | `true` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Log matched EventBridge events to CloudWatch | `bool` | `true` | no |
| <a name="input_event_pattern"></a> [event\_pattern](#input\_event\_pattern) | EventBridge event pattern — which events this consumer receives. See AWS docs for pattern syntax. | `any` | n/a | yes |
| <a name="input_lambda_batch_size"></a> [lambda\_batch\_size](#input\_lambda\_batch\_size) | Max SQS records per Lambda invocation (1–10000) | `number` | `10` | no |
| <a name="input_lambda_code"></a> [lambda\_code](#input\_lambda\_code) | Path to Lambda deployment package zip (required when create\_lambda = true) | `string` | `null` | no |
| <a name="input_lambda_environment_variables"></a> [lambda\_environment\_variables](#input\_lambda\_environment\_variables) | Environment variables for Lambda function. Applied to both primary and DR functions. | `map(string)` | `{}` | no |
| <a name="input_lambda_error_threshold"></a> [lambda\_error\_threshold](#input\_lambda\_error\_threshold) | Lambda errors per minute that trigger alarm | `number` | `1` | no |
| <a name="input_lambda_handler"></a> [lambda\_handler](#input\_lambda\_handler) | Lambda function handler | `string` | `"index.handler"` | no |
| <a name="input_lambda_memory_size"></a> [lambda\_memory\_size](#input\_lambda\_memory\_size) | Lambda memory in MB | `number` | `128` | no |
| <a name="input_lambda_runtime"></a> [lambda\_runtime](#input\_lambda\_runtime) | Lambda runtime | `string` | `"nodejs20.x"` | no |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | Lambda timeout in seconds. Must be less than sqs\_visibility\_timeout\_seconds. | `number` | `30` | no |
| <a name="input_max_receive_count"></a> [max\_receive\_count](#input\_max\_receive\_count) | Receive attempts before moving to DLQ (1–1000) | `number` | `3` | no |
| <a name="input_name"></a> [name](#input\_name) | Resource naming prefix (e.g. 'payments-enricher') | `string` | n/a | yes |
| <a name="input_sqs_message_retention_seconds"></a> [sqs\_message\_retention\_seconds](#input\_sqs\_message\_retention\_seconds) | SQS message retention period in seconds | `number` | `345600` | no |
| <a name="input_sqs_visibility_timeout_seconds"></a> [sqs\_visibility\_timeout\_seconds](#input\_sqs\_visibility\_timeout\_seconds) | SQS visibility timeout in seconds. Should be at least 6× lambda\_timeout. | `number` | `180` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alarm_topic_arn_dr"></a> [alarm\_topic\_arn\_dr](#output\_alarm\_topic\_arn\_dr) | ARN of the DR SNS alarm topic |
| <a name="output_alarm_topic_arn_primary"></a> [alarm\_topic\_arn\_primary](#output\_alarm\_topic\_arn\_primary) | ARN of the primary SNS alarm topic |
| <a name="output_dlq_arn_dr"></a> [dlq\_arn\_dr](#output\_dlq\_arn\_dr) | ARN of the DR Dead Letter Queue |
| <a name="output_dlq_arn_primary"></a> [dlq\_arn\_primary](#output\_dlq\_arn\_primary) | ARN of the primary Dead Letter Queue |
| <a name="output_lambda_arn_dr"></a> [lambda\_arn\_dr](#output\_lambda\_arn\_dr) | ARN of the DR Lambda function |
| <a name="output_lambda_arn_primary"></a> [lambda\_arn\_primary](#output\_lambda\_arn\_primary) | ARN of the primary Lambda function |
| <a name="output_lambda_function_name_dr"></a> [lambda\_function\_name\_dr](#output\_lambda\_function\_name\_dr) | Name of the DR Lambda function |
| <a name="output_lambda_function_name_primary"></a> [lambda\_function\_name\_primary](#output\_lambda\_function\_name\_primary) | Name of the primary Lambda function |
| <a name="output_lambda_role_arn"></a> [lambda\_role\_arn](#output\_lambda\_role\_arn) | ARN of the Lambda execution role (shared by both regions) |
| <a name="output_queue_arn_dr"></a> [queue\_arn\_dr](#output\_queue\_arn\_dr) | ARN of the DR SQS queue |
| <a name="output_queue_arn_primary"></a> [queue\_arn\_primary](#output\_queue\_arn\_primary) | ARN of the primary SQS queue |
| <a name="output_queue_url_dr"></a> [queue\_url\_dr](#output\_queue\_url\_dr) | URL of the DR SQS queue |
| <a name="output_queue_url_primary"></a> [queue\_url\_primary](#output\_queue\_url\_primary) | URL of the primary SQS queue |
| <a name="output_rule_arn_dr"></a> [rule\_arn\_dr](#output\_rule\_arn\_dr) | ARN of the DR EventBridge rule |
| <a name="output_rule_arn_primary"></a> [rule\_arn\_primary](#output\_rule\_arn\_primary) | ARN of the primary EventBridge rule |
<!-- END_TF_DOCS -->
