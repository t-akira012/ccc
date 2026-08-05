#!/usr/bin/env bash

# Source this from the host shell:
#   source "$HOME/.local/.claude-code/host.sh"

# 長期 OAuth トークンの保管先 (claude 正規ディレクトリの外に置く)
ccc_token_file="${HOME}/.local/ccc/ccc-oauth-token"

# 保管トークンを env として注入する。
# bind mount せず値だけを渡すことで、隔離コンテナにファイル自体を晒さない。
# bedrock モードは AWS 認証で動き OAuth を要さないため注入しない。
ccc_export_oauth_token(){
  if [ "${CLAUDE_CODE_USE_BEDROCK:-0}" != 0 ]; then
    return 0
  fi
  if [ -f "${ccc_token_file}" ]; then
    local token
    token="$(cat "${ccc_token_file}")"
    export CLAUDE_CODE_OAUTH_TOKEN="${token}"
  fi
}

# 長期トークンを発行する (初回のみ)。
# 書き込み可能な使い捨てコンテナで setup-token を実行し、ホストの保管先に保存する。
# 通常の ccc は env 注入のみでマウントしないため、発行はこの関数に分離する。
ccc_login(){
  mkdir -p "$(dirname "${ccc_token_file}")"
  docker run --rm -it \
    -v "${HOME}/.local/ccc:/ccc" \
    origin_ccc:latest \
    bash -lc 'claude setup-token; read -r -p "表示された長期トークンを貼り付けてください: " token; printf "%s" "${token}" > /ccc/ccc-oauth-token'
}

ccc() {
  local ccc_dir="${HOME}/.local/.claude-code"

  if [ ! -f "${ccc_dir}/Makefile" ]; then
    echo "ccc: ${ccc_dir}/Makefile not found" >&2
    return 1
  fi

  ccc_export_oauth_token
  make -f "${ccc_dir}/Makefile" "$@"
}
