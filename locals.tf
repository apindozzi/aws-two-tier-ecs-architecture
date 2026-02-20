locals {
  region = data.aws_region.current.region

  common_tags = {
    Project     = "aws-ecs-two-tier"
    Environment = "poc"
    Owner       = "cloud-engineer"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }

  base_name = join("-", [
    var.project_info.prefix,
    local.region,
  ])
}