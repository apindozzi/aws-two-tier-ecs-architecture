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