#!/bin/bash
# ============================================================
# diagnose-pod.sh — Coleta diagnóstico completo de um pod
# Uso: ./diagnose-pod.sh <pod-name> <namespace>
# ============================================================

set -euo pipefail

POD="${1:?Informe o nome do pod}"
NS="${2:-default}"
OUTPUT_DIR="/tmp/diagnose-${POD}-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$OUTPUT_DIR"

echo "🔍 Coletando diagnóstico do pod: $POD (namespace: $NS)"
echo "📁 Salvando em: $OUTPUT_DIR"
echo ""

# ── Informações básicas ───────────────────────────────────────
echo "📋 [1/6] Describe do pod..."
kubectl describe pod "$POD" -n "$NS" > "$OUTPUT_DIR/describe.txt" 2>&1

# ── Logs ─────────────────────────────────────────────────────
echo "📜 [2/6] Logs atuais..."
kubectl logs "$POD" -n "$NS" --tail=200 > "$OUTPUT_DIR/logs-current.txt" 2>&1 || true

echo "📜 [3/6] Logs anteriores (antes do último crash)..."
kubectl logs "$POD" -n "$NS" --previous --tail=200 > "$OUTPUT_DIR/logs-previous.txt" 2>&1 || echo "Sem logs anteriores" > "$OUTPUT_DIR/logs-previous.txt"

# ── Status detalhado ──────────────────────────────────────────
echo "🔎 [4/6] Status JSON completo..."
kubectl get pod "$POD" -n "$NS" -o json > "$OUTPUT_DIR/pod-status.json" 2>&1

# ── Eventos do namespace ──────────────────────────────────────
echo "⚡ [5/6] Eventos recentes do namespace..."
kubectl get events -n "$NS" --sort-by='.lastTimestamp' > "$OUTPUT_DIR/events.txt" 2>&1

# ── Uso de recursos ───────────────────────────────────────────
echo "📊 [6/6] Uso de recursos..."
kubectl top pod "$POD" -n "$NS" > "$OUTPUT_DIR/resources.txt" 2>&1 || echo "Metrics server não disponível" > "$OUTPUT_DIR/resources.txt"

# ── Resumo rápido ─────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════"
echo "  RESUMO DO DIAGNÓSTICO"
echo "═══════════════════════════════════════"

# Status do pod
STATUS=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Desconhecido")
RESTARTS=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
REASON=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}' 2>/dev/null || echo "N/A")

echo "  Status:    $STATUS"
echo "  Restarts:  $RESTARTS"
echo "  Motivo:    $REASON"
echo ""
echo "  Arquivos gerados em: $OUTPUT_DIR"
echo "═══════════════════════════════════════"

# Dica baseada no motivo
case "$REASON" in
  "OOMKilled")
    echo "  💡 DICA: Container morto por falta de memória."
    echo "     Aumente o memory limit no deployment."
    ;;
  "Error")
    echo "  💡 DICA: Container saiu com erro."
    echo "     Verifique os logs em: $OUTPUT_DIR/logs-previous.txt"
    ;;
  "CrashLoopBackOff")
    echo "  💡 DICA: Container em loop de crash."
    echo "     Verifique configurações e variáveis de ambiente."
    ;;
esac
