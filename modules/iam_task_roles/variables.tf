variable "execution_role_name" {
  type        = string
  description = "Name of the ECS task execution role (used by ECS agent to pull images and push logs)"
  validation {
    condition     = length(var.execution_role_name) > 0
    error_message = "execution_role_name must be provided and non-empty"
  }
}

variable "task_role_name" {
  type        = string
  description = "Name of the ECS task role (assumed by the application containers)"
  validation {
    condition     = length(var.task_role_name) > 0
    error_message = "task_role_name must be provided and non-empty"
  }
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to IAM roles"
  default     = {}
}

# --- Execution role extra (optional, least privilege) ---
variable "enable_execution_extra_policy" {
  type        = bool
  description = "Whether to create an extra inline policy for execution role (SSM/Secrets/KMS)"
  default     = true
}

variable "execution_ssm_parameter_arns" {
  type        = list(string)
  description = "List of SSM Parameter Manager ARNs accessible by the execution role"
  default     = []
}

variable "execution_secretsmanager_arns" {
  type        = list(string)
  description = "List of AWS Secrets Manager secret ARNs accessible by the execution role"
  default     = []
}

variable "execution_kms_key_arns" {
  type        = list(string)
  description = "List of KMS Key ARNs allowed for decryption by the execution role (only needed for customer-managed keys)"
  default     = []
}

# Additional arbitrary inline policies as JSON documents
variable "execution_inline_policies" {
  type        = map(string)
  description = "Map of {policy_name => policy_json} for custom inline policies attached to execution role"
  default     = {}
}

variable "task_inline_policies" {
  type        = map(string)
  description = "Map of {policy_name => policy_json} for custom inline policies attached to task role (application permissions)"
  default     = {}
}