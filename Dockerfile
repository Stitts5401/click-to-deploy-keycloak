FROM marketplace.gcr.io/google/c2d-debian11 AS build

ENV KEYCLOAK_VERSION 23.0.5
ARG KEYCLOAK_DIST=https://github.com/keycloak/keycloak/releases/download/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.tar.gz

ADD $KEYCLOAK_DIST /tmp/keycloak/

RUN (cd /tmp/keycloak && \
    tar -xvf /tmp/keycloak/keycloak-*.tar.gz && \
    rm /tmp/keycloak/keycloak-*.tar.gz) || true

RUN mv /tmp/keycloak/keycloak-* /opt/keycloak && mkdir -p /opt/keycloak/data

RUN chmod -R g+rwX /opt/keycloak

FROM marketplace.gcr.io/google/c2d-debian11
ENV LANGUAGE=C.UTF-8 LANG=C.UTF-8 LC_ALL=C.UTF-8 LC_CTYPE=C.UTF-8 LC_MESSAGES=C.UTF-8

COPY --from=build --chown=1000:0 /opt/keycloak /opt/keycloak

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates-java

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
          ca-certificates-java \
          curl \
          locales \
          openjdk-17-jre-headless \
          libh2-java \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


ENV KC_DB=postgres
RUN /opt/keycloak/bin/kc.sh build --db=postgres

ENV C2D_RELEASE 23.0.5

ENV DOCKER_HOST_IP=10.32.0.3 \
    DB_PORT=5432 \
    DB_NAME=postgres \
    DB_VENDOR=postgresql \
    KC_DB_PASSWORD_SECRET=''

ENV KC_DB_URL=jdbc:$DB_VENDOR://$DOCKER_HOST_IP:$DB_PORT/$DB_NAME \
    KC_DB_USERNAME=keycloak_API \
    KC_DB_PASSWORD=${KC_DB_PASSWORD_SECRET} \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true \
    KC_HOSTNAME=keycloak-service.domain.com \
    KC_ADMIN_URL=https://keycloak-service.domain.com/auth/ \
    KC_QUARKUS_TRANSACTION_MANAGER_ENABLE_RECOVERY=true \
    KC_HOSTNAME_STRICT=true \
    KC_HOSTNAME_STRICT_HTTPS=true \
    KC_HTTPS_ENABLED=true \
    KC_HTTP_ENABLED=true \
    KC_LOG=console \
    KC_LOG_LEVEL=INFO \
    KC_PROXY=edge



USER 1000

EXPOSE 8080
EXPOSE 8443

ENTRYPOINT [ "/opt/keycloak/bin/kc.sh" , "start" ]