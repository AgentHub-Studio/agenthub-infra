#!/usr/bin/env bash
# Verificação de saúde pós-switch para serviços Go
# Usage: ./verify-health.sh [observability|skill-runtime|orchestrator|api|all]
set -euo pipefail

NAMESPACE="${NAMESPACE:-agenthub}"
TARGET="${1:-all}"
BASE_URL="${AGENTHUB_BASE_URL:-http://localhost}"
PASS=0
FAIL=0

check() {
  local name="$1"
  local cmd="$2"
  if eval "${cmd}" &>/dev/null; then
    echo "  [OK] ${name}"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] ${name}"
    FAIL=$((FAIL + 1))
  fi
}

check_pod_ready() {
  local label="$1"
  kubectl wait --for=condition=ready pod -l "${label},version=go" \
    -n "${NAMESPACE}" --timeout=30s
}

check_http() {
  local url="$1"
  curl -sf --max-time 5 "${url}" > /dev/null
}

# ─────────────────────────────────────────────
verify_observability() {
  echo ""
  echo "=== agenthub-observability ==="
  check "Pod Go Ready" "check_pod_ready app=agenthub-observability"
  check "Health endpoint" "check_http '${BASE_URL}:8086/health'"
  check "RabbitMQ consumer active" \
    "kubectl logs -l app=agenthub-observability,version=go -n ${NAMESPACE} --tail=20 | grep -q 'consumer started'"
  check "ClickHouse writer active" \
    "kubectl logs -l app=agenthub-observability,version=go -n ${NAMESPACE} --tail=20 | grep -qi 'clickhouse'"
}

verify_skill_runtime() {
  echo ""
  echo "=== agenthub-skill-runtime ==="
  check "Pod Go Ready" "check_pod_ready app=agenthub-skill-runtime"
  check "Health endpoint" "check_http '${BASE_URL}:8083/health'"
  check "No error logs" \
    "! kubectl logs -l app=agenthub-skill-runtime,version=go -n ${NAMESPACE} --tail=50 | grep -i 'panic\|fatal'"
}

verify_orchestrator() {
  echo ""
  echo "=== agenthub-orchestrator ==="
  check "Pod Go Ready" "check_pod_ready app=agenthub-orchestrator"
  check "Health endpoint" "check_http '${BASE_URL}:8084/health'"
  check "No panic in logs" \
    "! kubectl logs -l app=agenthub-orchestrator,version=go -n ${NAMESPACE} --tail=50 | grep -i 'panic\|fatal'"
}

verify_api() {
  echo ""
  echo "=== agenthub-api ==="
  check "Pod Go Ready" "check_pod_ready app=agenthub-api"
  check "Health endpoint" "check_http '${BASE_URL}:8081/health'"
  check "Public tenants endpoint" "check_http '${BASE_URL}:8081/public/tenants'"
  check "No panic in logs" \
    "! kubectl logs -l app=agenthub-api,version=go -n ${NAMESPACE} --tail=50 | grep -i 'panic\|fatal'"
  check "Database migrations applied" \
    "kubectl logs -l app=agenthub-api,version=go -n ${NAMESPACE} --tail=100 | grep -qi 'migration'"
}

# ─────────────────────────────────────────────
case "${TARGET}" in
  observability) verify_observability ;;
  skill-runtime) verify_skill_runtime ;;
  orchestrator)  verify_orchestrator ;;
  api)           verify_api ;;
  all)
    verify_observability
    verify_skill_runtime
    verify_orchestrator
    verify_api
    ;;
  *)
    echo "Usage: $0 [observability|skill-runtime|orchestrator|api|all]"
    exit 1
    ;;
esac

echo ""
echo "─────────────────────────────────"
echo "Resultado: ${PASS} OK, ${FAIL} FALHOS"
echo "─────────────────────────────────"

if [ "${FAIL}" -gt 0 ]; then
  echo "ATENÇÃO: ${FAIL} verificações falharam. Revisar antes de prosseguir com cutover."
  exit 1
fi
echo "Todas as verificações passaram."
