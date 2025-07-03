claude-notify() {
    local log_file="$1"
    mail -s "Claude Log" "${MAIL_TO}" < "$log_file"
}

# 簡易通知
notify() {
    echo "$(date) $1: $2"  < /dev/null |  mail -s "Notification" "${MAIL_TO}"
}
