# Quick Reference: Keycloak Broker Setup

## Current Configuration (Default)
- **Web UI Authentication:** Keycloak Broker (cross-infrastructure enabled)
- **Login URL:** `https://keycloak-broker.basyx.localhost`
- **Realm:** `BrokerRealm`
- **Access:** All infrastructures via identity federation

## Ready to Use

Just run:
```bash
docker compose up -d
```

The broker is pre-configured and ready! You'll see login options for:
- **Infrastructure 1** (john/john, jane.doe/jane, etc.)
- **Infrastructure 3** (same users as Infrastructure 1)
- **Broker Direct** (broker.admin/admin123, broker.user/user123)

## Keycloak Access Points

| Service | URL | Port | Realm | Admin User | Admin Pass |
|---------|-----|------|-------|------------|------------|
| Infra 1 Keycloak | https://keycloak.trameri.basyx.localhost | 9097 | BaSyx | admin | keycloak-admin |
| Infra 3 Keycloak | https://keycloak.eurogoodies.basyx.localhost | 9098 | BaSyx | admin | keycloak-admin |
| Broker Keycloak | https://keycloak-broker.basyx.localhost | 9099 | BrokerRealm | admin | keycloak-admin |

## Test Users

### Broker (after enabling broker mode):
- `broker.admin` / `admin123`
- `broker.user` / `user123`

### Infrastructure 1 & 3:
- `john` / `john` (admin)
- `jane.doe` / `jane` (user)
- `paul.visitor` / `paul` (visitor)

## Troubleshooting

**Problem:** Can't see identity provider options in login page
- **Solution:** Make sure you've uncommented the broker configuration in docker-compose.yml and restarted aas-web-ui

**Problem:** "Invalid redirect URI" error
- **Solution:** Run `./configure-broker.sh` to ensure all clients are configured correctly

**Problem:** Certificate errors
- **Solution:** All SSL certificates are self-signed. Accept them in your browser or use HTTP for local development

**Problem:** Can't access Infrastructure 3 services after logging in via Infra 1
- **Solution:** The broker provides federated authentication, but you may need to configure cross-infrastructure service authorization in the RBAC rules

## Architecture Diagram

```
┌──────────────────┐
│   Web UI (3000)  │  ← User accesses this
└────────┬─────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Keycloak Broker (9099)         │  ← Central auth broker
│  keycloak-broker.basyx.localhost│
└────────┬───────────────┬────────┘
         │               │
         ▼               ▼
┌───────────────┐ ┌───────────────┐
│ Keycloak      │ │ Keycloak      │
│ Infra1 (9097) │ │ Infra3 (9098) │
└───────┬───────┘ └───────┬───────┘
        │                 │
        ▼                 ▼
┌───────────────┐ ┌───────────────┐
│ Infrastructure│ │ Infrastructure│
│ 1 Services    │ │ 3 Services    │
└───────────────┘ └───────────────┘
```

## Files to Know

- `BROKER_SETUP.md` - Complete setup guide
- `BROKER_CONFIGURATION_SUMMARY.md` - What was configured
- `configure-broker.sh` - Automated configuration script
- `docker-compose.yml` - Enable/disable broker mode here
- `keycloak-broker/realm/broker-realm.json` - Broker configuration
