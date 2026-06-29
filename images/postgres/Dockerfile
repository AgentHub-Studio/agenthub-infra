FROM docker.io/library/golang@sha256:523c3effe300580ed375e43f43b1c9b091b68e935a7c3a92bfcc4e7ed55b18c2 AS gosu-builder

ARG GOSU_MODULE_VERSION="v0.0.0-20250923190938-6456aaa0f3c8"

ENV PATH="/usr/local/go/bin:${PATH}"

RUN set -eux; \
    GOBIN=/out CGO_ENABLED=0 go install "github.com/tianon/gosu@${GOSU_MODULE_VERSION}"; \
    /out/gosu --version; \
    strings /out/gosu | grep -F "go1.25.11"

FROM docker.io/library/postgres@sha256:cd17e2ac98240fce1541ad2a803b34009b4eea5aec8a832363cdc7eca62e722e

ARG OCI_CREATED
ARG OCI_REVISION
ARG OCI_SOURCE="https://github.com/AgentHub-Studio/agenthub-infra"
ARG OCI_VERSION="local"
ARG OCI_TITLE="agenthub-infra-postgres"

LABEL org.opencontainers.image.title="${OCI_TITLE}" \
      org.opencontainers.image.description="AgentHub infra Postgres 15 runtime with rebuilt gosu" \
      org.opencontainers.image.source="${OCI_SOURCE}" \
      org.opencontainers.image.revision="${OCI_REVISION}" \
      org.opencontainers.image.created="${OCI_CREATED}" \
      org.opencontainers.image.version="${OCI_VERSION}" \
      org.opencontainers.image.vendor="AgentHub Studio" \
      org.opencontainers.image.licenses="Proprietary"

COPY --from=gosu-builder /out/gosu /usr/local/bin/gosu

RUN set -eux; \
    apk upgrade --no-cache; \
    chmod 0755 /usr/local/bin/gosu; \
    gosu --version; \
    gosu nobody true; \
    postgres --version
