variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "meu-projeto"
}

variable "vpc_id" {
  description = "ID da VPC onde o servidor VPN será criado"
  type        = string
}

variable "public_subnet_id" {
  description = "ID da subnet pública para o servidor VPN"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR da VPC para roteamento"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpn_network" {
  description = "Rede interna da VPN (ex: 10.8.0.0)"
  type        = string
  default     = "10.8.0.0"
}

variable "ami_id" {
  description = "AMI do Amazon Linux 2023"
  type        = string
  default     = "ami-0c02fb55956c7d316"  # us-east-1 — atualize conforme região
}

variable "instance_type" {
  description = "Tipo de instância EC2 para o servidor VPN"
  type        = string
  default     = "t3.micro"  # Suficiente para até 50 usuários
}
