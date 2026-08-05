# CCC: `claude --dangerously-skip-permissions` in Container

設計とツール選定方針は [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) を参照してください。

## これは何か

* Claude Code を安全に `--dangerously-skip-permissions` モードで動かすための、コンテナ

## 目的


* Claude Code を `--dangerously-skip-permissions` モードで動すと、システムファイルを壊される恐れがあります。
* そこで、Claude Code をコンテナに隔離することで、安全に動作させます。

## 使い方

* このコンテナは、ホストマシンの `$HOME/.local/.claude-code` に配置する想定です。
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

## ログイン

複数コンテナを並行で動かすため、回転する対話 login トークンではなく、回転しない長期トークンを一本だけ共有します。これにより、何台並行しても refresh 競合で login が外れることがありません。

初回のみ、長期トークンを発行します。`host.sh` の `ccc_login` を実行すると、書き込み可能な使い捨てコンテナで `claude setup-token` が起動します。画面に表示されたトークンを貼り付けると、ホストの `~/.local/ccc/ccc-oauth-token` に保存されます（ブラウザ認可と貼り付けが初回の一度だけ。setup-token はトークンを画面表示する方式のため、貼り付けは省けません)。

```
$ ccc_login
```

以降は `ccc` 実行時に `host.sh` がこのトークンを読み、`CLAUDE_CODE_OAUTH_TOKEN` として env でコンテナへ注入します。トークンのファイル自体はコンテナへ bind mount せず、値だけを渡すため、隔離コンテナにホストの保管庫を晒しません。回転する `.credentials.json` はコンテナ内では空ファイルで隠され、長期トークンが使われます。

bedrock モードは AWS 認証で動くため、このトークン処理は実行されません。

### 細かい使い方

#### ホストマシンのCLAUDE.mdを読みたい

* ホストマシンの `~/.config/claude/` はコンテナにbindされますので、自動でロードされます。

#### MCPを自動でインストールしたい

* `mcp.sh` に `claude mcp` コマンドを列挙してください。Claude Codeの実行時に自動でロードされます。
* デフォルトでは、Serena MCPと AWS ドキュメントMCPサーバーを導入しています。

#### コンテナの `.bashrc` に追記をしたい

* aliasやexportをしたいときに`.bashrc` に追記をしたいことがあると思います。
* `bashrc-ex.sh` が自動で `.bashrc` からsourceされます。こちらに追記をしてください。


### 同梱しているAIエージェント

* Claude CodeはAnthropic公式のnative installer、Codex CLIはOpenAI公式のstandalone installerで導入します。
* Gemini CLIに加えてHermes Agentも同梱しています。
* Codexの設定はホストの `~/.codex`、Hermesの設定と状態は `~/.hermes` をコンテナにbindして引き継ぎます。
* Hermesを初めて使うときは、コンテナ内で `hermes setup --portal` または `hermes setup` を実行してください。
* TerraformもHashiCorp公式Homebrew tapから導入しています。
* 軽量な文書変換・解析用CLIとしてPandocも利用できます。
* 言語環境はasdfではなくmiseでビルド時に構築し、Node.js、Go、Deno、Bunを起動直後から利用できます。PythonはUbuntu標準版とuvを利用します。
* 軽量な調査・IaC補助ツールとしてSQLite、strace、lsof、age、SOPS、TFLint、terraform-docsを同梱します。
* イメージ肥大化を避けるため、Hermesのブラウザ依存、Ruby、Rust、Java、Kubernetes、Office・画像処理ツールは標準搭載しません。

### その他

#### VPN用に用意した社内信頼CA証明書が使えない

* VPNなどの環境で動かすためにコンテナ内部に `/etc/ssl/certs/ca-certificates.crt` を社内信頼証明書に追加したが、curlやgitなどがエラーになる
* Cloudflare ZeroTrust環境で発生
* 仕方ないので `GIT_SSL_NO_VERIFY=true` にしている
