#!/usr/bin/env bash
# Build, push para registry local e redeploy no k3s — servicos Go
# Uso: ./build-push-go.sh <service-name>
# Ex.: ./build-push-go.sh agenthub-api

set -euo pipefail

SERVICE="${1:-}"
if [[ -z "$SERVICE" ]]; then
    echo "Uso: $0 <service>"
    echo "Servicos Go: agenthub-api agenthub-orchestrator agenthub-skill-runtime agenthub-observability"
    exit 1
fi

REGISTRY="${REGISTRY:-registry.local}"
TAG="${TAG:-latest}"
IMAGE="${REGISTRY}/${SERVICE}:${TAG}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(cd "${SCRIPT_DIR}/../../${SERVICE}" && pwd)"

if [[ ! -f "${SERVICE_DIR}/Dockerfile" ]]; then
    echo "Erro: Dockerfile nao encontrado em ${SERVICE_DIR}"
    exit 1
fi

echo "==> Buildando ${SERVICE}..."
docker build -t "${IMAGE}" "${SERVICE_DIR}"

echo "==> Pushing ${IMAGE}..."
docker push "${IMAGE}"

echo "==> Redeployando no k3s..."
kubectl rollout restart deployment/"${SERVICE}" -n agenthub
kubectl rollout status deployment/"${SERVICE}" -n agenthub --timeout=120s

echo "==> ${SERVICE} deployado com sucesso!"
