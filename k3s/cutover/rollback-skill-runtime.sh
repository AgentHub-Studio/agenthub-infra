#!/usr/bin/env bash
# rollback-skill-runtime.sh — reverte tráfego do agenthub-skill-runtime de Go para Java
set -euo pipefail

NAMESPACE="agenthub"
SERVICE="agenthub-skill-runtime"

echo "=== ROLLBACK: ${SERVICE} Go → Java ==="
echo "Alterando selector do Service para version=java..."

kubectl patch svc "${SERVICE}" -n "${NAMESPACE}" \
  -p '{"spec":{"selector":{"app":"'"${SERVICE}"'","version":"java"}}}'

echo "OK: Tráfego revertido para Java"
echo "Verificando pods Java ativos..."
kubectl get pods -n "${NAMESPACE}" -l "app=${SERVICE},version=java"
