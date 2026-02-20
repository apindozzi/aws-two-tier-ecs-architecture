# Network Module

Provisions a two-tier VPC architecture with public and private subnets across multiple availability zones, including NAT gateways for outbound traffic from private subnets.

## Module Structure

This module creates and manages:
- **VPC**: Main virtual private cloud with configurable CIDR
- **Public Subnets**: Subnets with routes to Internet Gateway, deployed across AZs
- **Private Subnets**: Subnets with routes through NAT Gateway, deployed across AZs
- **Internet Gateway**: Enables inbound/outbound internet traffic to public subnets
- **NAT Gateway**: Enables outbound-only internet traffic from private subnets
- **Route Tables**: Separate routing for public and private subnets

## Features

- ✅ **Multi-AZ deployment**: Automatically distributes subnets across available zones
- ✅ **CIDR validation**: Validates all CIDR blocks for proper format
- ✅ **Dynamic subnet count**: Number of AZs/subnets determined by CIDR list length
- ✅ **Flexible tagging**: Common tags applied consistently across all resources
- ✅ **High availability**: NAT Gateway in first public subnet ensures private subnet egress

## Usage

```hcl
module "network" {
  source = "./modules/network"

  name     = "myapp"
  vpc_cidr = "10.0.0.0/16"

  # Create 2 public subnets (one per AZ)
  public_subnet_cidrs = ["10.0.0.0/24", "10.0.1.0/24"]

  # Create 2 private subnets (one per AZ)
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

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
| `name` | `string` | Name prefix for VPC and networking resources (used in resource naming and tags) |
| `vpc_cidr` | `string` | CIDR block for the VPC (e.g. `10.0.0.0/16`). Must be valid CIDR notation. |
| `public_subnet_cidrs` | `list(string)` | CIDR blocks for public subnets. One subnet will be created per CIDR in each availability zone. Must contain at least one valid CIDR. |
| `private_subnet_cidrs` | `list(string)` | CIDR blocks for private subnets. Must have the same number of entries as `public_subnet_cidrs`. |

### Optional

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `tags` | `map(string)` | `{}` | Common tags to apply to all VPC and networking resources |

## Outputs

| Name | Type | Description |
| --- | --- | --- |
| `vpc_id` | `string` | VPC ID |
| `vpc_cidr` | `string` | VPC CIDR block |
| `public_subnet_ids` | `list(string)` | List of public subnet IDs |
| `private_subnet_ids` | `list(string)` | List of private subnet IDs |
| `internet_gateway_id` | `string` | Internet Gateway ID |
| `nat_gateway_id` | `string` | NAT Gateway ID |
| `public_route_table_id` | `string` | Public route table ID |
| `private_route_table_id` | `string` | Private route table ID |

## Architecture

```
┌─────────────────────────────────────────────┐
│             VPC (10.0.0.0/16)               │
├─────────────────────────────────────────────┤
│  AZ-1                          │  AZ-2      │
│  ┌──────────────┐              │            │
│  │ Public Sub   │              │ ┌────────┐ │
│  │ 10.0.0.0/24  ├──────┐       │ │ Public │ │
│  │              │      │IGW    │ │10.0.1. │ │
│  └──────────────┘      │       │ │   0/24 │ │
│  ┌──────────────┐      ├───────┤─┤        │ │
│  │ Private Sub  │      │       │ └────────┘ │
│  │10.0.10.0/24  ├──NAT─┘       │            │
│  │              │              │ ┌────────┐ │
│  └──────────────┘              │ │Private │ │
│                                │ │10.0.11.│ │
│                                │ │  0/24  │ │
│                                │ └────────┘ │
└─────────────────────────────────────────────┘
```

## Validation Rules

- **vpc_cidr**: Must be valid CIDR notation (e.g., `10.0.0.0/16`)
- **public_subnet_cidrs**: At least one CIDR required; all must be valid CIDR notation
- **private_subnet_cidrs**: Must have same count as `public_subnet_cidrs`; all must be valid CIDR notation
- **Consistency**: Number of AZs used equals the number of subnet CIDRs

## Examples

### Minimal Setup (Single AZ)

```hcl
module "network" {
  source = "./modules/network"

  name             = "simple-app"
  vpc_cidr         = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24"]
}
```

### High-Availability Setup (3 AZs)

```hcl
module "network" {
  source = "./modules/network"

  name             = "ha-app"
  vpc_cidr         = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Environment = "production"
    HighAvailability = true
  }
}
```

---

For detailed variable validation rules and error messages, see `variables.tf`.
