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

module "ecs_cluster" {
  source = "./modules/ecs"

  name                      = "${local.base_name}-cluster"
  enable_container_insights = var.ecs_cluster.enable_container_insights

  tags = merge(local.common_tags, {
    Layer = "ecs"
  })
}

module "iam_task_roles" {
  source = "./modules/iam_task_roles"

  execution_role_name = "${var.project_info.prefix}-ecs-exec"
  task_role_name      = "${var.project_info.prefix}-ecs-task"

  tags = merge(local.common_tags, var.ecs_app.tags, {
    Layer = "iam"
  })
}

module "ecs_app" {
  source = "./modules/ecs_reverseproxy_backend"

  name   = "${local.base_name}-app"
  region = local.region

  cluster_arn        = module.ecs_cluster.cluster_arn
  private_subnet_ids = module.network.private_subnet_ids

  # Reuse existing SG + TG created by your security/alb modules
  service_security_group_id = module.security.app_sg_id
  target_group_arn          = module.alb.target_group_arn

  # Task sizing
  desired_count = var.ecs_app.desired_count
  task_cpu      = var.ecs_app.task_cpu
  task_memory   = var.ecs_app.task_memory

  # Images (ECR URLs or public images)
  proxy_image   = var.ecs_app.proxy_image
  backend_image = var.ecs_app.backend_image

  proxy_container_port   = var.ecs_app.proxy_container_port
  backend_container_port = var.ecs_app.backend_container_port

  # IAM
  execution_role_arn = module.iam_task_roles.execution_role_arn
  task_role_arn      = module.iam_task_roles.task_role_arn

  # Backend env/secrets
  environment     = var.ecs_app.environment
  backend_secrets = var.ecs_app.backend_secrets

  backend_command = [
    "-listen=:8080",
    "-text=hello world"
  ]

  # Networking
  assign_public_ip = var.ecs_app.assign_public_ip

  # Autoscaling
  enable_autoscaling = var.ecs_app.enable_autoscaling
  min_capacity       = var.ecs_app.min_capacity
  max_capacity       = var.ecs_app.max_capacity
  target_cpu         = var.ecs_app.target_cpu
  target_memory      = var.ecs_app.target_memory

  tags = merge(local.common_tags, var.ecs_app.tags, {
    Layer = "ecs"
  })
}