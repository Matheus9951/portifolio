variable "project" {
  description = "Nome do projeto"
  type        = string
}

variable "env" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "Lista de CIDRs para subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets_cidr" {
  description = "Lista de CIDRs para subnets privadas"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "Lista de AZs para distribuição das subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "tags" {
  description = "Tags padrão aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}
