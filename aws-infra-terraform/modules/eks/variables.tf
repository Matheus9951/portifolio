variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes"
  type        = string
  default     = "1.29"
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas para o cluster"
  type        = list(string)
}

variable "public_access" {
  description = "Habilitar acesso público ao API server"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDRs permitidos para acesso público ao API server"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "Tipos de instância para os nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "Tipo de capacidade: ON_DEMAND ou SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "desired_nodes" {
  type    = number
  default = 2
}

variable "min_nodes" {
  type    = number
  default = 1
}

variable "max_nodes" {
  type    = number
  default = 5
}

variable "tags" {
  type    = map(string)
  default = {}
}
