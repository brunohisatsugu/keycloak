# Build Keycloakify theme
FROM node:22 AS ui-builder
RUN apt-get update && apt-get install -y maven git-lfs

WORKDIR /app
COPY . .

# Just in case
WORKDIR /app/keycloakify
RUN rm -rf dist_keycloak
RUN rm -rf node_modules
RUN rm -rf package-lock.json

RUN npm install
RUN npm run build-keycloak-theme

# copy built theme into keycloak and build keycloak
FROM quay.io/keycloak/keycloak:26.1 AS builder

# these must be set in the build in order to enable an optimized build
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_TRACING_ENABLED=true
ENV KC_DB=postgres

COPY --from=ui-builder /app/keycloakify/dist_keycloak/keycloak-theme-for-kc-all-other-versions.jar /opt/keycloak/providers/keycloak-theme.jar

RUN /opt/keycloak/bin/kc.sh build

# Copy built keycloak into final image
FROM quay.io/keycloak/keycloak:26.1

COPY --from=builder --chown=keycloak:keycloak /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]

#testcssxcsasass