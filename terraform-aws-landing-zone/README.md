# 🏢 AWS Landing Zone com Terraform

Infraestrutura base de segurança e governança para uma conta AWS pronta para produção. Implementa os controles essenciais recomendados pelo AWS Well-Architected Framework.

## 🎯 O que é uma Landing Zone?

É o conjunto de configurações que toda conta AWS deveria ter **antes** de subir qualquer workload. Sem isso, você está operando sem visibilidade, sem alertas de custo e sem auditoria.

## 🛡️ O que este projeto configura

| Módulo | O que faz |
|--------|-----------|
| `cloudtrail` | Auditoria de todas as chamadas de API na conta |
| `guardduty` | Detecção de ameaças com ML (IPs maliciosos, comportamento anômalo) |
| `config` | Inventário e compliance contínuo de recursos |
| `budgets` | Alertas de custo para evitar surpresas na fatura |

## 🚀 Deploy

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## ⚡ Resultado após o apply

- ✅ Todos os eventos de API logados no S3 com criptografia
- ✅ GuardDuty monitorando a conta 24/7
- ✅ AWS Config registrando mudanças em todos os recursos
- ✅ Alertas de budget por e-mail quando atingir 80% e 100%
- ✅ Alarmes CloudWatch para atividades suspeitas (root login, MFA desabilitado)
