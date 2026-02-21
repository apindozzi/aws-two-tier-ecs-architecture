output "service_name" {
  value = aws_ecs_service.svc.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.task.arn
}

output "proxy_log_group_name" {
  value = aws_cloudwatch_log_group.proxy.name
}

output "backend_log_group_name" {
  value = aws_cloudwatch_log_group.backend.name
}