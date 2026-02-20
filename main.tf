module "network" {
  source = "./modules/network"

  name     = local.base_name
  vpc_cidr = var.vpc_config.vpc_cidr

  public_subnet_cidrs  = var.vpc_config.public_subnet_cidrs
  private_subnet_cidrs = var.vpc_config.private_subnet_cidrs

  tags = merge(local.common_tags, {
    Layer = "network"
  })
}

module "security" {
  source = "./modules/security"

  name_prefix            = local.base_name
  vpc_id                 = module.network.vpc_id
  vpc_cidr               = module.network.vpc_cidr
  allowed_ingress_cidrs  = var.security.allowed_ingress_cidrs
  app_port               = var.security.app_port
  restrict_egress_to_vpc = false

  tags = merge(local.common_tags, {
    Layer = "security"
  })
}

module "alb" {
  source = "./modules/alb"

  name_prefix       = local.base_name
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  target_port       = var.alb.target_port
  target_type       = var.alb.target_type
  health_check_path = var.alb.health_check_path
  listener_http     = true

    tags = merge(local.common_tags, {
        Layer = "alb"
    })
}