# AgentHub Infrastructure

Repositório centralizado de infraestrutura para o projeto AgentHub.

## 🚀 Quick Start

### Pré-requisitos
- Docker 20+
- Docker Compose 2+
- GitHub CLI (gh)

### Subir ambiente completo

```bash
# Clonar repositório
git clone git@github.com:AgentHub-Studio/agenthub-infra.git
cd agenthub-infra

# Copiar arquivo de ambiente
cd docker
cp .env.example .env

# Iniciar todos os serviços
docker-compose up -d

# Ver logs
docker-compose logs -f

# Parar todos os serviços
docker-compose down
```

## 📂 Estrutura

```
agenthub-infra/
├── docker/              # Docker Compose consolidado
├── k8s/                 # Kubernetes manifests (futuro)
├── scripts/             # Scripts de automação
├── templates/           # Templates para novos repositórios
│   ├── README.template.md
│   └── .github/workflows/
│       ├── java-ci.yml
│       ├── go-ci.yml
│       └── frontend-ci.yml
└── docs/                # Documentação
    ├── SERVICES_CONFIG.md
    ├── DEPLOYMENT.md
    ├── BRANCHING_STRATEGY.md
    └── CONVENTIONAL_COMMITS.md
```

## 🔧 Serviços

| Serviço | Porta | URL | Descrição |
|---------|-------|-----|-----------|
| Frontend | 4200 | http://localhost:4200 | Angular UI |
| Backend | 8081 | http://localhost:8081 | Spring Boot API |
| Orchestrator | 8082 | - | Pipeline execution |
| Skill Runtime | 8083 | - | Skill/tool resolution |
| Observability | 8084 | - | Traces & metrics |
| Package Registry | 8085 | - | Package management |
| Marketplace | 8086 | - | Community marketplace |
| MCP Client | 9001 | - | MCP client runtime (Go) |
| MCP Server | 9002 | - | MCP server runtime (Go) |
| PostgreSQL | 5432 | localhost:5432 | Database |
| Keycloak | 8080 | http://localhost:8080 | Auth |
| MinIO | 9000/9001 | http://localhost:9001 | Object storage |
| Ollama | 11434 | http://localhost:11434 | LLM runtime |
| RabbitMQ | 5672/15672 | http://localhost:15672 | Message broker |

## 📚 Documentação

- [SERVICES_CONFIG.md](./docs/SERVICES_CONFIG.md) - Configuração de serviços
- [DEPLOYMENT.md](./docs/DEPLOYMENT.md) - Como fazer deploy
- [BRANCHING_STRATEGY.md](./docs/BRANCHING_STRATEGY.md) - Estratégia Git
- [CONVENTIONAL_COMMITS.md](./docs/CONVENTIONAL_COMMITS.md) - Commits semânticos
- [Especificação Completa](https://github.com/AgentHub-Studio/agenthub-middleware/tree/main/docs/spec)

## 🏗️ Repositórios do Projeto

### Serviços Java
- [agenthub-backend](https://github.com/AgentHub-Studio/agenthub-backend) - Backend principal
- [agenthub-orchestrator](https://github.com/AgentHub-Studio/agenthub-orchestrator) - Pipeline execution
- [agenthub-skill-runtime](https://github.com/AgentHub-Studio/agenthub-skill-runtime) - Skill/tool resolution
- [agenthub-package-registry](https://github.com/AgentHub-Studio/agenthub-package-registry) - Package management
- [agenthub-marketplace](https://github.com/AgentHub-Studio/agenthub-marketplace) - Marketplace
- [agenthub-observability](https://github.com/AgentHub-Studio/agenthub-observability) - Observability

### Serviços Go
- [agenthub-mcp-client-runtime](https://github.com/AgentHub-Studio/agenthub-mcp-client-runtime) - MCP client
- [agenthub-mcp-server-runtime](https://github.com/AgentHub-Studio/agenthub-mcp-server-runtime) - MCP server

### Frontend
- [agenthub-frontend](https://github.com/AgentHub-Studio/agenthub-frontend) - Angular application

### Infraestrutura
- [agenthub-postgresql](https://github.com/AgentHub-Studio/agenthub-postgresql) - PostgreSQL
- [agenthub-keycloak](https://github.com/AgentHub-Studio/agenthub-keycloak) - Keycloak
- [agenthub-minio](https://github.com/AgentHub-Studio/agenthub-minio) - MinIO
- [agenthub-nginx](https://github.com/AgentHub-Studio/agenthub-nginx) - Nginx
- [agenthub-ollama](https://github.com/AgentHub-Studio/agenthub-ollama) - Ollama

## 🤝 Contribuindo

Ver [BRANCHING_STRATEGY.md](./docs/BRANCHING_STRATEGY.md) e [CONVENTIONAL_COMMITS.md](./docs/CONVENTIONAL_COMMITS.md).

## 📝 Licença

MIT License - ver [LICENSE](LICENSE)

## 📖 Links Úteis

- [Roadmap V2](https://github.com/AgentHub-Studio/agenthub-middleware/blob/main/docs/SPRINTS_V2.md)
- [Sprint Atual](https://github.com/AgentHub-Studio/agenthub-middleware/blob/main/docs/CURRENT_SPRINT_V2.md)
- [Especificação Técnica](https://github.com/AgentHub-Studio/agenthub-middleware/tree/main/docs/spec)
