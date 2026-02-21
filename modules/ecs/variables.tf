variable "name" {
  type        = string
  description = "ECS cluster name"
  validation {
    condition     = length(var.name) > 0
    error_message = "name must be provided and non-empty"
  }
}

variable "enable_container_insights" {
  type        = bool
  description = "Enable Container Insights for the ECS cluster (captures metrics and logs)"
  default     = true
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags to apply to the ECS cluster"
}