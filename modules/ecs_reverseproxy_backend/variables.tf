variable "name" {
  type        = string
  description = "Base name for ECS resources (service, task, etc.)"
}

variable "region" {
  type        = string
  description = "AWS region (used for logs)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs where the ECS service ENIs will be attached"
}

variable "cluster_arn" {
  type        = string
  description = "ECS cluster ARN where the service will be placed"
  validation {
    condition     = length(var.cluster_arn) > 0
    error_message = "cluster_arn must be provided and non-empty"
  }
}

variable "service_security_group_id" {
  type        = string
  description = "Security Group ID to attach to the ECS service ENIs (controls ENI ingress/egress)"
  validation {
    condition     = length(var.service_security_group_id) > 0
    error_message = "service_security_group_id must be provided and non-empty"
  }
}

variable "target_group_arn" {
  type        = string
  description = "ALB Target Group ARN where the proxy container will be registered"
  validation {
    condition     = length(var.target_group_arn) > 0
    error_message = "target_group_arn must be provided and non-empty"
  }
}

variable "desired_count" {
  type        = number
  default     = 1
  description = "Initial desired number of running tasks for the service"
  validation {
    condition     = var.desired_count >= 0
    error_message = "desired_count must be 0 or greater"
  }
}

variable "task_cpu" {
  type        = number
  default     = 512
  description = "Task CPU units (for Fargate: typical values 256, 512, 1024, ...)."
  validation {
    condition     = var.task_cpu > 0
    error_message = "task_cpu must be greater than 0"
  }
}

variable "task_memory" {
  type        = number
  default     = 1024
  description = "Task memory in MiB (for Fargate)."
  validation {
    condition     = var.task_memory > 0
    error_message = "task_memory must be greater than 0"
  }
}

variable "proxy_image" {
  type        = string
  description = "Docker image for reverse proxy (e.g., nginx)"
}

variable "backend_image" {
  type        = string
  description = "Docker image for the backend application (private image on DockerHub or public image)"
}

variable "backend_container_port" {
  type        = number
  default     = 8080
  description = "Container port on which the backend application listens"
  validation {
    condition     = var.backend_container_port > 0 && var.backend_container_port <= 65535
    error_message = "backend_container_port must be a valid TCP port (1-65535)"
  }
}

variable "proxy_container_port" {
  type        = number
  default     = 80
  description = "Container port for the reverse proxy (the ALB forwards to this port on the proxy container)"
  validation {
    condition     = var.proxy_container_port > 0 && var.proxy_container_port <= 65535
    error_message = "proxy_container_port must be a valid TCP port (1-65535)"
  }
}

variable "assign_public_ip" {
  type        = bool
  default     = false
  description = "Whether to assign public IPs to task ENIs. For private backend with internet access via NAT, keep false."
}

variable "execution_role_arn" {
  type        = string
  description = "IAM role ARN used by ECS for pulling images and publishing logs (task execution role)"
  validation {
    condition     = length(var.execution_role_arn) > 0
    error_message = "execution_role_arn must be provided and non-empty"
  }
}

variable "task_role_arn" {
  type        = string
  description = "IAM role ARN assumed by containers for application-level permissions (task role)"
  validation {
    condition     = length(var.task_role_arn) > 0
    error_message = "task_role_arn must be provided and non-empty"
  }
}

variable "log_retention_days" {
  type        = number
  default     = 14
  description = "CloudWatch Logs retention period (days) for both proxy and backend logs"
  validation {
    condition     = var.log_retention_days >= 0
    error_message = "log_retention_days must be 0 or greater"
  }
}

variable "enable_autoscaling" {
  type        = bool
  default     = true
  description = "Whether to create Service Auto Scaling policies for the ECS service"
}

variable "min_capacity" {
  type        = number
  default     = 1
  description = "Minimum number of tasks for autoscaling"
}

variable "max_capacity" {
  type        = number
  default     = 4
  description = "Maximum number of tasks for autoscaling"
  validation {
    condition     = var.max_capacity >= var.min_capacity
    error_message = "max_capacity must be greater than or equal to min_capacity"
  }
}

variable "target_cpu" {
  type        = number
  default     = 60
  description = "Target average CPU utilization percentage for autoscaling (1-100)"
  validation {
    condition     = var.target_cpu > 0 && var.target_cpu <= 100
    error_message = "target_cpu must be between 1 and 100"
  }
}

variable "target_memory" {
  type        = number
  default     = 70
  description = "Target average memory utilization percentage for autoscaling (1-100)"
  validation {
    condition     = var.target_memory > 0 && var.target_memory <= 100
    error_message = "target_memory must be between 1 and 100"
  }
}

variable "environment" {
  type        = map(string)
  description = "Map of environment variables to set in the backend container"
  default     = {}
}

variable "backend_secrets" {
  type        = map(string)
  description = "Map of environment variable name => Secrets Manager or SSM parameter ARN to inject as secrets into the backend container"
  default     = {}
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags to apply to created resources"
}

variable "backend_command" {
  type        = list(string)
  description = "Optional command override for backend container"
  default     = null
}