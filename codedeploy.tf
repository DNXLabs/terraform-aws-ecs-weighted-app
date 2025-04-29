resource "aws_codedeploy_app" "ecs" {
  for_each = {
    for service in var.services : service.name => service
    if service.deployment_controller == "CODE_DEPLOY"
  }
  compute_platform = "ECS"
  name             = "${var.cluster_name}-${each.key}"
}

resource "aws_codedeploy_deployment_group" "ecs" {
  for_each = {
    for service in var.services : service.name => service
    if service.deployment_controller == "CODE_DEPLOY"
  }
  app_name               = aws_codedeploy_app.ecs[each.key].name
  deployment_config_name = var.codedeploy_deployment_config_name
  deployment_group_name  = "${var.cluster_name}-${each.key}"
  service_role_arn       = var.create_iam_codedeployrole == true ? aws_iam_role.codedeploy_service[each.key].arn : var.codedeploy_role_arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = var.codedeploy_wait_time_for_cutover == 0 ? "CONTINUE_DEPLOYMENT" : "STOP_DEPLOYMENT"
      wait_time_in_minutes = var.codedeploy_wait_time_for_cutover
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = var.codedeploy_wait_time_for_termination
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.cluster_name
    service_name = aws_ecs_service.default[each.key].name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.alb_listener_https_arn]
      }
      target_group {
        name = aws_lb_target_group.default[each.key].name
      }
    }
  }
}
