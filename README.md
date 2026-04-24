# CCC: `claude --dangerously-skip-permissions` in Container

## これは何か

* Claude Code を安全に `--dangerously-skip-permissions` モードで動かすための、コンテナ

## 目的


* Claude Code を `--dangerously-skip-permissions` モードで動すと、システムファイルを壊される恐れがあります。
* そこで、Claude Code をコンテナに隔離することで、安全に動作させます。

## 使い方

* このコンテナは、ホストマシンの `$HOME/.claude-code` に配置する想定です。
* リポジトリのファイルはコンテナ内部の `/workspace` に配置されます。

### ディレクトリ構成

```
.
├── README.md     # リポジトリの中身 ( コンテナ内で /workspace に bind される)
:
```

## ホストマシンの `$HOME/.local/.claude-code` に配置する

* `curl | bash` でdownload ~ 配置できるようにしています。

```
cd $HOME/.local/
curl -s https://raw.githubusercontent.com/t-akira012/ccc/refs/heads/main/dl.sh | bash
```

ホストマシンの `.bashrc` などで `host.sh` を読み込みます。

```
source "$HOME/.local/.claude-code/host.sh"
```

## 実行手順

```
# イメージをビルド
$ ccc build-nocache

# コンテナに入る
$ ccc

# dangerously-skip-permissionsをモードで実行 (claude --dangerously-skip-permissions のalias)
$ ccd
```

### 細かい使い方

#### ホストマシンのCLAUDE.mdを読みたい

* ホストマシンの `~/.config/claude/` はコンテナにbindされますので、自動でロードされます。

#### MCPを自動でインストールしたい

* `mcp.sh` に `claude mcp` コマンドを列挙してください。Claude Codeの実行時に自動でロードされます。
* デフォルトでは、Serena MCPと AWS ドキュメントMCPサーバーを導入しています。

#### コンテナの `.bashrc` に追記をしたい

* aliasやexportをしたいときに`.bashrc` に追記をしたいことがあると思います。
* `bashrc-ex.sh` が自動で `.bashrc` からsourceされます。こちらに追記をしてください。


### おまけ

* Gemini CLIと、Codex CLIも同梱しています。
* いずれもホストマシンのConfigディレクトリをコンテナにbindしているので、ローカルの設定を使えます。

### その他

#### VPN用に用意した社内信頼CA証明書が使えない

* VPNなどの環境で動かすためにコンテナ内部に `/etc/ssl/certs/ca-certificates.crt` を社内信頼証明書に追加したが、curlやgitなどがエラーになる
* Cloudflare ZeroTrust環境で発生
* 仕方ないので `GIT_SSL_NO_VERIFY=true` にしている
