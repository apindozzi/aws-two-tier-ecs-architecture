# ecs_reverseproxy_backend

Description
- Deploys an ECS service that runs two containers in the same task: a reverse proxy (proxy) and a backend application (backend). The proxy is registered with an external ALB target group; the backend container is private inside the task and communicates with the proxy via localhost. The backend is intended to be private (no public IP) but still have internet access via VPC NAT.

Key features
- Two-container task (proxy + backend)
- CloudWatch Logs for both containers
- Optional Service Auto Scaling
- Supports injecting environment variables and secrets into the backend container

Important notes
- For a private backend with internet access, set `assign_public_ip = false` and ensure the `private_subnet_ids` are in subnets that route to a NAT gateway.
- Provide appropriate `execution_role_arn` and `task_role_arn` for pulling images, logging, and any backend permissions.

Inputs (selected)
- `name`: base name for ECS resources
- `region`: AWS region
- `cluster_arn`: ECS cluster ARN
- `private_subnet_ids`: list of private subnet IDs for ENIs
- `service_security_group_id`: SG ID for the service ENIs
- `target_group_arn`: ALB Target Group ARN for the proxy
- `proxy_image`, `backend_image`: docker images
- `execution_role_arn`, `task_role_arn`: IAM role ARNs
- `environment`, `backend_secrets`: env vars and secret ARNs for backend

Outputs
- `service_name` - ECS service name
- `task_definition_arn` - Task definition ARN
- `proxy_log_group_name` - CloudWatch log group name for proxy
- `backend_log_group_name` - CloudWatch log group name for backend

Example usage
```
module "ecs_app" {
  source                   = "../modules/ecs_reverseproxy_backend"
  name                     = "myapp"
  region                   = var.region
  cluster_arn              = module.network.cluster_arn
  private_subnet_ids       = module.network.private_subnets
  service_security_group_id = module.security.app_sg_id
  target_group_arn         = module.alb.this_tg_arn
  proxy_image              = "nginx:latest"
  backend_image            = "username/simple-backend:latest"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  tags = {
    Project = "demo"
  }
}
```

If you'd like, I can also add example `tasks.json` or a sample `nginx` proxy config used by the module.
