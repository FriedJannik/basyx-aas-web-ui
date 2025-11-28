#!/bin/bash

# Script to generate CA-signed SSL certificates for BaSyx Multi-Infrastructure setup
# Generates certificates for Trameri (formerly Infra1) and Infra3 infrastructures
# Creates a Certificate Authority that can be added to your system keychain

set -e

echo "================================================"
echo "BaSyx Multi-Infrastructure Certificate Generator"
echo "================================================"
echo ""

# Certificate configuration
DAYS_VALID=3650  # 10 years
CA_DAYS_VALID=7300  # 20 years for CA
KEY_SIZE=2048
COUNTRY="DE"
STATE="NRW"
LOCALITY="Dortmund"
ORGANIZATION="BaSyx"
ORG_UNIT="Infrastructure"

# Output directory
CERTS_DIR="./certs"
CA_KEY="${CERTS_DIR}/BaSyx-CA.key"
CA_CERT="${CERTS_DIR}/BaSyx-CA.crt"

# Ensure certs directory exists
mkdir -p "$CERTS_DIR"

# Function to generate Certificate Authority
generate_ca() {
    echo "Step 1: Generating Certificate Authority (CA)"
    echo "-----------------------------------------------------------"
    
    if [ -f "$CA_KEY" ] && [ -f "$CA_CERT" ]; then
        echo "⚠ CA already exists. Skipping CA generation."
        echo "  To regenerate, delete: $CA_KEY and $CA_CERT"
        echo ""
        return
    fi
    
    echo "Creating BaSyx Certificate Authority..."
    
    # Generate CA private key
    openssl genrsa -out "$CA_KEY" 4096 2>/dev/null
    
    # Generate CA certificate
    openssl req -new -x509 \
        -key "$CA_KEY" \
        -out "$CA_CERT" \
        -days $CA_DAYS_VALID \
        -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORG_UNIT}/CN=BaSyx Certificate Authority" \
        -addext "basicConstraints=critical,CA:TRUE" \
        -addext "keyUsage=critical,keyCertSign,cRLSign" \
        2>/dev/null
    
    echo "  ✓ Created: $CA_KEY"
    echo "  ✓ Created: $CA_CERT"
    echo ""
    echo "🔑 IMPORTANT: Add BaSyx-CA.crt to your system keychain!"
    echo ""
}

# Function to generate CA-signed certificate
generate_cert() {
    local hostname=$1
    local cn=$2
    local output_prefix="${CERTS_DIR}/${hostname}"
    
    echo "Generating certificate for: ${hostname}"
    echo "  Common Name: ${cn}"
    
    # Generate private key
    openssl genrsa -out "${output_prefix}.key" $KEY_SIZE 2>/dev/null
    
    # Generate Certificate Signing Request (CSR)
    openssl req -new \
        -key "${output_prefix}.key" \
        -out "${output_prefix}.csr" \
        -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORG_UNIT}/CN=${cn}" \
        2>/dev/null
    
    # Create config file for SAN
    cat > "${output_prefix}.cnf" <<EOF
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${hostname}
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF
    
    # Sign certificate with CA
    openssl x509 -req \
        -in "${output_prefix}.csr" \
        -CA "$CA_CERT" \
        -CAkey "$CA_KEY" \
        -CAcreateserial \
        -out "${output_prefix}.crt" \
        -days $DAYS_VALID \
        -extfile "${output_prefix}.cnf" \
        -extensions v3_req \
        2>/dev/null
    
    # Clean up temporary files
    rm "${output_prefix}.csr" "${output_prefix}.cnf"
    
    echo "  ✓ Created: ${output_prefix}.key"
    echo "  ✓ Created: ${output_prefix}.crt (CA-signed)"
    echo ""
}

# Generate CA first
generate_ca

echo "Step 2: Generating Trameri (Infrastructure 1) Certificates"
echo "-----------------------------------------------------------"
generate_cert "keycloak.trameri.basyx.localhost" "keycloak.trameri.basyx.localhost"
generate_cert "aasenv.trameri.basyx.localhost" "aasenv.trameri.basyx.localhost"
generate_cert "aasreg.trameri.basyx.localhost" "aasreg.trameri.basyx.localhost"
generate_cert "smreg.trameri.basyx.localhost" "smreg.trameri.basyx.localhost"
generate_cert "discovery.trameri.basyx.localhost" "discovery.trameri.basyx.localhost"

echo "Step 3: Generating Infra3 Certificates"
echo "-----------------------------------------------------------"
generate_cert "keycloak.eurogoodies.basyx.localhost" "keycloak.eurogoodies.basyx.localhost"
generate_cert "aasenv.eurogoodies.basyx.localhost" "aasenv.eurogoodies.basyx.localhost"
generate_cert "aasreg.eurogoodies.basyx.localhost" "aasreg.eurogoodies.basyx.localhost"
generate_cert "smreg.eurogoodies.basyx.localhost" "smreg.eurogoodies.basyx.localhost"
generate_cert "discovery.eurogoodies.basyx.localhost" "discovery.eurogoodies.basyx.localhost"

echo "Step 4: Generating Common Certificates"
echo "-----------------------------------------------------------"
generate_cert "keycloak-broker.basyx.localhost" "keycloak-broker.basyx.localhost"
generate_cert "aasgui.basyx.localhost" "aasgui.basyx.localhost"

echo "================================================"
echo "Certificate Generation Complete!"
echo "================================================"
echo ""
echo "Generated certificates for:"
echo "  - Trameri Infrastructure (keycloak, aasenv, aasreg, smreg, discovery)"
echo "  - Infra3 Infrastructure (keycloak, aasenv, aasreg, smreg, discovery)"
echo "  - Common Services (keycloak-broker, aasgui)"
echo ""
echo "All certificates are:"
echo "  - Signed by the BaSyx Certificate Authority"
echo "  - Valid for ${DAYS_VALID} days (~10 years)"
echo "  - Located in: ${CERTS_DIR}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 IMPORTANT: Install the Certificate Authority"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To trust all generated certificates, add the CA to your system:"
echo ""
echo "📦 macOS:"
echo "  1. Open the certificate:"
echo "     open ${CERTS_DIR}/BaSyx-CA.crt"
echo "  2. In Keychain Access, select 'System' keychain"
echo "  3. Double-click the imported certificate"
echo "  4. Expand 'Trust' section"
echo "  5. Set 'When using this certificate' to 'Always Trust'"
echo "  6. Close the window and enter your password"
echo ""
echo "🐧 Linux (Ubuntu/Debian):"
echo "  sudo cp ${CERTS_DIR}/BaSyx-CA.crt /usr/local/share/ca-certificates/BaSyx-CA.crt"
echo "  sudo update-ca-certificates"
echo ""
echo "🪟 Windows:"
echo "  1. Double-click ${CERTS_DIR}/BaSyx-CA.crt"
echo "  2. Click 'Install Certificate'"
echo "  3. Select 'Local Machine' and click Next"
echo "  4. Choose 'Place all certificates in the following store'"
echo "  5. Browse and select 'Trusted Root Certification Authorities'"
echo "  6. Click Finish"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Install the CA certificate (see above)"
echo "2. Rebuild Docker images to include new certificates:"
echo "   docker compose build --no-cache"
echo "3. Restart services:"
echo "   docker compose down && docker compose up -d"
echo ""
