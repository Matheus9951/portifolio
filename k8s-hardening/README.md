# 🔒 Kubernetes Hardening — Segurança em Produção

Conjunto de configurações e políticas para hardening de clusters Kubernetes em produção, cobrindo RBAC, Network Policies, Pod Security Standards e OPA/Gatekeeper.

## 🎯 O que este projeto resolve

Clusters Kubernetes mal configurados são um dos vetores de ataque mais comuns em ambientes cloud. Este projeto implementa as principais camadas de defesa recomendadas pelo CIS Kubernetes Benchmark.

## 🛡️ Camadas de Segurança

```
┌─────────────────────────────────────────────┐
│           Cluster Kubernetes                 │
│                                              │
│  ┌──────────────┐   ┌──────────────────┐    │
│  │     RBAC     │   │  Network Policy  │    │
│  │ (quem pode   │   │ (quem fala com   │    │
│  │  fazer o quê)│   │   quem)          │    │
│  └──────────────┘   └──────────────────┘    │
│                                              │
│  ┌──────────────┐   ┌──────────────────┐    │
│  │Pod Security  │   │OPA / Gatekeeper  │    │
│  │  Standards   │   │ (políticas custom)│   │
│  └──────────────┘   └──────────────────┘    │
└─────────────────────────────────────────────┘
```

## 📁 Estrutura

```
.
├── rbac/
│   ├── developer-role.yaml        # Role para devs (read-only em prod)
│   ├── sre-role.yaml              # Role para SREs (acesso operacional)
│   └── ci-serviceaccount.yaml     # ServiceAccount para pipelines CI/CD
├── network-policies/
│   ├── default-deny-all.yaml      # Nega todo tráfego por padrão
│   ├── allow-dns.yaml             # Permite resolução DNS
│   └── allow-app-to-db.yaml       # Permite app → banco de dados
├── pod-security/
│   ├── namespace-restricted.yaml  # Namespace com PSS Restricted
│   └── seccomp-profile.yaml       # Perfil seccomp customizado
└── policies/
    ├── require-labels.yaml        # OPA: exige labels obrigatórias
    ├── no-latest-tag.yaml         # OPA: proíbe tag :latest
    └── require-resource-limits.yaml # OPA: exige limits em todos os containers
```

## 🚀 Aplicar no cluster

```bash
# RBAC
kubectl apply -f rbac/

# Network Policies
kubectl apply -f network-policies/

# Pod Security Standards (via label no namespace)
kubectl label namespace production pod-security.kubernetes.io/enforce=restricted

# OPA Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
kubectl apply -f policies/
```

## ✅ Checklist CIS Benchmark coberto

- [x] RBAC com menor privilégio
- [x] ServiceAccounts dedicadas por workload
- [x] Network Policies default-deny
- [x] Pod Security Standards (Restricted)
- [x] Proibição de containers privilegiados
- [x] Exigência de resource limits
- [x] Proibição de tag :latest
- [x] Seccomp profiles habilitados
