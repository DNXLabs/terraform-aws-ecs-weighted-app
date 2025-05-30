resource "aws_cloudwatch_metric_alarm" "min_healthy_tasks" {
  for_each = {
    for service in var.services : service.name => service
    if length(var.alarm_sns_topics) > 0 && var.alarm_min_healthy_tasks != 0
  }

  alarm_name                = "${try(data.aws_iam_account_alias.current[0].account_alias, var.alarm_prefix)}-ecs-${var.cluster_name}-${each.key}-min-healthy-tasks"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = var.alarm_evaluation_periods
  threshold                 = var.alarm_min_healthy_tasks
  alarm_description         = "Service ${each.key} has less than ${var.alarm_min_healthy_tasks} healthy tasks"
  alarm_actions             = var.alarm_sns_topics
  ok_actions                = var.alarm_sns_topics
  insufficient_data_actions = []
  treat_missing_data        = "ignore"

  metric_query {
    id          = "e1"
    expression  = "m1"
    label       = "HealthyHostCountCombined"
    return_data = "true"
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "HealthyHostCount"
      namespace   = "AWS/ApplicationELB"
      period      = "60"
      stat        = "Maximum"
      unit        = "Count"

      dimensions = {
        LoadBalancer = join("/", slice(split("/", data.aws_lb_listener.ecs.load_balancer_arn), 1, 4))
        TargetGroup  = aws_lb_target_group.default[each.key].arn_suffix
      }
    }
  }

  lifecycle {
    ignore_changes = [alarm_actions, ok_actions]
  }

}

resource "aws_cloudwatch_metric_alarm" "high_cpu_usage" {
  for_each = {
    for service in var.services : service.name => service
    if length(var.alarm_sns_topics) > 0 && var.alarm_high_cpu_usage_above != 0
  }
  alarm_name                = "${try(data.aws_iam_account_alias.current[0].account_alias, var.alarm_prefix)}-ecs-${var.cluster_name}-${each.key}-high-cpu-usage"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = var.alarm_evaluation_periods
  threshold                 = var.alarm_high_cpu_usage_above
  alarm_description         = "Service ${each.key} CPU usage average is above ${var.alarm_high_cpu_usage_above} percent"
  alarm_actions             = var.alarm_sns_topics
  ok_actions                = var.alarm_sns_topics
  insufficient_data_actions = []
  treat_missing_data        = "ignore"

  metric_name = "CPUUtilization"
  namespace   = "AWS/ECS"
  period      = "60"
  statistic   = "Average"
  unit        = "Percent"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = aws_ecs_service.default[each.key].name
  }

  lifecycle {
    ignore_changes = [alarm_actions, ok_actions]
  }

}

resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks" {
  for_each = {
    for service in var.services : service.name => service
    if length(var.alarm_sns_topics) > 0 && var.alarm_ecs_running_tasks_threshold != 0
  }
  alarm_name                = "${try(data.aws_iam_account_alias.current[0].account_alias, var.alarm_prefix)}-ecs-${each.key}-running-tasks"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "RunningTaskCount"
  namespace                 = "ECS/ContainerInsights"
  period                    = "30"
  statistic                 = "Average"
  threshold                 = var.alarm_ecs_running_tasks_threshold
  alarm_description         = "ECS service ${each.key} running tasks is lower than the threshold"
  alarm_actions             = var.alarm_sns_topics
  ok_actions                = var.alarm_sns_topics
  insufficient_data_actions = []
  treat_missing_data        = "ignore"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = aws_ecs_service.default[each.key].name
  }

  lifecycle {
    ignore_changes = [alarm_actions, ok_actions]
  }

}
