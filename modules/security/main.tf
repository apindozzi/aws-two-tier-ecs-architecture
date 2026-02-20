locals {
  ingress_cidrs = length(var.allowed_ingress_cidrs) > 0 ? var.allowed_ingress_cidrs : ["0.0.0.0/0"]
  # use vpc_cidr if restrict_egress_to_vpc is true, otherwise allow all
  egress_cidrs = var.restrict_egress_to_vpc ? [var.vpc_cidr] : ["0.0.0.0/0"]
}

# --- ALB Security Group ---
resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-"
  description = "ALB SG - controls inbound traffic from allowed sources"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
  })
}

# ALB ingress: HTTP from allowed CIDRs
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each          = toset(local.ingress_cidrs)
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from ${each.value}"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value

  tags = {
    Name = "${var.name_prefix}-alb-http"
  }
}

# ALB ingress: HTTPS from allowed CIDRs
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each          = toset(local.ingress_cidrs)
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from ${each.value}"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value

  tags = {
    Name = "${var.name_prefix}-alb-https"
  }
}

# ALB egress: restrict ALB outbound so it can only reach the App security group
# (prevents ALB from reaching the internet or other CIDRs)
resource "aws_vpc_security_group_egress_rule" "alb_egress_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow ALB to reach App SG on application port"
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id

  tags = {
    Name = "${var.name_prefix}-alb-egress-to-app"
  }
}

# --- App/Service Security Group ---
resource "aws_security_group" "app" {
  name_prefix = "${var.name_prefix}-app-"
  description = "App SG - accepts traffic from ALB on app_port only"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-sg"
  })
}

# App ingress: from ALB SG on app_port
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Traffic from ALB on port ${var.app_port}"
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id

  tags = {
    Name = "${var.name_prefix}-app-from-alb"
  }
}

# App egress: to egress destinations
resource "aws_vpc_security_group_egress_rule" "app_egress" {
  for_each          = toset(local.egress_cidrs)
  security_group_id = aws_security_group.app.id
  description       = "All traffic to ${each.value}"
  ip_protocol       = "-1"
  cidr_ipv4         = each.value

  tags = {
    Name = "${var.name_prefix}-app-egress"
  }
}