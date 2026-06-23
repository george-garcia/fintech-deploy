# Deployment — one EC2 box, Docker Compose + Caddy

All apps run on a single small EC2 instance (recommended **t4g.medium**, arm64) behind **Caddy**
(automatic HTTPS). One shared Postgres serves the ticketing + bank databases; the casino keeps SQLite.

## Subdomains (one domain: georgegarciadev.com)

| Host | → service | Notes |
|---|---|---|
| `georgegarciadev.com` | `portfolio` | apex + www |
| `helpdeskhero.georgegarciadev.com` | `ticketing-client` | Help Desk Hero console |
| `apis.georgegarciadev.com` | `ticketing-server:3001` | ticketing API (matches existing DNS) |
| `bank.georgegarciadev.com` | `mockbank-web` | |
| `bank-admin.georgegarciadev.com` | `mockbank-admin` | |
| `bank-api.georgegarciadev.com` | `mockbank-api:3000` | |
| `casino.georgegarciadev.com` | `casino-web` | |
| `casino-api.georgegarciadev.com` | `casino-server:4100` | |

## Local

```bash
docker compose up -d                 # reworked apps only (portfolio :8080, ticketing :8081, api :3001)
docker compose --profile bank --profile casino up -d   # + bank + casino
docker compose down
```

`AUTH_MODE=dev` (default) lets you sign into Help Desk Hero with any email — no AWS needed.

## AWS deploy

1. **Instance**: t4g.medium (arm64), Ubuntu 24.04, 20 GB gp3. Allocate an **Elastic IP**.
2. **Security group**: inbound 80, 443, 22 (SSH from your IP only).
3. **DNS** (Route 53 or your registrar): A records for the apex + each subdomain above → the Elastic IP.
4. **Bootstrap**: `sudo bash infra/ec2-bootstrap.sh` (installs Docker + Compose + swap).
5. **Deploy**: copy this repo to `/opt/fintech`, create `.env` from `.env.example`, then:
   ```bash
   cd /opt/fintech
   docker compose --profile bank --profile casino --profile edge up -d --build
   ```
   Caddy obtains certs automatically once DNS resolves to the box.

## Auth — Cognito (Help Desk Hero)

1. Create a **User Pool** + an **app client** (no client secret, SRP/USER_PASSWORD auth).
2. Create groups `agent` and `admin` (role is derived from group membership).
3. Set in `.env`: `TICKETING_AUTH_MODE=cognito`, `TICKETING_COGNITO_POOL_ID`, `TICKETING_COGNITO_CLIENT_ID`,
   `AWS_REGION`. Rebuild the client (Vite inlines these): `docker compose build ticketing-client`.

## Email — SES (portfolio contact)

1. Verify the sending domain/identity in SES; request production access (out of sandbox).
2. Deploy `infra/ses-contact/` as a Lambda (Node 20) behind an HTTP API Gateway; set `TO_ADDRESS`,
   `FROM_ADDRESS`, `ALLOWED_ORIGIN`.
3. Point the portfolio at it: replace the EmailJS call in
   `Portfolio/src/lib/sendContactMessage.ts` with a `fetch(POST)` to the API Gateway URL.

## Logs/metrics — Datadog

Set `DD_API_KEY` (+ `DD_SITE`) in `.env`. The `edge` profile runs the Datadog agent, which collects
container logs (the NestJS API already emits structured JSON via pino) + APM + host metrics.

## Migrations

- **Ticketing**: runs automatically on container start (`node dist/db/migrate.js`).
- **Mock Bank**: run once after first deploy —
  `docker compose exec mockbank-api pnpm --filter @mock-bank/database migrate`.

## Status / caveats

- **Verified**: `portfolio`, `ticketing-client`, `ticketing-server`, `postgres` build and run via
  `docker compose up`, with the ticketing API smoke-tested end-to-end.
- **Wired, build-verification pending**: `mockbank-*` (pnpm monorepo) and `casino-*` (native
  `better-sqlite3` + a GitHub-sourced SDK dep). Build them with
  `docker compose --profile bank --profile casino build` and iterate on any app-specific issues —
  these apps were out of the review scope.
