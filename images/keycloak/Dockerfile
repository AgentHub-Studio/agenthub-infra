FROM docker.io/library/amazoncorretto@sha256:30b1b2246cee9a98c9bf8a11537a04f1eaf8c59279b0c70ae02d7e5b934edeaa AS keycloak-dist

ARG KEYCLOAK_VERSION="26.6.4"
ARG KEYCLOAK_SHA1="f11ea9cf03cf737bf733845813ec538ecc99a728"
ARG JACKSON_DATABIND_VERSION="2.21.4"
ARG JACKSON_DATABIND_SHA1="09e495680be707d466527d734368ebf36e464da2"
ARG MSSQL_JDBC_VERSION="13.4.0.jre11"
ARG MSSQL_JDBC_SHA1="061d769c8a7dd4870fd85099ab55fbc6040b1997"

RUN set -eux; \
    apk add --no-cache ca-certificates curl gzip tar; \
    curl -fsSL -o /tmp/keycloak.tar.gz "https://github.com/keycloak/keycloak/releases/download/${KEYCLOAK_VERSION}/keycloak-${KEYCLOAK_VERSION}.tar.gz"; \
    echo "${KEYCLOAK_SHA1}  /tmp/keycloak.tar.gz" | sha1sum -c -; \
    mkdir -p /opt; \
    tar -xzf /tmp/keycloak.tar.gz -C /opt; \
    mv "/opt/keycloak-${KEYCLOAK_VERSION}" /opt/keycloak; \
    rm -f "/opt/keycloak/bin/client/keycloak-admin-cli-${KEYCLOAK_VERSION}.jar"; \
    curl -fsSL -o /tmp/jackson-databind.jar "https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-databind/${JACKSON_DATABIND_VERSION}/jackson-databind-${JACKSON_DATABIND_VERSION}.jar"; \
    echo "${JACKSON_DATABIND_SHA1}  /tmp/jackson-databind.jar" | sha1sum -c -; \
    cp /tmp/jackson-databind.jar /opt/keycloak/lib/lib/main/com.fasterxml.jackson.core.jackson-databind-2.21.2.jar; \
    curl -fsSL -o /tmp/mssql-jdbc.jar "https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/${MSSQL_JDBC_VERSION}/mssql-jdbc-${MSSQL_JDBC_VERSION}.jar"; \
    echo "${MSSQL_JDBC_SHA1}  /tmp/mssql-jdbc.jar" | sha1sum -c -; \
    cp /tmp/mssql-jdbc.jar /opt/keycloak/lib/lib/main/com.microsoft.sqlserver.mssql-jdbc-13.2.1.jre11.jar; \
    test ! -e "/opt/keycloak/bin/client/keycloak-admin-cli-${KEYCLOAK_VERSION}.jar"; \
    test -s /opt/keycloak/lib/lib/main/com.fasterxml.jackson.core.jackson-databind-2.21.2.jar; \
    test -s /opt/keycloak/lib/lib/main/com.microsoft.sqlserver.mssql-jdbc-13.2.1.jre11.jar; \
    rm -rf /tmp/keycloak.tar.gz /tmp/jackson-databind.jar /tmp/mssql-jdbc.jar

FROM docker.io/library/amazoncorretto@sha256:30b1b2246cee9a98c9bf8a11537a04f1eaf8c59279b0c70ae02d7e5b934edeaa

ARG OCI_CREATED
ARG OCI_REVISION
ARG OCI_SOURCE="https://github.com/AgentHub-Studio/agenthub-infra"
ARG OCI_VERSION="local"
ARG OCI_TITLE="agenthub-infra-keycloak"

LABEL org.opencontainers.image.title="${OCI_TITLE}" \
      org.opencontainers.image.description="AgentHub infra Keycloak runtime with pinned distribution and patched Java dependencies" \
      org.opencontainers.image.source="${OCI_SOURCE}" \
      org.opencontainers.image.revision="${OCI_REVISION}" \
      org.opencontainers.image.created="${OCI_CREATED}" \
      org.opencontainers.image.version="${OCI_VERSION}" \
      org.opencontainers.image.vendor="AgentHub Studio" \
      org.opencontainers.image.licenses="Apache-2.0"

COPY --from=keycloak-dist /opt/keycloak /opt/keycloak

ENV KC_HOME="/opt/keycloak" \
    KC_RUN_IN_CONTAINER="true" \
    KC_HTTP_HOST="0.0.0.0" \
    PATH="/opt/keycloak/bin:${PATH}"

RUN set -eux; \
    apk upgrade --no-cache; \
    apk add --no-cache ca-certificates; \
    addgroup -S -g 10001 agenthub; \
    adduser -S -D -H -u 10001 -G agenthub -s /sbin/nologin agenthub; \
    mkdir -p /opt/keycloak/data /tmp; \
    chown -R 10001:10001 /opt/keycloak /tmp; \
    chmod -R g=u /opt/keycloak /tmp; \
    /opt/keycloak/bin/kc.sh --version | grep -F "Keycloak 26.6.4"

USER 10001:10001
EXPOSE 8080
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
