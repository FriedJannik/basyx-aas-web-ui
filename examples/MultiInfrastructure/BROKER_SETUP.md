# Keycloak Broker Setup for Cross-Infrastructure Authentication

This guide explains how to configure the Keycloak broker so users from Infrastructure 1 can access Infrastructure 3 (and vice versa).

## Architecture Overview

```
┌─────────────────┐
│  AAS Web UI     │
│  (Port 3000)    │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│         Keycloak Broker (Port 9099)                 │
│         keycloak-broker.basyx.localhost             │
│                                                       │
│  Acts as central identity provider that             │
│  federates authentication between infras            │
└─────────┬───────────────────────────────┬───────────┘
          │                               │
          ▼                               ▼
┌─────────────────┐           ┌─────────────────┐
│ Keycloak Infra1 │           │ Keycloak Infra3 │
│   (Port 9097)   │           │   (Port 9098)   │
│                 │           │                 │
│ Manages auth    │           │ Manages auth    │
│ for Infra 1     │           │ for Infra 3     │
│ services        │           │ services        │
└─────────────────┘           └─────────────────┘
```

## Configuration Steps

### Step 1: Configure Identity Providers in Infra1 and Infra3 Keycloak

Both Infrastructure 1 and Infrastructure 3 Keycloak instances need to be configured to use the Broker as an identity provider.

#### Manual Configuration (via Keycloak Admin Console):

1. **Access Keycloak Infra1 Admin Console:**
   - URL: `https://keycloak.trameri.basyx.localhost` or `http://localhost:9097`
   - Username: `admin`
   - Password: `keycloak-admin`

2. **Add Broker as Identity Provider:**
   - Navigate to: **Identity Providers** → **Add provider** → **OpenID Connect v1.0**
   - Configuration:
     - **Alias:** `broker`
     - **Display Name:** `Login via Broker`
     - **Enabled:** ON
     - **Store Tokens:** ON
     - **Trust Email:** ON
     - **First Login Flow:** `first broker login`
     - **Authorization URL:** `https://keycloak-broker.basyx.localhost/realms/BrokerRealm/protocol/openid-connect/auth`
     - **Token URL:** `https://keycloak-broker.basyx.localhost/realms/BrokerRealm/protocol/openid-connect/token`
     - **Logout URL:** `https://keycloak-broker.basyx.localhost/realms/BrokerRealm/protocol/openid-connect/logout`
     - **User Info URL:** `https://keycloak-broker.basyx.localhost/realms/BrokerRealm/protocol/openid-connect/userinfo`
     - **Client ID:** `broker`
     - **Client Secret:** `broker-secret`
     - **Issuer:** `https://keycloak-broker.basyx.localhost/realms/BrokerRealm`

3. **Repeat for Infrastructure 3:**
   - Access: `https://keycloak.eurogoodies.basyx.localhost` or `http://localhost:9098`
   - Same configuration as above

### Step 2: Update Broker Realm Configuration

The broker realm needs to be configured to accept authentication requests from both infrastructures and map users appropriately.

The current broker realm (`/keycloak-broker/realm/broker-realm.json`) already has:
- Client `broker` with `client_id: broker` and `secret: broker-secret`
- Redirect URIs configured for both infrastructures
- Two test users: `broker.admin` / `admin123` and `broker.user` / `user123`

### Step 3: Configure Web UI to Use Broker

Update the AAS Web UI to point to the broker Keycloak instead of directly to Infra1:

Edit `docker-compose.yml` and change the `aas-web-ui` environment variables:

```yaml
aas-web-ui:
  environment:
    # Change from keycloak.trameri.basyx.localhost to broker
    KEYCLOAK_URL: https://keycloak-broker.basyx.localhost
    KEYCLOAK_REALM: BrokerRealm  # Change from BaSyx to BrokerRealm
    KEYCLOAK_CLIENT_ID: basyx-web-ui
```

### Step 4: Add Web UI Client to Broker Realm

The broker realm needs a client configuration for the Web UI. Add this to `/keycloak-broker/realm/broker-realm.json`:

```json
{
  "clientId": "basyx-web-ui",
  "publicClient": true,
  "protocol": "openid-connect",
  "redirectUris": [
    "https://aasgui.basyx.localhost/*",
    "http://localhost:3000/*"
  ],
  "webOrigins": [
    "https://aasgui.basyx.localhost",
    "http://localhost:3000"
  ],
  "enabled": true,
  "standardFlowEnabled": true,
  "implicitFlowEnabled": true,
  "directAccessGrantsEnabled": true,
  "frontchannelLogout": true,
  "attributes": {
    "post.logout.redirect.uris": "http://localhost:3000/*##https://aasgui.basyx.localhost/*"
  }
}
```

## How It Works

1. **User accesses the Web UI** at `https://aasgui.basyx.localhost`
2. **Web UI redirects to Broker Keycloak** for authentication
3. **Broker presents login options:**
   - Direct login with broker users (`broker.admin`, `broker.user`)
   - Login via Infrastructure 1 identity provider
   - Login via Infrastructure 3 identity provider
4. **User selects an infrastructure** and is redirected to that Keycloak
5. **User authenticates** with their infrastructure-specific credentials
6. **Infrastructure Keycloak** returns tokens to the Broker
7. **Broker** creates a federated user session and returns tokens to the Web UI
8. **Web UI can now access services** in both Infrastructure 1 and Infrastructure 3 using the brokered tokens

## User Management

### Broker Users (for testing):
- `broker.admin` / `admin123` (has `basyx-admin` role)
- `broker.user` / `user123` (has `basyx-user` role)

### Infrastructure 1 Users (some examples):
- `john` / `john` (admin role)
- `jane.doe` / `jane` (user role)
- `paul.visitor` / `paul` (visitor role)

### Infrastructure 3 Users:
- Same as Infrastructure 1 (uses same realm configuration)

## Testing the Setup

1. **Start all services:** `docker compose up -d`
2. **Access Web UI:** `https://aasgui.basyx.localhost` or `http://localhost:3000`
3. **You should see Keycloak broker login page** with options to:
   - Login directly with broker credentials
   - Login via Infrastructure 1
   - Login via Infrastructure 3
4. **Select "Login via Infrastructure 1"** and use `john` / `john`
5. **After successful authentication**, you should have access to services in both infrastructures

## Troubleshooting

### Issue: "Invalid redirect URI"
- Ensure all redirect URIs are properly configured in both broker and infrastructure Keycloak clients
- Check that HTTPS is used consistently (or HTTP consistently for local development)

### Issue: "Identity Provider not found"
- Verify the identity provider configuration in Infrastructure Keycloak instances
- Check that the broker Keycloak is accessible from the infrastructure Keycloak containers

### Issue: Token validation fails
- Ensure the issuer URLs match exactly between configurations
- Check that SSL certificates are properly trusted (or use HTTP for local dev)
- Verify that the `Trust Email` and `Store Tokens` options are enabled in the identity provider configuration

### Issue: CORS errors
- Ensure `webOrigins` includes the Web UI origin in all Keycloak client configurations
- Check that `BASYX_CORS_ALLOWED_ORIGINS` is set to `*` in BaSyx service configurations
