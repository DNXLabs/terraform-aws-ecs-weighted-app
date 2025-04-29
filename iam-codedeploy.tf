resource "aws_iam_role" "codedeploy_service" {
  for_each = {
    for service in var.services : service.name => service
    if var.create_iam_codedeployrole
  }

  name = "codedeploy-service-${var.cluster_name}-${each.key}-${local.regions_shortname[data.aws_region.current.name]}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codedeploy_service" {
  for_each = {
    for service in var.services : service.name => service
    if var.create_iam_codedeployrole
  }
  role       = aws_iam_role.codedeploy_service[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}
