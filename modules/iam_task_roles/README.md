# IAM Module for the tasks

## Description

Creates IAM roles required for ECS tasks:
- **Execution Role**: Used by the ECS agent to pull Docker images from ECR and write logs to CloudWatch
- **Task Role**: Assumed by the application containers to interact with AWS services (e.g., S3, DynamoDB, Secrets Manager)

This module supports flexible policy attachment through inline policies and optional extra permissions for accessing SSM Parameters, Secrets Manager, and KMS keys.

## Key Features

- Two distinct roles following AWS best practices (separation of concerns)
- AWS managed policy baseline for execution role (AmazonECSTaskExecutionRolePolicy)
- Optional extra inline policy for secrets/parameter access (least privilege)
- Support for custom inline policies via variables
- Proper tagging for resource organization and cost tracking
- Validation of required role names

## Important Notes

- **Execution Role**: Automatically includes AWS managed policy `AmazonECSTaskExecutionRolePolicy` which grants baseline permissions for pulling images and writing logs
- **Task Role**: Intentionally has no default policies; attach only the permissions your application needs
- Use `execution_inline_policies` or `task_inline_policies` to attach custom policies as JSON documents
- For environment-specific permissions, pass pre-built policy JSON from higher-level Terraform modules
- Both roles trust the `ecs-tasks.amazonaws.com` service principal

## Inputs

| Name                            | Type          | Default | Description |
|---------------------------------|---------------|---------|-------------|
| `execution_role_name`           | string        | (required) | Name of the execution role |
| `task_role_name`                | string        | (required) | Name of the task role |
| `tags`                          | map(string)   | `{}`    | Common tags for IAM roles |
| `enable_execution_extra_policy` | bool          | `true`  | Enable extra inline policy (SSM/Secrets/KMS) |
| `execution_ssm_parameter_arns`  | list(string)  | `[]`    | SSM Parameter ARNs for execution role |
| `execution_secretsmanager_arns` | list(string)  | `[]`    | Secrets Manager ARNs for execution role |
| `execution_kms_key_arns`        | list(string)  | `[]`    | KMS Key ARNs for execution role |
| `execution_inline_policies`     | map(string)   | `{}`    | Custom inline policies for execution role |
| `task_inline_policies`          | map(string)   | `{}`    | Custom inline policies for task role (application permissions) |

## Outputs

| Name                   | Description |
|------------------------|-------------|
| `execution_role_arn`   | ARN of the execution role |
| `execution_role_name`  | Name of the execution role |
| `task_role_arn`        | ARN of the task role |
| `task_role_name`       | Name of the task role |

## Example Usage

### Basic Setup (no extra permissions)

```hcl
module "ecs_iam" {
  source = "../modules/iam_task_roles"
  
  execution_role_name = "my-app-ecs-execution-role"
  task_role_name      = "my-app-ecs-task-role"
  
  tags = {
    Project = "my-app"
    Env     = "prod"
  }
}
```

### With Secrets Manager Access

```hcl
module "ecs_iam" {
  source = "../modules/iam_task_roles"
  
  execution_role_name = "my-app-ecs-execution-role"
  task_role_name      = "my-app-ecs-task-role"
  
  # Allow execution role to read secrets
  enable_execution_extra_policy    = true
  execution_secretsmanager_arns    = ["arn:aws:secretsmanager:us-east-1:123456789:secret:db-password-*"]
  
  tags = {
    Project = "my-app"
    Env     = "prod"
  }
}
```

### With Custom Application Policies

```hcl
locals {
  s3_access_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      Resource = "arn:aws:s3:::my-bucket/*"
    }]
  })
}

module "ecs_iam" {
  source = "../modules/iam_task_roles"
  
  execution_role_name = "my-app-ecs-execution-role"
  task_role_name      = "my-app-ecs-task-role"
  
  # Attach S3 access policy to task role
  task_inline_policies = {
    s3-access = local.s3_access_policy
  }
  
  tags = {
    Project = "my-app"
    Env     = "prod"
  }
}
```

## IAM Trust Relationships

Both roles trust:
```
Service: ecs-tasks.amazonaws.com
```

This allows ECS to assume these roles on behalf of the tasks.

## Least Privilege Best Practices

- **Execution Role**: Use `execution_ssm_parameter_arns`, `execution_secretsmanager_arns`, and `execution_kms_key_arns` to grant only the resources needed
- **Task Role**: Attach only the policies your application actually requires via `task_inline_policies`
- Avoid * (wildcard) permissions; always specify exact ARNs
