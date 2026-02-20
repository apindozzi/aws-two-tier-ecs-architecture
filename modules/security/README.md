# Security Module

Manages security groups for a two-tier application architecture with an Application Load Balancer (ALB) and backend services.

## Module Structure

This module creates and manages:
- **ALB Security Group**: Controls inbound HTTP/HTTPS traffic from specified CIDRs and manages egress rules
- **App Security Group**: Accepts traffic from the ALB on a configurable port and manages egress

## Features

- ✅ **Restrictive by default**: Egress limited to VPC CIDR (configurable)
- ✅ **CIDR validation**: Validates all CIDR inputs for proper format
- ✅ **Port validation**: Ensures app_port is within valid range (1-65535)
- ✅ **Flexible ingress**: Support multiple allowed CIDRs or open to the world (if needed)
- ✅ **Tagging**: Common tags applied to all security groups

## Usage

```hcl
module "security" {
  source = "./modules/security"

  name_prefix = "myapp"
  vpc_id      = aws_vpc.main.id
  vpc_cidr    = aws_vpc.main.cidr_block

  # Restrict ingress to office/VPN CIDRs (empty list defaults to 0.0.0.0/0)
  allowed_ingress_cidrs = ["203.0.113.0/24", "198.51.100.0/24"]

  app_port = 8080

  # Restrict egress to VPC CIDR only (hardening)
  restrict_egress_to_vpc = true

  tags = {
    Tier    = "network"
    Project = "myapp"
  }
}
```

## Inputs

### Required

| Name | Type | Description |
| --- | --- | --- |
| `name_prefix` | `string` | Prefix for all security group names |
| `vpc_id` | `string` | VPC ID where security groups will be created |

### Optional

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `allowed_ingress_cidrs` | `list(string)` | `[]` | CIDR blocks allowed to reach ALB. If empty, defaults to `0.0.0.0/0` (not recommended). Must be valid CIDR notation. |
| `app_port` | `number` | `8080` | Port on which the app listens (1-65535) |
| `restrict_egress_to_vpc` | `bool` | `true` | If `true`, restrict egress to VPC CIDR only; if `false`, allow `0.0.0.0/0` |
| `vpc_cidr` | `string` | `null` | VPC CIDR block (**required** if `restrict_egress_to_vpc=true`) |
| `tags` | `map(string)` | `{}` | Common tags to apply to all resources |

## Outputs

| Name | Type | Description |
| --- | --- | --- |
| `alb_sg_id` | `string` | ALB security group ID |
| `alb_sg_arn` | `string` | ALB security group ARN |
| `app_sg_id` | `string` | Application security group ID |
| `app_sg_arn` | `string` | Application security group ARN |

## Rules

### ALB Security Group

**Ingress:**
- HTTP (port 80) from allowed CIDRs
- HTTPS (port 443) from allowed CIDRs

**Egress:**
- All traffic to VPC CIDR (if `restrict_egress_to_vpc=true`)
- All traffic to `0.0.0.0/0` (if `restrict_egress_to_vpc=false`)

**Note:** As of this version the module restricts ALB egress to the App security
group only (instead of CIDR-based egress) to enforce a stricter security posture.
This means the ALB can only initiate connections to targets in the App security
group on `app_port`. If you need ALB-originated outbound access to other CIDRs
(for example, to reach external services), adjust the module to add explicit
egress rules or change the design accordingly.

### App Security Group

**Ingress:**
- TCP on `app_port` from ALB security group only

**Egress:**
- All traffic to VPC CIDR (if `restrict_egress_to_vpc=true`)
- All traffic to `0.0.0.0/0` (if `restrict_egress_to_vpc=false`)

## Example: Multiple Allowed CIDRs

```hcl
module "security" {
  source = "./modules/security"

  name_prefix = "myapp"
  vpc_id      = aws_vpc.main.id
  vpc_cidr    = aws_vpc.main.cidr_block

  allowed_ingress_cidrs = [
    "10.0.0.0/8",        # Corporate office
    "192.168.1.0/24",    # VPN CIDR
    "203.0.113.100/32"   # Specific remote IP
  ]

  app_port               = 3000
  restrict_egress_to_vpc = true

  tags = {
    Environment = "production"
    Name        = "myapp-sgs"
  }
}
```

## Security Best Practices

1. **Always restrict `allowed_ingress_cidrs`**: Avoid opening to `0.0.0.0/0` in production
2. **Enable `restrict_egress_to_vpc`**: Limits lateral movement if a resource is compromised
3. **Use security group descriptions**: All rules include descriptive text for auditing
4. **Review egress rules**: Consider if your app needs external egress (e.g., to fetch from CDNs)

## Validation Errors

- **`allowed_ingress_cidrs` invalid format**: Ensure all CIDRs follow notation like `10.0.0.0/16`
- **`app_port` out of range**: Must be between 1 and 65535
- **`vpc_cidr` missing when required**: If `restrict_egress_to_vpc=true`, you must provide `vpc_cidr`

---

For questions or issues, review the main.tf and variables.tf files in this module.
