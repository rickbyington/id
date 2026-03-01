# id

[![CI](https://github.com/rickbyington/id/actions/workflows/ci.yml/badge.svg)](https://github.com/rickbyington/id/actions/workflows/ci.yml) [![CodeQL](https://github.com/rickbyington/id/actions/workflows/codeql.yml/badge.svg)](https://github.com/rickbyington/id/actions/workflows/codeql.yml) [![Security](https://img.shields.io/badge/security-code%20scanning-blue)](https://github.com/rickbyington/id/security) [![codecov](https://codecov.io/gh/rickbyington/id/graph/badge.svg)](https://codecov.io/gh/rickbyington/id) [![Ruby](https://img.shields.io/badge/ruby-3.4-red.svg)](https://www.ruby-lang.org/) [![Release](https://img.shields.io/github/v/release/rickbyington/id)](https://github.com/rickbyington/id/releases)

Rails app: OAuth 2.0 / OpenID Connect identity provider (Doorkeeper, Devise).

**Environment variables:** see [ENV.md](ENV.md) for a full list of required and optional ENV vars.

## Local development

### Option 1: Docker (recommended)

Use the dev Docker Compose file (app + PostgreSQL):

```bash
cp .env.example .env
# Set SECRET_KEY_BASE and OIDC_PRIVATE_KEY
docker compose up -d
```

Open http://localhost:3000.

You can also use the `Makefile` shortcuts:

```bash
make build     # docker compose build
make up        # docker compose up -d
make logs      # follow logs
make shell     # sh into the app container
make migrate   # run db:migrate in the container
```

### Option 2: Native Ruby (optional)

If you prefer running Rails directly:

- Use **Ruby 3.4.7** (see `.ruby-version`).
- Install dependencies and prepare the database:

```bash
gem install bundler
bundle install
bin/rails db:prepare
bin/rails server
```

## Running CI locally

Run the same CI workflow as GitHub (lint, test, Brakeman, audits) using [act](https://github.com/nektos/act) in Docker:

```bash
make ci
```

## Testing

Unit and integration tests use Minitest. Coverage is reported by SimpleCov (see `/coverage` after `bin/rails test`). CI enforces a **90% minimum coverage**; aim for near 100% when adding features. Tests cover models (User, Permission, PhoneOtpCode), helpers, services (SmsService), phone OTP flows, OAuth, password/phone changes, admin, and health.

## Versioning

This project uses [Semantic Versioning](https://semver.org/). The version is in `VERSION` and shown in the app footer.

### Releasing

Releases are driven by [semantic-release](https://github.com/semantic-release/semantic-release) and [conventional commits](https://www.conventionalcommits.org/).

1. **Use conventional commits on `main`** so the next version is computed automatically:
   - `fix:` or `fix(scope):` → patch (e.g. 0.1.0 → 0.1.1)
   - `feat:` or `feat(scope):` → minor (e.g. 0.1.0 → 0.2.0)
   - `BREAKING CHANGE:` in a footer or `feat!:` → major (e.g. 0.1.0 → 1.0.0)
2. **Push to `main`.** The [Release](.github/workflows/release.yml) workflow runs, analyzes commits, updates `CHANGELOG.md` and `VERSION`, creates a GitHub release and tag (e.g. `v0.2.0`).
3. **The tag triggers [Docker Publish](.github/workflows/docker-publish.yml)** to build and push `id:<version>` and `id:standalone` to Docker Hub.

No manual tagging or release drafting is required.

## Docker

Two images are published:

| Image | Use case |
|-------|----------|
| `id:latest` / `id:0.1.0` | App only; expects Postgres (Compose or your own). |
| `id:standalone` / `id:0.1.0-standalone` | Single container with SQLite; pull and run, no external DB. |

### Standalone SQLite (pull and run)

One container, no external database. **First startup:** if you don’t pass any secrets, the entrypoint generates `storage/secrets.env` with `SECRET_KEY_BASE` and an OIDC key, and defaults to SQLite. Mount a volume for `storage/` so the file persists; on the next run it will reuse it.

**Minimal run (no ENV needed for first run):**

```bash
docker run -d -p 80:80 -v id_storage:/rails/storage --name id rickbyington/id:standalone
```

Open http://localhost:80. Data and the generated secrets file live in the `id_storage` volume. **For outgoing email** set `SMTP_USER_NAME`, `SMTP_PASSWORD`, `SMTP_ADDRESS`, `SMTP_PORT` (see [ENV.md](ENV.md)).

To provide your own secrets instead of auto-generation, pass `SECRET_KEY_BASE` and `OIDC_PRIVATE_KEY` as ENV or use a pre-populated `secrets.env` in the volume.

### Postgres (app + DB with Compose)

Run the app and a PostgreSQL database with one command:

1. Copy `.env.example` to `.env` and set `SECRET_KEY_BASE`, `OIDC_PRIVATE_KEY` (and optionally DB passwords).
2. `docker compose up -d`
3. Open http://localhost:3000

The app runs migrations on first boot. Data is stored in a named volume `postgres_data`. To use the published image instead of building locally, set `image: rickbyington/id:latest` in `docker-compose.yml` (and remove `build: .`).

### Building locally

Both images come from one Dockerfile. Default build is Postgres; use `--target standalone` for SQLite:

- Postgres: `docker build -t id:latest .`
- Standalone: `docker build --target standalone -t id:standalone .`

### Publishing to Docker Hub

The workflow `.github/workflows/docker-publish.yml` runs when a version tag (e.g. `v0.1.0`) is pushed. With semantic-release, that tag is pushed after CI passes; the tag must be pushed using a **Personal Access Token** or the Docker workflow will not trigger.

1. Add repo secrets: `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` (Docker Hub → Account Settings → Security → New Access Token).
2. Add repo secret **`GH_TOKEN`**: a GitHub Personal Access Token with `repo` scope (Settings → Developer settings → Personal access tokens). The Release workflow uses it to push the version tag so that the tag push triggers Docker Publish. Without `GH_TOKEN`, releases still run but Docker images are not built.
3. **(Optional)** Add repo secret **`CODECOV_TOKEN`**: sign up at [codecov.io](https://codecov.io) (free for public repos), add this repo, then paste the token so CI can upload coverage. Without it, the coverage upload step is skipped and the Codecov badge will show "unknown".
4. Run `bundle install` once so `Gemfile.lock` includes the `sqlite3` gem (required for the standalone image build).
5. Push to `main` (with conventional commits); after CI passes, Release runs and pushes a tag, which triggers the Docker workflow. Or push a tag manually: `git tag v0.1.0 && git push origin v0.1.0`.
6. The workflow builds and pushes both images: `id:<version>` and `id:latest` (Postgres), `id:<version>-standalone` and `id:standalone` (SQLite).