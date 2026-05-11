# ============================================================
# Módulo IAM — Roles e Policies com least privilege
# ============================================================

# ── Role para aplicações via IRSA (IAM Roles for Service Accounts) ──
resource "aws_iam_role" "app_role" {
  name = "${var.project}-${var.env}-${var.app_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

# ── Policy customizada para a aplicação ──────────────────────
resource "aws_iam_policy" "app_policy" {
  name        = "${var.project}-${var.env}-${var.app_name}-policy"
  description = "Policy para ${var.app_name} no ambiente ${var.env}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = var.policy_statements
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "app" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.app_policy.arn
}
