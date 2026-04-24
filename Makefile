CCC_DIR := $(HOME)/.local/.claude-code
WORKSPACE_DIR := $(CURDIR)

PROJECT := ccc_$(shell echo "$(WORKSPACE_DIR)" | shasum | cut -c1-12)
SERVICE_NAME := claude-code-container_origin_name
COMPOSE_ARGS := -p $(PROJECT) -f $(CCC_DIR)/compose.yaml --project-directory $(CCC_DIR)
COMPOSE := WORKSPACE_DIR=$(WORKSPACE_DIR) \
	CCC_DIR=$(CCC_DIR) \
	docker-compose \
	-p $(PROJECT) \
	-f $(CCC_DIR)/compose.yaml \
	--project-directory $(CCC_DIR)

.DEFAULT_GOAL := run

.PHONY: run up down build build-nocache logs restart clean dev bedrock

run: up dev

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

build:
	DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 $(COMPOSE) build

build-nocache:
	DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 $(COMPOSE) build --no-cache

logs:
	$(COMPOSE) logs -f

restart:
	$(COMPOSE) restart

clean:
	$(CCC_DIR)/clean.sh

dev:
	@echo "==========================================================="
	@echo "Claude Code コンテナに入ります"
	@echo "対象: $(WORKSPACE_DIR)"
	@echo "PROJECT: $(PROJECT)"
	@echo "==========================================================="
	WORKSPACE_DIR=$(WORKSPACE_DIR) \
	CCC_DIR=$(CCC_DIR) \
	SERVICE_NAME=$(SERVICE_NAME) \
	COMPOSE_ARGS="$(COMPOSE_ARGS)" \
	$(CCC_DIR)/run normal

bedrock: up
	@echo "==========================================================="
	@echo "Claude Code コンテナに入ります"
	@echo "対象: $(WORKSPACE_DIR)"
	@echo "PROJECT: $(PROJECT)"
	@echo "==========================================================="
	WORKSPACE_DIR=$(WORKSPACE_DIR) \
	CCC_DIR=$(CCC_DIR) \
	SERVICE_NAME=$(SERVICE_NAME) \
	COMPOSE_ARGS="$(COMPOSE_ARGS)" \
	$(CCC_DIR)/run bedrock
