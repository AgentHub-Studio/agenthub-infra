# Runbook legado de cutover

Os manifests `k3s/*/deployment-go.yaml` foram desativados. A publicação usa
exclusivamente os workloads canônicos em `k8s/`, controlados por
`scripts/build-push-go.sh`. Não reaplique os antigos deployments `*-go`.
