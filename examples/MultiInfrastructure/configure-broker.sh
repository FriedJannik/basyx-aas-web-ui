#!/bin/bash

# Script to configure Keycloak Broker integration for Infrastructure 1 and 3
# This script should be run after all Keycloak instances are up and running

set -e

echo "================================================"
echo "Keycloak Broker Configuration Script"
echo "================================================"
echo ""

# Configuration
KEYCLOAK_TRAMERI_URL="http://localhost:9097"
KEYCLOAK_INFRA3_URL="http://localhost:9098"
KEYCLOAK_BROKER_URL="http://localhost:9099"
ADMIN_USER="admin"
ADMIN_PASS="keycloak-admin"
REALM_INFRA="BaSyx"
REALM_BROKER="BrokerRealm"

# Function to get admin token
get_admin_token() {
    local keycloak_url=$1
    local realm=$2
    
    TOKEN=$(curl -s -X POST "${keycloak_url}/realms/master/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=${ADMIN_USER}" \
        -d "password=${ADMIN_PASS}" \
        -d "grant_type=password" \
        -d "client_id=admin-cli" | jq -r '.access_token')
    
    echo "$TOKEN"
}

# Function to create client
create_client() {
    local keycloak_url=$1
    local realm=$2
    local token=$3
    local client_json=$4
    
    echo "Creating client in ${realm}..."
    
    response=$(curl -s -w "\n%{http_code}" -X POST "${keycloak_url}/admin/realms/${realm}/clients" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json" \
        -d "${client_json}")
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" == "201" ] || [ "$http_code" == "409" ]; then
        echo "✓ Client created or already exists"
        return 0
    else
        echo "✗ Failed to create client (HTTP ${http_code})"
        echo "$response" | head -n-1
        return 1
    fi
}

# Function to create identity provider
create_idp() {
    local keycloak_url=$1
    local realm=$2
    local token=$3
    local idp_json=$4
    
    echo "Creating identity provider in ${realm}..."
    
    response=$(curl -s -w "\n%{http_code}" -X POST "${keycloak_url}/admin/realms/${realm}/identity-provider/instances" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json" \
        -d "${idp_json}")
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" == "201" ] || [ "$http_code" == "409" ]; then
        echo "✓ Identity provider created or already exists"
        return 0
    else
        echo "✗ Failed to create identity provider (HTTP ${http_code})"
        echo "$response" | head -n-1
        return 1
    fi
}

echo "Step 1: Waiting for Keycloak instances to be ready..."
echo "-----------------------------------------------"

# Wait for Keycloak instances
for url in "$KEYCLOAK_TRAMERI_URL" "$KEYCLOAK_INFRA3_URL" "$KEYCLOAK_BROKER_URL"; do
    echo "Waiting for ${url}..."
    until curl -sf "${url}/health/ready" > /dev/null 2>&1; do
        echo -n "."
        sleep 2
    done
    echo " Ready!"
done

echo ""
echo "Step 2: Adding broker client to Trameri Keycloak..."
echo "-----------------------------------------------"

TOKEN_TRAMERI=$(get_admin_token "$KEYCLOAK_TRAMERI_URL" "master")

CLIENT_TRAMERI_JSON=$(cat Infrastructure1/keycloak/realm/broker-client-patch.json)
create_client "$KEYCLOAK_TRAMERI_URL" "$REALM_INFRA" "$TOKEN_TRAMERI" "$CLIENT_TRAMERI_JSON"

echo ""
echo "Step 3: Adding broker client to Infrastructure 3 Keycloak..."
echo "-----------------------------------------------"

TOKEN_INFRA3=$(get_admin_token "$KEYCLOAK_INFRA3_URL" "master")

CLIENT_INFRA3_JSON=$(cat Infrastructure3/keycloak/realm/broker-client-patch.json)
create_client "$KEYCLOAK_INFRA3_URL" "$REALM_INFRA" "$TOKEN_INFRA3" "$CLIENT_INFRA3_JSON"

echo ""
echo "Step 4: Broker Realm already configured via import"
echo "-----------------------------------------------"
echo "✓ Broker realm configuration includes:"
echo "  - Identity providers for Trameri and Infrastructure 3"
echo "  - Client configuration for basyx-web-ui"
echo "  - Test users: broker.admin / admin123 and broker.user / user123"

echo ""
echo "================================================"
echo "Configuration Complete!"
echo "================================================"
echo ""
echo "Next Steps:"
echo "1. Update docker-compose.yml to point aas-web-ui to the broker:"
echo "   KEYCLOAK_URL: https://keycloak-broker.basyx.localhost"
echo "   KEYCLOAK_REALM: BrokerRealm"
echo ""
echo "2. Restart the Web UI container:"
echo "   docker compose restart aas-web-ui"
echo ""
echo "3. Access the Web UI at https://aasgui.basyx.localhost"
echo "   You should see login options for:"
echo "   - Trameri"
echo "   - Infrastructure 3"
echo "   - Direct broker login"
echo ""
echo "Test Users:"
echo "  Broker: broker.admin / admin123"
echo "  Trameri: john / john"
echo "  Infra3: john / john (same as Trameri)"
echo ""
