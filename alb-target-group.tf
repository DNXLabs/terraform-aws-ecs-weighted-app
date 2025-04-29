resource "aws_lb_listener_rule" "default" {
  listener_arn = var.alb_listener_https_arn

  action {
    type = "forward"
    forward {
      dynamic "target_group" {
        for_each = { for service in var.services : service.name => service }
        content {
          arn    = aws_lb_target_group.default[target_group.key].arn
          weight = target_group.value.target_group_weight
        }
      }

    }
  }

  dynamic "condition" {
    for_each = length(var.paths) > 0 ? [var.paths] : []
    content {
      path_pattern {
        values = toset(condition.value)
      }
    }
  }

  dynamic "condition" {
    for_each = length(var.hostnames) > 0 ? [var.hostnames] : []
    content {
      host_header {
        values = toset(condition.value)
      }
    }
  }

  dynamic "condition" {
    for_each = length(var.source_ips) > 0 ? [var.source_ips] : []
    content {
      source_ip {
        values = toset(condition.value)
      }
    }
  }

  dynamic "condition" {
    for_each = var.http_header
    content {
      http_header {
        http_header_name = condition.value.name
        values           = condition.value.values
      }
    }
  }

  lifecycle {
    ignore_changes       = [action[0].target_group_arn]
    replace_triggered_by = [aws_lb_target_group.default]
  }

  priority = try(
    aws_lb_listener_rule.path_redirects[length(aws_lb_listener_rule.path_redirects) - 1].priority + 1,
    try(
      aws_lb_listener_rule.green_auth_oidc[0].priority + 1, var.alb_priority != 0 ? var.alb_priority : null
    )
  )
}

resource "aws_lb_listener_rule" "redirects" {
  count        = length(compact(split(",", var.hostname_redirects)))
  listener_arn = var.alb_listener_https_arn

  action {
    type = "redirect"

    redirect {
      host        = var.hostnames[0]
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = [element(split(",", var.hostname_redirects), count.index)]
    }
  }
}

resource "aws_lb_listener_rule" "path_redirects" {
  count        = length(var.redirects)
  listener_arn = var.alb_listener_https_arn

  action {
    type = "redirect"
    redirect {
      path        = keys(var.redirects)[count.index]
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = [values(var.redirects)[count.index]]
    }
  }

  priority = try(aws_lb_listener_rule.green_auth_oidc[0].priority + 1,
    var.alb_priority != 0 ? var.alb_priority : null
  )
}

# Generate a random string to add it to the name of the Target Group
resource "random_string" "alb_prefix" {
  length  = 4
  upper   = false
  special = false
}

resource "aws_lb_target_group" "default" {
  for_each = { for service in var.services : service.name => service }

  name                 = var.compat_keep_target_group_naming ? "${var.cluster_name}-${each.key}" : format("%s-%s", substr("${var.cluster_name}-${each.key}", 0, 27), random_string.alb_prefix.result)
  port                 = each.value.port
  protocol             = each.value.protocol
  vpc_id               = var.vpc_id
  deregistration_delay = 10
  target_type          = var.launch_type == "FARGATE" ? "ip" : "instance"

  health_check {
    path                = each.value.healthcheck_path
    interval            = each.value.healthcheck_interval
    healthy_threshold   = each.value.healthy_threshold
    unhealthy_threshold = each.value.unhealthy_threshold
    timeout             = each.value.healthcheck_timeout
    matcher             = each.value.healthcheck_matcher
    protocol            = each.value.protocol
  }

  dynamic "stickiness" {
    for_each = var.dynamic_stickiness
    iterator = stickiness

    content {
      cookie_duration = stickiness.value.cookie_duration
      cookie_name     = stickiness.value.cookie_name
      type            = stickiness.value.type
    }
  }
}
