# Docker Compose dev targets (app + PostgreSQL).
# Usage: make build && make up
# Or: make up   (builds if needed)
#
# Ensure .env exists with SECRET_KEY_BASE, OIDC_PRIVATE_KEY (copy from .env.example).
# Inline recipes (;) so no TAB character is required—safe with any editor.

COMPOSE := docker compose
SERVICE := app
PORT    := 3000

.PHONY: build up down run run-bg stop logs shell migrate console clean clean-data ci

build: ; $(COMPOSE) build

up: ; $(COMPOSE) up -d ; echo "App at http://localhost:$(PORT)"

down: ; $(COMPOSE) down

run: ; $(COMPOSE) up

run-bg: up

stop: down

logs: ; $(COMPOSE) logs -f

shell: ; $(COMPOSE) exec $(SERVICE) sh

migrate: ; $(COMPOSE) run --rm $(SERVICE) bin/rails db:migrate

console: ; $(COMPOSE) exec $(SERVICE) bin/rails console

clean: down

clean-data: down ; $(COMPOSE) down -v ; echo "Stopped and removed volumes"

# Run the GitHub Actions CI workflow locally via [act](https://github.com/nektos/act) in Docker.
# Uses the same workflow file as GitHub; no act install required on the host.
ci:
	docker run --rm -it \
	  -v "$(CURDIR):/workspace" \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  -w /workspace \
	  -e DOCKER_HOST=unix:///var/run/docker.sock \
	  efrecon/act:v0.2.84 push -W .github/workflows/ci.yml -P ubuntu-latest=catthehacker/ubuntu:act-latest
