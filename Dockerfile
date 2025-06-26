FROM node:lts

# 追加パッケージをインストール
RUN apt-get update && apt-get install -y \
    # 基本ツール
    curl \
    wget \
    git \
    make \
    unzip \
    # エディタとユーティリティ
    nano \
    vim \
    ripgrep \
    # Python環境
    python3 \
    python3-pip \
    # ブラウザ認証用
    xdg-utils \
    # タイムゾーン設定用
    tzdata \
    && rm -rf /var/lib/apt/lists/* \
    # uvx
    && curl -LsSf https://astral.sh/uv/install.sh | sh

# JST（日本標準時）を設定
ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Claude Code CLIをグローバルインストール
RUN npm install -g @anthropic-ai/claude-code

# 非rootユーザーを作成（セキュリティ強化）
RUN useradd -m -s /bin/bash developer \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

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

# bashエイリアスを追加
RUN echo "alias ccc='claude'" >> /home/developer/.bashrc
RUN echo "alias cca='claude auth'" >> /home/developer/.bashrc
RUN echo "alias ccd='claude --dangerously-skip-permissions'" >> /home/developer/.bashrc

# Claude Codeの動作確認
RUN claude --version || echo "Claude Code installed, auth required"

# デフォルトコマンド（対話型bash）
CMD ["bash", "-l"]
