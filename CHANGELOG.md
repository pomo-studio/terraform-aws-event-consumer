# Changelog

## v1.0.0

- Initial release
- EventBridge rule → SQS queue consumer pattern
- Optional DLQ with configurable max receive count
- Optional Lambda processor with SQS event source mapping and `ReportBatchItemFailures`
- CloudWatch alarms: DLQ depth, Lambda errors, Lambda throttles
- SNS email notifications for alarms
- EventBridge event logging to CloudWatch
- Multi-region support (primary + DR) per ADR-007
- Cross-variable validation (Terraform >= 1.9.0)
