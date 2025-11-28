FROM keycloak/keycloak:24.0.4

# Switch to root to install certificates
USER root

# Copy SSL certificates
COPY certs/*.crt /tmp/

# Import SSL certificates into Java cacerts
RUN for cert in /tmp/*.crt; do \
    alias=$(basename "$cert" .crt); \
    keytool -import -trustcacerts -noprompt \
    -alias "$alias" \
    -file "$cert" \
    -cacerts \
    -storepass changeit; \
    done && \
    rm /tmp/*.crt

# Switch back to keycloak user
USER keycloak
