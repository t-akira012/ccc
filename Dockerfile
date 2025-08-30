FROM ubuntu:latest
ENV TZ=Asia/Tokyo
# 作業ディレクトリ設定
WORKDIR /workspace
# プロジェクトファイルをコピー
COPY --chown=ubuntu:ubuntu . .
# スクリプトに実行権限付与
# RUN chmod +x *.sh

RUN <<EOF
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y \
        build-essential curl git sudo ca-certificates procps tzdata libsasl2-modules \
        nodejs npm \
        vim \
        pipx python3-all python-is-python3
    apt-get clean
    rm -rf /var/lib/apt/lists/*

    # ca update
    update-ca-certificates

    # Install AI Agents
    npm install -g @anthropic-ai/claude-code @openai/codex @google/gemini-cli

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
    mkdir -p /home/ubuntu/.codex
    mkdir -p /home/ubuntu/.config/claude
    mkdir -p /home/ubuntu/.config/gemini

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
