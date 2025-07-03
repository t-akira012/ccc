run: up dev

# Docker Compose コマンド
up:
	docker compose up -d

down:
	docker compose down

build:
	docker compose build

build-nocache:
	docker compose build --no-cache

logs:
	docker compose logs -f

restart:
	docker compose restart

# 開発環境アクセス
dev:
	docker compose exec claude-code-container_origin_name bash

deploy:
	export CURRENT_DIR=$$(pwd) && echo $$CURRENT_DIR && echo create-reverce-symlink && mv $$CURRENT_DIR $$HOME/ccc/.ccc && ln -si $$HOME/ccc/.ccc $${CURRENT_DIR}
