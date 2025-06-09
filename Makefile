# =============================================================================
# WSL-Setup-Tool • Multi-Language Development Makefile
# =============================================================================

# You can run:  make,  make dev,  make test,  make rebuild, …
.DEFAULT_GOAL := help
SVC ?= devcontainer  # primary service name (matches docker-compose.yml)

# ----------------------------------------------------------------------------- #
# Helper functions
define green
	@printf "\033[32m$1\033[0m\n"
endef

define blue
	@printf "\033[34m$1\033[0m\n"
endef

# ----------------------------------------------------------------------------- #
# .env generation (only if missing)
.env:
	$(call green,📄  Generating .env)
	@{ \
	  echo "LOCAL_UID=$(shell id -u)"; \
	  echo "LOCAL_GID=$(shell id -g)"; \
	  echo "VCS_REF=$(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)"; \
	  echo "BUILD_DATE=$(shell date -u +%Y-%m-%dT%H:%M:%SZ)"; \
	} > .env

# ----------------------------------------------------------------------------- #
# Development lifecycle
dev-up: .env ## Build & start dev container
	$(call green,🏗️  Building container)
	@DOCKER_BUILDKIT=1 docker compose build --pull
	$(call green,🚀  Starting container)
	@docker compose up --wait -d
	$(call green,💡  Run: docker compose exec $(SVC) bash)

dev-down: ## Stop dev container
	$(call green,🛑  Stopping)
	@docker compose down

dev-rebuild: .env ## Rebuild from scratch (no cache)
	$(call green,♻️  Full rebuild)
	@DOCKER_BUILDKIT=1 docker compose build --no-cache --pull

dev-shell: ## Open interactive shell in dev container
	@docker compose exec $(SVC) bash

dev-clean: ## Remove containers, images & *named* volumes (data-loss!)
	$(call green,🧹  Cleaning everything – this may delete volumes)
	@docker compose down -v --rmi local

dev: dev-up dev-shell ## Quick: up + shell

# ----------------------------------------------------------------------------- #
# Python development
py-test: ## Run Python tests with pytest
	@docker compose exec $(SVC) bash -c "pytest -v"

py-lint: ## Run Python linting with Ruff
	@docker compose exec $(SVC) bash -c "ruff check ."

py-format: ## Format Python code with Ruff
	@docker compose exec $(SVC) bash -c "ruff format ."

py-typecheck: ## Run Python type checking with mypy
	@docker compose exec $(SVC) bash -c "mypy ."

py-check: py-lint py-typecheck ## Full Python code quality check

# ----------------------------------------------------------------------------- #
# Java development
java-build: ## Build Java project with Maven
	@docker compose exec $(SVC) bash -c "mvn clean compile"

java-test: ## Run Java tests with Maven
	@docker compose exec $(SVC) bash -c "mvn test"

java-package: ## Package Java application
	@docker compose exec $(SVC) bash -c "mvn clean package"

gradle-build: ## Build Java project with Gradle
	@docker compose exec $(SVC) bash -c "gradle build"

gradle-test: ## Run Java tests with Gradle
	@docker compose exec $(SVC) bash -c "gradle test"

java-clean: ## Clean Java build artifacts
	@docker compose exec $(SVC) bash -c "mvn clean && gradle clean"

# ----------------------------------------------------------------------------- #
# Rust development
rust-build: ## Build Rust project
	@docker compose exec $(SVC) bash -c "cargo build"

rust-test: ## Run Rust tests
	@docker compose exec $(SVC) bash -c "cargo test"

rust-check: ## Check Rust code (fast compile check)
	@docker compose exec $(SVC) bash -c "cargo check"

rust-lint: ## Run Rust linting with Clippy
	@docker compose exec $(SVC) bash -c "cargo clippy -- -D warnings"

rust-format: ## Format Rust code with rustfmt
	@docker compose exec $(SVC) bash -c "cargo fmt"

rust-release: ## Build Rust project in release mode
	@docker compose exec $(SVC) bash -c "cargo build --release"

rust-clean: ## Clean Rust build artifacts
	@docker compose exec $(SVC) bash -c "cargo clean"

# ----------------------------------------------------------------------------- #
# Cross-language quality checks
test: ## Run all tests (Python, Java, Rust)
	$(call blue,🐍  Running Python tests...)
	@docker compose exec $(SVC) bash -c "[ -f pyproject.toml ] && pytest -q || echo 'No Python tests found'"
	$(call blue,☕  Running Java tests...)
	@docker compose exec $(SVC) bash -c "[ -f pom.xml ] && mvn -q test || [ -f build.gradle ] && gradle -q test || echo 'No Java tests found'"
	$(call blue,🦀  Running Rust tests...)
	@docker compose exec $(SVC) bash -c "[ -f Cargo.toml ] && cargo test || echo 'No Rust tests found'"

lint: ## Run all linters
	$(call blue,🐍  Linting Python...)
	@docker compose exec $(SVC) bash -c "[ -f pyproject.toml ] && ruff check . || echo 'No Python project found'"
	$(call blue,🦀  Linting Rust...)
	@docker compose exec $(SVC) bash -c "[ -f Cargo.toml ] && cargo clippy -- -D warnings || echo 'No Rust project found'"

format: ## Format all code
	$(call blue,🐍  Formatting Python...)
	@docker compose exec $(SVC) bash -c "[ -f pyproject.toml ] && ruff format . || echo 'No Python project found'"
	$(call blue,🦀  Formatting Rust...)
	@docker compose exec $(SVC) bash -c "[ -f Cargo.toml ] && cargo fmt || echo 'No Rust project found'"

check: lint ## Universal code quality check

# ----------------------------------------------------------------------------- #
# Tool versions
versions: ## Show installed tool versions
	$(call green,📋  Installed tool versions:)
	@docker compose exec $(SVC) bash -c "echo 'Python:' && python3 --version"
	@docker compose exec $(SVC) bash -c "echo 'Java:' && java --version | head -1"
	@docker compose exec $(SVC) bash -c "echo 'Rust:' && rustc --version"
	@docker compose exec $(SVC) bash -c "echo 'Maven:' && mvn --version | head -1"
	@docker compose exec $(SVC) bash -c "echo 'Gradle:' && gradle --version | head -1"
	@docker compose exec $(SVC) bash -c "echo 'UV:' && uv --version"

# ----------------------------------------------------------------------------- #
# Status & logs
status: ## Show container status
	@docker compose ps

logs: ## Tail logs
	@docker compose logs -f $(SVC)

# ----------------------------------------------------------------------------- #
# Help (auto-generated)
help: ## Show this help
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' 