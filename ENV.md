# Environment variables

All secrets and configuration are read from environment variables. No Rails credentials or `config/master.key` is used.

## First startup (Docker)

When running the **standalone** Docker image, if no secrets file exists at `storage/secrets.env`, the entrypoint **generates** one on first run with:

- `SECRET_KEY_BASE` (random)
- `OIDC_PRIVATE_KEY` (newly generated RSA PEM string, stored as one line with `\n` in `secrets.env`)
- `DATABASE_ADAPTER=sqlite3` (so the rest defaults to local SQLite)

The file is written under the `storage/` volume so it persists. You can copy it out and reuse it. **For outgoing email** you still need to set SMTP vars (see Optional: mail below); the generated file includes a reminder comment.

Override the path with `SECRETS_FILE=/path/to/secrets.env` (e.g. a different volume).

On first server start, the entrypoint creates an **initial admin user** if none exists. Set `ADMIN_EMAIL` and `ADMIN_PASSWORD` in ENV (or in `secrets.env`) to choose credentials; otherwise the default is `admin@example.com` with a random password printed to the log.

## Required (production, when not using first-run generation)

| Variable | Description |
|----------|-------------|
| `SECRET_KEY_BASE` | Rails session signing/encryption. Generate: `openssl rand -hex 64` |
| `OIDC_PRIVATE_KEY` | RSA private key (PEM) for signing **OIDC ID tokens and JWT access tokens** (RS256). Public key for validation is at the OIDC discovery `jwks_uri`. In `.env`, use `\n` for newlines. Generate: `openssl genrsa 2048` |

## Database (PostgreSQL production)

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_HOST` | `localhost` | PostgreSQL host |
| `DATABASE_PORT` | `5432` | PostgreSQL port |
| `DATABASE_USERNAME` | `postgres` | PostgreSQL user |
| `DATABASE_PASSWORD` | (empty) | PostgreSQL password (used in `database.yml` for primary/cache/queue/cable) |

For SQLite (standalone Docker image): set `DATABASE_ADAPTER=sqlite3`. No DB host/user/password needed.

## OmniAuth (Sign in with Google / GitHub)

| Variable | Description |
|----------|-------------|
| `GOOGLE_CLIENT_ID` | Google OAuth 2.0 client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth 2.0 client secret |
| `GITHUB_CLIENT_ID` | GitHub OAuth app client ID |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth app client secret |
| `OMNIAUTH_FULL_HOST` | Override callback base URL (e.g. `https://id.example.com`). Used when redirect_uri must be exact. |

If Google or GitHub vars are unset, that provider is not shown on the sign-in page.

## Login methods

| Variable | Default | Description |
|----------|---------|-------------|
| `DEFAULT_LOGIN_METHODS` | `email,phone` | Comma-separated list when no OAuth client context: `email`, `phone`, `google`, `github`. Controls which options appear on the direct sign-in page. |

## Server / runtime

| Variable | Default | Description |
|----------|---------|-------------|
| `RAILS_ENV` | — | `development`, `test`, or `production` |
| `PORT` | `3000` | Puma port (development) |
| `RAILS_MAX_THREADS` | `3` (dev), `5` (DB pool) | Puma threads; also used for DB pool size |
| `WEB_CONCURRENCY` | — | Puma workers (see `config/puma.rb`) |
| `PIDFILE` | — | Optional Puma pid file path |
| `SOLID_QUEUE_IN_PUMA` | — | If set, run Solid Queue supervisor inside Puma (e.g. Kamal) |
| `JOB_CONCURRENCY` | `1` | Solid Queue processes (see `config/queue.yml`) |
| `RAILS_LOG_LEVEL` | `info` | Log level in production |
| `CI` | — | If set, eager load in test (see `config/environments/test.rb`) |

## SignalWire SMS (phone auth)

Required when using phone number sign-in or sign-up.

| Variable | Description |
|----------|-------------|
| `SIGNALWIRE_PROJECT_ID` | Project ID from your SignalWire dashboard |
| `SIGNALWIRE_API_TOKEN` | API token from your SignalWire dashboard |
| `SIGNALWIRE_SPACE_URL` | Your SignalWire space hostname, e.g. `yourspace.signalwire.com` |
| `SIGNALWIRE_FROM_NUMBER` | Your SignalWire phone number in E.164 format, e.g. `+15551234567` |

If these are unset, SMS delivery is silently skipped in development and raises an error in production.

## Optional: SMTP (sending email)

Required to send real email (confirmations, password reset, etc.). If all are unset, production does not send mail; development uses the in-memory test mailbox.

| Variable | Description |
|----------|-------------|
| `SMTP_ADDRESS` | SMTP server hostname (e.g. `smtp.example.com`) |
| `SMTP_PORT` | SMTP port (e.g. `587` for TLS, `465` for SSL) |
| `SMTP_USER_NAME` | SMTP username |
| `SMTP_PASSWORD` | SMTP password |
| `ACTION_MAILER_DEFAULT_HOST` | Host used in links inside emails (e.g. `id.example.com`). Should match your app URL. |
| `ACTION_MAILER_DEFAULT_PROTOCOL` | Protocol for those links (`https` or `http`). Default: `https`. |

## Optional (storage, etc.)

| Variable | Description |
|----------|-------------|
| `AWS_ACCESS_KEY_ID` | For Active Storage S3 (if enabled) |
| `AWS_SECRET_ACCESS_KEY` | For Active Storage S3 (if enabled) |

## Summary by use case

- **Minimal production (Postgres):** `SECRET_KEY_BASE`, `OIDC_PRIVATE_KEY`, `DATABASE_PASSWORD`, plus DB host/user if not localhost.
- **Standalone Docker (SQLite):** `SECRET_KEY_BASE` and `OIDC_PRIVATE_KEY`.
- **Sign in with Google:** `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`.
- **Sign in with GitHub:** `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`.
- **Phone sign-in / sign-up (SMS OTP):** `SIGNALWIRE_PROJECT_ID`, `SIGNALWIRE_API_TOKEN`, `SIGNALWIRE_SPACE_URL`, `SIGNALWIRE_FROM_NUMBER`.
