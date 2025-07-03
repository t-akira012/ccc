#!/usr/bin/env bash
# メール通知関数（Claude用）
claude-notify() {
    claude code "$@" 2>&1 | tee /tmp/claude.log
    local exit_code=$?
    local status=\$([ \$exit_code -eq 0 ] && echo "Success" || echo "Failed")
    mail -s "Claude $status" "${MAIL_TO}" < /tmp/claude.log
    rm -f /tmp/claude.log
    return $exit_code
}

# メール通知関数（Gemini用）
gemini-notify() {
    gemini "$@" 2>&1 | tee /tmp/gemini.log
    local exit_code=$?
    local status=$([ $exit_code -eq 0 ] && echo "Success" || echo "Failed")
    mail -s "Gemini $status" "${MAIL_TO}" < /tmp/gemini.log
    rm -f /tmp/gemini.log
    return $exit_code
}

# 簡易通知
notify() {
    echo "$2" | mail -s "$1" "${MAIL_TO}"
}

alias alert='notify "Container Alert"'
