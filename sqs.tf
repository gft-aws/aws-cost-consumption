data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

##
## The primary and dead-letter queues
##

resource "aws_sqs_queue" "base_queue" {
  name                       = "report-delivery-queue"
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 60
  redrive_policy = jsonencode({
    "deadLetterTargetArn" = aws_sqs_queue.deadletter_queue.arn,
    "maxReceiveCount"     = 3
  })
}

resource "aws_sqs_queue" "deadletter_queue" {
  name                       = "report-delivery-DLQ"
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 60
}

resource "aws_sqs_queue_policy" "sqspolicy" {
  queue_url = aws_sqs_queue.base_queue.id

  policy = <<POLICY

{
  "Id": "Queue_Policy_access",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Queue_Actions",
      "Action": [
        "sqs:SendMessage"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:sqs:eu-west-2:${data.aws_caller_identity.current.account_id}:report-delivery-queue",
      "Principal": {
        "AWS": [
          "${var.cross_account_role}"
        ]
      }
    }
  ]
}
POLICY
}
