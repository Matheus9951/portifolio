# ============================================================
# CloudTrail — Auditoria completa de todas as chamadas de API
# ============================================================

# Bucket S3 para armazenar os logs do CloudTrail
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.project}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = false

  tags = var.tags
}

data "aws_caller_identity" "current" {}

# Bloquear acesso público ao bucket de logs
resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Criptografia SSE-S3 nos logs
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versionamento para proteção contra deleção acidental
resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle — mover para Glacier após 90 dias, deletar após 365
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  rule {
    id     = "cloudtrail-lifecycle"
    status = "Enabled"
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    expiration {
      days = 365
    }
  }
}

# Policy do bucket — permite que o CloudTrail escreva
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

# CloudTrail — multi-region para capturar tudo
resource "aws_cloudtrail" "main" {
  name                          = "${var.project}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true   # IAM, STS, etc.
  is_multi_region_trail         = true   # Captura todas as regiões
  enable_log_file_validation    = true   # Detecta adulteração de logs

  # Logar eventos de dados do S3 (opcional — gera custo adicional)
  # event_selector {
  #   read_write_type           = "All"
  #   include_management_events = true
  # }

  tags = var.tags
}

# Alarme CloudWatch — alerta se alguém logar como root
resource "aws_cloudwatch_metric_alarm" "root_login" {
  alarm_name          = "${var.project}-root-login-detected"
  alarm_description   = "ALERTA: Login com usuário root detectado"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootAccountUsage"
  namespace           = "CloudTrailMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  tags = var.tags
}
