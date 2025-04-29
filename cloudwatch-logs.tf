resource "aws_cloudwatch_log_group" "default" {
  for_each          = { for service in var.services : service.name => service }
  name              = "/ecs/${var.cluster_name}/${each.key}"
  retention_in_days = each.value.cloudwatch_logs_retention
  tags = {
    ExportToS3 = each.value.cloudwatch_logs_export
  }
}
