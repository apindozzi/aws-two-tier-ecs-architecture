variable "name_prefix" {
  type        = string
  description = "Prefix for ALB and target group names"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where ALB and target group will be created"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for ALB deployment (typically public subnets)"
}

variable "alb_sg_id" {
  type        = string
  description = "Security group ID for the ALB"
}

variable "deregistration_delay" {
  type        = number
  default     = 30
  description = "Time in seconds to wait before deregistering a target (0-3600)"
  validation {
    condition     = var.deregistration_delay >= 0 && var.deregistration_delay <= 3600
    error_message = "deregistration_delay must be between 0 and 3600."
  }
}

variable "target_port" {
  type        = number
  default     = 8080
  description = "Port on which the target application listens (1-65535)"

  validation {
    condition     = var.target_port > 0 && var.target_port <= 65535
    error_message = "target_port must be between 1 and 65535."
  }
}

variable "target_type" {
  type        = string
  default     = "ip"
  description = "Type of target: 'ip' for ECS/Fargate, 'instance' for EC2, 'lambda' for Lambda functions"

  validation {
    condition     = contains(["ip", "instance", "lambda"], var.target_type)
    error_message = "target_type must be 'ip', 'instance', or 'lambda'."
  }
}

variable "health_check_path" {
  type        = string
  default     = "/health"
  description = "Path for health check requests sent by the ALB"
}

variable "health_check_interval" {
  type        = number
  default     = 30
  description = "Health check interval in seconds (5-300)"

  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 300
    error_message = "health_check_interval must be between 5 and 300 seconds."
  }
}

variable "health_check_timeout" {
  type        = number
  default     = 5
  description = "Health check timeout in seconds (2-120)"

  validation {
    condition     = var.health_check_timeout >= 2 && var.health_check_timeout <= 120
    error_message = "health_check_timeout must be between 2 and 120 seconds."
  }

  validation {
    condition     = var.health_check_timeout < var.health_check_interval
    error_message = "health_check_timeout must be less than health_check_interval."
  }
}

variable "health_check_healthy_threshold" {
  type        = number
  default     = 2
  description = "Number of consecutive successful health checks to mark target healthy (2-10)"

  validation {
    condition     = var.health_check_healthy_threshold >= 2 && var.health_check_healthy_threshold <= 10
    error_message = "health_check_healthy_threshold must be between 2 and 10."
  }
}

variable "health_check_unhealthy_threshold" {
  type        = number
  default     = 3
  description = "Number of consecutive failed health checks to mark target unhealthy (2-10)"

  validation {
    condition     = var.health_check_unhealthy_threshold >= 2 && var.health_check_unhealthy_threshold <= 10
    error_message = "health_check_unhealthy_threshold must be between 2 and 10."
  }
}

variable "listener_http" {
  type        = bool
  default     = true
  description = "Whether to create an HTTP listener on port 80 (typically redirects to HTTPS in production)"
}

variable "listener_https" {
  type        = bool
  default     = false
  description = "Whether to create an HTTPS listener on port 443"
}

variable "acm_certificate_arn" {
  type        = string
  default     = null
  description = "ACM certificate ARN for HTTPS listener (required if listener_https=true)"
  validation {
    condition     = var.listener_https == false || (var.acm_certificate_arn != null && length(var.acm_certificate_arn) > 0)
    error_message = "acm_certificate_arn must be provided when listener_https=true."
  }
}

variable "ssl_policy" {
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  description = "SSL policy for HTTPS listener"
}

variable "http_redirect_to_https" {
  type        = bool
  default     = false
  description = "If true, HTTP listener redirects to HTTPS (requires listener_https=true). Default is false to permit HTTP-only deployments."
  validation {
    condition     = var.http_redirect_to_https == false || var.listener_https == true
    error_message = "http_redirect_to_https=true requires listener_https=true."
  }
}

variable "enable_deletion_protection" {
  type        = bool
  default     = false
  description = "Enable deletion protection for the ALB to prevent accidental deletion"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags to apply to all ALB resources"
}
