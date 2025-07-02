# `claude --dangerously-skip-permissions` in Container

## これは何か

* Claude Code を `--dangerously-skip-permissions` モードで動かすための、コンテナ

## すぐ使うには

1. 以下を行う
```
curl -L raw.githubusercontent.com/t-akira012/ccc/main/dl.sh | bash
```
2. `./.ccc` 以下にファイルが展開される
3. `cd .ccc && make` でコンテナの中に入る
4. `ccd` で、`claude --dangerously-skip-permissions` で起動する

## ファイル

```
$ tree
.
├── CLAUDE.md
├── compose.yaml
├── mcp.sh            # claude mcp addを列挙したシェル。コンテナに入った時に、.bashrcでロードされる
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
