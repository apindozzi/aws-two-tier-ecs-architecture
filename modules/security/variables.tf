variable "name_prefix" {
  type        = string
  description = "Prefix for all security group names"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where security groups will be created"
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks allowed to reach ALB (HTTP/HTTPS). If empty, defaults to 0.0.0.0/0 (not recommended for production)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.allowed_ingress_cidrs : can(cidrhost(cidr, 0))])
    error_message = "allowed_ingress_cidrs must contain valid CIDR notation (e.g. 192.168.0.0/16)."
  }
}

variable "app_port" {
  type        = number
  default     = 8080
  description = "Port on which the app listens (must be between 1 and 65535)"

  validation {
    condition     = var.app_port > 0 && var.app_port <= 65535
    error_message = "app_port must be between 1 and 65535."
  }
}

variable "restrict_egress_to_vpc" {
  description = "If true, restrict egress from ALB/App to VPC CIDR only. If false, allow 0.0.0.0/0 (not recommended for production)"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "VPC CIDR block (required if restrict_egress_to_vpc=true)"
  type        = string
  default     = null

  validation {
    condition     = var.restrict_egress_to_vpc == false || (var.vpc_cidr != null && can(cidrhost(var.vpc_cidr, 0)))
    error_message = "vpc_cidr must be provided and valid CIDR notation when restrict_egress_to_vpc=true."
  }
}

variable "tags" {
  description = "Common tags to apply to all security groups"
  type        = map(string)
  default     = {}
}
