FROM --platform=linux/amd64 public.ecr.aws/docker/library/archlinux:latest

# pacmanを初期化とアップデート
RUN pacman-key --init \
    && pacman-key --populate \
    && pacman -Sy --noconfirm archlinux-keyring \
    && pacman -Syu --noconfirm

# 必要なパッケージをインストール
RUN pacman -S --noconfirm \
    # 基本ツール
    base-devel \
    curl \
    wget \
    git \
    make \
    unzip \
    # エディタとユーティリティ
    vim \
    ripgrep \
    # Python環境
    python \
    python-pip \
    python-uv \
    # Node.js環境
    nodejs \
    npm \
    pnpm \
    # Go環境
    go \
    # メール送信（軽量設定）
    msmtp \
    msmtp-mta \
    s-nail \
    # ブラウザ認証用
    xdg-utils \
    # タイムゾーン設定用
    tzdata \
    # sudo
    sudo \
    && pacman -Scc --noconfirm

# JST（日本標準時）を設定
ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Claude Code CLIをグローバルインストール
RUN npm install -g @anthropic-ai/claude-code

# 非rootユーザーを作成（セキュリティ強化）
RUN useradd -m -s /bin/bash developer \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# msmtp設定（自前SMTPサーバ用）
RUN cat <<EOF > /etc/msmtprc
# 自前SMTP設定
defaults
auth           off
tls            off
port           25
domain         localhost

# 自前SMTPサーバアカウント
account        local
host           smtp.local
from           notifications@container

# デフォルトアカウント
account default : local
EOF

# 設定ファイルのパーミッション設定
RUN chmod 644 /etc/msmtprc

# メール宛先リスト（環境変数MAIL_RECIPIENTSで上書き可能）
COPY ./.env.mail /etc/mail-recipients

# 作業ディレクトリ設定
WORKDIR /workspace

# プロジェクトファイルをコピー
COPY --chown=developer:developer . .

# スクリプトに実行権限付与
RUN chmod +x *.sh

# 開発ユーザーに切り替え
USER developer

# Claude Code設定ディレクトリを作成
RUN mkdir -p /home/developer/.claude

# bashエイリアスとMCP設定を追加
RUN cat <<EOF > /home/developer/.bashrc
alias ccc='claude'
alias cca='claude auth'
alias ccd='claude --dangerously-skip-permissions'
export CLAUDE_CONFIG_DIR=/home/developer/.config/claude
source /workspace/.ccc/mcp.sh

# Go環境変数
export GOPATH=/home/developer/go
export PATH=\$PATH:\$GOPATH/bin

# pnpmグローバルディレクトリ
export PNPM_HOME=/home/developer/.local/share/pnpm
export PATH=\$PATH:\$PNPM_HOME

# メール通知関数
notify() {
    local subject="\${1:-Container Alert}"
    local message="\${2:-Notification from container}"
    local recipients="\${MAIL_RECIPIENTS:-\$(cat /etc/mail-recipients 2>/dev/null || echo 'admin@example.com')}"
    
    echo "\$message"  < /dev/null |  mail -s "\$subject" \$recipients
}

# メール送信エイリアス
alias alert='notify'
EOF

# 環境変数設定
ENV MAIL_RECIPIENTS=""
ENV SMTP_HOST="smtp.local"

# Claude Codeの動作確認
RUN claude --version || echo "Claude Code installed, auth required"

# デフォルトコマンド（対話型bash）
CMD ["bash", "-l"]
