# ============================================================
# Módulo Secrets Manager — Gerenciamento seguro de credenciais
# ============================================================

resource "aws_secretsmanager_secret" "main" {
  name                    = "${var.project}/${var.env}/${var.secret_name}"
  description             = var.description
  recovery_window_in_days = var.recovery_window

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-${var.secret_name}"
  })
}

# Versão inicial do secret (valor definido fora do Terraform)
resource "aws_secretsmanager_secret_version" "main" {
  secret_id     = aws_secretsmanager_secret.main.id
  secret_string = var.secret_value

  lifecycle {
    # Evita que o Terraform sobrescreva rotações automáticas
    ignore_changes = [secret_string]
  }
}

# ── Policy de acesso ao secret ────────────────────────────────
resource "aws_secretsmanager_secret_policy" "main" {
  count      = length(var.allowed_role_arns) > 0 ? 1 : 0
  secret_arn = aws_secretsmanager_secret.main.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = var.allowed_role_arns }
      Action    = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource  = "*"
    }]
  })
}
