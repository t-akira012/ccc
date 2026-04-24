#!/usr/bin/env bash

# Source this from the host shell:
#   source "$HOME/.claude-code/host.sh"

ccc() {
  local ccc_dir="$HOME/.local/.claude-code"

  if [ ! -f "${ccc_dir}/Makefile" ]; then
    echo "ccc: ${ccc_dir}/Makefile not found" >&2
    return 1
  fi

  make -f "${ccc_dir}/Makefile" "$@"
}
