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
COPY --chown=ubuntu:ubuntu . .

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
        procps \
        locales \
        tzdata \
        sudo \
        ca-certificates
    
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
    
    # ------ 言語ランタイム ------
    # Node.js: Claude Code, Codex, Gemini CLI に必要
    brew install node@22
    brew link node@22
    
    # Python: uvx, 各種スクリプトに必要
    brew install python@3.12 uv
    
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
        vim \
        tree \
        shellcheck \
        shfmt \
        go \
        deno
    # ------ キャッシュ削除 ------
    # イメージサイズ削減（それでも大きいが、ローカル環境では許容）
    brew cleanup --prune=all
    rm -rf "$(brew --cache)"
EOF

ENV GOPATH="/home/ubuntu/go"

# ============================================================
# AI エージェントのインストール
# ============================================================
RUN <<EOF
    set -e
    
    npm install -g @anthropic-ai/claude-code
    npm install -g @openai/codex
    npm install -g @google/gemini-cli
    
    # 設定ディレクトリの作成
    mkdir -p /home/ubuntu/.claude
    mkdir -p /home/ubuntu/.config/claude
    mkdir -p /home/ubuntu/.codex
    mkdir -p /home/ubuntu/.config/gemini
EOF

# ============================================================
# シェル設定
# ============================================================
RUN <<EOF
    cat >> /home/ubuntu/.bashrc << 'BASHRC_EOF'
# homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# PATH
export PATH="$PATH:/home/ubuntu/.local/bin"

# .claude-code ディレクトリが存在する場合のみ読み込む
if [ -d "/workspace/.claude-code" ]; then
    [ -f "/workspace/.claude-code/.env" ] && source /workspace/.claude-code/.env
    [ -f "/workspace/.claude-code/bashrc-ex.sh" ] && source /workspace/.claude-code/bashrc-ex.sh
    
    # 非対話シェルの場合のみ MCP 設定を読み込む
    if [[ $- != *i* ]]; then
        [ -f "/workspace/.claude-code/mcp.sh" ] && source /workspace/.claude-code/mcp.sh
    fi
fi
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
    echo "Python: $(python3 --version)"
    echo "uv: $(uv --version)"
    echo "Homebrew: $(brew --version | head -1)"
    echo "----------------------------------------"
    claude --version 2>/dev/null || echo "Claude Code: installed (auth required)"
    codex --version 2>/dev/null || echo "Codex CLI: installed (auth required)"
    gemini --version 2>/dev/null || echo "Gemini CLI: installed (auth required)"
    echo "========================================"
EOF

CMD ["bash", "-l"]
