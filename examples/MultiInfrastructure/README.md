# BaSyx Multi-Infrastructure Example with Keycloak Broker

This example demonstrates a multi-infrastructure BaSyx setup with centralized authentication using Keycloak as an identity broker.

## Quick Start

```bash
# Start all services
docker compose up -d

# Wait for services to be ready (takes ~2-3 minutes)
# You can check status with:
docker compose ps

# Access the Web UI
open https://aasgui.basyx.localhost
# or
open http://localhost:3000
```

## What You'll See

When you access the Web UI, you'll be redirected to the Keycloak broker login page with options to authenticate via:

1. **Infrastructure 1** - Click to login with users from Infrastructure 1
2. **Infrastructure 3** - Click to login with users from Infrastructure 3  
3. **Or login directly** with broker credentials

## Test Users

### Broker Users (Direct Login)
- Username: `broker.admin` / Password: `admin123` (admin role)
- Username: `broker.user` / Password: `user123` (user role)

### Infrastructure 1 & 3 Users
- Username: `john` / Password: `john` (admin)
- Username: `jane.doe` / Password: `jane` (user)
- Username: `paul.visitor` / Password: `paul` (visitor)
- And many more (see realm files for complete list)

## Architecture

```
Web UI → Broker Keycloak → Choose Infrastructure
              ↓
    Infra1 or Infra3 Keycloak
              ↓
        User Authenticates
              ↓
    Federated Access to Both Infrastructures
```

## Key Features

- **Single Sign-On (SSO):** Authenticate once, access multiple infrastructures
- **Identity Federation:** Users from Infrastructure 1 can access Infrastructure 3 and vice versa
- **Centralized Management:** Manage authentication policies in one place
- **Secure:** All services protected with Keycloak RBAC
- **Production-Ready:** SSL certificates included (self-signed for local dev)

## Services & Ports

| Service | URL | Port | Credentials |
|---------|-----|------|-------------|
| Web UI | https://aasgui.basyx.localhost | 3000 | (via Keycloak) |
| Broker Keycloak | https://keycloak-broker.basyx.localhost | 9099 | admin / keycloak-admin |
| Keycloak Infra1 | https://keycloak.trameri.basyx.localhost | 9097 | admin / keycloak-admin |
| Keycloak Infra3 | https://keycloak.eurogoodies.basyx.localhost | 9098 | admin / keycloak-admin |
| AAS Env Infra1 | https://aasenv.trameri.basyx.localhost | 8081 | (secured) |
| AAS Env Infra2 | http://localhost:9081 | 9081 | (unsecured) |
| AAS Env Infra3 | https://aasenv.eurogoodies.basyx.localhost | 8181 | (secured) |
| AAS Registry Infra1 | https://aasreg.trameri.basyx.localhost | 8082 | (secured) |
| AAS Registry Infra2 | http://localhost:9082 | 9082 | (unsecured) |
| AAS Registry Infra3 | https://aasreg.eurogoodies.basyx.localhost | 8182 | (secured) |

## Infrastructure Overview

- **Infrastructure 1:** Fully secured with Keycloak authentication
- **Infrastructure 2:** Unsecured (no authentication required)
- **Infrastructure 3:** Fully secured with Keycloak authentication
- **Broker:** Federates authentication between Infrastructure 1 and 3

## Documentation

- **QUICK_REFERENCE.md** - One-page quick reference
- **BROKER_SETUP.md** - Detailed setup and architecture documentation
- **BROKER_CONFIGURATION_SUMMARY.md** - What was configured and why

## Stopping Services

```bash
# Stop all services
docker compose down

# Stop and remove volumes (reset to clean state)
docker compose down -v
```

## Troubleshooting

### Certificate Warnings
The setup uses self-signed SSL certificates. Your browser will show security warnings - this is expected for local development. Click "Advanced" and proceed to accept the certificate.

### Services Not Ready
Give the services 2-3 minutes to start. Keycloak takes the longest to initialize. Check status:
```bash
docker compose logs -f keycloak-broker
docker compose logs -f keycloak-trameri
docker compose logs -f keycloak-eurogoodies
```

### Can't Access Services
Ensure all containers are running:
```bash
docker compose ps
```

All services should show "Up" status. If any are restarting, check logs:
```bash
docker compose logs [service-name]
```

## Advanced Configuration

### Switching Back to Direct Infrastructure 1 Auth
If you want to disable the broker and use direct Infrastructure 1 authentication:

1. Edit `docker-compose.yml`
2. In the `aas-web-ui` service, change:
   ```yaml
   KEYCLOAK_URL: https://keycloak.trameri.basyx.localhost
   KEYCLOAK_REALM: BaSyx
   ```
3. Restart: `docker compose restart aas-web-ui`

### Adding More Infrastructures
To add additional infrastructures to the broker:

1. Create a new infrastructure configuration (copy Infrastructure1 or 3)
2. Add an identity provider to the broker realm configuration
3. Add a broker client to the new infrastructure's realm
4. Update docker-compose.yml to include the new infrastructure

See **BROKER_SETUP.md** for detailed instructions.

## Support

For issues or questions about BaSyx, visit:
- GitHub: https://github.com/eclipse-basyx
- Documentation: https://wiki.eclipse.org/BaSyx
