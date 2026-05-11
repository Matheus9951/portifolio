# ============================================================
# AWS Landing Zone — Orquestração de todos os módulos
# ============================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "meu-projeto-terraform-state"
    key            = "landing-zone/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  tags = {
    project    = var.project
    managed_by = "terraform"
    owner      = "sre-team"
  }
}

# ── SNS para alertas centralizados ───────────────────────────
resource "aws_sns_topic" "alerts" {
  name = "${var.project}-security-alerts"
  tags = local.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ── CloudTrail ────────────────────────────────────────────────
module "cloudtrail" {
  source        = "./modules/cloudtrail"
  project       = var.project
  sns_topic_arn = aws_sns_topic.alerts.arn
  tags          = local.tags
}

# ── GuardDuty ─────────────────────────────────────────────────
module "guardduty" {
  source      = "./modules/guardduty"
  project     = var.project
  alert_email = var.alert_email
  tags        = local.tags
}

# ── AWS Config ────────────────────────────────────────────────
module "config" {
  source  = "./modules/config"
  project = var.project
  tags    = local.tags
}

# ── Budgets ───────────────────────────────────────────────────
module "budgets" {
  source            = "./modules/budgets"
  project           = var.project
  alert_email       = var.alert_email
  monthly_limit_usd = var.monthly_budget_usd
  ec2_limit_usd     = var.ec2_budget_usd
  env_limits_usd = {
    dev     = "50"
    staging = "100"
    prod    = tostring(var.monthly_budget_usd * 0.7)
  }
  tags = local.tags
}
