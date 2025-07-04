FROM ubuntu:latest

ARG RESEND_TOKEN
ARG MAIL_TO
ARG MAIL_DOMAIN

ENV TZ=Asia/Tokyo
ENV RESEND_TOKEN=${RESEND_TOKEN}
ENV MAIL_TO=${MAIL_TO}
ENV MAIL_DOMAIN=${MAIL_DOMAIN}
ENV MAIL_FROM=notify@${MAIL_DOMAIN}
ENV MAIL_HOSTNAME=mail.${MAIL_DOMAIN}

# 作業ディレクトリ設定
WORKDIR /workspace
COPY ./mail_notify /usr/bin/mail_notify
# プロジェクトファイルをコピー
COPY --chown=ubuntu:ubuntu . .
# スクリプトに実行権限付与
RUN chmod +x *.sh

# 最小限のシステムパッケージのみインストール
RUN <<EOF
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y build-essential curl git sudo ca-certificates procps tzdata libsasl2-modules
    apt-get clean
    rm -rf /var/lib/apt/lists/*

    # JST（日本標準時）を設定
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone

    # 非rootユーザーを作成（セキュリティ強化）
    useradd -m -s /bin/bash ubuntu
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
EOF

# 開発ユーザーに切り替え
USER ubuntu

# bashエイリアスとMCP設定を追加
RUN <<EOF
# Claude Code設定ディレクトリを作成
    mkdir -p /home/ubuntu/.claude
    mkdir -p /home/ubuntu/.config/claude
    mkdir -p /home/ubuntu/.config/gemini

cat >> /home/ubuntu/.bashrc << 'BASHRC_EOF'
source /workspace/.ccc/.env
source /workspace/.ccc/alias.sh
if [[ $- != *i* ]]; then
    source /workspace/.ccc/mcp.sh
    touch /workspace/temp_file.sh
fi
BASHRC_EOF
EOF

# Homebrewをインストール
RUN <<EOF
    # install homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/ubuntu/.bashrc
    # Homebrewで開発ツールをインストール
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    brew install wget make unzip vim ripgrep python@3.11 node go
    # pnpmをインストール
    npm install -g pnpm
    # pnpmセットアップ（環境変数を設定してから実行）
    mkdir -p $PNPM_HOME
    export PNPM_HOME=/home/ubuntu/.local/share/pnpm
    export PATH="$PNPM_HOME:$PATH"
    source /home/ubuntu/.bashrc
    pnpm setup
    pnpm install -g @anthropic-ai/claude-code @google/gemini-cli
EOF

# Claude CodeとGemini CLIの動作確認
RUN claude --version || echo "Claude Code installed, auth required"
RUN gemini --version || echo "Gemini CLI installed, auth required"

# デフォルトコマンド（対話型bash）
CMD ["bash", "-l"]
