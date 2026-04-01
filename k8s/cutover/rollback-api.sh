#!/usr/bin/env bash
# Rollback: agenthub-api Go → Java (agenthub-backend)
# Usage: ./rollback-api.sh
# NOTE: This also re-routes marketplace and package-registry traffic back to their Java services.
set -euo pipefail

NAMESPACE="${NAMESPACE:-agenthub}"

echo "[rollback] Revertendo agenthub-api para Java (agenthub-backend)..."

# Switch agenthub-api service back to Java
kubectl patch svc agenthub-api -n "${NAMESPACE}" \
  -p '{"spec":{"selector":{"app":"agenthub-api","version":"java"}}}'

# Restore marketplace and package-registry if they have separate services
if kubectl get svc agenthub-marketplace -n "${NAMESPACE}" &>/dev/null; then
  kubectl patch svc agenthub-marketplace -n "${NAMESPACE}" \
    -p '{"spec":{"selector":{"app":"agenthub-marketplace","version":"java"}}}'
  echo "[rollback] agenthub-marketplace revertido para Java"
fi

if kubectl get svc agenthub-package-registry -n "${NAMESPACE}" &>/dev/null; then
  kubectl patch svc agenthub-package-registry -n "${NAMESPACE}" \
    -p '{"spec":{"selector":{"app":"agenthub-package-registry","version":"java"}}}'
  echo "[rollback] agenthub-package-registry revertido para Java"
fi

echo "[rollback] Verificando selector agenthub-api:"
kubectl get svc agenthub-api -n "${NAMESPACE}" -o jsonpath='{.spec.selector}' && echo

echo "[rollback] Verificando pods Java:"
kubectl get pods -l "version=java" -n "${NAMESPACE}"

echo ""
echo "[rollback] IMPORTANTE: Rollback concluído."
echo "  O serviço Go permanece deployado mas sem tráfego."
echo "  Verifique logs antes de investigar: kubectl logs -l app=agenthub-api,version=java -n ${NAMESPACE} --tail=100"
echo ""
echo "[rollback] NOTIFIQUE A EQUIPE sobre o rollback e o motivo."
