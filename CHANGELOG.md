# Changelog

All notable changes to this module are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/).

## [1.0.2] - 2026-09-05

### Added

- CHANGELOG.md

## [1.0.1] - 2026-09-04

### Added

- CI and release workflows (using mocked alias providers)
- `.tflint.hcl` linting configuration
- MIT `LICENSE`
- README badges
- Example Terraform blocks
- Committed `.terraform.lock.hcl` lock files

### Changed

- AWS provider constraint now allows `>= 5.0, < 7.0`
- Default branch renamed from `master` to `main`

## [1.0.0]

### Added

- Initial release
- EventBridge rule → SQS queue consumer pattern
- Optional DLQ with configurable max receive count
- Optional Lambda processor with SQS event source mapping and `ReportBatchItemFailures`
- CloudWatch alarms: DLQ depth, Lambda errors, Lambda throttles
- SNS email notifications for alarms
- EventBridge event logging to CloudWatch
- Multi-region support (primary + DR) per ADR-007
- Cross-variable validation (Terraform >= 1.9.0)

> Historical releases are documented in [GitHub Releases](https://github.com/pomo-studio/terraform-aws-event-consumer/releases).
