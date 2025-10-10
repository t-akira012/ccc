# CCC: `claude --dangerously-skip-permissions` in Container

## これは何か

* Claude Code を `--dangerously-skip-permissions` モードで動かすための、コンテナ

## 使用したいリポジトリの `.claude-code` に配置する

```
curl -s https://raw.githubusercontent.com/t-akira012/ccc/refs/heads/main/dl.sh | bash
```

## 使い方

```
# イメージをビルド
$ make build-nocache

# コンテナに入る
$ make

# Claude Codeを認証
$ claude auth

# dangerously-skip-permissionsをモードで実行
$ ccd
```
