FROM docker.io/clickhouse/clickhouse-server@sha256:a65ca89ddbe8e04a05036dd7d7110a203256293b407b9359130ed5e4333f45ff

ARG OCI_CREATED
ARG OCI_REVISION
ARG OCI_SOURCE="https://github.com/AgentHub-Studio/agenthub-infra"
ARG OCI_VERSION="local"
ARG OCI_TITLE="agenthub-infra-clickhouse"

LABEL org.opencontainers.image.title="${OCI_TITLE}" \
      org.opencontainers.image.description="AgentHub ClickHouse 24.12 runtime with pinned base and OS security updates" \
      org.opencontainers.image.source="${OCI_SOURCE}" \
      org.opencontainers.image.revision="${OCI_REVISION}" \
      org.opencontainers.image.created="${OCI_CREATED}" \
      org.opencontainers.image.version="${OCI_VERSION}" \
      org.opencontainers.image.vendor="AgentHub Studio" \
      org.opencontainers.image.licenses="Apache-2.0"

RUN set -eux; \
    apt-get update; \
    apt-mark hold clickhouse-client clickhouse-common-static clickhouse-server; \
    apt-get -y upgrade; \
    rm -rf /var/lib/apt/lists/*; \
    clickhouse-server --version

USER clickhouse
