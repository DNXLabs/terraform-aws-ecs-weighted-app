resource "aws_appautoscaling_target" "ecs" {
  for_each = {
    for service in var.services : service.name => service
    # if service.autoscaling_cpu || service.autoscaling_memory || length(service.autoscaling_custom) > 0
    if service.autoscaling_cpu || service.autoscaling_memory
  }
  max_capacity       = each.value.autoscaling_max
  min_capacity       = each.value.autoscaling_min
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.default[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_cpu" {
  for_each = {
    for service in var.services : service.name => service
    if service.autoscaling_cpu
  }
  name               = "scale-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[each.key].service_namespace
  target_tracking_scaling_policy_configuration {
    target_value       = each.value.autoscaling_target_cpu
    disable_scale_in   = false
    scale_in_cooldown  = each.value.autoscaling_scale_in_cooldown
    scale_out_cooldown = each.value.autoscaling_scale_out_cooldown
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "scale_memory" {
  for_each = {
    for service in var.services : service.name => service
    if service.autoscaling_memory
  }
  name               = "scale-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[each.key].service_namespace
  target_tracking_scaling_policy_configuration {
    target_value       = each.value.autoscaling_target_memory
    disable_scale_in   = false
    scale_in_cooldown  = each.value.autoscaling_scale_in_cooldown
    scale_out_cooldown = each.value.autoscaling_scale_out_cooldown
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

# resource "aws_appautoscaling_policy" "scale_custom" {
#   for_each = { for custom in var.autoscaling_custom : custom.name => custom }

#   name               = each.value.name
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.ecs[each.key].resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs[each.key].scalable_dimension
#   service_namespace  = aws_appautoscaling_target.ecs[each.key].service_namespace

#   target_tracking_scaling_policy_configuration {
#     scale_in_cooldown  = each.value.scale_in_cooldown
#     scale_out_cooldown = each.value.scale_out_cooldown
#     target_value       = each.value.target_value

#     customized_metric_specification {
#       metric_name = each.value.metric_name
#       namespace   = each.value.namespace
#       statistic   = each.value.statistic
#       dimensions {
#         name  = "ClusterName"
#         value = var.cluster_name
#       }
#       dimensions {
#         name  = "ServiceName"
#         value = var.name
#       }
#     }
#   }
# }

# resource "aws_appautoscaling_scheduled_action" "scale_service_out" {
#   count              = var.enable_schedule ? 1 : 0
#   name               = "${var.name}-scale-out"
#   service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
#   resource_id        = aws_appautoscaling_target.ecs[0].resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
#   schedule           = var.schedule_cron_stop
#   timezone           = "UTC"

#   scalable_target_action {
#     min_capacity = 0
#     max_capacity = 0
#   }
# }

# resource "aws_appautoscaling_scheduled_action" "scale_service_in" {
#   count              = var.enable_schedule ? 1 : 0
#   name               = "${var.name}-scale-in"
#   service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
#   resource_id        = aws_appautoscaling_target.ecs[0].resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
#   schedule           = var.schedule_cron_start
#   timezone           = "UTC"

#   scalable_target_action {
#     min_capacity = var.autoscaling_min
#     max_capacity = var.autoscaling_max
#   }
# }

# resource "aws_appautoscaling_scheduled_action" "scale_service_in_prod_1" {
#   count              = var.enable_schedule_prod_1 ? 1 : 0
#   name               = "${var.name}-scale-in-12am"
#   service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
#   resource_id        = aws_appautoscaling_target.ecs[0].resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
#   schedule           = var.schedule_cron_start_prod_1
#   timezone           = "UTC"

#   scalable_target_action {
#     min_capacity = 6
#     max_capacity = 10
#   }
# }

# resource "aws_appautoscaling_scheduled_action" "scale_service_out_prod_1" {
#   count              = var.enable_schedule_prod_1 ? 1 : 0
#   name               = "${var.name}-scale-out-12am"
#   service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
#   resource_id        = aws_appautoscaling_target.ecs[0].resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
#   schedule           = var.schedule_cron_stop_prod_1
#   timezone           = "UTC"

#   scalable_target_action {
#     min_capacity = 6
#     max_capacity = 10
#   }
# }

# resource "aws_appautoscaling_scheduled_action" "scale_service_in_prod_2" {
#   count              = var.enable_schedule_prod_2 ? 1 : 0
#   name               = "${var.name}-scale-in-10am"
#   service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
#   resource_id        = aws_appautoscaling_target.ecs[0].resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
#   schedule           = var.schedule_cron_start_prod_2
#   timezone           = "UTC"

#   scalable_target_action {
#     min_capacity = 6
#     max_capacity = 10
#   }
# }

# resource "aws_appautoscaling_scheduled_action" "scale_service_out_prod_2" {
#   count              = var.enable_schedule_prod_2 ? 1 : 0
#   name               = "${var.name}-scale-out-1030am"
#   service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
#   resource_id        = aws_appautoscaling_target.ecs[0].resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
#   schedule           = var.schedule_cron_stop_prod_2
#   timezone           = "UTC"

#   scalable_target_action {
#     min_capacity = 6
#     max_capacity = 10
#   }
# }

