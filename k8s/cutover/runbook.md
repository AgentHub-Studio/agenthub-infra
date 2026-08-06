# Runbook de cutover consolidado

Os deployments temporários `*-go` foram removidos. A publicação usa os
workloads canônicos em `k8s/services-go.yaml` e `k8s/workloads/`; o script
`scripts/build-push-go.sh` atualiza apenas esses deployments. Os scripts de
rollback históricos não devem ser executados até serem reescritos para o
controlador canônico e validados em ambiente não produtivo.
