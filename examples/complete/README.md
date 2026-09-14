# Event consumer complete

Full consumer with Lambda processing, DR, DLQ, and alarms.

## What it creates

- EventBridge rules in the primary and DR regions for `com.myapp.payments` events.
- SQS queues with a 360s visibility timeout, 7-day retention, and a DLQ at 5 receives.
- A `nodejs20.x` Lambda processor batched at 5 messages, wired to the primary queue.
- CloudWatch alarms that email `ops@example.com`.

## Before you start

- AWS credentials. Primary provider `us-east-1`, DR provider `us-west-2`.
- A bus named `payments-bus` must exist in both regions.
- Build `dist/handler.zip` before apply. It is not created here.
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
