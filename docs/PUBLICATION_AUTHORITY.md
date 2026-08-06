# Autoridade de publicação

`agenthub-infra` é o único repositório autorizado a publicar workloads
Kubernetes do AgentHub. Os repositórios de aplicação produzem imagens e não
devem conter manifestos publicáveis nem executar `kubectl`.

## Fonte canônica

- `k8s/services-go.yaml`: API, orchestrator, skill runtime e observability.
- `k8s/workloads/`: workloads que não pertencem ao arquivo agrupado, incluindo
  os runtimes MCP.
- `k8s/overlays/`: variações de ambiente que também são publicadas por este
  repositório.
- `scripts/build-push-go.sh`: fluxo de build, push e rollout dos workloads Go
  canônicos. Imagens AgentHub precisam usar tag imutável; `latest` é rejeitada.

Os diretórios `k3s/agenthub-*/deployment-go.yaml` e
`k8s/cutover/blue-green/` foram desativados para não criar um segundo
controlador. Não os recrie.

## Contrato Keycloak para o MCP client runtime

1. A API solicita por client credentials um token de serviço no realm do
   tenant.
2. O token precisa ter `azp=agenthub-api` e audiência
   `agenthub-mcp-client-runtime`.
3. O runtime consulta o JWKS do Keycloak, valida assinatura, expiração,
   emissor, audiência e cliente; depois extrai o tenant do realm em `iss`.
4. `tenantId` em query string e `X-Tenant-ID` não participam da autorização.
   O bearer do usuário não é encaminhado para o runtime.

Pré-requisito operacional por realm: o provisionador da API cria o cliente
confidencial `agenthub-api`, com service account habilitada, fluxos de usuário
desabilitados e audience mapper para `agenthub-mcp-client-runtime`. Cada realm
recebe um client secret aleatório e distinto. Esse segredo nunca é um único
valor no Kubernetes: fica cifrado em
`public.tenant_workload_credential` e só é decifrado pela API durante o grant
`client_credentials` daquele tenant.

O único segredo compartilhado é a chave de cifragem
`agenthub-secrets/mcp-runtime-credential-encryption-key`, exposta à API como
`MCP_RUNTIME_CREDENTIAL_ENCRYPTION_KEY`. Ela deve conter uma chave AES-256
aleatória de 32 bytes codificada em Base64, por exemplo:

```bash
openssl rand -base64 32
```

Não crie nem use `mcp-runtime-api-client-secret`: ele representaria uma
credencial comum a todos os tenants e viola este contrato.

### Backfill de realms existentes

Após a publicação da migração pública `000019_tenant_workload_credentials` e
depois de cadastrar a chave de cifragem, um operador autorizado deve executar
uma única vez o binário `/migrate-workload-identities` da mesma imagem da API,
com as variáveis de ambiente da API. O comando é idempotente: cria ou repara o
cliente de workload, verifica o audience mapper e grava a credencial cifrada
por tenant. Ele não deve ser disparado automaticamente por rollout. Revise os
logs por `tenantID`; o comando termina com erro se algum tenant não sincronizar.

## Gate

`scripts/validate-publication-layout.sh` é executado no CI do
`agenthub-infra`. Ele bloqueia manifests legados, imagens `:latest` e nomes de
deployment duplicados. Na migração coordenada, use também:

```bash
bash scripts/validate-publication-layout.sh --workspace /caminho/agenthub-middleware
```

Esse modo impede que um manifesto publicável permaneça fora do repositório de
infra. Os manifests do `agenthub-e2e-harness` são fixtures de teste e ficam
fora desse contrato.
