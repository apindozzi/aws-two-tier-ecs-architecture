output "alb_sg_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "Application security group ID"
  value       = aws_security_group.app.id
}

output "alb_sg_arn" {
  description = "ALB security group ARN"
  value       = aws_security_group.alb.arn
}

output "app_sg_arn" {
  description = "Application security group ARN"
  value       = aws_security_group.app.arn
}
