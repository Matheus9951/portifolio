# 💰 FinOps AWS Dashboard

Scripts Python para análise, visualização e otimização de custos na AWS usando o Cost Explorer API.

## 🎯 Funcionalidades

- 📊 Relatório de custos por serviço, conta e tag
- 📈 Tendência de gastos dos últimos 30/60/90 dias
- 🚨 Alertas de anomalias de custo
- 💡 Recomendações de Savings Plans e Reserved Instances
- 🏷️ Análise de recursos sem tags (untagged resources)
- 📉 Identificação de recursos ociosos (EC2, RDS, EBS)

## 🚀 Como usar

```bash
# Instalar dependências
pip install -r requirements.txt

# Configurar credenciais AWS
export AWS_PROFILE=meu-perfil
export AWS_REGION=us-east-1

# Relatório de custos dos últimos 30 dias
python scripts/cost_report.py --days 30

# Identificar recursos ociosos
python scripts/idle_resources.py

# Exportar relatório em HTML
python scripts/cost_report.py --days 30 --output reports/relatorio.html
```

## 📋 Pré-requisitos
- Python 3.9+
- Permissões IAM: `ce:GetCostAndUsage`, `ce:GetRecommendations`, `ec2:Describe*`, `rds:Describe*`
