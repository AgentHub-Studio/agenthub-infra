#!/usr/bin/env bash
# Rollback: agenthub-orchestrator Go → Java
# Usage: ./rollback-orchestrator.sh
set -euo pipefail

NAMESPACE="${NAMESPACE:-agenthub}"
SERVICE="agenthub-orchestrator"

echo "[rollback] Revertendo ${SERVICE} para Java..."
kubectl patch svc "${SERVICE}" -n "${NAMESPACE}" \
  -p '{"spec":{"selector":{"app":"agenthub-orchestrator","version":"java"}}}'

echo "[rollback] Verificando selector atual:"
kubectl get svc "${SERVICE}" -n "${NAMESPACE}" -o jsonpath='{.spec.selector}' && echo

echo "[rollback] Verificando pods Java:"
kubectl get pods -l "app=${SERVICE},version=java" -n "${NAMESPACE}"

echo "[rollback] Rollback concluído. Verifique os logs do pod Java:"
echo "  kubectl logs -l app=${SERVICE},version=java -n ${NAMESPACE} --tail=50"
