mock_provider "aws" {}
mock_provider "random" {}

run "valid_required_vars" {
  command = plan
  variables {
    alb_listener_https_arn = "aws:arn:123456789012:listener/app/test-alb/1234567890"
    vpc_id                 = "vpc-1234567890"
    task_role_arn          = "aws:arn:iam:123456789012:role/ecsTaskExecutionRole"
    service_role_arn       = "aws:arn:iam:123456789012:role/ecsServiceExecutionRole"
    cluster_name           = "test-cluster"
    services = [{
      name = "test-service"
    }]
    paths     = ["/test"]
    hostnames = ["test.example.com"]
    subnets   = ["subnet-1234567890"]
  }
}
