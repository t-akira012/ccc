# Architecture

## 目的

このリポジトリは、Claude Code、Codex CLI、Gemini CLI、Hermes Agentを
ホストのシステム領域から隔離しつつ、対象workspaceでは自律的に動かせる
使い捨て開発コンテナを提供する。

コンテナへ入った直後から作業できることを重視し、言語やCLIの初回起動時
インストールは前提にしない。環境構築はDockerビルド時に完了させる。

リポジトリ本体は実行時にbind mountするため、Docker imageへコピーしない。
`.dockerignore` でbuild contextをDockerfileだけに限定し、`.git` やworkspace内の
一時ファイルがbuild送信量やcache invalidationを増やさないようにする。

## 実行境界

- ホストのカレントディレクトリを `/workspace` へ読み書き可能でmountする。
- workspaceの絶対パスからCompose project名を生成し、複数workspaceを並行実行する。
- Claudeの長期OAuthトークンはファイルをmountせず、環境変数の値だけを渡す。
- Codexの状態は `~/.codex`、Hermesの状態は `~/.hermes` をホストからmountする。
- AI CLIの実行ファイルやHermesのソースは、mountで隠れないイメージ内の別領域へ置く。
- Bedrockモードだけホストで取得した一時AWS認証情報をコンテナへ渡す。

これはホスト全体を保護するための境界であり、`/workspace` 内のデータ保護を
保証するsandboxではない。workspaceの変更や削除はAIエージェントの権限内である。

## 言語ランタイム

asdfはplugin clone、最新版探索、ソースビルドが多く、ビルド時間と障害点が
増えるため使用しない。miseで次のランタイムをDockerビルド時に導入する。

| Runtime | 系列 | 理由 |
| --- | --- | --- |
| Node.js | 24 | AI CLIと一般的なWeb/TypeScript開発 |
| Go | 1.26 | バックエンド、CLI、単一バイナリ系ツール |
| Deno | 2 | 軽量な事前ビルド済みTypeScript runtime |
| Bun | 1 | 軽量な事前ビルド済みruntime/package manager/test runner |
| Python | Ubuntu 24.04標準 | OS標準版を使い、project環境はuvで管理 |

miseの指定は安定系列を固定する。解決されたpatchバージョンはDocker layerへ
保存され、通常起動ではダウンロードされない。意図的なイメージ再ビルド時に
系列内の更新を取り込む。Ruby、Rust、Javaは常用用途がなく、容量・構築時間に
対する効果が低いため標準搭載しない。

asdf時代に必要だったPython/Rubyのソースビルド用development libraryは削除する。
Python 3とvenvだけをUbuntu packageとして明示的に導入し、追加のPython versionや
project dependencyはuvで管理する。

## ツール選定基準

採用条件は次の通り。

1. コンテナへ入った直後に利用価値がある。
2. 事前ビルド済みバイナリまたはHomebrew bottleがある。
3. daemonや大型データベースを常駐させない。
4. 同等機能の既存CLIに対して明確な利点がある。
5. 認証情報をイメージへ焼き込まない。

標準搭載する軽量ツールにはPandoc、SQLite、strace、lsof、age、SOPS、
TFLint、terraform-docsを含む。TerraformはHashiCorp公式Homebrew tapから導入する。
TFLintは廃止予定の公式install scriptを使わず、公式GitHub Releaseの
事前ビルド済みバイナリをバージョン固定して導入する。

標準搭載しない重量級カテゴリは次の通り。

- JDK、Gradle、MavenなどのJVM環境
- Rust toolchain
- Kubernetes CLI群
- LibreOffice、ImageMagickなどのOffice・画像処理環境
- Trivyのように大型DBの継続取得を伴うscanner
- Docker socketへのアクセスを必要とするDocker-in-Docker相当の構成

Hermes Agentは標準搭載するが、Chromium/Playwrightの取得を避けるため
`--skip-browser` で導入する。必要になった重量級機能は標準イメージへ混ぜず、
用途別imageまたは明示的なprofileとして追加する。

## AI CLIの導入

- Claude Code: Anthropic公式native installer。自動更新可能。
- Codex CLI: OpenAI公式standalone installer。package本体と `~/.codex` を分離。
- Hermes Agent: Nous Research公式installer。setupとbrowser取得をビルド時にskip。
- Gemini CLI: npm package。Node.jsはmiseで事前導入する。

Hermesのprovider認証など、ユーザー固有でビルド時に確定できない操作だけは
初回利用時の `hermes setup` に残す。これはソフトウェア導入ではなく認証・設定である。

## 更新と再現性

ベースイメージとtool系列は明示する。通常の `docker compose up` は既存imageを
再利用し、ネットワークからtoolchainを取得しない。`build-nocache` は意図的な
全面更新操作であり、native installerや指定系列内の最新patchを取り込む。

ビルド末尾で主要CLIの `--version` を実行し、PATH、mount前の配置、installerの
成功を検証する。シェルロジックは構文検査、ShellCheck、OAuth単体テストで確認する。
