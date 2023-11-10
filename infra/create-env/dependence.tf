data "template_file" "task_definitions" {
  count = var.create_service && length(var.services) != 0 ? length(var.services) : 0

  template = file("${path.module}/task_definitions/default_ec2.json")

  vars = {
    containerPort = tonumber(var.services[count.index].port)
    image_name    = var.services[count.index].name
    service_name  = var.services[count.index].name
    account_id    = local.account_id
    region        = local.region
  }
}

data "template_file" "task_definitions_filedemon" {

  template = file("${path.module}/task_definitions/task_definition_filedemon.json")

  vars = {
    StackName = var.name_cluster
  }
}

data "aws_ami" "amazon_linux_ecs" {
  most_recent = true # get the latest version

  filter {
    name = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"] # ECS optimized image
  }

  owners = [
    "amazon" # Only official images
  ]
}

data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.sh")

  vars = {
    cluster_name = var.name_cluster
  }
}

##data terraform_remote_state base {
##    backend = "s3"
##
##    config = {
##        bucket = "dojo-remote-state"
##        key    = "base.tfstate"
##        region = "us-east-1"
##    }
##}
##
##vpc_id                            = data.terraform_remote_state.base.outputs.vpc_id
