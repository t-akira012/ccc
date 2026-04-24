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
        autoconf \
        bison \
        curl \
        file \
        git \
        gnupg \
        dirmngr \
        gawk \
        procps \
        locales \
        tzdata \
        sudo \
        ca-certificates \
        tar \
        unzip \
        xz-utils \
        libssl-dev \
        zlib1g-dev \
        libreadline-dev \
        libsqlite3-dev \
        libbz2-dev \
        libffi-dev \
        liblzma-dev \
        libyaml-dev
    
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
        uv
    # ------ キャッシュ削除 ------
    # イメージサイズ削減（それでも大きいが、ローカル環境では許容）
    brew cleanup --prune=all
    rm -rf "$(brew --cache)"
EOF

ENV GOPATH="/home/ubuntu/go"

# ============================================================
# asdf による言語ランタイムのインストール
# ============================================================
ENV ASDF_DIR="/home/ubuntu/.asdf"
ENV ASDF_DATA_DIR="/home/ubuntu/.asdf"
ENV PATH="${ASDF_DIR}/shims:${ASDF_DIR}/bin:/home/ubuntu/.local/bin:${PATH}"

RUN <<EOF
    set -e

    mkdir -p "$ASDF_DIR/bin"
    asdf_version="$(curl -fsSL https://api.github.com/repos/asdf-vm/asdf/releases/latest | jq -r .tag_name)"
    case "$(uname -m)" in
        x86_64) asdf_arch=amd64 ;;
        aarch64|arm64) asdf_arch=arm64 ;;
        *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
    esac
    curl -fsSL \
        "https://github.com/asdf-vm/asdf/releases/download/${asdf_version}/asdf-${asdf_version}-linux-${asdf_arch}.tar.gz" \
        -o /tmp/asdf.tar.gz
    tar -xzf /tmp/asdf.tar.gz -C "$ASDF_DIR/bin"
    rm -f /tmp/asdf.tar.gz
    asdf --version

    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
    asdf plugin add deno https://github.com/asdf-community/asdf-deno.git
    asdf plugin add golang https://github.com/asdf-community/asdf-golang.git
    asdf plugin add python https://github.com/danhper/asdf-python.git
    asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git

    nodejs_version="$(asdf latest nodejs)"
    deno_version="$(asdf latest deno)"
    golang_version="$(asdf latest golang)"
    python_version="$(asdf latest python)"
    ruby_version="$(asdf latest ruby)"

    asdf install nodejs "$nodejs_version"
    asdf install deno "$deno_version"
    asdf install golang "$golang_version"
    asdf install python "$python_version"
    asdf install ruby "$ruby_version"

    asdf set -u nodejs "$nodejs_version"
    asdf set -u deno "$deno_version"
    asdf set -u golang "$golang_version"
    asdf set -u python "$python_version"
    asdf set -u ruby "$ruby_version"

    asdf reshim

    npm install -g npm@latest
    npm install -g pnpm
    asdf reshim nodejs
EOF

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

# asdf
export ASDF_DATA_DIR="$HOME/.asdf"
export PATH="${ASDF_DATA_DIR}/shims:${ASDF_DATA_DIR}/bin:$PATH"
source "${ASDF_DATA_DIR}/plugins/golang/set-env.bash"

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
    echo "Go: $(go version)"
    echo "Python: $(python3 --version)"
    echo "Ruby: $(ruby --version)"
    echo "uv: $(uv --version)"
    echo "asdf: $(asdf --version)"
    echo "Neovim: $(nvim --version | head -1)"
    echo "Homebrew: $(brew --version | head -1)"
    echo "----------------------------------------"
    claude --version
    codex --version
    gemini --version
    echo "========================================"
EOF

CMD ["bash", "-l"]
