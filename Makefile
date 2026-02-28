# Docker Compose dev targets (app + PostgreSQL).
# Usage: make build && make up
# Or: make up   (builds if needed)
#
# Ensure .env exists with SECRET_KEY_BASE, JWT_SECRET (copy from .env.example).
# Inline recipes (;) so no TAB character is required—safe with any editor.

COMPOSE := docker compose -f docker-compose.dev.yml
SERVICE := app
PORT    := 3000

.PHONY: build up down run run-bg stop logs shell migrate console clean clean-data

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
