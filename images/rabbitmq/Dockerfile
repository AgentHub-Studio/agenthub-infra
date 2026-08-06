FROM docker.io/library/rabbitmq@sha256:e582c0bc7766f3342496d8485efb5a1df782b5ce3886ad017e2eaae442311f69

ARG OCI_CREATED
ARG OCI_REVISION
ARG OCI_SOURCE="https://github.com/AgentHub-Studio/agenthub-infra"
ARG OCI_VERSION="local"
ARG OCI_TITLE="agenthub-infra-rabbitmq"

LABEL org.opencontainers.image.title="${OCI_TITLE}" \
      org.opencontainers.image.description="AgentHub RabbitMQ 3.13 management runtime with pinned base and OS security updates" \
      org.opencontainers.image.source="${OCI_SOURCE}" \
      org.opencontainers.image.revision="${OCI_REVISION}" \
      org.opencontainers.image.created="${OCI_CREATED}" \
      org.opencontainers.image.version="${OCI_VERSION}" \
      org.opencontainers.image.vendor="AgentHub Studio" \
      org.opencontainers.image.licenses="MPL-2.0"

USER root

RUN set -eux; \
    apt-get update; \
    apt-get -y upgrade; \
    rm -rf /var/lib/apt/lists/*

USER rabbitmq

RUN rabbitmq-diagnostics --version
