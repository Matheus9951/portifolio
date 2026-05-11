# 🏗️ AWS Infrastructure with Terraform

Infraestrutura AWS completa provisionada como código com Terraform, seguindo boas práticas de modularização, segurança e escalabilidade.

## 📐 Arquitetura

```
┌─────────────────────────────────────────────────────┐
│                      AWS Cloud                       │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │                   VPC                         │   │
│  │  ┌─────────────┐    ┌─────────────────────┐  │   │
│  │  │ Public Subnet│    │   Private Subnet    │  │   │
│  │  │  (NAT/IGW)  │    │  EKS Node Groups    │  │   │
│  │  └─────────────┘    └─────────────────────┘  │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌──────┐  ┌──────┐  ┌──────────────┐  ┌────────┐  │
│  │  S3  │  │ ECR  │  │Secrets Mgr   │  │  IAM   │  │
│  └──────┘  └──────┘  └──────────────┘  └────────┘  │
└─────────────────────────────────────────────────────┘
```

## 📦 Módulos

| Módulo | Descrição |
|--------|-----------|
| `vpc` | VPC com subnets públicas/privadas, IGW, NAT Gateway, route tables |
| `eks` | Cluster EKS com node groups gerenciados e OIDC provider |
| `ec2` | Instâncias EC2 com security groups e key pairs |
| `s3` | Buckets S3 com versionamento, criptografia e políticas |
| `iam` | Roles, policies e instance profiles com least privilege |
| `secrets` | Secrets Manager para gerenciamento seguro de credenciais |

## 🚀 Como usar

### Pré-requisitos
- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado
- Permissões IAM adequadas

### Deploy em Dev
```bash
cd envs/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Deploy em Prod
```bash
cd envs/prod
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## 🔐 Segurança
- Secrets nunca em texto plano — todos via AWS Secrets Manager
- IAM com princípio de menor privilégio
- Subnets privadas para workloads sensíveis
- Security Groups restritivos por padrão

## 💰 FinOps
- Tags obrigatórias em todos os recursos (`env`, `project`, `owner`)
- NAT Gateway compartilhado por AZ para redução de custos
- S3 lifecycle policies configuradas
