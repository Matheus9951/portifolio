# 🔴 Runbook: Pod em CrashLoopBackOff

**Severidade:** P2 — Alto  
**Tempo médio de resolução:** 15–30 min

---

## 1. Detecção

O alerta é disparado quando um pod reinicia mais de 5 vezes em 10 minutos.

```
ALERT: KubePodCrashLooping
namespace=<namespace>, pod=<pod-name>
```

---

## 2. Diagnóstico

### 2.1 Verificar o estado do pod
```bash
kubectl get pod <pod-name> -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```
Procure em `Events:` a causa do crash (OOMKilled, Error, etc.)

### 2.2 Ver logs do container que está crashando
```bash
# Logs do container atual
kubectl logs <pod-name> -n <namespace>

# Logs do container anterior (antes do último crash)
kubectl logs <pod-name> -n <namespace> --previous
```

### 2.3 Verificar se é OOMKilled (falta de memória)
```bash
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.status.containerStatuses[*].lastState.terminated.reason}'
```
Se retornar `OOMKilled` → o container está sendo morto por falta de memória.

### 2.4 Verificar eventos recentes no namespace
```bash
kubectl get events -n <namespace> --sort-by='.lastTimestamp' | tail -20
```

---

## 3. Resolução

### Caso: OOMKilled
```bash
# Aumentar o memory limit do deployment
kubectl set resources deployment <deployment-name> \
  -n <namespace> \
  --limits=memory=512Mi \
  --requests=memory=256Mi
```

### Caso: Erro de configuração (variável de ambiente / secret ausente)
```bash
# Verificar se o secret existe
kubectl get secret <secret-name> -n <namespace>

# Verificar se o configmap existe
kubectl get configmap <configmap-name> -n <namespace>
```

### Caso: Imagem inválida ou não encontrada
```bash
# Verificar se a imagem existe no ECR
aws ecr describe-images \
  --repository-name <repo-name> \
  --image-ids imageTag=<tag>
```

### Caso: Liveness probe muito agressiva
```bash
# Editar o deployment para aumentar initialDelaySeconds
kubectl edit deployment <deployment-name> -n <namespace>
# Aumentar: initialDelaySeconds de 10 para 60
```

---

## 4. Verificação pós-resolução
```bash
# Confirmar que o pod está Running e estável
kubectl get pod <pod-name> -n <namespace> -w

# Verificar que não há mais restarts
kubectl get pod <pod-name> -n <namespace> \
  -o jsonpath='{.status.containerStatuses[*].restartCount}'
```

---

## 5. Prevenção

- [ ] Configurar memory requests e limits adequados (use VPA para recomendações)
- [ ] Ajustar liveness/readiness probes com `initialDelaySeconds` adequado
- [ ] Adicionar health check na aplicação (`/health`, `/ready`)
- [ ] Configurar alertas de memória antes de atingir o limite
