provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "dr"
  region = "us-west-2"
}

module "order_events" {
  source = "pomo-studio/event-consumer/aws"

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

  enable_alarms = false
  enable_dr     = false
}
