# ============================================================
# Ambiente DEV — Orquestra todos os módulos
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend remoto — estado no S3 com lock no DynamoDB
  backend "s3" {
    bucket         = "meu-projeto-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    project     = var.project
    env         = "dev"
    owner       = "matheus-silva"
    managed_by  = "terraform"
  }
}

# ── VPC ──────────────────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project              = var.project
  env                  = "dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets_cidr = ["10.0.10.0/24", "10.0.11.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
  tags                 = local.common_tags
}

# ── EKS ──────────────────────────────────────────────────────
module "eks" {
  source = "../../modules/eks"

  project             = var.project
  env                 = "dev"
  private_subnet_ids  = module.vpc.private_subnet_ids
  kubernetes_version  = "1.29"
  node_instance_types = ["t3.medium"]
  capacity_type       = "SPOT"   # SPOT em dev para reduzir custos
  desired_nodes       = 2
  min_nodes           = 1
  max_nodes           = 3
  tags                = local.common_tags
}
