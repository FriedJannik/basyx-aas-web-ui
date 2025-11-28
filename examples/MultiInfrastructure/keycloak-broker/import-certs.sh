#!/bin/bash

# Script to import SSL certificates into Keycloak's Java trust store
# This allows the Keycloak broker to trust self-signed certificates from infrastructure Keycloaks

set -e

KEYSTORE_PATH="/tmp/server.truststore"
KEYSTORE_PASS="changeit"
CERTS_DIR="/opt/keycloak/ssl-certs"

echo "Creating custom trust store for Keycloak broker..."

# Find the Java cacerts file
CACERTS=""
if [ -f "$JAVA_HOME/lib/security/cacerts" ]; then
    CACERTS="$JAVA_HOME/lib/security/cacerts"
elif [ -f "$JAVA_HOME/conf/security/cacerts" ]; then
    CACERTS="$JAVA_HOME/conf/security/cacerts"
elif [ -f "/etc/pki/ca-trust/extracted/java/cacerts" ]; then
    CACERTS="/etc/pki/ca-trust/extracted/java/cacerts"
elif [ -f "/etc/ssl/certs/java/cacerts" ]; then
    CACERTS="/etc/ssl/certs/java/cacerts"
else
    # If not found, create a new empty truststore
    echo "Default Java cacerts not found, creating new truststore"
    keytool -genkeypair -alias placeholder -keyalg RSA -keysize 2048 -validity 1 \
        -dname "CN=placeholder" -keypass "$KEYSTORE_PASS" -keystore "$KEYSTORE_PATH" \
        -storepass "$KEYSTORE_PASS" 2>/dev/null || true
    keytool -delete -alias placeholder -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASS" 2>/dev/null || true
fi

if [ -n "$CACERTS" ]; then
    echo "Using Java cacerts from: $CACERTS"
    cp "$CACERTS" "$KEYSTORE_PATH"
fi

# Import infrastructure Keycloak certificates
for cert_file in "$CERTS_DIR"/keycloak.infra*.crt; do
    if [ -f "$cert_file" ]; then
        cert_name=$(basename "$cert_file" .crt)
        echo "Importing certificate: $cert_name"
        keytool -import -trustcacerts -noprompt \
            -alias "$cert_name" \
            -file "$cert_file" \
            -keystore "$KEYSTORE_PATH" \
            -storepass "$KEYSTORE_PASS" || echo "Certificate $cert_name already exists or failed to import"
    fi
done

echo "Certificate import complete!"
echo "Trust store location: $KEYSTORE_PATH"

# Execute the original Keycloak entrypoint
exec /opt/keycloak/bin/kc.sh "$@"
