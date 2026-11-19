.DEFAULT_GOAL := help

.PHONY: help network up up-build down down-volumes build db-init logs rspec ps

help: ## Show available commands
	@grep -E '^[a-zA-Z_%-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "%-16s %s\n", $$1, $$2}'

network: ## Create the shared Docker network if it does not exist
	@docker network inspect mediavault >/dev/null 2>&1 || docker network create mediavault

up: ## Start the application in the background
	docker compose up -d

up-build: ## Build images and start the application in the background
	docker compose up --build -d

down: ## Stop and remove containers, keeping database data
	docker compose down

down-volumes: ## Stop and remove containers and volumes (deletes database data)
	docker compose down --volumes

build: ## Build application images
	docker compose build

db-init: ## Prepare the database and seed the initial user (requires running services)
	docker compose exec backend bundle exec rails db:prepare && docker compose exec backend bundle exec rails db:seed

logs: ## Follow logs from all services
	docker compose logs --follow

logs-%: ## Follow logs for a service (e.g. make logs-backend; services: backend, db, redis, sidekiq)
	docker compose logs --follow $*

rspec: ## Run RSpec (use SPEC=path/to/spec for one file)
	docker compose exec backend bundle exec rspec $(SPEC)

ps: ## Show service status
	docker compose ps
