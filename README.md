# id

Rails app: OAuth 2.0 / OpenID Connect identity provider (Doorkeeper, Devise).

**Environment variables:** see [ENV.md](ENV.md) for a full list of required and optional ENV vars.

## Local development

### Option 1: Docker (recommended)

Use the dev Docker Compose file (app + PostgreSQL):

```bash
cp .env.example .env
# Set SECRET_KEY_BASE, JWT_SECRET, and OIDC_PRIVATE_KEY
docker compose -f docker-compose.dev.yml up -d
```

Open http://localhost:3000.

You can also use the `Makefile` shortcuts:

```bash
make build     # docker compose -f docker-compose.dev.yml build
make up        # docker compose -f docker-compose.dev.yml up -d
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

## Versioning

This project uses [Semantic Versioning](https://semver.org/). The version is in `VERSION` and shown in the app footer.

### Releasing

1. Bump `VERSION` (e.g. `0.1.0` → `0.2.0`).
2. Add an entry under `[Unreleased]` in `CHANGELOG.md`, then move it under a new `[X.Y.Z]` heading with the release date.
3. Commit: `git add VERSION CHANGELOG.md && git commit -m "Release vX.Y.Z"`.
4. Tag and push: `git tag vX.Y.Z && git push origin main --tags`.
5. Create a [GitHub Release](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) from the tag and paste the changelog entry.

Replace `your-org/id` in `CHANGELOG.md` links with your GitHub org/repo.

## Docker

Two images are published:

| Image | Use case |
|-------|----------|
| `id:latest` / `id:0.1.0` | App only; expects Postgres (Compose or your own). |
| `id:standalone` / `id:0.1.0-standalone` | Single container with SQLite; pull and run, no external DB. |

### Standalone SQLite (pull and run)

One container, no external database. **First startup:** if you don’t pass any secrets, the entrypoint generates `storage/secrets.env` with `SECRET_KEY_BASE`, `JWT_SECRET`, and an OIDC key, and defaults to SQLite. Mount a volume for `storage/` so the file persists; on the next run it will reuse it.

**Minimal run (no ENV needed for first run):**

```bash
docker run -d -p 80:80 -v id_storage:/rails/storage --name id your-org/id:standalone
```

Open http://localhost:80. Data and the generated secrets file live in the `id_storage` volume. **For outgoing email** set `SMTP_USER_NAME`, `SMTP_PASSWORD`, `SMTP_ADDRESS`, `SMTP_PORT` (see [ENV.md](ENV.md)).

To provide your own secrets instead of auto-generation, pass `SECRET_KEY_BASE`, `JWT_SECRET`, and `OIDC_PRIVATE_KEY` as ENV or use a pre-populated `secrets.env` in the volume.

### Postgres (app + DB with Compose)

Run the app and a PostgreSQL database with one command:

1. Copy `.env.example` to `.env` and set `SECRET_KEY_BASE`, `JWT_SECRET` (and optionally OIDC key, DB passwords).
2. `docker compose -f docker-compose.dev.yml up -d`
3. Open http://localhost:3000

The app runs migrations on first boot. Data is stored in a named volume `postgres_data`. To use the published image instead of building locally, set `image: your-org/id:latest` in `docker-compose.dev.yml` (and remove `build: .`).

### Building locally

Both images come from one Dockerfile. Default build is Postgres; use `--target standalone` for SQLite:

- Postgres: `docker build -t id:latest .`
- Standalone: `docker build --target standalone -t id:standalone .`

### Publishing to Docker Hub

The workflow `.github/workflows/docker-publish.yml` runs on push of a version tag (e.g. `v0.1.0`).

1. Add repo secrets: `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` (Docker Hub → Account Settings → Security → New Access Token).
2. Run `bundle install` once so `Gemfile.lock` includes the `sqlite3` gem (required for the standalone image build).
3. Push a tag: `git tag v0.1.0 && git push origin v0.1.0`
4. The workflow builds and pushes both images: `id:<version>` and `id:latest` (Postgres), `id:<version>-standalone` and `id:standalone` (SQLite).
