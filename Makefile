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
	docker compose exec claude-code bash

