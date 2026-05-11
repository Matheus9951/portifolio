# ============================================================
# GuardDuty — Detecção de ameaças com Machine Learning
# Monitora: CloudTrail, VPC Flow Logs, DNS logs
# ============================================================

resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true   # Detecta acesso anômalo a S3
    }
    kubernetes {
      audit_logs {
        enable = true  # Detecta comportamento suspeito no EKS
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true  # Scan de malware em volumes EBS
        }
      }
    }
  }

  tags = var.tags
}

# SNS para notificações de findings críticos
resource "aws_sns_topic" "guardduty_alerts" {
  name = "${var.project}-guardduty-alerts"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.guardduty_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# EventBridge — captura findings HIGH e CRITICAL e envia para SNS
resource "aws_cloudwatch_event_rule" "guardduty_high" {
  name        = "${var.project}-guardduty-high-findings"
  description = "Captura findings HIGH e CRITICAL do GuardDuty"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 7] }]  # HIGH = 7+, CRITICAL = 9+
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "guardduty_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_high.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.guardduty_alerts.arn

  input_transformer {
    input_paths = {
      severity    = "$.detail.severity"
      type        = "$.detail.type"
      description = "$.detail.description"
      region      = "$.region"
    }
    input_template = "\"🚨 GuardDuty ALERTA | Severidade: <severity> | Tipo: <type> | Região: <region> | Descrição: <description>\""
  }
}
