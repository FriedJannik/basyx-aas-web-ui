#!/bin/bash
set -e

echo "Importing SSL certificates into Java trust store..."

# Find Java cacerts location
JAVA_CACERTS=""
if [ -f "$JAVA_HOME/lib/security/cacerts" ]; then
    JAVA_CACERTS="$JAVA_HOME/lib/security/cacerts"
elif [ -f "$JAVA_HOME/conf/security/cacerts" ]; then
    JAVA_CACERTS="$JAVA_HOME/conf/security/cacerts"
fi

if [ -n "$JAVA_CACERTS" ] && [ -d "/opt/ssl-certs" ]; then
    for cert in /opt/ssl-certs/*.crt; do
        if [ -f "$cert" ]; then
            cert_alias=$(basename "$cert" .crt)
            echo "Importing certificate: $cert_alias"
            keytool -import -trustcacerts -noprompt \
                -alias "$cert_alias" \
                -file "$cert" \
                -keystore "$JAVA_CACERTS" \
                -storepass changeit 2>/dev/null || echo "  (already exists or failed)"
        fi
    done
    echo "Certificate import complete!"
else
    echo "Java cacerts not found or certificates directory missing, skipping certificate import"
fi

# Execute the original entrypoint
exec java -jar /opt/application.jar "$@"
