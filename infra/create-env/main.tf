locals {
  vpc_id          = var.vpc_id
  subnets_private = var.subnets_ids_private
  subnets_public  = var.subnets_ids_public
  #subnets_private_rds = var.subnets_idsrds_private
  region          = var.region
  account_id      = var.account_id

  tags = {
    Terraform   = true
    environment = var.environment
  }
}

resource "aws_ecs_cluster" "this" {
  count = var.create_ecs ? 1 : 0

  name               = var.name_cluster
  capacity_providers = var.capacity_providers == null ? [element(concat(aws_ecs_capacity_provider.this.*.name, [""]), 0)] : var.capacity_providers

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  tags = merge(
    local.tags,
    var.tags
  )

  
  depends_on = [
    aws_ecs_capacity_provider.this
  ]
}

resource "aws_ecs_capacity_provider" "this" {
  count = var.create_ecs ? 1 : 0

  name = var.name_cluster

  auto_scaling_group_provider {
    auto_scaling_group_arn         = module.autoscaling_group.autoscaling_group_arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      instance_warmup_period    = var.cp_instance_warmup_period
      minimum_scaling_step_size = var.cp_min_scaling_step_size
      maximum_scaling_step_size = var.cp_max_scaling_step_size
      status                    = "ENABLED"
      target_capacity           = var.target_capacity
    }
  }

  tags = merge(
    local.tags,
    var.tags
  )
    
    depends_on = [
    module.autoscaling_group
  ]
}

resource "aws_ecs_service" "this" {
  count = var.create_service && length(var.services) != 0 ? length(var.services) : 0

  name            = var.services[count.index].name
  desired_count   = 0
  cluster         = element(concat(aws_ecs_cluster.this.*.id, [""]), 0)
  task_definition = element(concat(aws_ecs_task_definition.this.*.arn, [""]), count.index)
  iam_role        = module.role_service.role_arn
  enable_ecs_managed_tags = true
  propagate_tags = "TASK_DEFINITION"

  #Esta estrategia coloca tareas en base a la menor cantidad de CPU o memoria utilizada. Es útil cuando deseas utilizar la menor cantidad de instancias de EC2 posible, lo cual puede ser más rentable.
  #"binpack" con "memory": Seleccionarás instancias que tengan la menor cantidad de memoria libre disponible que aún pueda alojar la tarea. Esto maximiza la utilización de memoria en cada instancia antes de pasar a la siguiente.
  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  load_balancer {
    target_group_arn = element(concat(module.alb.elbv2_target_group_arn, [""]), count.index)
    container_name   = var.services[count.index].name
    container_port   = var.services[count.index].port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
  

  depends_on = [
    aws_ecs_cluster.this,
    aws_ecs_task_definition.this,
    module.alb
  ]

  timeouts {
    delete = "30m"
  }
}

# resource "aws_ecs_service" "filedemon" {
#   name            = "filebeat-daemon"
#   cluster         = element(concat(aws_ecs_cluster.this.*.id, [""]), 0)
#   task_definition = element(concat(aws_ecs_task_definition.filebeatdaemon.*.arn, [""]), 0)
#   enable_ecs_managed_tags = true
#   propagate_tags = "TASK_DEFINITION"
#   scheduling_strategy = "DAEMON"

#   depends_on = [
#     aws_ecs_cluster.this,
#     aws_ecs_task_definition.filebeatdaemon
#   ]

#   lifecycle {
#     ignore_changes = [desired_count]
#   }
# }

# resource "aws_ecs_task_definition" "filebeatdaemon" {
#   family                = "filebeat-daemon-${var.name_cluster}"
#   container_definitions = element(concat(data.template_file.task_definitions_filedemon.*.rendered, [""]), 0)
#   cpu                   = 128
#   network_mode          = "host"

#   volume {
#     name      = "docker-sock"
#     host_path = "/var/run/docker.sock"
#   }

#   volume {
#     name      = "docker-containers"
#     host_path = "/var/lib/docker/containers"
#   }

#   #execution_role_arn    = module.role_task_definition.role_arn

#   tags = merge(
#     local.tags,
#     var.tags
#   )
  
#   depends_on = [
#     aws_cloudwatch_log_group.filebeatdaemon
    
#   ]
# }

# resource "aws_cloudwatch_log_group" "filebeatdaemon" {
#   name = "/ecs/filebeat-daemon-${var.name_cluster}"
#   retention_in_days = 1

#   tags = merge(
#     local.tags,
#     var.tags
#   )    
# }

resource "aws_ecs_task_definition" "this" {
  count = var.create_task_definition && length(var.services) != 0 ? length(var.services) : 0

  family                = var.services[count.index].name
  container_definitions = element(concat(data.template_file.task_definitions.*.rendered, [""]), count.index)
  #network_mode          = var.services[count.index].task_network_mode
  cpu                   = 256
  memory                = 512
  execution_role_arn    = module.role_task_definition.role_arn

  tags = merge(
    local.tags,
    var.tags
  )
    depends_on = [
    module.role_task_definition
    
  ]  
}

module "autoscaling_group" {
  source  = "cloudposse/ec2-autoscale-group/aws"
  version = "0.28.1"

  namespace   = "oca"
  environment = "qa"
  name        = var.name_cluster

  autoscaling_policies_enabled = false
  security_group_ids           = [element(concat(aws_security_group.ec2_autoscaling.*.id, [""]), 0)]
  iam_instance_profile_name    = module.ec2_ecs_instance_profile.iam_instance_profile_id
  instance_type                = "t3.medium"
  subnet_ids                   = local.subnets_private
  max_size                     = var.asg_max_size
  instance_refresh             = var.instance_refresh_settings
  key_name                     = "eks_key_cluster"
  health_check_type            = "EC2"
  min_size                     = 1
  image_id                     = data.aws_ami.amazon_linux_ecs.id
  user_data_base64             = base64encode(data.template_file.user_data.rendered)
  associate_public_ip_address  = false

  cpu_utilization_high_threshold_percent = 70
  cpu_utilization_low_threshold_percent  = 50

  tags = merge(
    local.tags,
    var.tags
  )

    depends_on = [
    aws_security_group.ec2_autoscaling,
    module.ec2_ecs_instance_profile
    
  ]
}

resource "aws_security_group" "ec2_autoscaling" {
  count       = var.create_service ? 1 : 0
  name        = "${var.name_cluster}-ec2_autoscaling"
  description = "Security Group for ${var.name_cluster} ALB"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = var.autoscaling_sg_ingress_rules

    content {
      description = ingress.value["description"]
      from_port   = ingress.value["from_port"]
      to_port     = ingress.value["to_port"]
      cidr_blocks = ingress.value["cidr_blocks"]
      protocol    = ingress.value["protocol"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    var.tags
  )
}

# resource "aws_autoscaling_schedule" "night" {
#   scheduled_action_name  = "night"
#   min_size               = 0
#   max_size               = 0
#   desired_capacity       = 0
#   recurrence             = "00 02 * * 1-5" #Mon-Fri at 9PM COL
#   autoscaling_group_name = module.autoscaling_group.autoscaling_group_name

#   depends_on = [
#     module.autoscaling_group
#   ]
# }

# resource "aws_autoscaling_schedule" "morning" {
#   scheduled_action_name  = "morning"
#   min_size               = 3
#   max_size               = 3
#   desired_capacity       = 3
#   recurrence             = "00 11 * * 1-5" #Mon-Fri at 6AM COL
#   autoscaling_group_name = module.autoscaling_group.autoscaling_group_name

#   depends_on = [
#     module.autoscaling_group
#   ]
# }

module "r53_listener_rules" {
  source = "git@github.com:Pyxis-Portal/infra-devops-tf-aws-route53.git?ref=v0.1.6"

  count = var.create_service && length(var.services) != 0 ? length(var.services) : 0

  zone_id          = var.services[count.index].zone_id
  create_r53_alias = true

  records = [
    {
      name    = var.services[count.index].conditions[0].host_headers[0]
      type    = "CNAME"
      records = [module.alb.elbv2_dns_name]
      ttl     = 5
    }
  ]

    depends_on = [
    module.alb
    
  ]
}

module "alb" {
  source = "git@github.com:Pyxis-Portal/infra-devops-tf-aws-elbv2.git?ref=v0.1.5"

  create_elbv2               = true
  elbv2_name                 = var.name_cluster
  elbv2_target_groups        = var.services
  elbv2_https_listener_rules = var.services
  elbv2_https_listeners      = var.elbv2_https_listeners
  elbv2_internal             = var.elbv2_internal
  elbv2_sg_ingress_rules     = var.elbv2_sg_ingress_rules
  elbv2_vpc                  = local.vpc_id
  elbv2_subnets              = local.subnets_private
  elbv2_extra_ssl_certs      = var.elbv2_extra_ssl_certs
  environment                = "qa"
}

# resource "aws_sns_topic_subscription" "topic_lambda" {
#   topic_arn = aws_sns_topic.topic.arn
#   protocol  = "lambda"
#   endpoint  = aws_lambda_function.draining_lambda.arn
# }

# resource "aws_lambda_permission" "with_sns" {
#   statement_id  = "AllowExecutionFromSNS"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.draining_lambda.function_name
#   principal     = "sns.amazonaws.com"
#   source_arn    = aws_sns_topic.topic.arn
# }

# resource "aws_lambda_function" "draining_lambda" {
#   function_name = format("%s-draining-function", substr(var.autoscaling_group_name, 1, 32))
#   role          = aws_iam_role.lambda.arn
#   handler       = "lambda_function.lambda_handler"
#   runtime       = "python3.8"
#   memory_size   = 128
#   timeout       = 60

#   environment {
#     variables = {
#       CLUSTER = var.ecs_cluster_name
#       REGION  = var.region
#     }
#   }

#   filename         = data.local_file.lambda_zip.filename
#   source_code_hash = filebase64sha256(data.local_file.lambda_zip.filename)

#   tags = var.tags
# }

# resource "aws_cloudwatch_log_group" "lambda_log_group" {
#   name              = format("/aws/lambda/%s", substr(aws_lambda_function.draining_lambda.function_name, 1, 32))
#   retention_in_days = 14

#   tags = var.tags
# }

# resource "aws_autoscaling_lifecycle_hook" "asg_terminate_hook" {
#   name                    = format("%s-terminating-hook", substr(var.autoscaling_group_name, 1, 32))
#   autoscaling_group_name  = var.autoscaling_group_name
#   default_result          = "ABANDON"
#   heartbeat_timeout       = 900
#   lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
#   notification_target_arn = aws_sns_topic.topic.arn
#   role_arn                = aws_iam_role.lifecycle.arn
# }


# resource "null_resource" "remove_instance" {  

#   provisioner "local-exec" {
#     when    = destroy
#     command = "echo 'Destroying instances...'"
#   }

   
# }


# resource "time_sleep" "wait_120_seconds" {
#   depends_on = [null_resource.remove_instance]

#   destroy_duration = "120s"
# }