# CCC: `claude --dangerously-skip-permissions` in Container

## これは何か

* Claude Code を安全に `--dangerously-skip-permissions` モードで動かすための、コンテナ

## 目的


* Claude Code を `--dangerously-skip-permissions` モードで動すと、システムファイルを壊される恐れがあります。
* そこで、Claude Code をコンテナに隔離することで、安全に動作させます。

## 使い方

* このコンテナは、対象リポジトリの `git-root/.claude-code` に配置する想定です。
* リポジトリのファイルはコンテナ内部の `/workspace` に配置されます。

### ディレクトリ構成

```
.
├── .claude-code/           # Claude Codeのコンテナ関連ファイル
│   ├── .env
│   ├── Dockerfile
│   :
│
├── README.md     # リポジトリの中身 ( コンテナ内で /workspace に bind される)
:
```

## 使用したいリポジトリの `.claude-code` に配置する

* `curl | bash` でdownload ~ 配置できるようにしています。

```
curl -s https://raw.githubusercontent.com/t-akira012/ccc/refs/heads/main/dl.sh | bash
```

## 使い方

```
# イメージをビルド
$ make build-nocache

# コンテナに入る
$ make

# dangerously-skip-permissionsをモードで実行 (claude --dangerously-skip-permissions のalias)
$ ccd
```
