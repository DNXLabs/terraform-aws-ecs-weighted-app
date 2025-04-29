resource "aws_cloudwatch_log_group" "ecs_events" {
  for_each          = { for service in var.services : service.name => service }
  name              = "/ecs/events/${var.cluster_name}/${each.key}"
  retention_in_days = each.value.cloudwatch_logs_retention
  tags = {
    ExportToS3 = each.value.cloudwatch_logs_export
  }
}


resource "aws_cloudwatch_event_rule" "ecs_events" {
  for_each      = { for service in var.services : service.name => service }
  name          = "capture-ecs-events-${var.cluster_name}-${each.key}"
  description   = "Capture ecs service events from ${var.cluster_name}-${each.key}"
  event_pattern = <<EOF
{
  "source": ["aws.ecs"],
  "detail-type": ["ECS Task State Change", "ECS Container Instance State Change"],
  "detail": {
    "clusterArn": ["${data.aws_ecs_cluster.ecs_cluster.arn}"],
    "group": ["service:${each.key}"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "ecs_events" {
  for_each = { for service in var.services : service.name => service }
  rule     = aws_cloudwatch_event_rule.ecs_events[each.key].name
  arn      = aws_cloudwatch_log_group.ecs_events[each.key].arn
}

data "aws_iam_policy_document" "ecs_events" {
  for_each = { for service in var.services : service.name => service }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]
    resources = ["${aws_cloudwatch_log_group.ecs_events[each.key].arn}:*"]
    principals {
      identifiers = ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "ecs_events" {
  for_each        = { for service in var.services : service.name => service }
  policy_document = data.aws_iam_policy_document.ecs_events[each.key].json
  policy_name     = "capture-ecs-events-${var.cluster_name}-${each.key}"
}
