module "role_task_definition" {
  source           = "git@github.com:Pyxis-Portal/infra-devops-tf-aws-iam?ref=v0.0.2"
  create_role      = var.create_task_definition
  role_name        = "${var.name_cluster}-task_definition"
  identifiers_role = ["ecs-tasks.amazonaws.com"]

  policy_arn = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    #var.role_task_definition_policy_arn
  ]

  tags = var.tags
  
}

module "role_service" {
  source           = "git@github.com:Pyxis-Portal/infra-devops-tf-aws-iam?ref=v0.0.2"
  create_role      = var.create_service
  role_name        = "${var.name_cluster}-service"
  identifiers_role = ["ecs.amazonaws.com"]

  policy_arn = [
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
  ]
  tags = var.tags
}

module "ec2_ecs_instance_profile" {
  source  = "git@github.com:Pyxis-Portal/infra-devops-tf-aws-iam?ref=v0.0.3"

  create_role_instance_profile  = var.create_service
  name_role_profile             = var.name_cluster  
  include_ssm                   = true
  policy_arn_profile            = var.ec2_ecs_instance_profile_policys_arn

  tags = merge(
    local.tags,
    var.tags
  )  
}