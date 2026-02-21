# ECS Module

## Description

Deploys an AWS ECS cluster to orchestrate containerized applications. This module creates the cluster infrastructure with optional CloudWatch Container Insights monitoring for observability.

## Key Features

- ECS cluster with configurable naming
- Optional Container Insights integration for monitoring and logging
- Support for custom tagging across cluster resources

## Important Notes

- The cluster is created with `FARGATE` and `FARGATE_SPOT` capacity providers available by default
- Container Insights should be enabled in production for better observability and troubleshooting
- Tasks can be deployed to this cluster by other modules that reference the cluster ARN

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | string | (required) | ECS cluster name |
| `enable_container_insights` | bool | `true` | Enable Container Insights for the ECS cluster |
| `tags` | map(string) | `{}` | Common tags to apply to the ECS cluster |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_arn` | ARN of the ECS cluster |
| `cluster_name` | Name of the ECS cluster |

## Example Usage

```hcl
module "ecs_cluster" {
  source = "../modules/ecs"
  name   = "myapp-cluster"
  
  enable_container_insights = true
  
  tags = {
    Project = "myapp"
    Env     = "prod"
  }
}
```

## Integration with Other Modules

- **Reference the cluster ARN** in the `ecs_reverseproxy_backend` module via `module.ecs_cluster.cluster_arn`
- Use in any other module that deploys ECS services or task definitions
