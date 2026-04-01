#!/usr/bin/env bash
# verify-health.sh — verifica saúde de um serviço Go antes do switch de tráfego
set -euo pipefail

SERVICE="${1:?usage: verify-health.sh <service> <version>}"
VERSION="${2:-go}"
NAMESPACE="agenthub"

# Map service name to port
case "$SERVICE" in
  api)               PORT=8081 ;;
  orchestrator)      PORT=8084 ;;
  skill-runtime)     PORT=8083 ;;
  observability)     PORT=8086 ;;
  *) echo "Unknown service: $SERVICE" && exit 1 ;;
esac

DEPLOYMENT="agenthub-${SERVICE}-${VERSION}"

echo "=== Verificando saúde de ${DEPLOYMENT} ==="

# 1. Pod running
READY=$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" \
  -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
DESIRED=$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" \
  -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 1)

if [ "${READY}" != "${DESIRED}" ]; then
  echo "FALHA: Deployment ${DEPLOYMENT} tem ${READY}/${DESIRED} replicas prontas"
  exit 1
fi
echo "OK: Deployment pronto (${READY}/${DESIRED} replicas)"

# 2. Health endpoint via port-forward (background)
POD=$(kubectl get pod -n "${NAMESPACE}" -l "app=agenthub-${SERVICE},version=${VERSION}" \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "${POD}" ]; then
  echo "FALHA: Nenhum pod encontrado para agenthub-${SERVICE} version=${VERSION}"
  exit 1
fi

LOCAL_PORT=$((PORT + 10000))
kubectl port-forward "pod/${POD}" "${LOCAL_PORT}:${PORT}" -n "${NAMESPACE}" &
PF_PID=$!
trap "kill ${PF_PID} 2>/dev/null || true" EXIT

sleep 2

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${LOCAL_PORT}/health" || echo 000)
if [ "${HTTP_STATUS}" != "200" ]; then
  echo "FALHA: /health retornou ${HTTP_STATUS} (esperado 200)"
  exit 1
fi
echo "OK: /health retornou 200"

# 3. Verificar logs por erros críticos
ERRORS=$(kubectl logs "pod/${POD}" -n "${NAMESPACE}" --tail=50 2>/dev/null | grep -ci "FATAL\|panic\|fatal error" || true)
if [ "${ERRORS}" -gt 0 ]; then
  echo "AVISO: ${ERRORS} erros críticos encontrados nos logs — verifique antes de prosseguir"
  kubectl logs "pod/${POD}" -n "${NAMESPACE}" --tail=50 | grep -i "FATAL\|panic\|fatal error"
else
  echo "OK: Nenhum erro crítico nos logs"
fi

echo ""
echo "=== ${DEPLOYMENT} SAUDÁVEL — pode prosseguir com o switch ==="
