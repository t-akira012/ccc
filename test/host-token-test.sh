#!/usr/bin/env bash
set -eu

# host.sh の ccc_export_oauth_token を検証する。

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/../host.sh"

reset_env(){
  unset CLAUDE_CODE_OAUTH_TOKEN
  unset CLAUDE_CODE_USE_BEDROCK
}

test_exports_token_when_present(){
  local work
  work="$(mktemp -d)"
  ccc_token_file="${work}/ccc-oauth-token"
  printf 'sk-ant-oat01-HOST' > "${ccc_token_file}"
  reset_env

  ccc_export_oauth_token

  if [ "${CLAUDE_CODE_OAUTH_TOKEN}" != "sk-ant-oat01-HOST" ]; then
    echo "FAIL: token not exported: ${CLAUDE_CODE_OAUTH_TOKEN}" >&2
    return 1
  fi
  rm -rf "${work}"
  echo "PASS: exports token when present"
}

test_skips_when_absent(){
  local work
  work="$(mktemp -d)"
  ccc_token_file="${work}/ccc-oauth-token"   # ファイルは作らない
  reset_env

  ccc_export_oauth_token

  if [ "${CLAUDE_CODE_OAUTH_TOKEN+x}" = x ]; then
    echo "FAIL: must not export when file absent" >&2
    return 1
  fi
  rm -rf "${work}"
  echo "PASS: skips when file absent"
}

test_skips_in_bedrock(){
  local work
  work="$(mktemp -d)"
  ccc_token_file="${work}/ccc-oauth-token"
  printf 'sk-ant-oat01-HOST' > "${ccc_token_file}"
  reset_env
  export CLAUDE_CODE_USE_BEDROCK=1

  ccc_export_oauth_token

  if [ "${CLAUDE_CODE_OAUTH_TOKEN+x}" = x ]; then
    echo "FAIL: must not export in bedrock" >&2
    return 1
  fi
  unset CLAUDE_CODE_USE_BEDROCK
  rm -rf "${work}"
  echo "PASS: skips in bedrock"
}

main(){
  test_exports_token_when_present
  test_skips_when_absent
  test_skips_in_bedrock
  echo "ALL TESTS PASSED"
}

main
