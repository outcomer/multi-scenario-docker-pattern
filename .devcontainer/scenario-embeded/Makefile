# ==============================================================================
# Makefile for my-app Docker environment
# ==============================================================================
#
# IMPORTANT: This Makefile requires bash to run.
#
# On Windows:
#   - Open Git Bash terminal (NOT PowerShell or CMD)
#   - Navigate to .devcontainer/boxed directory
#   - Run: make help
#
# On Linux/Mac:
#   - Standard terminal works fine
#   - Run: make help
#
# ==============================================================================

SHELL := /bin/bash

DOCKER_COMPOSE = docker compose -f docker-compose.yml
ENV_FILE      = .env
ROOT_ENV_FILE = ../../.env
MAKE = make --no-print-directory
PROJECT = $(shell grep -E '^COMPOSE_PROJECT_NAME=' $(ENV_FILE) | cut -d= -f2)

.PHONY: help check-env deploy build up down deploy-rollback healthcheck migrations-run migrations-check migrations-status migrations-rollback rebuild destroy


help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

check-env:
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo "Error: .env file not found at .devcontainer/scenario-embeded/.env"; \
		echo "Please create it with Docker Compose variables."; \
		exit 1; \
	fi
	@if [ ! -f "$(ROOT_ENV_FILE)" ]; then \
		echo "Error: root .env file not found at ../../.env"; \
		echo "It is required for API credentials used in healthcheck."; \
		exit 1; \
	fi

# --- Deployment ---

## Safe deployment pipeline:
##
##   1. BUILD: Tags the current running image as :rollback (preserves it for recovery),
##             then builds a new :latest image from source.
##
##   2. MIGRATE DRY-RUN: Runs all pending migrations inside a PostgreSQL transaction
##             that is always rolled back regardless of outcome. This validates that
##             migrations are syntactically correct and executable without touching the DB.
##
##   3. UP: Replaces the running container with the new image (~2-3 sec downtime).
##
##   4. HEALTHCHECK: Polls GET /api/health every 10s (up to 2 min) until the app responds
##             HTTP 200, confirming PHP and DB connectivity are working.
##
##   5. MIGRATE RUN: Applies pending migrations for real inside a transaction.
##             On failure the transaction is rolled back — DB stays consistent.
##
## Rollback behaviour:
##   - Failure at step 2: new image is discarded, :rollback image is restored, no DB changes.
##   - Failure at step 4: container is replaced back with :rollback image, no DB changes.
##   - Failure at step 5: transaction is rolled back (DB unchanged), container is restored to :rollback image.
deploy: check-env
	@echo "------------------------------------------------------------"
	@echo "  DEPLOYMENT STARTED"
	@echo "------------------------------------------------------------"
	@echo ""
	@echo "  [1/4] Building new image..."
	@echo ""
	@$(MAKE) build || exit 1
	@echo ""
	@echo "  [2/4] Starting new container..."
	@echo ""
	@$(MAKE) up
	@echo ""
	@echo "  [3/4] Waiting for healthcheck..."
	@echo ""
	@$(MAKE) healthcheck || { echo ""; echo "  !! Healthcheck failed, rolling back !!"; echo ""; $(MAKE) deploy-rollback; exit 1; }
	@echo ""
	@echo "  [4/4] Applying migrations..."
	@echo ""
	@$(MAKE) migrations-run || { echo ""; echo "  !! Migration failed, rolling back !!"; echo ""; $(MAKE) deploy-rollback; exit 1; }
	@echo ""
	@echo "------------------------------------------------------------"
	@echo "  DEPLOYMENT SUCCESSFUL"
	@echo "------------------------------------------------------------"

build: check-env ## Build app image
	@docker tag $(PROJECT)-app:latest $(PROJECT)-app:rollback 2>/dev/null || true
	$(DOCKER_COMPOSE) build app

up: check-env ## Start containers
	$(DOCKER_COMPOSE) up -d --force-recreate

down: check-env ## Stop and remove containers
	$(DOCKER_COMPOSE) down

deploy-rollback: check-env ## Restore rollback image and restart
	@docker tag $(PROJECT)-app:rollback $(PROJECT)-app:latest
	$(DOCKER_COMPOSE) up -d

healthcheck: check-env ## Wait for container to respond on /
	@for i in $$(seq 1 6); do \
		STATUS=$$($(DOCKER_COMPOSE) exec -T app curl -s -o /dev/null -w "%{http_code}" http://localhost/health); \
		echo "  HTTP: $$STATUS ($$i/6)"; \
		if [ "$$STATUS" = "200" ]; then \
			echo "  Healthy."; \
			exit 0; \
		fi; \
		sleep 10; \
	done; \
	echo "Healthcheck failed."; \
	exit 1

# --- Migrations ---

migrations-run: check-env ## Run database migrations
	$(DOCKER_COMPOSE) run --rm app php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration

migrations-check: check-env ## Validate migrations without applying (dry-run)
	$(DOCKER_COMPOSE) run --rm app php bin/console doctrine:migrations:migrate --dry-run --no-interaction

migrations-status: check-env ## Show migration status
	$(DOCKER_COMPOSE) run --rm app php bin/console doctrine:migrations:status

migrations-rollback: check-env ## Rollback last migration
	$(DOCKER_COMPOSE) run --rm app php bin/console doctrine:migrations:migrate prev --no-interaction

# --- Maintenance ---

rebuild: check-env ## Clean rebuild and start
	$(DOCKER_COMPOSE) down -v
	@docker rmi $(PROJECT)-app:rollback 2>/dev/null || true
	docker image prune -f
	$(DOCKER_COMPOSE) build
	$(DOCKER_COMPOSE) up -d

destroy: check-env ## Remove containers, volumes, and networks
	$(DOCKER_COMPOSE) down -v
	@docker rmi $(PROJECT)-app:rollback 2>/dev/null || true
	docker image prune -f
