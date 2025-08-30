FROM ubuntu:devel

ENV TZ=Asia/Tokyo
# 作業ディレクトリ設定
WORKDIR /workspace
# プロジェクトファイルをコピー
COPY --chown=ubuntu:ubuntu . .

# base package & python
RUN <<EOF
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends \
        build-essential curl git sudo ca-certificates procps tzdata libsasl2-modules vim software-properties-common \
        pipx python3-all python-is-python3
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# install uv
RUN <<EOF
    pipx ensurepath
    source ~/.bashrc
    pipx install uv
EOF

# install nodejs
RUN <<EOF
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y --no-install-recommends nodejs
    corepack enable
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# install ai agent
RUN <<EOF
    set -euo pipefail
    # https://zenn.dev/discus0434/scraps/e0b1a0aa5406eb
    npm install -g @anthropic-ai/claude-code@1.0.24 @openai/codex@native @google/gemini-cli
EOF

RUN <<EOF
    set -euo pipefail
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

EOF



# 開発ユーザーに切り替え
USER ubuntu

# bashエイリアスとMCP設定を追加
RUN <<EOF
# Claude Code設定ディレクトリを作成
    mkdir -p /home/ubuntu/.claude
    mkdir -p /home/ubuntu/.codex
    mkdir -p /home/ubuntu/.config/claude
    mkdir -p /home/ubuntu/.config/gemini

    # aliasやexportを追加したい場合は、alias.shに追記する
    cat >> /home/ubuntu/.bashrc << 'BASHRC_EOF'
source /workspace/.claude-code/.env
source /workspace/.claude-code/alias.sh
if [[ $- != *i* ]]; then
    source /workspace/.claude-code/mcp.sh
fi
BASHRC_EOF
EOF

# Claude CodeとGemini CLIの動作確認
RUN claude --version || echo "Claude Code installed, auth required"
RUN codex --version || echo "Codex CLI installed, auth required"
RUN gemini --version || echo "Gemini CLI installed, auth required"

# デフォルトコマンド（対話型bash）
CMD ["bash", "-l"]
