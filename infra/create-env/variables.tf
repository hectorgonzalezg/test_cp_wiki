variable "vpc_id" {
  type        = string
  description = "vpc_id (vpc-00000)"
}

variable "subnets_ids_private" {
  type        = list(string)
  description = "subnets_ids"
}

variable "subnets_ids_public" {
  type        = list(string)
  default     = null
  description = "subnets_ids"
}

variable "subnets_idsrds_private" {
  type        = list(string)
  default     = null
  description = "subnets_ids_rds"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "region"
}

variable "account_id" {
  type        = string
  description = "account_id"
}

variable "environment" {
  type    = string
  default = "qa-dev"
}

variable "tags" {
  type    = any
  default = [""]
}

######### ECS Cluster #######

variable "create_ecs" {
  type    = bool
  default = true
}
variable "elbv2_internal" {
  type    = bool
  default = false
}

variable "name_cluster" {
  type        = string
  default     = ""
  description = "name of cluster"
}

variable "capacity_providers" {
  type    = list(string)
  default = null
}

variable "default_capacity_provider_strategy" {
  type    = any
  default = [""]
}

variable "cp_instance_warmup_period" {
  description = "seconds"
  type        = number
  default     = 300
}

variable "cp_min_scaling_step_size" {
  description = "seconds"
  type        = number
  default     = 120
}

variable "cp_max_scaling_step_size" {
  description = "seconds"
  type        = number
  default     = 300
}

variable "target_capacity" {
  description = "number"
  type        = number
  default     = 45
}

variable "container_insights" {
  type    = bool
  default = true
}


######## ECS Service #########

variable "create_service" {
  type    = bool
  default = true
}

variable "services" {
  type        = any
  default     = [""]
  description = "all configuration for ecs service"
}

variable "create_task_definition" {
  type    = bool
  default = true
}

variable "create_ecr" {
  type    = bool
  default = true
}

##### Auto Scaling ####

variable "asg_max_size" {
  type        = number
  description = "The maximum size of the autoscale group"
  default     = 4
}

variable "instance_refresh_settings" {
  description = "The instance refresh definition"
  type = object({
    strategy = string
    preferences = object({
      instance_warmup        = number
      min_healthy_percentage = number
    })
    triggers = list(string)
  })

  default = {
    strategy = "Rolling"
    preferences = {
      instance_warmup        = 300
      min_healthy_percentage = 90
    }
    triggers = ["tag"]
  }
}

variable "autoscaling_sg_ingress_rules" {
  type        = any
  default     = []
  description = "all configuration for rules ingress of security group"
}

#### Load Balancer ####

variable "elbv2_https_listeners" {
  type        = any
  default     = []
  description = "all configuration for https listeners"
}

variable "elbv2_sg_ingress_rules" {
  type        = any
  default     = []
  description = "all configuration for rules ingress of security group"
}

variable "elbv2_extra_ssl_certs" {
  description = "A list of maps describing any extra SSL certificates to apply to the HTTPS listeners. Required key/values: certificate_arn, https_listener_index (the index of the listener within https_listeners which the cert applies toward)."
  type        = list(map(string))
  default     = []
}


##### RDS ######

variable "create_rds" {
  type    = bool
  default = false
}

variable "rds_name" {
  type    = string
  default = "dev"
}

variable "rds_engine" {
  type    = string
  default = ""
}

variable "rds_engine_version" {
  type    = string
  default = ""
}

variable "rds_major_engine_version" {
  type    = string
  default = ""
}

variable "rds_instance_type" {
  type    = string
  default = ""
}

variable "rds_disk_params" {
  type    = any
  default = []
}

variable "rds_master_username" {
  type    = string
  default = ""
}

variable "rds_master_password" {
  type    = string
  default = ""
}

variable "rds_mssql_port" {
  type    = number
  default = 0
}

variable "rds_multi_az" {
  type    = bool
  default = false
}

variable "rds_engine_options" {
  type    = any
  default = []
}

variable "rds_ingress_cidrs" {
  type    = any
  default = []
}

variable rds_snapshot_identifier {
  type        = string
  default     = ""
  description = ""
}


variable "ec2_ecs_instance_profile_policys_arn" {
  type        = any
  default     = []
  description = "A list of ARN policys for the ec2_instance"
}