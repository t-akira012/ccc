# `claude --dangerously-skip-permissions` in Container

## これは何か

* Claude Code を `--dangerously-skip-permissions` モードで動かすための、コンテナ

## すぐ使うには

```
curl -L raw.githubusercontent.com/t-akira012/claude-code-compose/main/dl.sh | bash
```

## ファイル

```
$ tree
.
├── CLAUDE.md
├── compose.yaml
├── danger.sh
├── Dockerfile
├── Makefile
└── README.md
```

## 使い方

```
# コンテナを起動
$ make up

# コンテナに入る
$ make dev

# Claude Codeを認証
$ claude auth

# dangerously-skip-permissionsをモードで実行
$ ./danger.sh
```
