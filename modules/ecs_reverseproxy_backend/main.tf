locals {
  service_name = "${var.name}-svc"
  task_family  = "${var.name}-task"

  proxy_log_group   = "/ecs/${var.name}/proxy"
  backend_log_group = "/ecs/${var.name}/backend"

  backend_env_list = [
    for k, v in var.environment : {
      name  = k
      value = v
    }
  ]

  backend_secrets_list = [
    for k, arn in var.backend_secrets : {
      name      = k
      valueFrom = arn
    }
  ]

  container_definitions = jsonencode([
    {
      name      = "proxy"
      image     = var.proxy_image
      essential = true

      portMappings = [{
        containerPort = var.proxy_container_port
        protocol      = "tcp"
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.proxy_log_group
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      dependsOn = [{
        containerName = "backend"
        condition     = "START"
      }]
    },
    {
      name      = "backend"
      image     = var.backend_image
      essential = true

      portMappings = [{
        containerPort = var.backend_container_port
        protocol      = "tcp"
      }]

      environment = local.backend_env_list
      secrets     = local.backend_secrets_list

      command = var.backend_command # to remove

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.backend_log_group
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "proxy" {
  name              = local.proxy_log_group
  retention_in_days = var.log_retention_days
  tags = merge(var.tags, {
    Name = "${var.name}-proxy-log"
  })
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = local.backend_log_group
  retention_in_days = var.log_retention_days
  tags = merge(var.tags, {
    Name = "${var.name}-backend-log"
  })
}

resource "aws_ecs_task_definition" "task" {
  family                   = local.task_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

  container_definitions = local.container_definitions
  tags = merge(var.tags, {
    Name = "${var.name}-task-def"
  })
}

resource "aws_ecs_service" "svc" {
  name            = local.service_name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.service_security_group_id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "proxy"
    container_port   = var.proxy_container_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  tags = merge(var.tags, {
    Name = local.service_name
  })

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# Autoscaling target
resource "aws_appautoscaling_target" "ecs" {
  count              = var.enable_autoscaling ? 1 : 0
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${split("/", var.cluster_arn)[1]}/${aws_ecs_service.svc.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.target_cpu
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "memory" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.name}-mem"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.target_memory
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}