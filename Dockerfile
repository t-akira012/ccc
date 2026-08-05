# syntax=docker/dockerfile:1.4
# バージョンを明示的に固定（LTS、2029年までサポート）
FROM public.ecr.aws/ubuntu/ubuntu:24.04

ENV TZ=Asia/Tokyo
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en

# Homebrew の挙動制御
# - 自動アップデートを無効化（ビルド時間短縮、再現性向上）
# - 匿名の使用統計送信を無効化
ENV HOMEBREW_NO_AUTO_UPDATE=1
ENV HOMEBREW_NO_ANALYTICS=1
ENV HOMEBREW_NO_INSTALL_CLEANUP=0

WORKDIR /workspace

# TODO: VPN/プロキシ環境での証明書問題の回避策
# 本来は正しく証明書を設定すべき
ENV GIT_SSL_NO_VERIFY=true

# ============================================================
# システム基盤の構築（apt）
# ここでは Homebrew の依存関係と、brew では入れにくいものだけを入れる
# ============================================================
RUN <<EOF
    set -e
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get update
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        file \
        git \
        gnupg \
        procps \
        lsof \
        python3 \
        python3-venv \
        sqlite3 \
        strace \
        locales \
        tzdata \
        sudo \
        ca-certificates \
        tar \
        unzip \
        xz-utils
    
    # ロケール生成（Homebrew が必要とする）
    locale-gen en_US.UTF-8
    
    # タイムゾーン設定
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone
    
    # 非rootユーザー作成
    # useradd -m -s /bin/bash ubuntu -- ubuntu userはすでに存在するので作らなくて良い
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    
    # クリーンアップ
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# ============================================================
# 以降は ubuntu ユーザーで実行
# ============================================================
USER ubuntu
ENV HOME=/home/ubuntu

# ============================================================
# Homebrew のインストール
# ============================================================
RUN <<EOF
    set -e
    
    # 非対話的インストール
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # シェル環境に追加（この RUN 内で brew を使うため）
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    
    # 動作確認
    brew --version
EOF

# Homebrew の PATH を永続化
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
ENV HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
ENV HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"

# ============================================================
# 開発ツールのインストール（brew）
# ここが「安定した初期状態」の中核
# ============================================================
RUN <<EOF
    set -e

    # HashiCorp公式tapからTerraformを導入
    brew tap hashicorp/tap

    # ------ 開発支援ツール ------
    # これらが最初から使えることで、destroy しても快適に作業再開できる
    
    brew install \
        gh \
        ripgrep \
        fzf \
        jq \
        yq \
        bat \
        eza \
        fd \
        delta \
        lazygit \
        tmux \
        neovim \
        tree \
        shellcheck \
        shfmt \
        pandoc \
        mise \
        age \
        sops \
        terraform-docs \
        uv \
        hashicorp/tap/terraform
    # ------ キャッシュ削除 ------
    # イメージサイズ削減（それでも大きいが、ローカル環境では許容）
    brew cleanup --prune=all
    rm -rf "$(brew --cache)"
EOF

# TFLintは公式GitHub Releaseの事前ビルド済みバイナリを導入する。
# 公式install_linux.shは2026-09-01廃止予定のため使用しない。
ARG TFLINT_VERSION=v0.63.0
RUN <<EOF
    set -e
    case "$(uname -m)" in
        x86_64) tflint_arch=amd64 ;;
        aarch64|arm64) tflint_arch=arm64 ;;
        *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
    esac
    curl -fsSL \
        "https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_${tflint_arch}.zip" \
        -o /tmp/tflint.zip
    unzip -q /tmp/tflint.zip -d /tmp/tflint
    sudo install -m 0755 /tmp/tflint/tflint /usr/local/bin/tflint
    rm -rf /tmp/tflint /tmp/tflint.zip
EOF

# ============================================================
# mise による言語ランタイムのインストール
# ============================================================
# major/minor系列を固定し、事前ビルド済み配布物をビルド時に取得する。
# Docker layerが有効な限り再取得せず、明示的な再ビルドで系列内を更新する。
ENV MISE_DATA_DIR="/home/ubuntu/.local/share/mise"
ENV MISE_CONFIG_DIR="/home/ubuntu/.config/mise"
ENV MISE_CACHE_DIR="/home/ubuntu/.cache/mise"
ENV PATH="${MISE_DATA_DIR}/shims:/home/ubuntu/.local/bin:${PATH}"
ENV GOPATH="/home/ubuntu/go"
ARG NODE_VERSION=24
ARG GO_VERSION=1.26
ARG DENO_VERSION=2
ARG BUN_VERSION=1

RUN <<EOF
    set -e

    mkdir -p "$MISE_DATA_DIR" "$MISE_CONFIG_DIR" "$MISE_CACHE_DIR"
    mise use --global \
        "node@${NODE_VERSION}" \
        "go@${GO_VERSION}" \
        "deno@${DENO_VERSION}" \
        "bun@${BUN_VERSION}"
    mise reshim

    npm install -g pnpm@latest
    mise reshim
EOF

# ============================================================
# AI エージェントのインストール
# ============================================================
RUN <<EOF
    set -e

    # Claude Code: Anthropic推奨のnative installer
    curl -fsSL https://claude.ai/install.sh | bash

    # Codex CLI: OpenAI公式のstandalone installer。
    # 実行時にbind mountされる ~/.codex とパッケージ本体を分離する。
    mkdir -p /home/ubuntu/.local/share/codex-install
    curl -fsSL https://chatgpt.com/codex/install.sh \
        | CODEX_NON_INTERACTIVE=1 \
          CODEX_HOME=/home/ubuntu/.local/share/codex-install \
          CODEX_INSTALL_DIR=/home/ubuntu/.local/bin \
          sh

    # Hermes Agent: 公式installerを非対話で実行し、初期設定は利用時に行う。
    # コード本体は永続化対象の ~/.hermes の外に置く。
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh \
        | bash -s -- \
          --non-interactive \
          --skip-setup \
          --skip-browser \
          --dir /home/ubuntu/.local/share/hermes-agent

    npm install -g @google/gemini-cli
    npm cache clean --force
    rm -rf "$MISE_CACHE_DIR"
    
    # 設定ディレクトリの作成
    mkdir -p /home/ubuntu/.claude
    mkdir -p /home/ubuntu/.config/claude
    mkdir -p /home/ubuntu/.codex
    mkdir -p /home/ubuntu/.hermes
    mkdir -p /home/ubuntu/.config/gemini
    mkdir -p /home/ubuntu/.config/nvim
EOF

# ============================================================
# パッケージマネージャ設定
# ============================================================
RUN <<EOF
    set -e

    npm config set ignore-scripts=true --global
    npm config set min-release-age=7 --global

    pnpm config set --location=global minimumReleaseAge 14400
    pnpm config list --location=global
EOF

# ============================================================
# シェル設定
# ============================================================
RUN <<EOF
    cat >> /home/ubuntu/.bashrc << 'BASHRC_EOF'
# homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# mise
eval "$(mise activate bash)"

# PATH
export PATH="$PATH:/home/ubuntu/.local/bin"

# .claude-code
source $HOME/.claude-code/bashrc-ex.sh

source $HOME/.claude-code/mcp.sh
BASHRC_EOF
EOF

# ============================================================
# ビルド完了時の確認（ログ用）
# ============================================================
RUN <<EOF
    echo "========================================"
    echo "Build completed. Installed versions:"
    echo "========================================"
    echo "Node.js: $(node --version)"
    echo "npm: $(npm --version)"
    echo "pnpm: $(pnpm --version)"
    echo "Deno: $(deno --version | head -1)"
    echo "Bun: $(bun --version)"
    echo "Go: $(go version)"
    echo "Python: $(python3 --version)"
    echo "uv: $(uv --version)"
    echo "mise: $(mise --version)"
    echo "Neovim: $(nvim --version | head -1)"
    echo "Pandoc: $(pandoc --version | head -1)"
    echo "Homebrew: $(brew --version | head -1)"
    echo "TFLint: $(tflint --version | head -1)"
    echo "terraform-docs: $(terraform-docs --version)"
    echo "----------------------------------------"
    claude --version
    codex --version
    gemini --version
    hermes --version
    terraform version
    echo "========================================"
EOF

CMD ["bash", "-l"]
