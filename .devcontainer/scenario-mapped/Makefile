# ==============================================================================
# Makefile for my-app Docker environment
# ==============================================================================
# 
# IMPORTANT: This Makefile requires bash to run.
# 
# On Windows:
#   - Open Git Bash terminal (NOT PowerShell or CMD)
#   - Navigate to .devcontainer/mapped directory
#   - Run: make help
# 
# On Linux/Mac:
#   - Standard terminal works fine
#   - Run: make help
# 
# ==============================================================================

SHELL := /bin/bash

DOCKER_COMPOSE = docker compose -f docker-compose.yml
ENV_FILE = .env

.PHONY: help up down restart rebuild destroy migrations-run migrations-status migrations-rollback migrations-create install update check-env

check-env:
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo "Error: .env file not found at .devcontainer/scenario-mapped/.env"; \
		echo ""; \
		echo "Please create a symlink:"; \
		echo "  On Linux/Mac: ln -s ../../.env .devcontainer/scenario-mapped/.env"; \
		echo "  On Windows (Git Bash): ln -s ../../.env .devcontainer/scenario-mapped/.env"; \
		echo "  Or configure git: git config core.symlinks true"; \
		exit 1; \
	fi

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: check-env ## Start containers in detached mode
	$(DOCKER_COMPOSE) up -d

down: check-env ## Stop and remove containers
	$(DOCKER_COMPOSE) down

restart: check-env ## Rebuild and restart containers
	$(DOCKER_COMPOSE) down
	$(DOCKER_COMPOSE) build
	$(DOCKER_COMPOSE) up -d

rebuild: check-env ## Clean rebuild and start
	$(DOCKER_COMPOSE) down -v
	docker system prune -f
	$(DOCKER_COMPOSE) build
	$(DOCKER_COMPOSE) up -d

destroy: check-env ## Remove containers, volumes, and networks
	$(DOCKER_COMPOSE) down -v
	docker system prune -f

migrations-run: check-env ## Run database migrations
	$(DOCKER_COMPOSE) exec app php bin/console doctrine:migrations:migrate --no-interaction

migrations-status: check-env ## Show migration status
	$(DOCKER_COMPOSE) exec app php bin/console doctrine:migrations:status

migrations-rollback: check-env ## Rollback last migration
	$(DOCKER_COMPOSE) exec app php bin/console doctrine:migrations:migrate prev --no-interaction

migrations-create: check-env ## Generate new migration
	$(DOCKER_COMPOSE) exec app php bin/console doctrine:migrations:generate

install: check-env ## Install Composer dependencies
	$(DOCKER_COMPOSE) exec app composer install --no-interaction --prefer-dist --optimize-autoloader

update: check-env ## Update Composer dependencies
	$(DOCKER_COMPOSE) exec app composer update

cs: check-env ## Check code style (dry-run)
	$(DOCKER_COMPOSE) exec app composer cs

cs-fix: check-env ## Fix code style automatically
	$(DOCKER_COMPOSE) exec app composer cs-fix

analyze: check-env ## Run code analysis (alias for cs)
	$(DOCKER_COMPOSE) exec app composer analyze
