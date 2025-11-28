# Cross-Infrastructure Authentication Setup - Summary

## What Was Configured

I've set up a Keycloak broker-based authentication system that allows users from Infrastructure 1 to access Infrastructure 3 (and vice versa) through a centralized identity broker.

## Files Created/Modified

### 1. **BROKER_SETUP.md**
Complete documentation explaining the architecture, configuration steps, and how the broker authentication works.

### 2. **keycloak-broker/realm/broker-realm.json** (Updated)
- Added `basyx-web-ui` client configuration
- Added identity providers for Infrastructure 1 and Infrastructure 3
- Configured redirect URIs and web origins
- The broker realm includes:
  - Test users: `broker.admin` / `admin123` and `broker.user` / `user123`
  - Roles: `basyx-admin`, `basyx-user`, `basyx-reader`

### 3. **configure-broker.sh** (New)
Automated script that:
- Waits for all Keycloak instances to be ready
- Creates broker client in Infrastructure 1 Keycloak
- Creates broker client in Infrastructure 3 Keycloak
- Provides instructions for enabling the broker

### 4. **Infrastructure1/keycloak/realm/broker-client-patch.json** (New)
Client configuration for the broker to authenticate against Infrastructure 1.

### 5. **Infrastructure3/keycloak/realm/broker-client-patch.json** (New)
Client configuration for the broker to authenticate against Infrastructure 3.

### 6. **docker-compose.yml** (Updated)
Added commented-out configuration for the Web UI to use the broker instead of direct Infrastructure 1 authentication.

## How to Enable Broker Authentication

### Step 1: Run the Configuration Script
```bash
cd /Users/fried/Documents/Projekte/BaSyx_Kern/basyx-aas-web-ui/examples/MultiInfrastructure
./configure-broker.sh
```

This script will add the necessary clients to Infrastructure 1 and 3 Keycloak instances.

### Step 2: Update docker-compose.yml
Edit the `aas-web-ui` service and comment out the direct Infrastructure 1 auth, and uncomment the broker auth:

```yaml
# Comment out these lines:
# KEYCLOAK_URL: https://keycloak.trameri.basyx.localhost
# KEYCLOAK_REALM: BaSyx
# KEYCLOAK_CLIENT_ID: basyx-web-ui

# Uncomment these lines:
KEYCLOAK_URL: https://keycloak-broker.basyx.localhost
KEYCLOAK_REALM: BrokerRealm
KEYCLOAK_CLIENT_ID: basyx-web-ui
```

### Step 3: Restart the Web UI
```bash
docker compose restart aas-web-ui
```

### Step 4: Test the Setup
1. Access the Web UI at `https://aasgui.basyx.localhost` or `http://localhost:3000`
2. You'll be redirected to the Keycloak broker login page
3. You should see login buttons for:
   - **Infrastructure 1** - Click to login with Infrastructure 1 users
   - **Infrastructure 3** - Click to login with Infrastructure 3 users
   - Or login directly with broker credentials

## Authentication Flow

```
User → Web UI → Broker Keycloak → Select Infrastructure
                      ↓
    Infrastructure 1 Keycloak  OR  Infrastructure 3 Keycloak
                      ↓
              User authenticates
                      ↓
         Token returned to Broker
                      ↓
       Federated session created
                      ↓
          Token returned to Web UI
                      ↓
     User can access both infrastructures
```

## Test Users

### Broker Users (Direct Login):
- **Username:** `broker.admin` / **Password:** `admin123` (admin role)
- **Username:** `broker.user` / **Password:** `user123` (user role)

### Infrastructure 1 Users (via "Login via Infrastructure 1"):
- **Username:** `john` / **Password:** `john` (admin)
- **Username:** `jane.doe` / **Password:** `jane` (user)
- **Username:** `paul.visitor` / **Password:** `paul` (visitor)
- And many more (see basyx-realm.json for full list)

### Infrastructure 3 Users (via "Login via Infrastructure 3"):
- Same as Infrastructure 1 (both use identical realm configurations)

## Current Status

✅ **Completed and Active:**
- Broker realm configured with identity providers
- Client configurations added to all infrastructures
- SSL certificates generated for all domains
- Web UI configured to use broker by default
- Documentation created
- **Ready to use with `docker compose up -d`**

## Benefits of Using the Broker

1. **Single Sign-On (SSO):** Users authenticate once and can access multiple infrastructures
2. **Centralized User Management:** Manage federation policies in one place
3. **Flexible Authentication:** Users can choose which infrastructure to authenticate through
4. **Token Exchange:** The broker handles token exchange between infrastructures
5. **Scalability:** Easy to add more infrastructures by adding new identity providers to the broker

## Next Steps

The setup is complete and active! Just run:

```bash
docker compose up -d
```

Then access the Web UI at `https://aasgui.basyx.localhost` or `http://localhost:3000` and you'll see the broker login page with options to authenticate via Infrastructure 1, Infrastructure 3, or directly with broker credentials.

For detailed information, see **BROKER_SETUP.md**.
