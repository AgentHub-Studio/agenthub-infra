FROM docker.io/library/golang@sha256:b305420a68d0f229d91eb3b3ed9e519fcf2cf5461da4bef997bf927e8c0bfd2b AS ollama-builder

ARG OLLAMA_VERSION="v0.30.11"
ARG OLLAMA_COMMIT="d26a58557d83aa8892bdfa79b3550f5ee969cd1c"

ENV PATH="/usr/local/go/bin:${PATH}"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends git ca-certificates build-essential binutils; \
    rm -rf /var/lib/apt/lists/*; \
    git clone --depth 1 --branch "${OLLAMA_VERSION}" https://github.com/ollama/ollama.git /src/ollama; \
    cd /src/ollama; \
    test "$(git rev-parse HEAD)" = "${OLLAMA_COMMIT}"; \
    go get github.com/buger/jsonparser@v1.1.2 golang.org/x/crypto@v0.52.0 golang.org/x/net@v0.55.0; \
    ollama_version_number="${OLLAMA_VERSION#v}"; \
    CGO_ENABLED=1 go build -trimpath \
      -ldflags="-w -s -X=github.com/ollama/ollama/version.Version=${ollama_version_number} -X=github.com/ollama/ollama/server.mode=release" \
      -o /out/ollama .; \
    /out/ollama --version 2>&1 | grep -F "${ollama_version_number}"; \
    go version -m /out/ollama | grep -F "go1.26.4"; \
    go version -m /out/ollama | grep -F "github.com/buger/jsonparser"; \
    go version -m /out/ollama | grep -F "v1.1.2"; \
    go version -m /out/ollama | grep -F "golang.org/x/crypto"; \
    go version -m /out/ollama | grep -F "v0.52.0"; \
    go version -m /out/ollama | grep -F "golang.org/x/net"; \
    go version -m /out/ollama | grep -F "v0.55.0"

FROM ollama/ollama@sha256:c484b703176aa19dfc0a54cbfb60ab8094b38faa04283fb77eba1d33319e5eca

ARG OCI_CREATED
ARG OCI_REVISION
ARG OCI_SOURCE="https://github.com/AgentHub-Studio/agenthub-infra"
ARG OCI_VERSION="local"
ARG OCI_TITLE="agenthub-infra-ollama"

LABEL org.opencontainers.image.title="${OCI_TITLE}" \
      org.opencontainers.image.description="AgentHub Ollama runtime with rebuilt Ollama binary and patched Go dependencies" \
      org.opencontainers.image.source="${OCI_SOURCE}" \
      org.opencontainers.image.revision="${OCI_REVISION}" \
      org.opencontainers.image.created="${OCI_CREATED}" \
      org.opencontainers.image.version="${OCI_VERSION}" \
      org.opencontainers.image.vendor="AgentHub Studio" \
      org.opencontainers.image.licenses="Proprietary"

ENV HOME="/home/ollama" \
    OLLAMA_MODELS="/home/ollama/.ollama/models"

RUN set -eux; \
    groupadd --system --gid 10001 ollama; \
    useradd --system --uid 10001 --gid 10001 --home-dir /home/ollama --shell /usr/sbin/nologin ollama; \
    mkdir -p /home/ollama/.ollama; \
    chown -R 10001:10001 /home/ollama

COPY --from=ollama-builder /out/ollama /usr/bin/ollama

RUN set -eux; \
    chmod 0755 /usr/bin/ollama; \
    /usr/bin/ollama --version 2>&1 | grep -F "0.30.11"

USER 10001:10001
