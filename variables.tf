variable "project_info" {
  description = "General project information containing name and prefix."

  type = object({
    name   = string
    prefix = string
  })
}

variable "vpc_config" {
  description = "Configuration for the VPC including CIDRs and subnets."

  type = object({
    vpc_cidr             = string
    public_subnet_cidrs  = list(string)
    private_subnet_cidrs = list(string)
  })
}

variable "security" {
  description = "Security configuration for the application."

  type = object({
    allowed_ingress_cidrs = list(string)
    app_port              = number
  })
}

variable "alb" {
  description = "Configuration for the Application Load Balancer."

  type = object({
    target_port       = number
    target_type       = string
    health_check_path = string
  })
}

variable "ecs_cluster" {
  description = "Configuration for the ECS Cluster."

  type = object({
    enable_container_insights = bool
  })
}

variable "ecs_app" {
  description = "ECS application configuration grouped as a single object"

  type = object({
    cluster_arn            = string
    desired_count          = number
    task_cpu               = number
    task_memory            = number
    proxy_image            = string
    backend_image          = string
    proxy_container_port   = number
    backend_container_port = number
    assign_public_ip       = bool
    environment            = map(string)
    backend_secrets        = map(string)
    enable_autoscaling     = bool
    min_capacity           = number
    max_capacity           = number
    target_cpu             = number
    target_memory          = number
    tags                   = map(string)
  })
}