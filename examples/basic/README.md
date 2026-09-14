# Event consumer basic

Queue matching events from an existing bus. No Lambda, no alarms.

## What it creates

- An EventBridge rule on `my-event-bus` matching `com.myapp.orders` `OrderCreated`.
- An SQS queue, rule target, and the IAM policy to deliver into it.
- DR stays off, so the queue and rule exist only in the primary region.

## Before you start

- AWS credentials. Primary provider `us-east-1`, DR provider `us-west-2`.
- A bus named `my-event-bus` must already exist.
- Uses the published registry module `pomo-studio/event-consumer/aws`, version `~> 1.0`.

## Run it

```bash
terraform init
terraform plan
terraform apply
```

## Clean up

```bash
terraform destroy
```
