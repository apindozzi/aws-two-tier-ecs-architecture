variable "name" {
  type        = string
  description = "Name prefix for VPC and networking resources (used in resource naming and tags)"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC (e.g. 10.0.0.0/16)"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.vpc_cidr))
    error_message = "vpc_cidr must be valid CIDR notation (e.g. 10.0.0.0/16)."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets. One subnet will be created per CIDR in each availability zone."

  validation {
    condition     = length(var.public_subnet_cidrs) > 0
    error_message = "At least one public subnet CIDR must be provided."
  }

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", cidr))])
    error_message = "All public_subnet_cidrs must be valid CIDR notation (e.g. 10.0.0.0/24)."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets. Must have the same number of entries as public_subnet_cidrs."

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.public_subnet_cidrs)
    error_message = "private_subnet_cidrs must have the same number of entries as public_subnet_cidrs."
  }

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", cidr))])
    error_message = "All private_subnet_cidrs must be valid CIDR notation (e.g. 10.0.10.0/24)."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags to apply to all VPC and networking resources"
}