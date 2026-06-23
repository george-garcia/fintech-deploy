# fintech-deploy

One-box deployment for georgegarciadev.com: portfolio + Help Desk Hero (ticketing) + Mock Bank +
Lucky Spin Casino, behind Caddy (automatic HTTPS), with a shared Postgres and a Datadog agent.

This repo holds only the orchestration (compose + `infra/`). The app code lives in its own repos and
is pulled in by `scripts/clone-apps.sh`.

## Architecture

- **Caddy** terminates TLS and reverse-proxies each subdomain (see `infra/Caddyfile`).
- **Postgres** (one container) with isolated per-app users: `ticketing_user` -> `ticketing`,
  `mockbank_user` -> `mockbank`. The casino keeps its own **SQLite** on a volume.
- App + DB ports bind to `127.0.0.1`; only Caddy (80/443) is internet-facing.
- **Datadog** agent collects every container's logs.

| Subdomain | Service |
|---|---|
| georgegarciadev.com | portfolio |
| helpdeskhero. | ticketing-client |
| apis. | ticketing-server |
| bank. / bank-admin. / bank-api. | mockbank-web / -admin / -api |
| casino. / casino-api. | casino-web / casino-server |

## Deploy (Ubuntu 24.04 arm64, t4g.medium)

```bash
# 1. Install Docker (one time)
sudo bash infra/ec2-bootstrap.sh

# 2. Pull the app repos as siblings of docker-compose.yml
./scripts/clone-apps.sh

# 3. Configure secrets
cp .env.example .env && nano .env      # set passwords, Cognito, Datadog, prod URLs

# 4. Build + run everything
docker compose --profile bank --profile casino --profile edge up -d --build
```

Caddy issues certificates automatically once the subdomains' DNS A-records point at the box's Elastic IP.

## Updating an app later

```bash
git -C <app-dir> pull
docker compose up -d --build <service>
```
