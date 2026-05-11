# 📊 Observability Stack — Prometheus + Grafana + Loki + Tempo

Stack completa de observabilidade no Kubernetes cobrindo as três dimensões: métricas, logs e traces.

## 🔭 Os Três Pilares

| Pilar | Ferramenta | O que monitora |
|-------|-----------|----------------|
| Métricas | Prometheus | CPU, memória, latência, erros, saturação |
| Logs | Loki | Logs de aplicações e infraestrutura |
| Traces | Tempo | Rastreamento distribuído de requisições |
| Visualização | Grafana | Dashboards unificados para tudo acima |

## 🏗️ Arquitetura

```
Aplicações → Prometheus (scrape métricas)
           → Promtail → Loki (logs)
           → OpenTelemetry → Tempo (traces)
                    ↓
               Grafana (visualização unificada)
```

## 🚀 Deploy

```bash
# Adicionar repositório Helm
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Criar namespace
kubectl create namespace monitoring

# Deploy do kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus/values.yaml

# Deploy do Loki
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --values loki/values.yaml

# Deploy do Tempo
helm upgrade --install tempo grafana/tempo \
  --namespace monitoring \
  --values tempo/values.yaml
```

## 📈 Dashboards incluídos
- Cluster Overview (nodes, pods, namespaces)
- Application RED metrics (Rate, Errors, Duration)
- Infrastructure (CPU, memória, disco, rede)
- Kubernetes Workloads
