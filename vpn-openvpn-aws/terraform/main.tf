# ============================================================
# OpenVPN na AWS — Terraform
# ============================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── Elastic IP fixo para o servidor VPN ──────────────────────
resource "aws_eip" "vpn" {
  domain = "vpc"
  tags = {
    Name = "${var.project}-vpn-eip"
  }
}

resource "aws_eip_association" "vpn" {
  instance_id   = aws_instance.vpn.id
  allocation_id = aws_eip.vpn.id
}

# ── Security Group — apenas portas necessárias ───────────────
resource "aws_security_group" "vpn" {
  name        = "${var.project}-vpn-sg"
  description = "Security Group para servidor OpenVPN"
  vpc_id      = var.vpc_id

  # OpenVPN
  ingress {
    description = "OpenVPN UDP"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Sem SSH direto — usar SSM Session Manager
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-vpn-sg"
  }
}

# ── IAM Role para SSM (acesso sem SSH) ───────────────────────
resource "aws_iam_role" "vpn_ssm" {
  name = "${var.project}-vpn-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.vpn_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "vpn" {
  name = "${var.project}-vpn-profile"
  role = aws_iam_role.vpn_ssm.name
}

# ── Instância EC2 com OpenVPN ─────────────────────────────────
resource "aws_instance" "vpn" {
  ami                    = var.ami_id  # Amazon Linux 2023
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.vpn.id]
  iam_instance_profile   = aws_iam_instance_profile.vpn.name

  # Habilitar IP forwarding para roteamento VPN
  source_dest_check = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  # Script de inicialização — instala e configura OpenVPN
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    vpn_network = var.vpn_network
    vpc_cidr    = var.vpc_cidr
  }))

  tags = {
    Name    = "${var.project}-vpn-server"
    project = var.project
  }
}
