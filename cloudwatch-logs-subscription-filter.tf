resource "aws_cloudwatch_log_subscription_filter" "log_subscription_filter" {
  for_each = {
    for service in var.services : service.name => service
    if service.log_subscription_filter_enabled
  }
  name            = "${each.key}_subscription_filter"
  log_group_name  = aws_cloudwatch_log_group.default[each.key].name
  filter_pattern  = var.log_subscription_filter_filter_pattern
  role_arn        = var.log_subscription_filter_role_arn
  destination_arn = var.log_subscription_filter_destination_arn
}
