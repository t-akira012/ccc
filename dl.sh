#!/usr/bin/env bash
set -eu

REPO_NAME=ccc
CCC_HOME="$HOME/.claude-code"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

curl -L "https://github.com/t-akira012/${REPO_NAME}/archive/main.tar.gz" --output "${TMP_DIR}/main.tar.gz"
tar -xf "${TMP_DIR}/main.tar.gz" -C "${TMP_DIR}"
rm -rf "${CCC_HOME}"
mkdir -p "$(dirname "${CCC_HOME}")"
mv "${TMP_DIR}/${REPO_NAME}-main" "${CCC_HOME}"

cd "${CCC_HOME}"
mv .env.temp .env
REPLACE_NAME=$(head /dev/urandom | md5sum | cut -c1-8)
perl -i -pe "s/container_origin_name/${REPLACE_NAME}/g" compose.yaml
perl -i -pe "s/container_origin_name/${REPLACE_NAME}/g" Makefile

echo "Installed CCC to ${CCC_HOME}"
echo "Add this to your host shell rc file:"
echo "source \"${CCC_HOME}/host.sh\""
