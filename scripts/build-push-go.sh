#!/usr/bin/env bash

set -euo pipefail

SERVICE="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMMONS_DIR="${WORKSPACE_DIR}/agenthub-go-commons"
NAMESPACE="${NAMESPACE:-agenthub}"
REGISTRY="${REGISTRY:-registry.cezar.dev}"
DRY_RUN="${DRY_RUN:-0}"

usage() {
    echo "Uso: $0 <service>"
    echo "Servicos Go: agenthub-api agenthub-orchestrator agenthub-skill-runtime agenthub-observability"
}

case "$SERVICE" in
    agenthub-api)
        DEPLOYMENT="agenthub-api"
        CONTAINER="agenthub-api"
        ;;
    agenthub-orchestrator)
        DEPLOYMENT="agenthub-orchestrator"
        CONTAINER="agenthub-orchestrator"
        ;;
    agenthub-skill-runtime)
        DEPLOYMENT="agenthub-skill-runtime"
        CONTAINER="agenthub-skill-runtime"
        ;;
    agenthub-observability)
        DEPLOYMENT="agenthub-observability"
        CONTAINER="agenthub-observability"
        ;;
    "")
        usage
        exit 1
        ;;
    *)
        echo "Erro: servico Go desconhecido: ${SERVICE}" >&2
        usage >&2
        exit 1
        ;;
esac

SERVICE_DIR="${WORKSPACE_DIR}/${SERVICE}"

if [[ ! -f "${SERVICE_DIR}/Dockerfile" ]]; then
    echo "Erro: Dockerfile nao encontrado em ${SERVICE_DIR}"
    exit 1
fi

if ! git -C "${SERVICE_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Erro: ${SERVICE_DIR} nao e um repositorio git independente" >&2
    exit 1
fi

if [[ -z "${TAG:-}" ]]; then
    TAG="$(git -C "${SERVICE_DIR}" rev-parse --short=12 HEAD)"
fi

if [[ "${TAG}" == "latest" ]]; then
    echo "Erro: TAG=latest nao e permitido para deploy. Use uma tag imutavel, como o SHA do commit." >&2
    exit 1
fi

if [[ ! "${TAG}" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$ ]]; then
    echo "Erro: TAG invalida: ${TAG}" >&2
    exit 1
fi

OCI_CREATED="${OCI_CREATED:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
OCI_REVISION="${OCI_REVISION:-$(git -C "${SERVICE_DIR}" rev-parse HEAD)}"
OCI_SOURCE="${OCI_SOURCE:-https://github.com/AgentHub-Studio/${SERVICE}}"
OCI_VERSION="${OCI_VERSION:-${TAG}}"
IMAGE="${REGISTRY}/${SERVICE}:${TAG}"

run() {
    if [[ "${DRY_RUN}" == "1" ]]; then
        printf '+'
        for arg in "$@"; do
            printf ' %q' "$arg"
        done
        printf '\n'
    else
        "$@"
    fi
}

build_cmd=(
    docker build
    --build-arg "OCI_CREATED=${OCI_CREATED}"
    --build-arg "OCI_REVISION=${OCI_REVISION}"
    --build-arg "OCI_SOURCE=${OCI_SOURCE}"
    --build-arg "OCI_VERSION=${OCI_VERSION}"
    -t "${IMAGE}"
)

if grep -q 'COPY --from=gocommons' "${SERVICE_DIR}/Dockerfile"; then
    if [[ ! -d "${COMMONS_DIR}" ]]; then
        echo "Erro: agenthub-go-commons nao encontrado em ${COMMONS_DIR}" >&2
        exit 1
    fi
    build_cmd+=(--build-context "gocommons=${COMMONS_DIR}")
fi

build_cmd+=("${SERVICE_DIR}")

echo "==> Buildando ${IMAGE}..."
run "${build_cmd[@]}"

echo "==> Pushing ${IMAGE}..."
run docker push "${IMAGE}"

echo "==> Atualizando imagem do deployment ${DEPLOYMENT} no k3s..."
run kubectl set image "deployment/${DEPLOYMENT}" "${CONTAINER}=${IMAGE}" -n "${NAMESPACE}"
run kubectl rollout status "deployment/${DEPLOYMENT}" -n "${NAMESPACE}" --timeout=120s

echo "==> ${SERVICE} deployado com imagem ${IMAGE}"
