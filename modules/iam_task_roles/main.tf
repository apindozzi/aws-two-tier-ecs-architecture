locals {
  common_tags = merge(var.tags, {
    Name = "ecs-task-roles"
  })
}

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# -----------------------------
# Execution Role (ECS agent)
# -----------------------------
resource "aws_iam_role" "execution" {
  name               = var.execution_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  tags = merge(local.common_tags, {
    Name = var.execution_role_name
  })
}

# AWS managed: ECR pull + CW logs baseline
resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Extra execution permissions (optional): secrets/ssm/kms (least privilege via ARNs)
data "aws_iam_policy_document" "execution_extra" {
  count = var.enable_execution_extra_policy ? 1 : 0

  dynamic "statement" {
    for_each = length(var.execution_ssm_parameter_arns) > 0 ? [1] : []
    content {
      sid       = "ReadSSMParameters"
      effect    = "Allow"
      actions   = ["ssm:GetParameters", "ssm:GetParameter", "ssm:GetParametersByPath"]
      resources = var.execution_ssm_parameter_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.execution_secretsmanager_arns) > 0 ? [1] : []
    content {
      sid       = "ReadSecretsManagerSecrets"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      resources = var.execution_secretsmanager_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.execution_kms_key_arns) > 0 ? [1] : []
    content {
      sid       = "DecryptWithKMS"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = var.execution_kms_key_arns
    }
  }
}

resource "aws_iam_role_policy" "execution_extra" {
  count  = var.enable_execution_extra_policy ? 1 : 0
  name   = "${var.execution_role_name}-extra"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution_extra[0].json
}

# Optional: attach arbitrary extra policies to execution role
resource "aws_iam_role_policy" "execution_inline_custom" {
  for_each = var.execution_inline_policies

  name   = each.key
  role   = aws_iam_role.execution.id
  policy = each.value
}

# -----------------------------
# Task Role (Application role)
# -----------------------------
resource "aws_iam_role" "task" {
  name               = var.task_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  tags = merge(local.common_tags, {
    Name = var.task_role_name
  })
}

# Optional: attach arbitrary inline policies to task role (recommended for app perms)
resource "aws_iam_role_policy" "task_inline_custom" {
  for_each = var.task_inline_policies

  name   = each.key
  role   = aws_iam_role.task.id
  policy = each.value
}