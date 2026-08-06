#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
    echo "ERRO: $*" >&2
    exit 1
}

require_file() {
    [[ -f "${INFRA_DIR}/$1" ]] || fail "manifesto canônico ausente: $1"
}

require_file "k8s/services-go.yaml"
require_file "k8s/workloads/agenthub-mcp-client-runtime.yaml"

legacy_manifests="$(find "${INFRA_DIR}/k3s" -type f -name 'deployment-go.yaml' -print 2>/dev/null; find "${INFRA_DIR}/k8s/cutover/blue-green" -type f \( -name '*.yaml' -o -name '*.yml' \) -print 2>/dev/null || true)"
[[ -z "${legacy_manifests}" ]] || fail "manifestos de controlador legados encontrados: ${legacy_manifests}"

if rg -n '^[[:space:]]*image:[[:space:]]+registry\.cezar\.dev/[^[:space:]]+:latest([[:space:]]|$)' "${INFRA_DIR}/k8s"; then
	fail "imagem AgentHub :latest não é permitida em manifesto de publicação"
fi

duplicate_deployments="$(
    find "${INFRA_DIR}/k8s" \( -path "${INFRA_DIR}/k8s/overlays" -o -path "${INFRA_DIR}/k8s/cutover" \) -prune -o -type f \( -name '*.yaml' -o -name '*.yml' \) -print0 |
        xargs -0 awk '
            /^kind: Deployment$/ { waiting_metadata=1; next }
            waiting_metadata && /^metadata:$/ { waiting_name=1; next }
            waiting_name && /^  name: / { print $2; waiting_metadata=0; waiting_name=0; next }
        ' |
        sort | uniq -d
)"
[[ -z "${duplicate_deployments}" ]] || fail "deployments duplicados: ${duplicate_deployments}"

if [[ "${1:-}" == "--workspace" ]]; then
    [[ -n "${2:-}" ]] || fail "informe o diretório do workspace após --workspace"
    WORKSPACE_DIR="$(cd "$2" && pwd)"
    outside_manifests="$(
        find "${WORKSPACE_DIR}" -mindepth 3 -maxdepth 3 -type f \( -name '*.yaml' -o -name '*.yml' \) \
            ! -path "${INFRA_DIR}/*" ! -path '*/agenthub-e2e-harness/*' -print0 |
            xargs -0 rg -l '^kind: (Deployment|StatefulSet|DaemonSet|Service|Ingress|NetworkPolicy|ConfigMap|Secret)$' 2>/dev/null || true
    )"
    [[ -z "${outside_manifests}" ]] || fail "manifestos de publicação fora de agenthub-infra: ${outside_manifests}"
fi

echo "Layout de publicação válido: agenthub-infra é o único controlador."

