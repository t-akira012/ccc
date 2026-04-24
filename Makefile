CCC_DIR := $(HOME)/.local/.claude-code
WORKSPACE_DIR := $(CURDIR)
COMPOSE := WORKSPACE_DIR=$(abspath $(WORKSPACE_DIR)) CCC_DIR=$(CCC_DIR) docker-compose -f $(CCC_DIR)/compose.yaml --project-directory $(CCC_DIR)

.DEFAULT_GOAL := run
.PHONY: up down build build-nocache logs restart clean dev bedrock deploy

run: up dev

# Docker Compose コマンド
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

# 開発環境アクセス
dev:
	echo "==========================================================="
	echo "Claude Code コンテナに入ります"
	echo "対象: $WORKSPACE_DIR"
	echo "==========================================================="
	export CONTAINER_NAME=claude-code-container_origin_name; export COMPOSE_ARGS="-f $(CCC_DIR)/compose.yaml --project-directory $(CCC_DIR)"; $(CCC_DIR)/run normal

bedrock: up
	echo "==========================================================="
	echo "Claude Code コンテナに入ります"
	echo "対象: $WORKSPACE_DIR"
	echo "==========================================================="
	export CONTAINER_NAME=claude-code-container_origin_name; export COMPOSE_ARGS="-f $(CCC_DIR)/compose.yaml --project-directory $(CCC_DIR)"; $(CCC_DIR)/run bedrock
