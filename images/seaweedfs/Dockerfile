FROM docker.io/library/golang@sha256:b305420a68d0f229d91eb3b3ed9e519fcf2cf5461da4bef997bf927e8c0bfd2b AS seaweedfs-builder

ARG SEAWEEDFS_VERSION="4.37"
ARG SEAWEEDFS_COMMIT="c06a2dca879cdbe742246d812431fbe2de01357b"

ENV PATH="/usr/local/go/bin:${PATH}"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends git ca-certificates build-essential binutils; \
    rm -rf /var/lib/apt/lists/*; \
    git clone --depth 1 --branch "${SEAWEEDFS_VERSION}" https://github.com/seaweedfs/seaweedfs.git /src/seaweedfs; \
    cd /src/seaweedfs; \
    test "$(git rev-parse HEAD)" = "${SEAWEEDFS_COMMIT}"; \
    go mod edit -dropreplace github.com/apache/thrift; \
    go mod download github.com/apache/thrift@v0.23.0; \
    cd weed; \
    CGO_ENABLED=0 GOOS=linux go build -trimpath \
      -ldflags="-s -w -extldflags -static -X github.com/seaweedfs/seaweedfs/weed/util/version.COMMIT=${SEAWEEDFS_COMMIT}" \
      -o /out/weed .; \
    /out/weed version 2>&1 | grep -F "${SEAWEEDFS_VERSION}"; \
    /out/weed version 2>&1 | grep -F "${SEAWEEDFS_COMMIT}"; \
    go version -m /out/weed | grep -F "go1.26.4"; \
    go version -m /out/weed | grep -F "github.com/apache/thrift" | grep -F "v0.23.0"; \
    ! go version -m /out/weed | grep -F "github.com/apache/thrift" | grep -F "v0.22.0"

FROM chrislusf/seaweedfs@sha256:f898c91e42d7da5f4bb13f1efd424ff03ba85b420312eb929708a384e8a8b03d

ARG OCI_CREATED
ARG OCI_REVISION
ARG OCI_SOURCE="https://github.com/AgentHub-Studio/agenthub-infra"
ARG OCI_VERSION="local"
ARG OCI_TITLE="agenthub-infra-seaweedfs"

LABEL org.opencontainers.image.title="${OCI_TITLE}" \
      org.opencontainers.image.description="AgentHub S3-compatible storage runtime using SeaweedFS with patched Go dependencies" \
      org.opencontainers.image.source="${OCI_SOURCE}" \
      org.opencontainers.image.revision="${OCI_REVISION}" \
      org.opencontainers.image.created="${OCI_CREATED}" \
      org.opencontainers.image.version="${OCI_VERSION}" \
      org.opencontainers.image.vendor="AgentHub Studio" \
      org.opencontainers.image.licenses="Apache-2.0"

COPY --from=seaweedfs-builder /out/weed /usr/bin/weed
COPY agenthub-seaweedfs-entrypoint.sh /usr/local/bin/agenthub-seaweedfs-entrypoint

RUN set -eux; \
    addgroup -S -g 10001 agenthub; \
    adduser -S -D -H -u 10001 -G agenthub -s /sbin/nologin agenthub; \
    mkdir -p /data; \
    chown -R 10001:10001 /data; \
    chmod 0755 /usr/bin/weed /usr/local/bin/agenthub-seaweedfs-entrypoint; \
    /usr/bin/weed version 2>&1 | grep -F "4.37"

ENV SEAWEEDFS_DATA_DIR="/data" \
    SEAWEEDFS_RUNTIME_DIR="/data/.agenthub-seaweedfs" \
    SEAWEEDFS_S3_PORT="9000" \
    SEAWEEDFS_CONSOLE_PORT="9001"

USER 10001:10001
ENTRYPOINT ["/usr/local/bin/agenthub-seaweedfs-entrypoint"]
CMD ["server", "-dir=/data", "-ip=127.0.0.1", "-ip.bind=0.0.0.0", "-master.telemetry=false", "-master.volumePreallocate=false", "-master.volumeSizeLimitMB=1024", "-volume.max=0", "-filer", "-filer.port=9001", "-s3", "-s3.port=9000", "-s3.ip.bind=0.0.0.0", "-s3.config=/data/.agenthub-seaweedfs/s3.json", "-s3.iam=false", "-s3.port.iceberg=0", "-s3.allowDeleteBucketNotEmpty=false"]
