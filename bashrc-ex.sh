alias ccc='claude'
alias cca='claude auth'
alias ccd='claude --dangerously-skip-permissions'
alias ccu='echo "Update Claude Code" && npm update -g @anthropic-ai/claude-code'
alias update_all='echo "Update AI Agents" && npm update -g @anthropic-ai/claude-code @openai/codex @google/gemini-cli'
export CLAUDE_CONFIG_DIR=/home/ubuntu/.config/claude
export GEMINI_CONFIG_DIR=/home/ubuntu/.config/gemini


# ============================================================
# ツール設定
# ============================================================
# fzf のキーバインド有効化
eval "$(fzf --bash)"

# bat: シンタックスハイライト付き cat
alias cat='bat --paging=never --style=plain'

# eza: 高機能 ls
# alias ls='eza'
# alias ll='eza -la --git'
# alias tree='eza --tree'

# delta: git diff を見やすく（git config で設定するのが本来だが、alias でも可）
alias diff='delta'
