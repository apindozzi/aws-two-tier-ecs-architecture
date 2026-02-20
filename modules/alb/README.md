# ALB Module

Provisions an Application Load Balancer (ALB) with configurable target groups and health checks for routing traffic to backend services in a two-tier architecture.

## Module Structure

This module creates and manages:
- **Application Load Balancer (ALB)**: Distributes incoming traffic across multiple targets
- **Target Group**: Defines backend targets and health check configuration
- **HTTP Listener**: Optional listener on port 80 (forwards directly or redirects to HTTPS)
- **HTTPS Listener**: Optional listener on port 443 for encrypted traffic
- **Connection Draining**: Configurable deregistration delay for graceful target shutdown

## Features

- ✅ **Flexible target type**: Support for IP (ECS/Fargate), EC2 instances, or Lambda functions
- ✅ **HTTP and HTTPS listeners**: Support for both, with optional HTTP → HTTPS redirect
- ✅ **Configurable health checks**: Full control over health check parameters (interval, timeout, thresholds)
- ✅ **SSL/TLS support**: ACM certificate integration with configurable SSL policies
- ✅ **Connection draining**: Configurable deregistration delay for graceful shutdowns
- ✅ **Validated inputs**: Port ranges, health check values, target types, and SSL/TLS parameters validated
- ✅ **Deletion protection**: Optional protection to prevent accidental ALB deletion
- ✅ **Comprehensive tagging**: Common tags applied consistently across all resources
- ✅ **IPv4 and DNS**: Outputs both DNS name and resource IDs for flexibility

## Usage

```hcl
module "alb" {
  source = "./modules/alb"

  name_prefix = "myapp"
  vpc_id      = aws_vpc.main.id
  subnet_ids  = aws_subnet.public[*].id

  alb_sg_id = aws_security_group.alb.id

  target_port       = 8080
  target_type       = "ip"
  health_check_path = "/api/health"

  listener_http = true

  tags = {
    Tier    = "load-balancer"
    Project = "myapp"
  }
}
```

## Inputs

### Required

| Name | Type | Description |
| --- | --- | --- |
| `name_prefix` | `string` | Prefix for ALB and target group names |
| `vpc_id` | `string` | VPC ID where ALB and target group will be created |
| `subnet_ids` | `list(string)` | List of subnet IDs for ALB deployment (typically public subnets) |
| `alb_sg_id` | `string` | Security group ID for the ALB |

### Optional

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `target_port` | `number` | `8080` | Port on which the target application listens (1-65535) |
| `target_type` | `string` | `"ip"` | Type of target: `"ip"` (ECS/Fargate), `"instance"` (EC2), or `"lambda"` |
| `health_check_path` | `string` | `"/health"` | Path for health check requests sent by the ALB |
| `health_check_interval` | `number` | `30` | Health check interval in seconds (5-300) |
| `health_check_timeout` | `number` | `5` | Health check timeout in seconds (2-120) |
| `health_check_healthy_threshold` | `number` | `2` | Consecutive successful checks to mark target healthy (2-10) |
| `health_check_unhealthy_threshold` | `number` | `3` | Consecutive failed checks to mark target unhealthy (2-10) |
| `deregistration_delay` | `number` | `30` | Connection draining timeout in seconds (0-3600) |
| `listener_http` | `bool` | `true` | Whether to create an HTTP listener on port 80 |
| `listener_https` | `bool` | `false` | Whether to create an HTTPS listener on port 443 |
| `http_redirect_to_https` | `bool` | `false` | If true, HTTP redirects to HTTPS (requires listener_https=true) |
| `acm_certificate_arn` | `string` | `null` | ACM certificate ARN for HTTPS listener (required if listener_https=true) |
| `ssl_policy` | `string` | `ELBSecurityPolicy-TLS13-1-2-2021-06` | SSL policy for HTTPS listener |
| `enable_deletion_protection` | `bool` | `false` | Enable deletion protection for the ALB |
| `tags` | `map(string)` | `{}` | Common tags to apply to all ALB resources |

## Outputs

| Name | Type | Description |
| --- | --- | --- |
| `alb_arn` | `string` | ARN of the Application Load Balancer |
| `alb_dns_name` | `string` | DNS name of the Application Load Balancer |
| `alb_name` | `string` | Name of the Application Load Balancer |
| `alb_id` | `string` | ID of the Application Load Balancer |
| `target_group_arn` | `string` | ARN of the target group |
| `target_group_name` | `string` | Name of the target group |
| `target_group_id` | `string` | ID of the target group |
| `http_listener_arn` | `string` | ARN of the HTTP listener (null if listener_http is false) |
| `http_listener_id` | `string` | ID of the HTTP listener (null if listener_http is false) |
| `https_listener_arn` | `string` | ARN of the HTTPS listener (null if listener_https is false) |

## Health Checks

The ALB performs regular HTTP health checks against your targets:

- **Path**: Configurable via `health_check_path` (default: `/health`)
- **Interval**: How often to perform checks (default: 30 seconds)
- **Timeout**: How long to wait for a response (default: 5 seconds)
- **Healthy threshold**: Consecutive successful checks to mark healthy (default: 2)
- **Unhealthy threshold**: Consecutive failed checks to mark unhealthy (default: 3)
- **Matcher**: HTTP 200-399 status codes are considered healthy

## Example: ECS Fargate Integration

```hcl
module "alb" {
  source = "./modules/alb"

  name_prefix = "myapp-ecs"
  vpc_id      = module.network.vpc_id
  subnet_ids  = module.network.public_subnet_ids

  alb_sg_id = module.security.alb_sg_id

  target_type              = "ip"
  target_port              = 3000
  health_check_path        = "/api/ready"
  health_check_interval    = 30
  health_check_timeout     = 5
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 3
  deregistration_delay     = 30

  listener_http = true
  enable_deletion_protection = false

  tags = {
    Tier        = "distribution"
    Environment = "production"
  }
}
```

## Example: HTTPS with HTTP Redirect

```hcl
module "alb" {
  source = "./modules/alb"

  name_prefix = "myapp-https"
  vpc_id      = module.network.vpc_id
  subnet_ids  = module.network.public_subnet_ids

  alb_sg_id = module.security.alb_sg_id

  target_type       = "ip"
  target_port       = 8080
  health_check_path = "/health"

  # HTTP listener that redirects to HTTPS
  listener_http         = true
  http_redirect_to_https = true

  # HTTPS listener with SSL certificate
  listener_https      = true
  acm_certificate_arn = aws_acm_certificate.example.arn
  ssl_policy          = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  enable_deletion_protection = true

  tags = {
    Tier        = "distribution"
    Environment = "production"
  }
}
```

## Example: HTTPS Only (No HTTP)

```hcl
module "alb" {
  source = "./modules/alb"

  name_prefix = "myapp-https-only"
  vpc_id      = module.network.vpc_id
  subnet_ids  = module.network.public_subnet_ids

  alb_sg_id = module.security.alb_sg_id

  target_type       = "ip"
  target_port       = 8080
  health_check_path = "/health"

  # HTTPS only, no HTTP listener
  listener_http  = false
  listener_https = true
  acm_certificate_arn = aws_acm_certificate.example.arn

  deregistration_delay   = 60
  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}
```

## Example: EC2 Target Group

```hcl
module "alb" {
  source = "./modules/alb"

  name_prefix = "myapp-ec2"
  vpc_id      = module.network.vpc_id
  subnet_ids  = module.network.public_subnet_ids

  alb_sg_id = module.security.alb_sg_id

  target_type       = "instance"
  target_port       = 8080
  health_check_path = "/status"

  tags = {
    Environment = "staging"
  }
}
```

## Target Registration

To register targets with the target group, use the `aws_lb_target_group_attachment` resource:

```hcl
resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = module.alb.target_group_arn
  target_id        = aws_ecs_service.app.id
  port             = module.alb.target_port
}
```

Or for ECS services, use the service load balancer configuration directly.

## Best Practices

1. **Health Checks**: Implement a lightweight `/health` endpoint that reflects service readiness
2. **Timeout values**: Ensure `health_check_timeout` is less than `health_check_interval`
3. **Deletion protection**: Enable in production to prevent accidental ALB deletion
4. **HTTPS in production**: Use HTTPS with ACM certificates and enable HTTP → HTTPS redirect
5. **SSL policy**: Keep modern SSL/TLS versions (default policy: TLS 1.3 and 1.2)
6. **Subnet distribution**: Use subnets from multiple AZs for high availability
7. **Deregistration delay**: Set appropriate timeout for graceful shutdown (30-60 seconds typical)
8. **HTTP redirect**: When using `http_redirect_to_https=true`, ensure `listener_https=true` is set
9. **HTTP-only deployments**: Use `listener_http=true` with `http_redirect_to_https=false` for POC/testing

## Validation Rules

- **target_port**: Must be between 1 and 65535
- **target_type**: Must be `"ip"`, `"instance"`, or `"lambda"`
- **health_check_interval**: Must be between 5 and 300 seconds
- **health_check_timeout**: Must be between 2 and 120 seconds
- **health_check_healthy_threshold**: Must be between 2 and 10
- **health_check_unhealthy_threshold**: Must be between 2 and 10
- **deregistration_delay**: Must be between 0 and 3600 seconds
- **acm_certificate_arn**: Required if `listener_https=true`
- **http_redirect_to_https**: Can only be true if `listener_https=true`

---

For more information, see the [AWS ALB documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/).
