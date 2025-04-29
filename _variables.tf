# Required Variables
variable "cluster_name" {
  description = "Name of existing ECS Cluster to deploy this app to"
  type        = string
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "Cluster name must be provided"
  }
}

variable "service_role_arn" {
  description = "Existing service role ARN created by ECS cluster module"
  type        = string
  validation {
    condition     = length(var.service_role_arn) > 0
    error_message = "Service role ARN must be provided"
  }
}

variable "task_role_arn" {
  type        = string
  description = "Existing task role ARN created by ECS cluster module"
  validation {
    condition     = length(var.task_role_arn) > 0
    error_message = "Task role ARN must be provided"
  }
}

variable "services" {
  type = list(object({
    name                            = string
    port                            = optional(number, 80)
    container_port                  = optional(number, 8080)
    protocol                        = optional(string, "HTTP")
    healthcheck_path                = optional(string, "/")
    healthcheck_interval            = optional(string, "10")
    healthy_threshold               = optional(number, 3)
    unhealthy_threshold             = optional(number, 3)
    healthcheck_timeout             = optional(number, 5)
    healthcheck_matcher             = optional(string, "200")
    target_group_weight             = optional(number, 100)
    desired_count                   = optional(number, 2)
    deployment_controller           = optional(string, "ECS")
    cloudwatch_logs_retention       = optional(number, 120)
    cloudwatch_logs_export          = optional(bool, false)
    image                           = optional(string, "")
    log_subscription_filter_enabled = optional(string, false)
    autoscaling_cpu                 = optional(bool, false)
    autoscaling_memory              = optional(bool, false)
    autoscaling_max                 = optional(number, 4)
    autoscaling_min                 = optional(number, 1)
    autoscaling_target_cpu          = optional(number, 50)
    autoscaling_target_memory       = optional(number, 90)
    autoscaling_scale_in_cooldown   = optional(number, 300)
    autoscaling_scale_out_cooldown  = optional(number, 300)
    memory                          = optional(number, 1024)
    cpu                             = optional(number, 512)
    # paths                           = optional(list(string), [])
    # hostnames                       = optional(list(string), [])
    # source_ips                      = optional(list(string), [])
  }))
  validation {
    condition     = length(var.services) > 0
    error_message = "At least one service must be provided"
  }
  validation {
    condition     = alltrue([for service in var.services : service.name != ""])
    error_message = "Service name cannot be empty"
  }
  # To-Do: Validate if target_group_weight of all services sum to 100
}

# Optional Variables

variable "hosted_zone_is_internal" {
  default     = "false"
  type        = string
  description = "Set true in case the hosted zone is in an internal VPC, otherwise false"
}

variable "hosted_zone" {
  default     = ""
  type        = string
  description = "Hosted Zone to create DNS record for this app"
}

variable "hosted_zone_id" {
  default     = ""
  type        = string
  description = "Hosted Zone ID to create DNS record for this app (use this to avoid data lookup when using `hosted_zone`)"
}

variable "hostname_create" {
  default     = false
  type        = bool
  description = "Optional parameter to create or not a Route53 record"
}

# TO-DO: These validations introduce a circular dependency, have to find a way to validate them
variable "hostnames" {
  default     = []
  type        = list(string)
  description = "List of hostnames to create listerner rule and optionally, DNS records for this app"
  # validation {
  #   error_message = "You must provide either var.hostnames, var.paths or var.source_ips"
  #   condition     = length(var.hostnames) > 0 || length(var.paths) > 0 || length(var.source_ips) > 0
  # }
}

variable "paths" {
  default     = []
  description = "List of paths to use on listener rule (example: ['/*'])"
  type        = list(string)
  # validation {
  #   error_message = "You must provide either var.hostnames, var.paths or var.source_ips"
  #   condition     = length(var.hostnames) > 0 || length(var.paths) > 0 || length(var.source_ips) > 0
  # }
}

variable "source_ips" {
  default     = []
  type        = list(string)
  description = "List of source ip to use on listerner rule"
  # validation {
  #   error_message = "You must provide either var.hostnames, var.paths or var.source_ips"
  #   condition     = length(var.hostnames) > 0 || length(var.paths) > 0 || length(var.source_ips) > 0
  # }
}

variable "http_header" {
  default     = []
  description = "Header to use on listerner rule with name e values"
  type        = list(any)
}

variable "hostname_redirects" {
  description = "List of hostnames to redirect to the main one, comma-separated"
  default     = ""
  type        = string
}

variable "codedeploy_role_arn" {
  default     = null
  type        = string
  description = "Existing IAM CodeDeploy role ARN created by ECS cluster module"
}

variable "service_health_check_grace_period_seconds" {
  default     = 0
  type        = number
  description = "Time until your container starts serving requests"
}

variable "service_deployment_maximum_percent" {
  default     = 200
  type        = number
  description = "Maximum percentage of tasks to run during deployments"
}

variable "service_deployment_minimum_healthy_percent" {
  default     = 100
  type        = number
  description = "Minimum healthy percentage during deployments"
}

variable "task_definition_arn" {
  type        = string
  description = "Task definition to use for this service (optional)"
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID to deploy this app to"
  type        = string
}

variable "alb_listener_https_arn" {
  type        = string
  description = "ALB HTTPS Listener created by ECS cluster module"
  validation {
    condition     = length(var.alb_listener_https_arn) > 0
    error_message = "ALB HTTPS Listener ARN must be provided"
  }
}

variable "alb_dns_name" {
  type        = string
  description = "ALB DNS Name"
  default     = ""
}

variable "alb_name" {
  description = "ALB name - Required if it is an internal one"
  default     = ""
  type        = string
}

variable "alb_priority" {
  default     = 0
  type        = number
  description = "priority rules ALB (leave 0 to let terraform calculate)"
}

variable "alarm_min_healthy_tasks" {
  default     = 2
  type        = number
  description = "Alarm when the number of healthy tasks is less than this number (use 0 to disable this alarm)"
}

variable "alarm_high_cpu_usage_above" {
  default     = 80
  type        = number
  description = "Alarm when CPU is above a certain value (use 0 to disable this alarm)"
}

variable "alarm_evaluation_periods" {
  default     = "2"
  type        = string
  description = "The number of minutes the alarm must be below the threshold before entering the alarm state."
}

variable "alarm_sns_topics" {
  default     = []
  type        = list(string)
  description = "Alarm topics to create and alert on ECS service metrics. Leaving empty disables all alarms."
}

variable "alb_only" {
  default     = false
  type        = bool
  description = "Whether to deploy only an alb and no cloudFront or not with the cluster"
}

variable "codedeploy_wait_time_for_cutover" {
  default     = 0
  type        = number
  description = "Time in minutes to route the traffic to the new application deployment"
}

variable "codedeploy_wait_time_for_termination" {
  type        = number
  default     = 0
  description = "Time in minutes to terminate the new deployment"
}

variable "codedeploy_deployment_config_name" {
  default     = "CodeDeployDefault.ECSAllAtOnce"
  type        = string
  description = "Specifies the deployment configuration for CodeDeploy"
}

variable "compat_keep_target_group_naming" {
  default     = false
  type        = bool
  description = "Keeps old naming convention for target groups to avoid recreation of resource in production environments"
}

variable "launch_type" {
  default     = "FARGATE"
  description = "The launch type on which to run your service. The valid values are EC2 and FARGATE. Defaults to EC2."
  type        = string
  validation {
    condition     = contains(["EC2", "FARGATE"], var.launch_type)
    error_message = "The launch type must be either EC2 or FARGATE"
  }
}

variable "fargate_spot" {
  default     = false
  description = "Set true to use FARGATE_SPOT capacity provider by default (only when launch_type=FARGATE)"
  type        = bool
}

variable "subnets" {
  default     = null
  description = "The subnets associated with the task or service. (REQUIRED IF var.launch_type IS FARGATE)"
  type        = list(string)
  validation {
    condition     = var.launch_type == "FARGATE" ? length(var.subnets) > 0 : true
    error_message = "Subnets must be provided when using Fargate launch type"
  }
}

variable "network_mode" {
  default     = null
  type        = string
  description = "The Docker networking mode to use for the containers in the task. The valid values are none, bridge, awsvpc, and host. (REQUIRED IF 'LAUCH_TYPE' IS FARGATE)"
  # validation {
  #   condition     = var.launch_type == "FARGATE" ? length(var.network_mode) > 0 : true
  #   error_message = "Networm mode must be provided when using Fargate launch type"
  # }
}

variable "security_groups" {
  default     = null
  description = "The security groups associated with the task or service"
  type        = list(string)
}

variable "log_subscription_filter_role_arn" {
  type    = string
  default = ""
}

variable "log_subscription_filter_destination_arn" {
  type    = string
  default = ""
}

variable "log_subscription_filter_filter_pattern" {
  default = ""
  type    = string
}

variable "ordered_placement_strategy" {
  # This variable may not be used with Fargate!
  description = "Service level strategy rules that are taken into consideration during task placement. List from top to bottom in order of precedence. The maximum number of ordered_placement_strategy blocks is 5."
  type = list(object({
    field = string
    type  = string
  }))
  default = []
}

variable "placement_constraints" {
  # This variables may not be used with Fargate!
  description = "Rules that are taken into consideration during task placement. Maximum number of placement_constraints is 10."
  type = list(object({
    type       = string
    expression = string
  }))
  default = []
}

variable "create_iam_codedeployrole" {
  type        = bool
  default     = true
  description = "Create Codedeploy IAM Role for ECS or not."
}

variable "alarm_prefix" {
  type        = string
  description = "String prefix for cloudwatch alarms. (Optional)"
  default     = "alarm"
}

variable "efs_mapping" {
  type        = map(string)
  description = "A map of efs volume ids and paths to mount into the default task definition"
  default     = {}
}

variable "ssm_variables" {
  type        = map(string)
  description = "Map of variables and SSM locations to add to the task definition"
  default     = {}
}

variable "static_variables" {
  type        = map(string)
  description = "Map of variables and static values to add to the task definition"
  default     = {}
}

# TO-DO: All the auth-* variables should be moved to a single object
variable "auth_oidc_enabled" {
  type        = bool
  default     = false
  description = "Enables OIDC-authenticated listener rule"
}

variable "auth_oidc_paths" {
  type        = list(string)
  default     = []
  description = "List of paths to use as a condition to authenticate (example: ['/admin*'])"
}

variable "auth_oidc_hostnames" {
  type        = list(string)
  default     = []
  description = "List of hostnames to use as a condition to authenticate with OIDC"
}

variable "auth_oidc_authorization_endpoint" {
  type        = string
  default     = ""
  description = "Authorization endpoint for OIDC (Google: https://accounts.google.com/o/oauth2/v2/auth)"
}

variable "auth_oidc_client_id" {
  type        = string
  default     = ""
  description = "Client ID for OIDC authentication"
}

variable "auth_oidc_client_secret" {
  type        = string
  default     = ""
  description = "Client Secret for OIDC authentication"
}

variable "auth_oidc_issuer" {
  type        = string
  default     = ""
  description = "Issuer URL for OIDC authentication (Google: https://accounts.google.com)"
}

variable "auth_oidc_token_endpoint" {
  type        = string
  default     = ""
  description = "Token Endpoint URL for OIDC authentication (Google: https://oauth2.googleapis.com/token)"
}

variable "auth_oidc_user_info_endpoint" {
  type        = string
  default     = ""
  description = "User Info Endpoint URL for OIDC authentication (Google: https://openidconnect.googleapis.com/v1/userinfo)"
}

variable "auth_oidc_session_timeout" {
  type        = number
  default     = 43200
  description = "Session timeout for OIDC authentication (default 12 hours)"
}

variable "ulimits" {
  type = list(object({
    name      = string
    hardLimit = number
    softLimit = number
  }))
  description = "Container ulimit settings. This is a list of maps, where each map should contain \"name\", \"hardLimit\" and \"softLimit\""
  default     = null
}

# variable "autoscaling_custom" {
#   type = list(object({
#     name               = string
#     scale_in_cooldown  = number
#     scale_out_cooldown = number
#     target_value       = number
#     metric_name        = string
#     namespace          = string
#     statistic          = string
#   }))
#   default     = []
#   description = "Set one or more app autoscaling by customized metric"
# }

variable "dynamic_stickiness" {
  type        = any
  default     = []
  description = "Target Group stickiness. Used in dynamic block."
}

variable "redirects" {
  description = "Map of path redirects to add to the listener"
  default     = {}
  type        = map(any)
}

variable "deployment_controller" {
  default     = "CODE_DEPLOY"
  type        = string
  description = "Type of deployment controller. Valid values: CODE_DEPLOY, ECS, EXTERNAL."
}

variable "ecs_service_capacity_provider_strategy" {
  description = "(Optional) The capacity provider strategy to use for the service. Can be one or more. These can be updated without destroying and recreating the service only if set to [] and not changing from 0 capacity_provider_strategy blocks to greater than 0, or vice versa."
  default     = [{}]
  type        = list(map(string))
}

variable "alarm_ecs_running_tasks_threshold" {
  type        = number
  default     = 0
  description = "Alarm when the number of ecs service running tasks is lower than a certain value. CloudWatch Container Insights must be enabled for the cluster."
}

# variable "enable_schedule" {
#   default     = false
#   type        = bool
#   description = "Enables schedule to shut down and start up instances outside business hours."
# }

variable "schedule_cron_start" {
  type        = string
  default     = ""
  description = "Cron expression to define when to trigger a start of the auto-scaling group. E.g. 'cron(00 21 ? * SUN-THU *)' to start at 8am UTC time."
}

variable "schedule_cron_stop" {
  type        = string
  default     = ""
  description = "Cron expression to define when to trigger a stop of the auto-scaling group. E.g. 'cron(00 09 ? * MON-FRI *)' to start at 8am UTC time"
}
