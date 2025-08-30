# Containerized Claude Code

## これは何か

* Claude Code を `--dangerously-skip-permissions` モードで動かすための、コンテナ
* Gemini CLI, Codex CLI, Claude Codeが入っています

## 注意

* Codex CLIはコンテナ内部でログインができないため、以下の手順でログインする
```
# ホストマシンで実施
$ codex login

# (VPSで動かしているなら)authファイルをコピー
$ cat $HOME/.codex/auth.json
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
