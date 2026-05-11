# 📋 Incident Runbooks — SRE

Runbooks práticos para os incidentes mais comuns em ambientes Kubernetes e AWS. Cada runbook segue o padrão: **detectar → diagnosticar → resolver → prevenir**.

## 🚨 Runbooks disponíveis

| Runbook | Cenário |
|---------|---------|
| [pod-crashloopbackoff.md](runbooks/pod-crashloopbackoff.md) | Pod em CrashLoopBackOff |
| [node-not-ready.md](runbooks/node-not-ready.md) | Node com status NotReady |
| [high-memory-usage.md](runbooks/high-memory-usage.md) | Uso de memória crítico no cluster |
| [deployment-stuck.md](runbooks/deployment-stuck.md) | Deployment travado / rollout parado |

## 📊 Alertas Prometheus incluídos

Regras de alertas prontas para importar no Prometheus/Alertmanager.

## 🛠️ Scripts de diagnóstico

Scripts Bash para coleta rápida de informações durante um incidente.

## 📐 Padrão de Severidade

| Severidade | Tempo de resposta | Exemplo |
|------------|-------------------|---------|
| P1 - Crítico | 15 min | Cluster down, perda de dados |
| P2 - Alto | 1 hora | Serviço principal degradado |
| P3 - Médio | 4 horas | Serviço secundário com erros |
| P4 - Baixo | 24 horas | Alertas de capacidade |
