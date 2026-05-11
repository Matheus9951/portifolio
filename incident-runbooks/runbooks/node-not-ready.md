# 🔴 Runbook: Node com Status NotReady

**Severidade:** P1 — Crítico  
**Tempo médio de resolução:** 20–45 min

---

## 1. Detecção

```
ALERT: KubeNodeNotReady
node=<node-name>
```

---

## 2. Diagnóstico

### 2.1 Identificar o node problemático
```bash
kubectl get nodes
kubectl describe node <node-name>
```
Procure em `Conditions:` o motivo do NotReady (DiskPressure, MemoryPressure, NetworkUnavailable, etc.)

### 2.2 Verificar pods afetados
```bash
kubectl get pods --all-namespaces --field-selector spec.nodeName=<node-name>
```

### 2.3 Verificar uso de recursos no node
```bash
kubectl top node <node-name>
```

### 2.4 Verificar logs do kubelet via SSM (sem SSH)
```bash
# Conectar na instância via SSM
aws ssm start-session --target <instance-id>

# Dentro da instância:
sudo journalctl -u kubelet -n 100 --no-pager
sudo systemctl status kubelet
```

---

## 3. Resolução

### Caso: DiskPressure (disco cheio)
```bash
# Dentro do node via SSM:
df -h
# Limpar imagens Docker não utilizadas
sudo docker system prune -f
# Ou com containerd:
sudo crictl rmi --prune
```

### Caso: MemoryPressure
```bash
# Verificar processos consumindo memória
sudo top -b -n 1 | head -20
# Reiniciar kubelet
sudo systemctl restart kubelet
```

### Caso: Kubelet parado
```bash
sudo systemctl restart kubelet
sudo systemctl status kubelet
```

### Caso: Node irrecuperável — drenar e substituir
```bash
# Drenar o node (move pods para outros nodes)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Marcar como não agendável enquanto investiga
kubectl cordon <node-name>

# Se for node group EKS — terminar a instância (ASG sobe outra)
aws ec2 terminate-instances --instance-ids <instance-id>

# Após novo node subir, verificar
kubectl get nodes
```

---

## 4. Verificação pós-resolução
```bash
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running | grep -v Completed
```

---

## 5. Prevenção

- [ ] Configurar alertas de DiskPressure antes de atingir 85%
- [ ] Habilitar node auto-repair no EKS node group
- [ ] Configurar PodDisruptionBudget para garantir disponibilidade durante drenos
- [ ] Revisar política de retenção de imagens no containerd
