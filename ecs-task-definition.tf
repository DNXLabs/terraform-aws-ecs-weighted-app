resource "aws_ecs_task_definition" "default" {
  for_each = {
    for service in var.services : service.name => service
    if service.image != ""
  }

  family = "${var.cluster_name}-${each.key}"

  execution_role_arn = var.task_role_arn
  task_role_arn      = var.task_role_arn

  requires_compatibilities = [var.launch_type]

  network_mode = var.launch_type == "FARGATE" ? "awsvpc" : var.network_mode
  cpu          = var.launch_type == "FARGATE" ? each.value.cpu : null
  memory       = var.launch_type == "FARGATE" ? each.value.memory : null

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = each.value.image
      cpu       = each.value.cpu
      memory    = each.value.memory
      essential = true
      portMappings = [
        { containerPort = each.value.container_port }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.default[each.key].name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "app"
        }
      }
      mountPoints = length(var.efs_mapping) == 0 ? null : [{
        sourceVolume  = "efs-${keys(var.efs_mapping)[0]}"
        containerPath = values(var.efs_mapping)[0]
      }]
      secrets     = [for k, v in var.ssm_variables : { name : k, valueFrom : v }]
      environment = [for k, v in var.static_variables : { name : k, value : v }]
      ulimits     = var.ulimits
    }
  ])

  dynamic "volume" {
    for_each = var.efs_mapping

    content {
      name = "efs-${volume.key}"

      efs_volume_configuration {
        file_system_id     = volume.key
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = aws_efs_access_point.default[volume.key].id
        }
      }
    }
  }
}

