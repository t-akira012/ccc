alias ccc='claude'
alias cca='claude auth'
alias ccd='claude --dangerously-skip-permissions'
alias ggc='gemini'
export CLAUDE_CONFIG_DIR=/home/ubuntu/.config/claude
export GEMINI_CONFIG_DIR=/home/ubuntu/.config/gemini

# Go環境変数
export GOPATH=/home/ubuntu/go
export PATH=$PATH:$GOPATH/bin
export PNPM_HOME=/home/ubuntu/.local/share/pnpm
export PATH="$PNPM_HOME:$PATH"

claude_smart_notify() {
  local TEMP_FILE=$(mktemp)
  if [[ -n $1 ]];then
    echo $(echo '1行目はタイトルにしなさい。2行目以降に出力を書きます。-p オプションの利用時はメール通知禁止'; cat $1) | claude -p > $TEMP_FILE
    local title=$(cat $TEMP_FILE | head -1)
    /usr/bin/mail_notify "$title" --file $TEMP_FILE
  else
    echo 引数にプロンプトファイルパスが必須です
  fi
  echo $TEMP_FILE
  cat $TEMP_FILE
}

