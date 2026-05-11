# 🔄 EKS + GitOps com ArgoCD e GitHub Actions

Pipeline completo de CI/CD com GitOps: build e push de imagem via GitHub Actions, deploy automático no EKS via ArgoCD.

## 🏗️ Fluxo

```
Developer → git push → GitHub Actions (CI)
                              │
                    ┌─────────▼──────────┐
                    │  Build & Test       │
                    │  Docker Build       │
                    │  Push to ECR        │
                    │  Update manifests   │
                    └─────────┬──────────┘
                              │ git push (manifests)
                    ┌─────────▼──────────┐
                    │     ArgoCD (CD)     │
                    │  Detecta mudança    │
                    │  Sync com EKS       │
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │    EKS Cluster      │
                    │  Deploy automático  │
                    └────────────────────┘
```

## 📁 Estrutura

```
.
├── .github/workflows/
│   └── ci-cd.yml          # Pipeline GitHub Actions
├── k8s/
│   ├── base/              # Manifests base (Kustomize)
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── dev/           # Configurações específicas de dev
│       └── prod/          # Configurações específicas de prod
└── argocd/
    └── application.yaml   # App ArgoCD
```

## 🚀 Setup

### 1. Instalar ArgoCD no cluster
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Aplicar a Application do ArgoCD
```bash
kubectl apply -f argocd/application.yaml
```

### 3. Configurar secrets no GitHub
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `ECR_REGISTRY`

## 🔐 Segurança
- Imagens assinadas e escaneadas antes do push
- RBAC configurado no ArgoCD
- Secrets via AWS Secrets Manager + External Secrets Operator
