# Runbook de Cutover — Java → Go (Blue-Green por Serviço)

**Estratégia:** Blue-green por serviço via `kubectl patch` no selector do Service k3s
**Rollback:** < 5 segundos (apenas altera selector)
**Ordem de migração:** Observability → Skill Runtime → Orchestrator → API

---

## Pré-requisitos

Antes de iniciar qualquer cutover, verificar:

```bash
# 1. Testes de contrato passando
cd agenthub-api && CONTRACT_TESTS=1 GO_URL=http://localhost:8081 go test ./contracts/...

# 2. Todos os pods Go saudáveis
kubectl get pods -n agenthub -l version=go

# 3. Manifests Java renomeados e backups em ordem
ls k3s/*/deployment-java.yaml

# 4. Dashboards Grafana abertos e monitorando
# Importar k3s/grafana/cutover-dashboard.json no Grafana
```

---

## Serviço 1: agenthub-observability

**Risco:** Baixo — apenas consome eventos RabbitMQ e escreve no ClickHouse

### Deploy do deployment Go

```bash
kubectl apply -f k3s/agenthub-observability/deployment-go.yaml
kubectl rollout status deployment/agenthub-observability-go -n agenthub
```

### Verificação pré-switch

```bash
./k3s/cutover/verify-health.sh observability go
```

### Switch de tráfego (⚠️ notificar equipe antes)

```bash
kubectl patch svc agenthub-observability -n agenthub \
  -p '{"spec":{"selector":{"app":"agenthub-observability","version":"go"}}}'
```

### Monitoramento (24h)

- Taxa de ingestão de traces (ClickHouse)
- Erros no consumer RabbitMQ
- Memory/CPU do pod Go vs baseline Java

### Rollback (se necessário)

```bash
./k3s/cutover/rollback-observability.sh
```

### Pós-cutover estável (72h)

```bash
kubectl delete deployment agenthub-observability-java -n agenthub
```

---

## Serviço 2: agenthub-skill-runtime

**Risco:** Médio — executa tools (HTTP, SQL, DocumentSearch, MCP, Script)

### Deploy do deployment Go

```bash
kubectl apply -f k3s/agenthub-skill-runtime/deployment-go.yaml
kubectl rollout status deployment/agenthub-skill-runtime-go -n agenthub
```

### Verificação pré-switch

```bash
./k3s/cutover/verify-health.sh skill-runtime go
# Testar cada executor manualmente:
# - HTTP tool
# - SQL tool
# - DocumentSearch tool
```

### Switch de tráfego

```bash
kubectl patch svc agenthub-skill-runtime -n agenthub \
  -p '{"spec":{"selector":{"app":"agenthub-skill-runtime","version":"go"}}}'
```

### Rollback

```bash
./k3s/cutover/rollback-skill-runtime.sh
```

---

## Serviço 3: agenthub-orchestrator

**Risco:** Médio-alto — executa DAGs de pipelines

### Deploy do deployment Go

```bash
kubectl apply -f k3s/agenthub-orchestrator/deployment-go.yaml
kubectl rollout status deployment/agenthub-orchestrator-go -n agenthub
```

### Verificação pré-switch

```bash
./k3s/cutover/verify-health.sh orchestrator go
# Executar um agent simples end-to-end antes do switch
```

### Switch de tráfego

```bash
kubectl patch svc agenthub-orchestrator -n agenthub \
  -p '{"spec":{"selector":{"app":"agenthub-orchestrator","version":"go"}}}'
```

### Rollback

```bash
./k3s/cutover/rollback-orchestrator.sh
```

---

## Serviço 4: agenthub-api (⚠️ maior risco — user-facing)

**Risco:** Alto — 44+ endpoints, frontend Angular depende diretamente
**Janela de monitoramento:** 48h (vs 24h para serviços internos)

### Deploy do deployment Go

```bash
kubectl apply -f k3s/agenthub-api/deployment-go.yaml
kubectl rollout status deployment/agenthub-api-go -n agenthub
```

### Verificação pré-switch

```bash
./k3s/cutover/verify-health.sh api go
# Verificar todos os endpoint groups via testes de contrato
CONTRACT_TESTS=1 GO_URL=http://<go-service-internal>:8081 go test ./contracts/...
```

### Switch de tráfego

```bash
kubectl patch svc agenthub-api -n agenthub \
  -p '{"spec":{"selector":{"app":"agenthub-api","version":"go"}}}'
# Monitorar imediatamente por 30 minutos
```

### Rollback

```bash
./k3s/cutover/rollback-api.sh
```

---

## Critérios de Sucesso

| Métrica | Threshold |
|---------|-----------|
| Latência P95 | ≤ baseline Java |
| Error rate (5xx) | < 0.1% |
| Memory por pod | < 128 MB (vs ~256 MB Java) |
| Startup time | < 1s (vs 5-15s Java) |
| Disponibilidade | 100% (zero downtime) |

---

## Ponto de Não Retorno

Após 72h de operação estável com Go, executar limpeza:

```bash
# Remover deployments Java
kubectl delete deployment agenthub-observability-java -n agenthub
kubectl delete deployment agenthub-skill-runtime-java -n agenthub
kubectl delete deployment agenthub-orchestrator-java -n agenthub
kubectl delete deployment agenthub-api-java -n agenthub

# Arquivar manifests Java (manter em branch archive/)
git checkout -b archive/java-services
git add k3s/*/deployment-java.yaml
git commit -m "archive: guardar manifests Java dos serviços migrados"
git push origin archive/java-services
```
