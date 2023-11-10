remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = "oca-tfstate"
    key            = "aws_ecs-demo/tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-dynamo"
    #role_arn       =  "arn:aws:iam::143407689206:role/terraform-test"
    profile        = "Pyxis_networking"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
  provider "aws" {
   region = "us-east-1"
   profile        = "oca_qa"
   # Make it faster by skipping something
   skip_get_ec2_platforms = true
   skip_metadata_api_check = true
   skip_region_validation = false
   skip_credentials_validation = true
   skip_requesting_account_id = false
  }
  EOF
}

terraform {
  source = "${get_terragrunt_dir()}/..//create-env"
}

inputs = {
  environment             = local.environment
  aws_region              = local.aws_region
  account_id              = local.account_id
  vpc_id                  = local.vpc_id
  subnets_ids_private     = local.subnets_private
  #subnets_idsrds_private  = local.subnets_private_rds
  #subnets_ids_public      = local.subnets_public
  services                = local.services
  name_cluster            = "${local.owner}-${local.environment}"
  # rds_snapshot_identifier = get_env("TF_VAR_SNAPSHOT_IDENTIFIER")
  # create_rds              = get_env("TF_VAR_CREATE_RDS")
  asg_max_size            = 1
  target_capacity         = 70
  elbv2_internal        = true
  ec2_ecs_instance_profile_policys_arn = [
    "arn:aws:iam::026690518203:policy/qa-oca-eks-cluster-worker-additonal-policy"    
  ]

  elbv2_https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = "arn:aws:acm:us-east-1:026690518203:certificate/e0b34504-2351-4460-888d-35d880efdb56"
    }
  ]

  elbv2_extra_ssl_certs = [
    {
      https_listener_index = 0
      certificate_arn = "arn:aws:acm:us-east-1:026690518203:certificate/e0b34504-2351-4460-888d-35d880efdb56"
    }
  ]

  elbv2_sg_ingress_rules = [
    {
      description = "load blancer "
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
      protocol    = "tcp"
    },
    {
      description = "load blancer"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
      protocol    = "tcp"
    }
  ]

  autoscaling_sg_ingress_rules = [
    {
      description = "ecs-host"
      from_port   = 80
      to_port     = 65535
      cidr_blocks = ["0.0.0.0/0"]
      protocol    = "tcp"
    }
  ]

  tags = {
    Maintainer     = "pyxis"
    IacTool        = "terraform"
    IacToolVersion = "0.14.6"
    IacCommit      = "${local.iac_commit}"
    Env            = "NonProd"
    Geo            = "Global"
  }
}

locals {
  account_id      = 026690518203
  aws_region      = "us-east-1"
  environment     = "qa"
  iac_commit      = "0.0.1"
  owner           = "ocacomercios"
  project_name    = "${local.owner}-${local.environment}"
  #vpc_cidr        = "172.33.0.0/16"
  vpc_id          = "vpc-09c78a914f0dd1d9b"
  ## App-NonProd-1a               App-NonProd-1b                App-NonProd-1c
  subnets_private = ["subnet-015f7a04e63829ed1", "subnet-0a7869b271b058b9a", "subnet-05d48315e24991fbd", "subnet-0193e6a4e84e3b303"]
  ## DMZ-NonProd
  #subnets_public  = ["subnet-0cbb515358396e825", "subnet-0d67c38ad0fb83951", "subnet-05f2a334b56ab5957"]
  #subnets_private_rds = ["subnet-006c9dc1e3dca7065", "subnet-06e067c40eae13f3d", "subnet-0cac5a309037e9150"]

  services = [
    {
      name              = "merchant-api-bff"
      port              = 8085

      backend_protocol  = "HTTP"
      backend_port      = 80
      target_type       = "instance"

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/ocacomercios-api"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 20
        protocol            = "HTTP"
        matcher             = "200,302"
      }

      zone_id = "Z098108827HSMQKPTLSJC"
      ### RULES
      https_listener_index = 0

      actions = [
        {
          type               = "forward"
          target_group_index = 0
        }
      ]

      conditions = [
        {
          path_patterns = ["/ocacomercios-api/*"]
          host_headers  = ["api-bff.comercios.aws.oca-dt.com.uy"]
        }
      ]
    }     
  ]
}
