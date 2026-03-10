# AgentHub Infrastructure

Repositório centralizado de infraestrutura para o projeto AgentHub.

## 🚀 Quick Start

### Prerequisites
- Docker 20+
- Docker Compose 2.20+ (with profiles support)
- GitHub CLI (gh) - for repository management

### First Time Setup

```bash
# Clone repository
git clone git@github.com:AgentHub-Studio/agenthub-infra.git
cd agenthub-infra

# Create environment file
cp .env.example .env

# Edit .env and update the values (especially passwords!)
nano .env

# Create external Docker network
docker network create agenthub-shared-net

# Start minimal infrastructure (fastest way to get started)
./scripts/start minimal
```

### Docker Compose Profiles

This repository uses Docker Compose **profiles** for granular control over which services run:

| Profile | Services | Use Case |
|---------|----------|----------|
| `minimal` | Infrastructure only (5 services) | Database, auth, storage, messaging |
| `backend` | Infrastructure + app (7 services) | Full stack development |
| `full` | All services (18 services) | Complete platform testing |
| `edge` | Backend + edge services (9 services) | Testing with Nginx + Cloudflare |

**Services by profile:**

- **minimal**: postgres, keycloak, minio, ollama, rabbitmq
- **backend**: minimal + backend + frontend
- **full**: backend + all microservices (orchestrator, skill-runtime, mcp runtimes, etc.)
- **edge**: backend + nginx + cloudflare

### Using Helper Scripts

```bash
# Start services with a specific profile
./scripts/start minimal    # Just infrastructure
./scripts/start backend    # Infrastructure + backend + frontend
./scripts/start full       # All 18 services
./scripts/start edge       # With Nginx + Cloudflare

# View logs
./scripts/logs             # All services
./scripts/logs backend     # Specific service
./scripts/logs backend -f  # Follow logs

# Check status
./scripts/status           # Service status + resource usage

# Stop services
./scripts/stop             # Stop all services
./scripts/stop backend     # Stop specific profile
```

### Development Mode (Hot-Reload)

For development with hot-reload enabled:

```bash
# Start with development overrides
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile backend up

# This enables:
# - Angular hot-reload (frontend)
# - Spring Boot DevTools (Java services)
# - Air hot-reload (Go services)
```

### Direct Docker Compose Usage

If you prefer using docker compose directly:

```bash
# Start with a profile
COMPOSE_PROFILES=minimal docker compose up -d

# Or use --profile flag (Docker Compose v2.20+)
docker compose --profile backend up -d

# Stop services
docker compose down

# View logs
docker compose logs -f backend
```

## 📂 Repository Structure

```
agenthub-infra/
├── docker-compose.yml       # Main compose file with profiles
├── docker-compose.dev.yml   # Development overrides (hot-reload)
├── .env.example             # Environment variables template
├── scripts/                 # Helper scripts
│   ├── start               # Start services by profile
│   ├── stop                # Stop services
│   ├── logs                # View logs
│   └── status              # Check service status
├── templates/              # Templates for new repositories
│   ├── .gitignore.java     # Java gitignore
│   ├── .gitignore.go       # Go gitignore
│   └── .github/workflows/
│       ├── java-ci.yml     # Java CI/CD template
│       └── go-ci.yml       # Go CI/CD template
├── docker/                 # Future: isolated configs
├── k8s/                    # Future: Kubernetes manifests
└── docs/                   # Documentation
    └── (future docs)
```

## 🔧 Services Overview

### Infrastructure (minimal profile)

| Service | Port | URL | Description |
|---------|------|-----|-------------|
| PostgreSQL | 5432 | localhost:5432 | Primary database |
| Keycloak | 8080 | http://localhost:8080 | Authentication & authorization |
| MinIO | 9000/9001 | http://localhost:9001 | S3-compatible object storage |
| Ollama | 11434 | http://localhost:11434 | Local LLM runtime |
| RabbitMQ | 5672/15672 | http://localhost:15672 | Message broker |

### Application (backend profile)

| Service | Port | URL | Description |
|---------|------|-----|-------------|
| Frontend | 4200 | http://localhost:4200 | Angular UI |
| Backend | 8081 | http://localhost:8081 | Spring Boot API |

### Microservices (full profile)

| Service | Port | Description |
|---------|------|-------------|
| Orchestrator | 8082 | Pipeline execution engine (Java) |
| Skill Runtime | 8083 | Skill/tool resolution (Java) |
| Package Registry | 8084 | Package management (Java) |
| Marketplace | 8085 | Community marketplace (Java) |
| Observability | 8086 | Traces & metrics (Java) |
| MCP Client Runtime | 8090 | MCP client runtime (Go) |
| MCP Server Runtime | 8091 | MCP server runtime (Go) |
| Embedding | 8092 | Embedding service (Go) |
| Embedding Job | - | Background embedding jobs (Go) |
| Extractor | 8093 | Content extraction (Go) |
| Graph Generator | 8094 | Knowledge graph generation (Go) |
| VPN Proxy | 8095 | VPN proxy service (Go) |

### Edge (edge profile)

| Service | Port | Description |
|---------|------|-------------|
| Nginx | 80/443 | Reverse proxy |
| Cloudflare | - | Cloudflare tunnel |

## ⚙️ Environment Variables

All environment variables are documented in `.env.example`. Key variables to configure:

```bash
# Database
POSTGRES_PASSWORD=changeme_secure_password

# Keycloak
KEYCLOAK_ADMIN_PASSWORD=changeme_admin_password

# MinIO
MINIO_ROOT_PASSWORD=changeme_minio_password

# RabbitMQ
RABBITMQ_DEFAULT_PASS=changeme_rabbitmq_password

# Cloudflare (only for edge profile)
CLOUDFLARE_TUNNEL_TOKEN=changeme_tunnel_token
```

**IMPORTANT**: Never commit the `.env` file! It contains sensitive credentials.

## 🔍 Troubleshooting

### Network Issues

```bash
# Create the external network if it doesn't exist
docker network create agenthub-shared-net

# Check if network exists
docker network ls | grep agenthub
```

### Service Won't Start

```bash
# Check service logs
./scripts/logs <service-name>

# Check service status
./scripts/status

# Restart a specific service
docker compose restart <service-name>
```

### Port Conflicts

If you get port binding errors:

```bash
# Check what's using the port
lsof -i :8081

# Stop conflicting services or change ports in .env
```

### Reset Everything

```bash
# Stop all services and remove volumes
docker compose down -v

# Remove network
docker network rm agenthub-shared-net

# Start fresh
docker network create agenthub-shared-net
./scripts/start minimal
```

## 📚 Documentation

- [Full Specification](https://github.com/AgentHub-Studio/agenthub-middleware/tree/main/docs/spec) - Complete technical spec
- Future docs (coming soon):
  - SERVICES_CONFIG.md - Service configuration guide
  - DEPLOYMENT.md - Deployment guide
  - BRANCHING_STRATEGY.md - Git workflow
  - CONVENTIONAL_COMMITS.md - Commit message conventions

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

### Infraestrutura & Suporte
- [agenthub-postgresql](https://github.com/AgentHub-Studio/agenthub-postgresql) - PostgreSQL
- [agenthub-keycloak](https://github.com/AgentHub-Studio/agenthub-keycloak) - Keycloak
- [agenthub-minio](https://github.com/AgentHub-Studio/agenthub-minio) - MinIO
- [agenthub-nginx](https://github.com/AgentHub-Studio/agenthub-nginx) - Nginx
- [agenthub-ollama](https://github.com/AgentHub-Studio/agenthub-ollama) - Ollama
- [agenthub-embedding](https://github.com/AgentHub-Studio/agenthub-embedding) - Embedding service
- [agenthub-embedding-job](https://github.com/AgentHub-Studio/agenthub-embedding-job) - Embedding job (Go)
- [agenthub-extractor](https://github.com/AgentHub-Studio/agenthub-extractor) - Document extractor
- [agenthub-graph-generator](https://github.com/AgentHub-Studio/agenthub-graph-generator) - Graph generator
- [agenthub-vpn-proxy](https://github.com/AgentHub-Studio/agenthub-vpn-proxy) - VPN proxy (Go)
- [agenthub-cloudflare](https://github.com/AgentHub-Studio/agenthub-cloudflare) - Cloudflare integration

## 🤝 Contribuindo

Ver [BRANCHING_STRATEGY.md](./docs/BRANCHING_STRATEGY.md) e [CONVENTIONAL_COMMITS.md](./docs/CONVENTIONAL_COMMITS.md).

## 📝 Licença

MIT License - ver [LICENSE](LICENSE)

## 📖 Links Úteis

- [Roadmap V2](https://github.com/AgentHub-Studio/agenthub-middleware/blob/main/docs/SPRINTS_V2.md)
- [Sprint Atual](https://github.com/AgentHub-Studio/agenthub-middleware/blob/main/docs/CURRENT_SPRINT_V2.md)
- [Especificação Técnica](https://github.com/AgentHub-Studio/agenthub-middleware/tree/main/docs/spec)
