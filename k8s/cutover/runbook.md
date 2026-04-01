# Runbook: Cutover Blue-Green Java → Go

**Versão:** 1.0
**Milestone:** fase-5-cutover
**Issue:** AgentHub-Studio/agenthub-docs#78

---

## Visão Geral

Este runbook descreve o processo de cutover incremental dos 4 serviços Java para Go usando
estratégia blue-green por serviço. Cada serviço é migrado independentemente, com janela de
monitoramento antes de prosseguir para o próximo.

### Princípios

- **Zero downtime:** switch via `kubectl patch` no Service selector (< 5s)
- **Rollback instantâneo:** reverter selector basta para voltar ao Java
- **Incremental:** um serviço por vez, janela de 24-48h entre cada um
- **Dados compatíveis:** Go e Java usam o mesmo schema PostgreSQL — rollback não perde dados

### Ordem de Migração

| Ordem | Serviço           | Risco  | Janela    | Depende de        |
|-------|-------------------|--------|-----------|-------------------|
| 1     | observability     | baixo  | 24h       | —                 |
| 2     | skill-runtime     | médio  | 24h       | observability OK  |
| 3     | orchestrator      | médio  | 24h       | skill-runtime OK  |
| 4     | api               | alto   | 48h       | orchestrator OK   |

---

## Pré-requisitos

Antes de iniciar qualquer cutover, verificar:

```bash
# 1. Todos os testes E2E passando
cd /home/cezar/desenvolvimento/agenthub-middleware/agenthub-e2e
./run-tests.sh

# 2. Todos os testes de contrato passando
cd /home/cezar/desenvolvimento/agenthub-middleware/agenthub-api
./build.sh test
cd /home/cezar/desenvolvimento/agenthub-middleware/agenthub-orchestrator
./build.sh test
cd /home/cezar/desenvolvimento/agenthub-middleware/agenthub-skill-runtime
./build.sh test
cd /home/cezar/desenvolvimento/agenthub-middleware/agenthub-observability
./build.sh test

# 3. Imagens Go buildadas e no registry
/data/desenvolvimento/infra-local/scripts/build-push.sh agenthub-observability
/data/desenvolvimento/infra-local/scripts/build-push.sh agenthub-skill-runtime
/data/desenvolvimento/infra-local/scripts/build-push.sh agenthub-orchestrator
/data/desenvolvimento/infra-local/scripts/build-push.sh agenthub-api

# 4. Estado atual do k3s salvo
kubectl get all -n agenthub -o yaml > /tmp/k3s-backup-$(date +%Y%m%d-%H%M%S).yaml

# 5. Dashboard Grafana de baseline coletado (24h antes do cutover)
# Acessar: http://grafana.agenthub.local/d/cutover-comparison
```

---

## Fase 1: Deploy Blue-Green (serviços Go ao lado dos Java)

Aplicar os manifests Go de todos os serviços **antes** de iniciar qualquer switch.
Isso garante que os pods Go estejam prontos e aquecidos antes do tráfego real.

```bash
# Deploy Go side-by-side (sem receber tráfego ainda)
kubectl apply -f k8s/cutover/blue-green/observability-go.yaml
kubectl apply -f k8s/cutover/blue-green/skill-runtime-go.yaml
kubectl apply -f k8s/cutover/blue-green/orchestrator-go.yaml
kubectl apply -f k8s/cutover/blue-green/api-go.yaml

# Aguardar todos ficarem Running
kubectl wait --for=condition=ready pod -l version=go -n agenthub --timeout=120s

# Verificar que Java ainda recebe tráfego
kubectl get svc -n agenthub -o wide
```

---

## Serviço 1: Observability

### 1.1 Verificação pré-switch

```bash
# Verificar pod Go está healthy
kubectl get pod -l app=agenthub-observability,version=go -n agenthub
kubectl logs -l app=agenthub-observability,version=go -n agenthub --tail=50

# Verificar que consome RabbitMQ
kubectl exec -it $(kubectl get pod -l app=agenthub-observability,version=go -n agenthub -o name | head -1) \
  -n agenthub -- /observability -health
```

### 1.2 Switch de tráfego

```bash
# Switch: Java → Go
kubectl patch svc agenthub-observability -n agenthub \
  -p '{"spec":{"selector":{"app":"agenthub-observability","version":"go"}}}'

# Confirmar switch
kubectl get svc agenthub-observability -n agenthub -o jsonpath='{.spec.selector}'
```

### 1.3 Monitoramento (24h)

Métricas a acompanhar no Grafana (`/d/cutover-comparison`):
- Ingestão de traces: `rate(execution_events_consumed_total[5m])` > 0
- Writes no ClickHouse: `rate(clickhouse_writes_total[5m])` > 0
- Error rate: `rate(http_requests_total{status=~"5.."}[5m])` < 0.001
- Memory: `container_memory_usage_bytes{pod=~".*observability.*"}` < 64Mi
- CPU: `container_cpu_usage_seconds_total{pod=~".*observability.*"}`

### 1.4 Decisão pós-24h

**OK → prosseguir:**
```bash
# Remover deployment Java
kubectl delete deployment agenthub-observability-java -n agenthub
```

**NOK → rollback:**
```bash
./k8s/cutover/rollback-observability.sh
```

---

## Serviço 2: Skill Runtime

### 2.1 Verificação pré-switch

```bash
kubectl get pod -l app=agenthub-skill-runtime,version=go -n agenthub
kubectl logs -l app=agenthub-skill-runtime,version=go -n agenthub --tail=50

# Testar executores
./k8s/cutover/verify-health.sh skill-runtime
```

### 2.2 Switch de tráfego

```bash
kubectl patch svc agenthub-skill-runtime -n agenthub \
  -p '{"spec":{"selector":{"app":"agenthub-skill-runtime","version":"go"}}}'
kubectl get svc agenthub-skill-runtime -n agenthub -o jsonpath='{.spec.selector}'
```

### 2.3 Monitoramento (24h)

- Latência de execução de tools: P95 < 500ms
- Error rate por tipo de executor: HTTP, SQL, DocumentSearch, MCP, Script
- Timeout rate: < 0.1%
- Memory: < 64Mi

### 2.4 Decisão pós-24h

**OK:**
```bash
kubectl delete deployment agenthub-skill-runtime-java -n agenthub
```

**NOK:**
```bash
./k8s/cutover/rollback-skill-runtime.sh
```

---

## Serviço 3: Orchestrator

### 3.1 Verificação pré-switch

```bash
kubectl get pod -l app=agenthub-orchestrator,version=go -n agenthub
kubectl logs -l app=agenthub-orchestrator,version=go -n agenthub --tail=50

# Testar pipeline simples (INPUT → LLM → OUTPUT)
./k8s/cutover/verify-health.sh orchestrator
```

### 3.2 Switch de tráfego

```bash
kubectl patch svc agenthub-orchestrator -n agenthub \
  -p '{"spec":{"selector":{"app":"agenthub-orchestrator","version":"go"}}}'
kubectl get svc agenthub-orchestrator -n agenthub -o jsonpath='{.spec.selector}'
```

### 3.3 Monitoramento (24h)

- Tempo de execução de pipelines: P95 por tipo de pipeline
- Node failures: `rate(pipeline_node_failures_total[5m])`
- DAG scheduling lag: tempo entre request e início de execução
- Pipelines com branches e loops: verificar zero regressões
- Memory: < 64Mi

### 3.4 Decisão pós-24h

**OK:**
```bash
kubectl delete deployment agenthub-orchestrator-java -n agenthub
```

**NOK:**
```bash
./k8s/cutover/rollback-orchestrator.sh
```

---

## Serviço 4: API (maior risco — janela 48h)

### 4.1 Verificação pré-switch

```bash
kubectl get pod -l app=agenthub-api,version=go -n agenthub
kubectl logs -l app=agenthub-api,version=go -n agenthub --tail=100

# Verificação abrangente (todos os módulos)
./k8s/cutover/verify-health.sh api

# Checklist manual antes do switch:
# [ ] Tenant provisioning (POST /public/tenants) funciona
# [ ] Login via Keycloak funciona
# [ ] Frontend Angular carrega e opera normalmente
# [ ] Upload de documentos para MinIO funciona
# [ ] Chat Flutter conecta e responde
# [ ] Isolamento multi-tenant verificado (testar com 2 tenants diferentes)
```

### 4.2 Switch de tráfego

```bash
# Notificar equipe antes do switch
echo "Iniciando switch agenthub-api Java → Go em $(date)" | slack-notify #ops

kubectl patch svc agenthub-api -n agenthub \
  -p '{"spec":{"selector":{"app":"agenthub-api","version":"go"}}}'
kubectl get svc agenthub-api -n agenthub -o jsonpath='{.spec.selector}'
```

### 4.3 Monitoramento (48h)

- Latência P50/P95/P99 de todos os 44+ endpoints
- Error rate: deve ser < 0.1%
- Multi-tenancy: nenhum data leak entre schemas (monitorar logs de erro de schema)
- Frontend Angular: todas as funcionalidades operando
- Chat Flutter: WebSocket stável, respostas corretas
- MinIO uploads: taxa de sucesso > 99.9%
- Keycloak integration: logins e provisioning de tenant OK
- Memory: < 128Mi (vs ~256Mi+ Java)
- Startup time: < 1s (vs 5-15s Java)

### 4.4 Decisão pós-48h

**OK — ponto de não retorno:**
```bash
kubectl delete deployment agenthub-api-java -n agenthub
kubectl delete deployment agenthub-backend -n agenthub       # nome legado
kubectl delete deployment agenthub-marketplace -n agenthub   # incorporado no api
kubectl delete deployment agenthub-package-registry -n agenthub  # incorporado no api
```

**NOK:**
```bash
./k8s/cutover/rollback-api.sh
```

---

## Pós-Cutover (após todos os 4 serviços)

### Limpeza

```bash
# Remover labels temporárias de version=java dos services
kubectl patch svc agenthub-api -n agenthub \
  -p '{"spec":{"selector":{"app":"agenthub-api"}}}'
kubectl patch svc agenthub-orchestrator -n agenthub \
  -p '{"spec":{"selector":{"app":"agenthub-orchestrator"}}}'
kubectl patch svc agenthub-skill-runtime -n agenthub \
  -p '{"spec":{"selector":{"app":"agenthub-skill-runtime"}}}'
kubectl patch svc agenthub-observability -n agenthub \
  -p '{"spec":{"selector":{"app":"agenthub-observability"}}}'

# Verificar que apenas pods Go existem
kubectl get pods -n agenthub -o wide
```

### Documentação

- [ ] Atualizar runbooks de operação (substituir comandos Java por Go)
- [ ] Atualizar dashboards Grafana (remover métricas Java)
- [ ] Atualizar CI/CD pipelines (buildar apenas imagens Go)
- [ ] Arquivar repos Java ou marcar como deprecated:
  - `agenthub-backend` → branch `archive/java-v1`
  - `agenthub-marketplace` → branch `archive/java-v1`
  - `agenthub-package-registry` → branch `archive/java-v1`
  - `agenthub-orchestrator` (Java) → tag `java-final`
  - `agenthub-skill-runtime` (Java) → tag `java-final`
  - `agenthub-observability` (Java) → tag `java-final`

### Comunicação

```
🎉 Migração Java → Go concluída com sucesso!

Todos os 4 serviços backend agora rodam em Go:
- agenthub-api (substitui backend + marketplace + registry)
- agenthub-orchestrator
- agenthub-skill-runtime
- agenthub-observability

Ganhos medidos:
- Memory: ~75% de redução (128Mi vs 512Mi por serviço)
- Startup: ~95% mais rápido (< 1s vs 5-15s)
- CPU idle: ~60% de redução
- Build time: ~80% mais rápido (imagens ~20MB vs ~200MB)
```

---

## Contatos de Emergência

| Situação              | Ação                    | Tempo máximo |
|-----------------------|-------------------------|--------------|
| Error rate > 1%       | Rollback imediato       | < 5 min      |
| Latência > 2x         | Investigar 15min → rollback | < 20 min  |
| Pod crash loop        | Rollback imediato       | < 5 min      |
| Data loss suspeito    | Rollback + freeze       | Imediato     |
| Multi-tenant leak     | Rollback + freeze       | Imediato     |

**Rollback sempre vem antes de investigação.** Disponibilidade > diagnóstico.
